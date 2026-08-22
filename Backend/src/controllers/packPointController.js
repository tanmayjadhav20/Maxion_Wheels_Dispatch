const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateWheelQr, generatePalletQr } = require('../utils/qr');

let currentActivePallet = null;

function printWheelQr(req, res) {
  const { itemCode, shift = 'A', line = 'PL2', count = 1 } = req.body;
  const store = getStore();

  const itemMaster = store.items.find(i => i.itemCode === itemCode);
  if (!itemMaster) {
    return res.status(404).json({ success: false, message: 'Item code not found in master' });
  }

  const baseSerial = Date.now();
  const dateStr = new Date().toISOString().slice(2, 10).replace(/-/g, '');
  const printCount = Math.max(1, Math.min(200, parseInt(count) || 1));

  const stickers = [];
  for (let i = 0; i < printCount; i++) {
    const serialNumber = String(baseSerial + i).slice(-8);
    const wheelQr = generateWheelQr({
      plant: 'P1',
      itemCode,
      serial: serialNumber,
      date: dateStr,
      shift,
      line
    });
    stickers.push({
      wheelQr,
      serialNumber,
      itemCode,
      wheelIndex: i + 1,
      totalBatchCount: printCount
    });
  }

  res.json({
    success: true,
    message: `Generated ${printCount} unique wheel QR stickers for ${itemCode}`,
    stickers,
    wheelQr: stickers[0].wheelQr,
    itemCode,
    totalCount: printCount
  });
}

function getActivePallet(req, res) {
  const store = getStore();
  res.json({
    success: true,
    activePallet: currentActivePallet
  });
}

function startOrScanWheel(req, res) {
  const { wheelQr, itemCode } = req.body;
  const store = getStore();

  const itemMaster = store.items.find(i => i.itemCode === itemCode);
  const stdQty = itemMaster ? itemMaster.stdPalletQty : 96;

  // Check if active pallet exists
  if (!currentActivePallet || currentActivePallet.itemCode !== itemCode) {
    // Check if there is an available half pallet to reuse (SSR Section 4.2 Step 1)
    const availableHalf = store.pallets.find(p =>
      p.itemCode === itemCode && (p.status === 'STORED_HALF' || p.typeSeries === 'H')
    );

    if (availableHalf && !req.body.ignoreHalfPallet) {
      return res.json({
        success: true,
        halfPalletAvailable: true,
        halfPallet: {
          palletNumber: availableHalf.palletNumber,
          currentQty: availableHalf.packedQty,
          shortfallQty: stdQty - availableHalf.packedQty,
          locationCode: availableHalf.locationCode,
          ageDays: Math.floor((Date.now() - new Date(availableHalf.createdAt).getTime()) / (1000 * 60 * 60 * 24)) || 1
        },
        message: `HALF PALLET AVAILABLE — use it first! ${availableHalf.palletNumber} with ${availableHalf.packedQty}/${stdQty} wheels at ${availableHalf.locationCode}`
      });
    }

    currentActivePallet = {
      palletNumber: formatNumber('P'),
      typeSeries: 'P',
      itemCode,
      packedQty: 0,
      stdQty,
      status: 'PACKING',
      wheels: [],
      currentLayer: 1,
      createdAt: new Date().toISOString()
    };
  }

  // Scan wheel onto active pallet
  if (wheelQr) {
    if (currentActivePallet.wheels.includes(wheelQr)) {
      return res.status(400).json({ success: false, message: 'DUPLICATE: Wheel QR already scanned on this pallet!' });
    }

    currentActivePallet.wheels.push(wheelQr);
    currentActivePallet.packedQty = currentActivePallet.wheels.length;
    currentActivePallet.currentLayer = Math.ceil(currentActivePallet.packedQty / (itemMaster ? itemMaster.wheelsPerLayer : 24));

    // Record in wheels store
    store.wheels.push({
      wheelQr,
      itemCode,
      palletNumber: currentActivePallet.palletNumber,
      packedBy: req.user ? req.user.name : 'Pack Operator',
      packedAt: new Date().toISOString()
    });

    // Update paint plan actual count
    const latestPlan = store.paintPlans ? store.paintPlans[0] : null;
    if (latestPlan) {
      const planItem = latestPlan.items.find(i => i.itemCode === itemCode);
      if (planItem) {
        planItem.packedQty = (planItem.packedQty || 0) + 1;
      }
    }

    saveStore();
  }

  res.json({
    success: true,
    activePallet: currentActivePallet,
    message: wheelQr ? `Wheel scanned: ${currentActivePallet.packedQty}/${currentActivePallet.stdQty}` : 'Pallet active'
  });
}

function closePallet(req, res) {
  const { reason = 'Standard Qty Reached', forceClose = false } = req.body;
  const store = getStore();

  if (!currentActivePallet) {
    return res.status(400).json({ success: false, message: 'No active pallet to close' });
  }

  let finalSeries = 'P';
  let finalStatus = 'CLOSED_FULL';
  let finalPalletNumber = currentActivePallet.palletNumber;

  if (currentActivePallet.oldHalfPalletNumber) {
    // Merged pallet logic (SSR Section 4.2 Step 5)
    finalSeries = 'PM';
    finalStatus = currentActivePallet.packedQty >= currentActivePallet.stdQty ? 'CLOSED_MERGED_FULL' : 'CLOSED_MERGED_HALF';
    finalPalletNumber = formatNumber('PM');

    // Void old H pallet and free old location
    const oldH = store.pallets.find(p => p.palletNumber === currentActivePallet.oldHalfPalletNumber);
    if (oldH) {
      oldH.status = 'MERGED_CONSUMED';
      oldH.mergedIntoPalletNumber = finalPalletNumber;
    }
  } else if (currentActivePallet.packedQty < currentActivePallet.stdQty) {
    // Sudden Changeover Half Pallet (SSR Section 4.1 Step 3)
    finalSeries = 'H';
    finalStatus = 'STORED_HALF';
    finalPalletNumber = formatNumber('H');
  } else {
    // Full Pallet
    finalSeries = 'P';
    finalStatus = 'STORED';
    finalPalletNumber = currentActivePallet.palletNumber.startsWith('P') ? currentActivePallet.palletNumber : formatNumber('P');
  }

  const closedPallet = {
    ...currentActivePallet,
    palletNumber: finalPalletNumber,
    typeSeries: finalSeries,
    status: finalStatus,
    masterQr: generatePalletQr(finalPalletNumber),
    closeReason: reason,
    locationCode: finalSeries === 'H' ? 'WH1-HALF-BAY' : 'WH1-STG-01',
    closedAt: new Date().toISOString(),
    closedBy: req.user ? req.user.name : 'Pack Operator'
  };

  store.pallets.unshift(closedPallet);
  currentActivePallet = null;
  saveStore();

  res.json({
    success: true,
    message: `Pallet closed successfully as ${finalSeries} (${closedPallet.palletNumber} - ${closedPallet.packedQty}/${closedPallet.stdQty})`,
    closedPallet
  });
}

function loadAndResumeHalfPallet(req, res) {
  const { halfPalletNumber } = req.body;
  const store = getStore();

  const halfPallet = store.pallets.find(p => p.palletNumber === halfPalletNumber);
  if (!halfPallet) {
    return res.status(404).json({ success: false, message: 'Half pallet not found' });
  }

  const itemMaster = store.items.find(i => i.itemCode === halfPallet.itemCode);

  currentActivePallet = {
    palletNumber: halfPallet.palletNumber,
    typeSeries: 'PM',
    oldHalfPalletNumber: halfPallet.palletNumber,
    itemCode: halfPallet.itemCode,
    packedQty: halfPallet.packedQty,
    stdQty: itemMaster ? itemMaster.stdPalletQty : 96,
    status: 'PACKING_MERGE',
    wheels: halfPallet.wheels || [],
    currentLayer: Math.ceil(halfPallet.packedQty / (itemMaster ? itemMaster.wheelsPerLayer : 24)),
    createdAt: halfPallet.createdAt || new Date().toISOString()
  };

  halfPallet.status = 'MERGING';
  saveStore();

  res.json({
    success: true,
    message: `Half pallet ${halfPalletNumber} loaded. Resuming counter at ${halfPallet.packedQty}/${currentActivePallet.stdQty}`,
    activePallet: currentActivePallet
  });
}

module.exports = {
  printWheelQr,
  getActivePallet,
  startOrScanWheel,
  closePallet,
  loadAndResumeHalfPallet
};
