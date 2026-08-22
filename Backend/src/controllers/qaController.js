const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateWheelQr, generatePalletQr } = require('../utils/qr');

/**
 * Module 11 — Quality Inspection & Wheel Replacement (SSR Section 7)
 * IOC-QA team opens closed pallets, locks them (UNDER_QA_INSPECTION), scans out removed wheels
 * with defect reason (sample/defect/rework/scrap), scans in replacement wheels from production,
 * and re-seals with a revision label (P26000148 / R1) or re-issues as a Half Pallet (H) if closed short.
 */

// Step 1: Open Pallet for QA Inspection (Section 7.1 Steps 1-2)
function openPalletForInspection(req, res) {
  const { palletNumber, inspectionRef = 'QA-AUDIT-001', reason = 'Routine Surface & Weight Inspection' } = req.body;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: `Pallet ${palletNumber} not found` });
  }

  if (pallet.status === 'UNDER_QA_INSPECTION') {
    return res.status(400).json({ success: false, message: `Pallet ${palletNumber} is ALREADY under QA Inspection!` });
  }

  if (pallet.status === 'LOADED_ON_VEHICLE' || pallet.status === 'DISPATCHED') {
    return res.status(400).json({ success: false, message: `Pallet ${palletNumber} cannot be opened as it is already loaded or dispatched` });
  }

  // Lock pallet from picking, allocation, merging, conversion, relocation
  pallet.previousStatus = pallet.status;
  pallet.status = 'UNDER_QA_INSPECTION';
  pallet.qaLock = true;
  pallet.qaInspectionRef = inspectionRef;
  pallet.revisionCount = (pallet.revisionCount || 0);

  const inspectionRecord = {
    inspectionId: formatNumber('QA'),
    inspectionRef,
    palletNumber: pallet.palletNumber,
    itemCode: pallet.itemCode,
    originalQty: pallet.packedQty || 96,
    removedWheels: [],
    replacementWheels: [],
    reason,
    status: 'IN_PROGRESS',
    openedAt: new Date().toISOString(),
    inspectorName: req.user ? req.user.name : 'IOC-QA Inspector'
  };

  if (!store.qaInspections) store.qaInspections = [];
  store.qaInspections.unshift(inspectionRecord);

  saveStore();

  res.json({
    success: true,
    message: `Pallet ${palletNumber} is now LOCKED and UNDER QA INSPECTION (${inspectionRecord.inspectionId})`,
    pallet,
    inspectionRecord
  });
}

// Step 2 & 3: Scan out removed wheel and scan in replacement wheel (Section 7.1 Steps 3-5)
function inspectAndReplaceWheels(req, res) {
  const { palletNumber, removedWheelQrs = [], replacementItemCode, reason = 'QA Defect / Destructive Test' } = req.body;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: `Pallet ${palletNumber} not found` });
  }

  const activeInspection = (store.qaInspections || []).find(q => q.palletNumber === palletNumber && q.status === 'IN_PROGRESS');

  const replacedCount = removedWheelQrs.length > 0 ? removedWheelQrs.length : 1;
  const itemCode = replacementItemCode || pallet.itemCode;

  // Generate new replacement wheel QRs from current production
  const newWheelQrs = [];
  const shift = 'A';
  const line = 'PL2';
  const dateStr = new Date().toISOString().slice(2, 10).replace(/-/g, '');

  for (let i = 0; i < replacedCount; i++) {
    const serialNumber = String(Date.now() + i).slice(-8);
    const newQr = generateWheelQr({
      plant: 'P1',
      itemCode,
      serial: serialNumber,
      date: dateStr,
      shift,
      line
    });
    newWheelQrs.push(newQr);

    store.wheels.push({
      wheelQr: newQr,
      itemCode,
      serialNumber,
      palletNumber: pallet.palletNumber,
      productionDate: new Date().toISOString().split('T')[0],
      shift,
      line,
      packedBy: req.user ? req.user.name : 'IOC-QA Inspector',
      packedAt: new Date().toISOString(),
      isQaReplacement: true
    });
  }

  if (activeInspection) {
    activeInspection.removedWheels.push(...removedWheelQrs);
    activeInspection.replacementWheels.push(...newWheelQrs);
  }

  pallet.lastInspectedAt = new Date().toISOString();
  pallet.lastInspectedBy = req.user ? req.user.name : 'IOC-QA Inspector';

  saveStore();

  res.json({
    success: true,
    message: `Swapped ${replacedCount} wheel(s) on Pallet ${palletNumber}. (${pallet.packedQty}/${pallet.stdQty || 96})`,
    newWheelQrs,
    pallet
  });
}

// Step 4: Close QA Inspection & Re-seal Label / Re-issue as Half Pallet (Section 7.1 Steps 6-8)
function closeQaInspection(req, res) {
  const { palletNumber, closeShort = false } = req.body;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: `Pallet ${palletNumber} not found` });
  }

  const activeInspection = (store.qaInspections || []).find(q => q.palletNumber === palletNumber && q.status === 'IN_PROGRESS');

  pallet.qaLock = false;
  const stdQty = pallet.stdQty || 96;
  const currentQty = pallet.packedQty || 96;

  let outcomeMessage = '';
  let labelRevisionMark = null;

  if (!closeShort && currentQty >= stdQty) {
    // Restored to full quantity -> Keeps original number with revision mark (Section 7.2 Q-04)
    pallet.revisionCount = (pallet.revisionCount || 0) + 1;
    labelRevisionMark = `R${pallet.revisionCount}`;
    pallet.revisionLabel = `${pallet.palletNumber} / ${labelRevisionMark}`;
    pallet.status = pallet.previousStatus || 'STORED';
    outcomeMessage = `Inspection closed. Pallet restored to full (${currentQty}/${stdQty}). Re-sealed with label ${pallet.revisionLabel}`;
  } else {
    // Closed short -> Re-issued as Half Pallet (H series) (Section 7.2 Q-05)
    const oldPalletNumber = pallet.palletNumber;
    const newHalfNumber = formatNumber('H');

    pallet.status = 'CLOSED_QA_SHORT';
    pallet.closedAsPointer = newHalfNumber;

    const newHalfPallet = {
      palletNumber: newHalfNumber,
      typeSeries: 'H',
      itemCode: pallet.itemCode,
      packedQty: currentQty,
      stdQty,
      status: 'STORED_HALF',
      locationCode: pallet.locationCode || 'WH1-HALF-BAY',
      masterQr: generatePalletQr(newHalfNumber),
      closeReason: `Re-issued from QA Inspection short closure of ${oldPalletNumber}`,
      createdAt: new Date().toISOString(),
      createdBy: req.user ? req.user.name : 'IOC-QA Inspector'
    };

    store.pallets.unshift(newHalfPallet);
    outcomeMessage = `Inspection closed short (${currentQty}/${stdQty}). Original ${oldPalletNumber} closed; Re-issued as Half Pallet ${newHalfNumber}`;
  }

  if (activeInspection) {
    activeInspection.status = 'COMPLETED';
    activeInspection.closedAt = new Date().toISOString();
    activeInspection.outcome = outcomeMessage;
  }

  saveStore();

  res.json({
    success: true,
    message: outcomeMessage,
    pallet,
    activeInspection,
    labelRevisionMark
  });
}

function getInspectionHistory(req, res) {
  const store = getStore();
  res.json({
    success: true,
    inspections: store.qaInspections || [],
    underInspectionPallets: (store.pallets || []).filter(p => p.status === 'UNDER_QA_INSPECTION')
  });
}

module.exports = {
  openPalletForInspection,
  inspectAndReplaceWheels,
  closeQaInspection,
  getInspectionHistory
};
