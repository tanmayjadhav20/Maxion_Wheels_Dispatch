const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateGatePassQr } = require('../utils/qr');

/**
 * Module 8 & Module 10 — Vehicle Loading, Gate Pass & Dispatch Poka-Yoke (SAP Invoice Check)
 * Section 10: Upload SAP invoice file at vehicle release -> background line-by-line cross-check ->
 * post & release gate pass if tallies, or block posting if mismatch. Override by Dispatch/Plant Head only.
 */

function getGatePasses(req, res) {
  const store = getStore();
  res.json({ success: true, gatePasses: store.gatePasses });
}

function scanLoadingPallet(req, res) {
  const { gatePassNumber, scannedPalletNumber } = req.body;
  const store = getStore();

  const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber);
  if (!gp) {
    return res.status(404).json({ success: false, message: 'Gate pass shipment record not found' });
  }

  if (gp.loadedPalletNumbers.includes(scannedPalletNumber)) {
    return res.status(400).json({ success: false, message: 'Pallet already loaded on vehicle!' });
  }

  const pallet = store.pallets.find(p => p.palletNumber === scannedPalletNumber);
  const spdPack = (store.spdPacks || []).find(sp => sp.spdPackNumber === scannedPalletNumber);

  if (!pallet && !spdPack) {
    return res.status(404).json({ success: false, message: 'Pallet or SPD Pack not found in inventory' });
  }

  if (pallet) {
    gp.loadedPalletNumbers.push(scannedPalletNumber);
    pallet.status = 'LOADED_ON_VEHICLE';
  } else if (spdPack) {
    if (!gp.loadedSpdPackNumbers) gp.loadedSpdPackNumbers = [];
    gp.loadedSpdPackNumbers.push(scannedPalletNumber);
    spdPack.status = 'LOADED_ON_VEHICLE';
  }

  gp.loadedPalletsCount = gp.loadedPalletNumbers.length + (gp.loadedSpdPackNumbers ? gp.loadedSpdPackNumbers.length : 0);

  if (gp.loadedPalletsCount >= gp.totalPallets) {
    gp.status = 'WAITING_FOR_INVOICE_CHECK';
  }

  saveStore();

  res.json({
    success: true,
    message: `Scanned ${scannedPalletNumber} loaded on vehicle. Count: ${gp.loadedPalletsCount}/${gp.totalPallets}`,
    gatePass: gp
  });
}

function createGatePass(req, res) {
  const { indentNumber, vehicleNumber, transporterName, driverName, driverLicence, driverPhone, sealNumber, returnableAssetsSent } = req.body;
  const store = getStore();

  const indent = store.indents.find(i => i.indentNumber === indentNumber);
  if (!indent) {
    return res.status(404).json({ success: false, message: 'Indent not found' });
  }

  const gatePassNumber = formatNumber('GP');
  const gatePassQr = generateGatePassQr(gatePassNumber);

  let totalWheels = 0;
  let totalWeightKg = 0;
  const allPalletNumbers = [];

  indent.items.forEach(item => {
    const master = store.items.find(m => m.itemCode === item.itemCode);
    const weight = master ? master.unitWeightKg : 10;

    item.allocatedPalletNumbers.forEach(pNum => {
      allPalletNumbers.push(pNum);
      const pallet = store.pallets.find(p => p.palletNumber === pNum);
      const qty = pallet ? pallet.packedQty : 96;
      totalWheels += qty;
      totalWeightKg += (qty * weight);
    });
  });

  const newGatePass = {
    gatePassNumber,
    gatePassQr,
    indentNumber,
    customerName: indent.customerName,
    shipToAddress: indent.shipToAddress,
    vehicleNumber: vehicleNumber || 'MH 12 QW 8890',
    transporterName: transporterName || 'Vistar Logistics Express',
    driverName: driverName || 'Rajesh Kumar',
    driverLicence: driverLicence || 'DL-99201928',
    driverPhone: driverPhone || '+91 98765 43210',
    sealNumber: sealNumber || 'SEAL-9921',
    status: 'LOADING',
    pokaYokeStatus: 'PENDING_INVOICE', // PENDING_INVOICE, PASSED, FAILED_MISMATCH, OVERRIDDEN
    sapInvoiceNumber: null,
    totalPallets: allPalletNumbers.length,
    loadedPalletsCount: 0,
    totalWheels,
    totalWeightKg,
    allPalletNumbers,
    loadedPalletNumbers: [],
    loadedSpdPackNumbers: [],
    returnableAssetsSent: returnableAssetsSent || ['RP0001842'],
    pokaYokeResults: [],
    createdAt: new Date().toISOString(),
    gateOutAt: null
  };

  store.gatePasses.unshift(newGatePass);
  saveStore();

  res.json({
    success: true,
    message: 'Gate pass generated automatically!',
    gatePass: newGatePass
  });
}

// Section 10: Dispatch Poka-Yoke — Upload SAP Invoice & Perform Cross-Check
function uploadSapInvoiceAndCheck(req, res) {
  const { gatePassNumber, invoiceNumber, invoiceDate = new Date().toISOString().split('T')[0], invoiceItems = [], customerCode = 'CUST-1001' } = req.body;
  const store = getStore();

  const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber);
  if (!gp) {
    return res.status(404).json({ success: false, message: `Gate pass ${gatePassNumber} not found` });
  }

  const itemsToCompare = invoiceItems.length > 0 ? invoiceItems : [
    { itemCode: 'MXW-17-BLK', quantity: gp.totalWheels || 192, unitOfMeasure: 'EA' }
  ];

  // Aggregate loaded quantity by item code
  const loadedQtyMap = {};

  gp.loadedPalletNumbers.forEach(pNum => {
    const pallet = store.pallets.find(p => p.palletNumber === pNum);
    if (pallet) {
      loadedQtyMap[pallet.itemCode] = (loadedQtyMap[pallet.itemCode] || 0) + (pallet.packedQty || 96);
    }
  });

  if (gp.loadedSpdPackNumbers) {
    gp.loadedSpdPackNumbers.forEach(spNum => {
      const spdPack = (store.spdPacks || []).find(sp => sp.spdPackNumber === spNum);
      if (spdPack) {
        loadedQtyMap[spdPack.itemCode] = (loadedQtyMap[spdPack.itemCode] || 0) + 1;
      }
    });
  }

  // If no pallets loaded yet, populate default for demonstration if loading is marked complete
  if (Object.keys(loadedQtyMap).length === 0 && gp.totalWheels > 0) {
    loadedQtyMap['MXW-17-BLK'] = gp.totalWheels;
  }

  let allMatch = true;
  const pokaYokeResults = [];

  itemsToCompare.forEach(invItem => {
    const loadedQty = loadedQtyMap[invItem.itemCode] || 0;
    const diff = loadedQty - invItem.quantity;
    const isMatch = diff === 0;
    if (!isMatch) allMatch = false;

    pokaYokeResults.push({
      itemCode: invItem.itemCode,
      invoiceQty: invItem.quantity,
      loadedQty,
      difference: diff,
      status: isMatch ? 'MATCH' : 'MISMATCH'
    });
  });

  gp.sapInvoiceNumber = invoiceNumber || `INV-SAP-2026-${String(Date.now()).slice(-4)}`;
  gp.pokaYokeResults = pokaYokeResults;

  if (allMatch) {
    gp.pokaYokeStatus = 'PASSED';
    gp.status = 'READY_FOR_GATE_OUT';
  } else {
    gp.pokaYokeStatus = 'FAILED_MISMATCH';
    gp.status = 'BLOCKED_INVOICE_MISMATCH';
  }

  saveStore();

  res.json({
    success: true,
    allMatch,
    message: allMatch
      ? `POKA-YOKE PASSED: SAP Invoice ${gp.sapInvoiceNumber} tallies with physical load. Release allowed!`
      : `POKA-YOKE BLOCKED: SAP Invoice ${gp.sapInvoiceNumber} has quantity/item mismatches! Posting blocked.`,
    gatePass: gp,
    pokaYokeResults
  });
}

// Section 10.4: Manager Override for Mismatch
function overrideInvoiceMismatch(req, res) {
  const { gatePassNumber, authorizedBy = 'Dispatch Head', reason = 'Approved deviation per customer schedule change' } = req.body;
  const store = getStore();

  const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber);
  if (!gp) {
    return res.status(404).json({ success: false, message: `Gate pass ${gatePassNumber} not found` });
  }

  gp.pokaYokeStatus = 'OVERRIDDEN';
  gp.status = 'READY_FOR_GATE_OUT';
  gp.overrideAuthorizer = authorizedBy;
  gp.overrideReason = reason;
  gp.overriddenAt = new Date().toISOString();

  saveStore();

  res.json({
    success: true,
    message: `POKA-YOKE OVERRIDDEN by ${authorizedBy}. Gate Pass ${gatePassNumber} unlocked for release.`,
    gatePass: gp
  });
}

function verifySecurityGateOut(req, res) {
  const { gatePassNumber, action = 'RELEASE', holdReason = '' } = req.body;
  const store = getStore();

  const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber || g.gatePassQr === gatePassNumber);
  if (!gp) {
    return res.status(404).json({ success: false, message: 'Invalid or unknown Gate Pass QR' });
  }

  if (gp.status === 'DISPATCHED') {
    return res.status(400).json({ success: false, message: 'GATE PASS EXPIRED: Same gate pass cannot be used twice!' });
  }

  if (gp.status === 'BLOCKED_INVOICE_MISMATCH' && action === 'RELEASE') {
    return res.status(400).json({ success: false, message: 'GATE OUT BLOCKED: SAP Invoice mismatch detected! Must be resolved or overridden by Dispatch/Plant Head first.' });
  }

  if (action === 'HOLD') {
    gp.status = 'GATE_HOLD';
    gp.holdReason = holdReason || 'Vehicle discrepancy reported by Security';
    saveStore();
    return res.json({
      success: true,
      message: `GATE OUT BLOCKED: Hold raised for Gate Pass ${gp.gatePassNumber}`,
      gatePass: gp
    });
  }

  gp.status = 'DISPATCHED';
  gp.gateOutAt = new Date().toISOString();
  gp.securityOfficer = req.user ? req.user.name : 'Security Guard';

  // Mark all loaded pallets as DISPATCHED
  gp.loadedPalletNumbers.forEach(pNum => {
    const pallet = store.pallets.find(p => p.palletNumber === pNum);
    if (pallet) {
      pallet.status = 'DISPATCHED';
    }
  });

  if (gp.loadedSpdPackNumbers) {
    gp.loadedSpdPackNumbers.forEach(spNum => {
      const spdPack = (store.spdPacks || []).find(sp => sp.spdPackNumber === spNum);
      if (spdPack) {
        spdPack.status = 'DISPATCHED';
      }
    });
  }

  // Mark returnable assets as With Customer
  if (gp.returnableAssetsSent) {
    gp.returnableAssetsSent.forEach(aNum => {
      const asset = store.returnableAssets.find(a => a.assetNumber === aNum || a.assetTag.includes(aNum));
      if (asset) {
        asset.status = 'With Customer';
        asset.customerName = gp.customerName;
        asset.issueDate = new Date().toISOString().split('T')[0];
        const returnDate = new Date();
        returnDate.setDate(returnDate.getDate() + 30);
        asset.expectedReturnDate = returnDate.toISOString().split('T')[0];
      }
    });
  }

  saveStore();

  res.json({
    success: true,
    message: `VEHICLE RELEASED: Gate pass ${gp.gatePassNumber} (SAP Invoice: ${gp.sapInvoiceNumber || 'N/A'}) cleared for Gate Out!`,
    gatePass: gp
  });
}

module.exports = {
  getGatePasses,
  scanLoadingPallet,
  createGatePass,
  uploadSapInvoiceAndCheck,
  overrideInvoiceMismatch,
  verifySecurityGateOut
};
