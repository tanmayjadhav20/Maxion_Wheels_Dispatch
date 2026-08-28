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

function resolvePalletCapacity(itemCode) {
  const store = getStore();
  if (!itemCode) return 96;

  // 1. Look up in Master Items
  if (store.items && Array.isArray(store.items)) {
    const im = store.items.find(i => 
      i.itemCode === itemCode || 
      (i.itemCode && String(i.itemCode).toLowerCase() === String(itemCode).toLowerCase())
    );
    if (im) {
      if (im.stdPalletQty != null) return parseInt(im.stdPalletQty) || 96;
      if (im.standardPalletQty != null) return parseInt(im.standardPalletQty) || 96;
      if (im.capacity != null) return parseInt(im.capacity) || 96;
      if (im.wheelsPerLayer && im.layersPerPallet) {
        return parseInt(im.wheelsPerLayer) * parseInt(im.layersPerPallet);
      }
    }
  }

  // 2. Look up in Pallet Masters
  if (store.palletMasters && Array.isArray(store.palletMasters)) {
    const pm = store.palletMasters.find(p => p.itemCode === itemCode || p.palletType === itemCode);
    if (pm && pm.capacity) return parseInt(pm.capacity) || 96;
  }

  // 3. Look up in Paint Plans
  if (store.paintPlans && store.paintPlans.length > 0) {
    for (const plan of store.paintPlans) {
      const planItem = (plan.items || []).find(i => i.itemCode === itemCode);
      if (planItem && planItem.stdPalletQty) return parseInt(planItem.stdPalletQty);
    }
  }

  return 96;
}

function getActivePallet(req, res) {
  const store = getStore();

  if (store.activePallet) {
    store.activePallet.stdQty = resolvePalletCapacity(store.activePallet.itemCode);
    const itemMaster = store.items ? store.items.find(i => i.itemCode === store.activePallet.itemCode) : null;
    const wheelsPerLayer = itemMaster ? (itemMaster.wheelsPerLayer || Math.ceil(store.activePallet.stdQty / 4)) : (store.activePallet.stdQty > 0 ? Math.ceil(store.activePallet.stdQty / 4) : 24);
    store.activePallet.currentLayer = Math.max(1, Math.ceil((store.activePallet.packedQty || 0) / (wheelsPerLayer || 1)));
  }

  if (!store.activePallet || store.activePallet.status === 'CLOSED_FULL' || store.activePallet.status === 'STORED' || store.activePallet.status === 'STORED_HALF') {
    const openPallet = (store.pallets || []).find(p => p.status === 'OPEN' || p.status === 'PACKING');
    if (openPallet) {
      const itemMaster = store.items.find(i => i.itemCode === openPallet.itemCode);
      const stdQty = resolvePalletCapacity(openPallet.itemCode);
      const wheelsPerLayer = itemMaster ? (itemMaster.wheelsPerLayer || Math.ceil(stdQty / 4)) : (stdQty > 0 ? Math.ceil(stdQty / 4) : 24);
      store.activePallet = {
        palletNumber: openPallet.palletNumber,
        typeSeries: openPallet.typeSeries || 'P',
        itemCode: openPallet.itemCode,
        packedQty: openPallet.packedQty || 0,
        stdQty: stdQty,
        status: 'PACKING',
        wheels: openPallet.wheels || [],
        currentLayer: Math.max(1, Math.ceil((openPallet.packedQty || 0) / wheelsPerLayer)),
        createdAt: openPallet.createdAt || new Date().toISOString()
      };
      saveStore();
    } else {
      const latestPlan = (store.paintPlans && store.paintPlans.length > 0) ? store.paintPlans[0] : null;
      if (latestPlan && latestPlan.items && latestPlan.items.length > 0) {
        const itemCode = latestPlan.items[0].itemCode;
        const stdQty = resolvePalletCapacity(itemCode);
        const palletNo = latestPlan.newPalletCreated || formatNumber('P');
        store.activePallet = {
          palletNumber: palletNo,
          typeSeries: 'P',
          itemCode,
          packedQty: 0,
          stdQty,
          status: 'PACKING',
          wheels: [],
          currentLayer: 1,
          createdAt: new Date().toISOString()
        };
        saveStore();
      }
    }
  }

  res.json({
    success: true,
    activePallet: store.activePallet || null
  });
}

function startOrScanWheel(req, res) {
  const { wheelQr, itemCode, ignoreHalfPallet, palletCapacity } = req.body;
  const store = getStore();

  const targetItem = itemCode || (store.activePallet ? store.activePallet.itemCode : 'MXW-17-BLK');
  const itemMaster = store.items ? store.items.find(i => i.itemCode === targetItem) : null;
  const configuredCapacity = palletCapacity && Number(palletCapacity) > 0 ? Number(palletCapacity) : resolvePalletCapacity(targetItem);
  const stdQty = configuredCapacity;
  const wheelsPerLayer = itemMaster ? (itemMaster.wheelsPerLayer || Math.max(1, Math.ceil(stdQty / 4))) : Math.max(1, Math.ceil(stdQty / 4));

  let currentActivePallet = store.activePallet;

  // Check if active pallet needs to be initialized or switched to a new item/capacity
  if (!currentActivePallet || currentActivePallet.status === 'CLOSED_FULL' || currentActivePallet.status === 'STORED' || (itemCode && currentActivePallet.itemCode !== itemCode && !wheelQr)) {
    // Only return half pallet suggestion if no wheelQr is provided (starting a new pallet)
    if (!wheelQr && !ignoreHalfPallet) {
      const availableHalf = (store.pallets || []).find(p =>
        p.itemCode === targetItem && (p.status === 'STORED_HALF' || p.typeSeries === 'H')
      );

      if (availableHalf) {
        return res.json({
          success: true,
          halfPalletAvailable: true,
          halfPallet: {
            palletNumber: availableHalf.palletNumber,
            currentQty: availableHalf.packedQty,
            shortfallQty: Math.max(0, stdQty - availableHalf.packedQty),
            locationCode: availableHalf.locationCode,
            ageDays: Math.floor((Date.now() - new Date(availableHalf.createdAt).getTime()) / (1000 * 60 * 60 * 24)) || 1
          },
          message: `HALF PALLET AVAILABLE — use it first! ${availableHalf.palletNumber} with ${availableHalf.packedQty}/${stdQty} wheels at ${availableHalf.locationCode}`
        });
      }
    }

    currentActivePallet = {
      palletNumber: formatNumber('P'),
      typeSeries: 'P',
      itemCode: targetItem,
      packedQty: 0,
      stdQty,
      status: 'PACKING',
      wheels: [],
      currentLayer: 1,
      createdAt: new Date().toISOString()
    };
    store.activePallet = currentActivePallet;
    saveStore();
  } else {
    // If active pallet already exists, update its itemCode / stdQty if explicitly changed
    if (itemCode && currentActivePallet.itemCode !== itemCode) {
      currentActivePallet.itemCode = itemCode;
    }
    if (palletCapacity && Number(palletCapacity) > 0) {
      currentActivePallet.stdQty = Number(palletCapacity);
      currentActivePallet.currentLayer = Math.max(1, Math.ceil(currentActivePallet.packedQty / wheelsPerLayer));
      saveStore();
    }
  }

  // Scan wheel onto active pallet
  if (wheelQr) {
    if (currentActivePallet.wheels.includes(wheelQr)) {
      return res.status(400).json({ success: false, message: 'DUPLICATE: Wheel QR already scanned on this pallet!' });
    }

    currentActivePallet.wheels.push(wheelQr);
    currentActivePallet.packedQty = currentActivePallet.wheels.length;
    currentActivePallet.currentLayer = Math.max(1, Math.ceil(currentActivePallet.packedQty / wheelsPerLayer));

    // Record in wheels store
    if (!store.wheels) store.wheels = [];
    store.wheels.push({
      wheelQr,
      itemCode: currentActivePallet.itemCode || targetItem,
      palletNumber: currentActivePallet.palletNumber,
      packedBy: req.user ? req.user.name : 'Pack Operator',
      packedAt: new Date().toISOString()
    });

    // Update paint plan actual count
    const latestPlan = store.paintPlans ? store.paintPlans[0] : null;
    if (latestPlan) {
      const planItem = latestPlan.items.find(i => i.itemCode === (currentActivePallet.itemCode || targetItem));
      if (planItem) {
        planItem.packedQty = (planItem.packedQty || 0) + 1;
      }
    }

    store.activePallet = currentActivePallet;
    saveStore();
  }

  res.json({
    success: true,
    message: wheelQr ? `Wheel scanned: ${currentActivePallet.packedQty}/${currentActivePallet.stdQty}` : 'Active pallet retrieved',
    activePallet: currentActivePallet
  });
}

function closePallet(req, res) {
  const { reason = 'Standard Qty Reached', forceClose = false } = req.body;
  const store = getStore();

  const currentActivePallet = store.activePallet;

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

  if (!store.pallets) store.pallets = [];
  store.pallets.unshift(closedPallet);
  store.activePallet = null;
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
  const stdQty = resolvePalletCapacity(halfPallet.itemCode);
  const wheelsPerLayer = itemMaster ? itemMaster.wheelsPerLayer : (stdQty > 0 ? Math.ceil(stdQty / 4) : 5);

  const currentActivePallet = {
    palletNumber: halfPallet.palletNumber,
    typeSeries: 'PM',
    oldHalfPalletNumber: halfPallet.palletNumber,
    itemCode: halfPallet.itemCode,
    packedQty: halfPallet.packedQty,
    stdQty: stdQty,
    status: 'PACKING_MERGE',
    wheels: halfPallet.wheels || [],
    currentLayer: Math.max(1, Math.ceil(halfPallet.packedQty / wheelsPerLayer)),
    createdAt: halfPallet.createdAt || new Date().toISOString()
  };

  halfPallet.status = 'MERGING';
  store.activePallet = currentActivePallet;
  saveStore();

  res.json({
    success: true,
    message: `Half pallet ${halfPalletNumber} loaded. Resuming counter at ${halfPallet.packedQty}/${currentActivePallet.stdQty}`,
    activePallet: currentActivePallet
  });
}

function getHalfPallets(req, res) {
  const store = getStore();
  const halfPallets = (store.pallets || []).filter(p => p.status === 'STORED_HALF' || p.typeSeries === 'H');
  res.json({
    success: true,
    halfPallets
  });
}

module.exports = {
  printWheelQr,
  getActivePallet,
  startOrScanWheel,
  closePallet,
  loadAndResumeHalfPallet,
  getHalfPallets
};
