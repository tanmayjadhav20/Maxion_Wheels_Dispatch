const { getStore, saveStore } = require('../config/db');

function traceWheelOrPallet(req, res) {
  const { query } = req.query || {};
  const store = getStore();

  if (!query) {
    return res.status(400).json({ success: false, message: 'Query string required' });
  }

  // 1. Check wheel QR or serial
  const wheel = store.wheels.find(w => w.wheelQr === query || w.serialNumber === query || w.wheelQr.includes(query));
  if (wheel) {
    const pallet = store.pallets.find(p => p.palletNumber === wheel.palletNumber);
    const gatePass = store.gatePasses.find(g => g.loadedPalletNumbers && g.loadedPalletNumbers.includes(wheel.palletNumber));

    return res.json({
      success: true,
      type: 'WHEEL',
      details: {
        wheelQr: wheel.wheelQr,
        itemCode: wheel.itemCode,
        serialNumber: wheel.serialNumber,
        productionDate: wheel.productionDate,
        shift: wheel.shift,
        line: wheel.line,
        packedBy: wheel.packedBy,
        packedAt: wheel.packedAt,
        palletNumber: wheel.palletNumber,
        palletStatus: pallet ? pallet.status : 'UNKNOWN',
        locationCode: pallet ? pallet.locationCode : 'N/A',
        gatePassNumber: gatePass ? gatePass.gatePassNumber : 'NOT_DISPATCHED',
        customerName: gatePass ? gatePass.customerName : 'N/A'
      }
    });
  }

  // 2. Check pallet number or master QR
  const pallet = store.pallets.find(p => p.palletNumber === query || p.masterQr === query || query.includes(p.palletNumber));
  if (pallet) {
    const gatePass = store.gatePasses.find(g => g.loadedPalletNumbers && g.loadedPalletNumbers.includes(pallet.palletNumber));
    const palletWheels = store.wheels.filter(w => w.palletNumber === pallet.palletNumber);

    return res.json({
      success: true,
      type: 'PALLET',
      details: {
        palletNumber: pallet.palletNumber,
        typeSeries: pallet.typeSeries,
        itemCode: pallet.itemCode,
        packedQty: pallet.packedQty,
        stdQty: pallet.stdQty,
        status: pallet.status,
        locationCode: pallet.locationCode,
        isHold: pallet.isHold,
        holdReason: pallet.holdReason,
        oldHalfPalletNumber: pallet.oldHalfPalletNumber,
        createdAt: pallet.createdAt,
        createdBy: pallet.createdBy,
        gatePassNumber: gatePass ? gatePass.gatePassNumber : 'NOT_DISPATCHED',
        customerName: gatePass ? gatePass.customerName : 'N/A',
        wheelCount: palletWheels.length,
        wheels: palletWheels
      }
    });
  }

  // 3. Check returnable asset tag
  const asset = store.returnableAssets.find(a => a.assetNumber === query || a.assetTag === query || query.includes(a.assetNumber));
  if (asset) {
    return res.json({
      success: true,
      type: 'RETURNABLE_ASSET',
      details: {
        assetNumber: asset.assetNumber,
        assetTag: asset.assetTag,
        palletNumber: asset.palletNumber || 'N/A',
        itemCode: asset.itemCode || 'N/A',
        type: asset.type,
        condition: asset.condition,
        status: asset.status,
        customerName: asset.customerName || 'In House',
        locationCode: asset.locationCode || 'WH1-A-01-A2',
        issueDate: asset.issueDate || 'N/A',
        expectedReturnDate: asset.expectedReturnDate || 'N/A',
        ageingDays: asset.ageingDays || 0
      }
    });
  }

  res.status(404).json({ success: false, message: `No record found matching QR/code '${query}'` });
}

function scanToKnow(req, res) {
  const { code } = req.body;
  const store = getStore();

  if (!code) {
    return res.status(400).json({ success: false, message: 'Scanned code required' });
  }

  // Check location
  const loc = store.locations.find(l => l.code === code || code.includes(l.code));
  if (loc) {
    const palletInLoc = store.pallets.find(p => p.locationCode === loc.code && p.status !== 'DISPATCHED');
    return res.json({
      success: true,
      category: 'LOCATION',
      title: `Location: ${loc.code}`,
      subtitle: `Zone: ${loc.zone} | Type: ${loc.type} | Status: ${loc.status}`,
      details: palletInLoc ? `Contains Pallet ${palletInLoc.palletNumber} (${palletInLoc.itemCode}, Qty: ${palletInLoc.packedQty})` : 'Location is empty'
    });
  }

  // Check pallet
  const pallet = store.pallets.find(p => p.palletNumber === code || p.masterQr === code || code.includes(p.palletNumber));
  if (pallet) {
    return res.json({
      success: true,
      category: 'PALLET',
      title: `Pallet: ${pallet.palletNumber} (${pallet.typeSeries})`,
      subtitle: `Item: ${pallet.itemCode} | Qty: ${pallet.packedQty}/${pallet.stdQty} | Status: ${pallet.status}`,
      details: `Currently located at: ${pallet.locationCode || 'Staging Area'}`
    });
  }

  // Check returnable asset
  const asset = store.returnableAssets.find(a => a.assetNumber === code || a.assetTag === code || code.includes(a.assetNumber));
  if (asset) {
    return res.json({
      success: true,
      category: 'RETURNABLE_ASSET',
      title: `Returnable Tag: ${asset.assetNumber}`,
      subtitle: `Type: ${asset.type} | Condition: ${asset.condition} | Status: ${asset.status}`,
      details: asset.customerName ? `Currently with customer ${asset.customerName}` : `In stock at ${asset.locationCode}`
    });
  }

  res.json({
    success: true,
    category: 'UNKNOWN',
    title: `Scanned: ${code}`,
    subtitle: 'Unknown identity tag',
    details: 'Tag not registered in system'
  });
}

function setQualityHold(req, res) {
  const { palletNumber, isHold, reason } = req.body;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: 'Pallet not found' });
  }

  pallet.isHold = isHold;
  pallet.holdReason = isHold ? (reason || 'Quality Inspection Hold') : null;
  if (isHold) {
    pallet.status = 'QUALITY_HOLD';
  } else {
    pallet.status = pallet.typeSeries === 'H' ? 'STORED_HALF' : 'STORED';
  }

  saveStore();

  res.json({
    success: true,
    message: isHold ? `Pallet ${palletNumber} placed on QUALITY HOLD` : `Pallet ${palletNumber} RELEASED from hold`,
    pallet
  });
}

module.exports = {
  traceWheelOrPallet,
  scanToKnow,
  setQualityHold
};
