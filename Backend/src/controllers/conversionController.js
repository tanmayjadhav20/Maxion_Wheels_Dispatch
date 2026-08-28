const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateSpdPackQr, generatePalletQr } = require('../utils/qr');

/**
 * Module 12 — SPD Conversion (SSR Section 8)
 * Partial take driven by request quantity (SR2600038).
 * Takes requested quantity of wheels off an OEM pallet, packs each wheel individually
 * with an SPD label (SP26000411 / MWS|...), closes source pallet as Split-Consumed,
 * and re-issues remaining wheels as a new Half Pallet (H26000091) into the top-up cycle.
 */

// 1. Raise SPD Request
function createSpdRequest(req, res) {
  const { itemCode, qtyRequired = 10, customerName, shipToAddress, requiredDate, reference } = req.body;
  const store = getStore();

  const itemMaster = store.items.find(i => i.itemCode === itemCode);
  if (!itemMaster) {
    return res.status(404).json({ success: false, message: `Item code ${itemCode} not found in master data` });
  }

  // Dynamic customer lookup
  const custMaster = (store.customers || []).find(c => c.customerName === customerName || c.customerCode === customerName || c.customerName === itemMaster.defaultCustomer);
  const resolvedCustomer = customerName || (custMaster ? custMaster.customerName : 'SPD Aftermarket');
  const resolvedAddress = shipToAddress || (custMaster ? custMaster.shipToAddress : '');
  const resolvedRef = reference || `PO-SPD-${Math.floor(1000 + Math.random() * 9000)}`;

  const spdRequestNumber = formatNumber('SR');
  const totalQty = Math.max(1, Number(qtyRequired));

  const newRequest = {
    spdRequestNumber,
    itemCode,
    itemDescription: itemMaster.description,
    qtyRequired: totalQty,
    qtyServed: 0,
    customerName: resolvedCustomer,
    shipToAddress: resolvedAddress,
    requiredDate: requiredDate || new Date().toISOString().split('T')[0],
    reference: resolvedRef,
    status: 'PENDING_PACKING',
    spdStickers: [],
    createdAt: new Date().toISOString(),
    createdBy: req.user ? req.user.name : 'SPD Planner'
  };

  if (!store.spdRequests) store.spdRequests = [];
  store.spdRequests.unshift(newRequest);
  saveStore();

  // Find proposed pallet using Order of Preference
  const proposedPallet = findProposedPalletForSpd(store, itemCode, totalQty);

  res.json({
    success: true,
    message: `SPD Request ${spdRequestNumber} created for ${totalQty} wheel(s) of ${itemCode}. Verify information in SPD Packing to generate QR stickers.`,
    spdRequest: newRequest,
    proposedPallet
  });
}

// 1b. Generate SPD QR Stickers on Demand (triggered in SPD Packing Page)
function generateSpdStickers(req, res) {
  const { spdRequestNumber } = req.body;
  const store = getStore();

  const spdRequest = (store.spdRequests || []).find(r => r.spdRequestNumber === spdRequestNumber);
  if (!spdRequest) {
    return res.status(404).json({ success: false, message: `SPD Request ${spdRequestNumber} not found` });
  }

  const totalQty = Math.max(1, Number(spdRequest.qtyRequired || 10));
  const itemMaster = (store.items || []).find(i => i.itemCode === spdRequest.itemCode);
  const itemDescription = itemMaster ? itemMaster.description : 'Individual Boxed SPD Spare Wheel (SP Series)';

  const spdStickers = [];
  for (let i = 1; i <= totalQty; i++) {
    const spNo = formatNumber('SP');
    const qrData = `MWS|${spNo}`;
    spdStickers.push({
      spdPackNumber: spNo,
      spdPackQr: qrData,
      uniqueQrData: qrData,
      codeText: spNo,
      serialNumber: spNo,
      itemCode: spdRequest.itemCode,
      itemDescription,
      wheelIndex: i,
      totalBatchCount: totalQty,
      primaryDetail: `SPD Req: ${spdRequest.spdRequestNumber} • Sticker ${i} of ${totalQty}`,
      secondaryDetail: `Customer: ${spdRequest.customerName}`,
      stickerDetails: [
        { 'PACK #': spNo },
        { 'REQ #': spdRequest.spdRequestNumber },
        { 'LABEL': `${i} OF ${totalQty}` },
        { 'CUSTOMER': spdRequest.customerName }
      ]
    });
  }

  if (!store.spdPacks) store.spdPacks = [];
  spdStickers.forEach(stk => {
    const existing = store.spdPacks.find(p => p.spdPackNumber === stk.spdPackNumber);
    if (!existing) {
      store.spdPacks.unshift({
        spdPackNumber: stk.spdPackNumber,
        spdPackQr: stk.spdPackQr,
        itemCode: spdRequest.itemCode,
        spdRequestNumber: spdRequest.spdRequestNumber,
        customerName: spdRequest.customerName,
        status: 'STORED_SPD_PACK',
        createdAt: new Date().toISOString()
      });
    }
  });

  spdRequest.spdStickers = spdStickers;
  spdRequest.status = 'READY_TO_PACK';
  saveStore();

  res.json({
    success: true,
    message: `Generated ${spdStickers.length} SPD QR Stickers for ${spdRequest.spdRequestNumber}`,
    spdStickers,
    spdRequest
  });
}

// 2. Propose Pallet for SPD (Order of Preference per Section 8.3)
function findProposedPalletForSpd(store, itemCode, qtyRequired) {
  const candidatePallets = (store.pallets || []).filter(p =>
    p.itemCode === itemCode &&
    !p.isHold &&
    p.status !== 'UNDER_QA_INSPECTION' &&
    p.status !== 'RESERVED_FOR_PICK' &&
    p.status !== 'LOADED_ON_VEHICLE' &&
    p.status !== 'DISPATCHED' &&
    p.status !== 'SPLIT_CONSUMED' &&
    (p.status === 'STORED' || p.status === 'STORED_HALF' || p.status === 'CLOSED_MERGED_FULL' || p.status === 'CLOSED_MERGED_HALF')
  );

  if (candidatePallets.length === 0) return null;

  // Order of Preference:
  // 1. Existing HALF pallet holding enough wheels
  // 2. Existing HALF pallet (oldest first)
  // 3. MERGED pallet (oldest first)
  // 4. FULL pallet (oldest first - FIFO)
  candidatePallets.sort((a, b) => {
    const aIsHalfEnough = (a.typeSeries === 'H' || a.status === 'STORED_HALF') && (a.packedQty || 0) >= qtyRequired;
    const bIsHalfEnough = (b.typeSeries === 'H' || b.status === 'STORED_HALF') && (b.packedQty || 0) >= qtyRequired;
    if (aIsHalfEnough && !bIsHalfEnough) return -1;
    if (!aIsHalfEnough && bIsHalfEnough) return 1;

    const aTypeScore = a.typeSeries === 'H' ? 1 : a.typeSeries === 'PM' ? 2 : 3;
    const bTypeScore = b.typeSeries === 'H' ? 1 : b.typeSeries === 'PM' ? 2 : 3;
    if (aTypeScore !== bTypeScore) return aTypeScore - bTypeScore;

    return new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
  });

  return candidatePallets[0];
}

// Endpoint to get candidate pallet recommendation
function getProposedPallet(req, res) {
  const { itemCode, qtyRequired } = req.query || {};
  const store = getStore();

  const proposed = findProposedPalletForSpd(store, itemCode, Number(qtyRequired || 10));
  if (!proposed) {
    return res.status(404).json({ success: false, message: `No eligible stored pallet found for item ${itemCode}` });
  }

  res.json({
    success: true,
    proposedPallet: proposed
  });
}

// 3. Pack Individual SPD Wheel (Guided Handheld Job - Step 5 to 7 in Section 8.2)
function packSpdWheel(req, res) {
  const { spdRequestNumber, sourcePalletNumber, wheelQr } = req.body;
  const store = getStore();

  const spdRequest = (store.spdRequests || []).find(r => r.spdRequestNumber === spdRequestNumber);
  if (!spdRequest) {
    return res.status(404).json({ success: false, message: `SPD Request ${spdRequestNumber} not found` });
  }

  const pallet = store.pallets.find(p => p.palletNumber === sourcePalletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: `Source pallet ${sourcePalletNumber} not found` });
  }

  // Hard Rule V-01: Only same item code allowed
  if (pallet.itemCode !== spdRequest.itemCode) {
    return res.status(400).json({ success: false, message: `HARD BLOCK (V-01): Pallet item (${pallet.itemCode}) does not match request item (${spdRequest.itemCode})` });
  }

  const totalQty = Math.max(1, Number(spdRequest.qtyRequired || 10));
  const createdPacks = [];
  const generatedStickers = [];

  if (!store.spdPacks) store.spdPacks = [];

  for (let i = 1; i <= totalQty; i++) {
    const spdPackNumber = formatNumber('SP');
    const spdPackQr = generateSpdPackQr(spdPackNumber);

    const spdPackObj = {
      spdPackNumber,
      spdPackQr,
      spdRequestNumber,
      itemCode: spdRequest.itemCode,
      originalWheelQr: wheelQr || `MW|P1|${spdRequest.itemCode}|${String(Date.now() + i).slice(-8)}|260822|A|PL2`,
      sourcePalletNumber,
      productionDate: pallet.createdAt ? pallet.createdAt.split('T')[0] : new Date().toISOString().split('T')[0],
      customerName: spdRequest.customerName,
      status: 'STORED_SPD_PACK',
      locationCode: 'WH1-SPD-BAY',
      createdAt: new Date().toISOString(),
      packedBy: req.user ? req.user.name : 'SPD Packing Operator'
    };

    store.spdPacks.unshift(spdPackObj);
    createdPacks.push(spdPackObj);

    generatedStickers.push({
      spdPackNumber,
      spdPackQr,
      uniqueQrData: spdPackQr,
      codeText: spdPackNumber,
      serialNumber: spdPackNumber,
      itemCode: spdRequest.itemCode,
      itemDescription: 'Individual Boxed SPD Spare Wheel (SP Series)',
      wheelIndex: i,
      totalBatchCount: totalQty,
      primaryDetail: `SPD Req: ${spdRequestNumber} • Wheel ${i} of ${totalQty}`,
      secondaryDetail: `Source: ${sourcePalletNumber} • Customer: ${spdRequest.customerName}`,
      stickerDetails: [
        { 'PACK #': spdPackNumber },
        { 'REQ #': spdRequestNumber },
        { 'LABEL': `${i} OF ${totalQty}` },
        { 'SOURCE': sourcePalletNumber }
      ]
    });
  }

  spdRequest.qtyServed = totalQty;
  spdRequest.status = 'COMPLETED';

  saveStore();

  res.json({
    success: true,
    message: `Successfully packed ${totalQty} wheel(s) into SPD packs with ${totalQty} individual QR stickers.`,
    spdPacks: createdPacks,
    spdStickers: generatedStickers,
    spdPack: createdPacks[0],
    spdRequest
  });
}

// 4. Finish SPD Job & Create Residual Half Pallet (Steps 9-14 in Section 8.2)
function finishSpdJob(req, res) {
  const { spdRequestNumber, sourcePalletNumber } = req.body;
  const store = getStore();

  const spdRequest = (store.spdRequests || []).find(r => r.spdRequestNumber === spdRequestNumber);
  const pallet = store.pallets.find(p => p.palletNumber === sourcePalletNumber);

  if (!pallet) {
    return res.status(404).json({ success: false, message: `Source pallet ${sourcePalletNumber} not found` });
  }

  const packsCreated = (store.spdPacks || []).filter(sp => sp.spdRequestNumber === spdRequestNumber && sp.sourcePalletNumber === sourcePalletNumber);
  const takenQty = packsCreated.length || 10;
  const initialQty = pallet.packedQty || 20;
  const residualQty = Math.max(0, initialQty - takenQty);

  // Close source pallet as SPLIT_CONSUMED
  pallet.status = 'SPLIT_CONSUMED';
  pallet.closedAs = `Split into ${takenQty} SPD Packs & Residual ${residualQty} Half Pallet`;

  let residualHalfPallet = null;
  if (residualQty > 0) {
    // Create new Half Pallet (H series) for remaining wheels
    const newHalfNumber = formatNumber('H');
    residualHalfPallet = {
      palletNumber: newHalfNumber,
      typeSeries: 'H',
      itemCode: pallet.itemCode,
      packedQty: residualQty,
      stdQty: pallet.stdQty || 96,
      status: 'STORED_HALF',
      locationCode: 'WH1-HALF-BAY',
      masterQr: generatePalletQr(newHalfNumber),
      closeReason: 'Created from SPD Split',
      createdAt: new Date().toISOString(),
      createdBy: req.user ? req.user.name : 'SPD Packing Operator'
    };
    store.pallets.unshift(residualHalfPallet);
  }

  if (spdRequest) {
    spdRequest.status = spdRequest.qtyServed >= spdRequest.qtyRequired ? 'COMPLETED' : 'IN_PROGRESS';
  }

  // Record conversion log
  const conversionRecord = {
    conversionId: formatNumber('SR'),
    type: 'PALLET_SPLIT_TO_SPD_PACKS',
    spdRequestNumber,
    sourcePalletNumber,
    spdPacksCreatedCount: takenQty,
    residualHalfPalletNumber: residualHalfPallet ? residualHalfPallet.palletNumber : null,
    residualQty,
    convertedBy: req.user ? req.user.name : 'SPD Packing Operator',
    timestamp: new Date().toISOString()
  };

  if (!store.conversions) store.conversions = [];
  store.conversions.unshift(conversionRecord);

  saveStore();

  res.json({
    success: true,
    message: `SPD Job finished! Pallet ${sourcePalletNumber} split into ${takenQty} SPD Packs and Residual Half Pallet ${residualHalfPallet ? residualHalfPallet.palletNumber : 'None'} (${residualQty} wheels)`,
    conversionRecord,
    residualHalfPallet,
    spdRequest
  });
}

// 5. Reverse Flow: SPD Packs back to Pallet (Section 8.6)
function convertSpdToPallet(req, res) {
  const { spdPackNumbers = [], targetLocationCode = 'WH1-STG-01' } = req.body;
  const store = getStore();

  if (!spdPackNumbers || spdPackNumbers.length === 0) {
    return res.status(400).json({ success: false, message: 'At least one SPD pack number is required' });
  }

  const validPacks = (store.spdPacks || []).filter(sp => spdPackNumbers.includes(sp.spdPackNumber) && sp.status === 'STORED_SPD_PACK');
  if (validPacks.length === 0) {
    return res.status(404).json({ success: false, message: 'No valid in-stock SPD packs found for conversion' });
  }

  const itemCode = validPacks[0].itemCode;
  const totalWheels = validPacks.length;

  const itemMaster = store.items.find(i => i.itemCode === itemCode);
  const stdQty = itemMaster ? itemMaster.stdPalletQty : 4;

  const newPalletNumber = totalWheels >= stdQty ? formatNumber('P') : formatNumber('H');
  const typeSeries = totalWheels >= stdQty ? 'P' : 'H';

  const newPallet = {
    palletNumber: newPalletNumber,
    typeSeries,
    itemCode,
    packedQty: totalWheels,
    stdQty,
    status: totalWheels >= stdQty ? 'STORED' : 'STORED_HALF',
    locationCode: targetLocationCode,
    isHold: false,
    masterQr: generatePalletQr(newPalletNumber),
    createdAt: new Date().toISOString(),
    createdBy: req.user ? req.user.name : 'SPD Operator',
    convertedFromSpdPacks: spdPackNumbers
  };

  validPacks.forEach(sp => {
    sp.status = 'CONVERTED_CONSUMED';
    sp.targetPalletNumber = newPalletNumber;
  });

  store.pallets.unshift(newPallet);

  const conversionRecord = {
    conversionId: formatNumber('SR'),
    type: 'SPD_PACKS_TO_PALLET',
    targetPalletNumber: newPalletNumber,
    consumedSpdPacksCount: totalWheels,
    convertedBy: req.user ? req.user.name : 'SPD Operator',
    timestamp: new Date().toISOString()
  };

  if (!store.conversions) store.conversions = [];
  store.conversions.unshift(conversionRecord);
  saveStore();

  res.json({
    success: true,
    message: `Re-assembled ${totalWheels} SPD Pack(s) into Pallet ${newPalletNumber} (${typeSeries})`,
    conversionRecord,
    newPallet
  });
}

// 6. Get Requests and History
function getSpdRequests(req, res) {
  const store = getStore();
  res.json({
    success: true,
    spdRequests: store.spdRequests || [],
    spdPacks: (store.spdPacks || []).filter(sp => sp.status === 'STORED_SPD_PACK'),
    conversions: store.conversions || [],
    halfPalletsFromSpd: (store.pallets || []).filter(p => p.status === 'STORED_HALF' && p.closeReason && p.closeReason.includes('SPD'))
  });
}

function getConversionHistory(req, res) {
  const store = getStore();
  res.json({
    success: true,
    conversions: store.conversions || [],
    spdPacks: store.spdPacks || [],
    spdRequests: store.spdRequests || []
  });
}

module.exports = {
  createSpdRequest,
  generateSpdStickers,
  getProposedPallet,
  packSpdWheel,
  finishSpdJob,
  convertSpdToPallet,
  getSpdRequests,
  getConversionHistory
};
