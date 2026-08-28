const { getStore, saveStore } = require('../config/db');

function getWarehouseMap(req, res) {
  const store = getStore();
  res.json({
    success: true,
    locations: store.locations,
    pallets: store.pallets
  });
}

function getHalfPalletRegister(req, res) {
  const store = getStore();
  const halfPallets = store.pallets.filter(p =>
    p.typeSeries === 'H' || p.status === 'STORED_HALF' || p.status === 'CLOSED_MERGED_HALF'
  ).map(p => ({
    palletNumber: p.palletNumber,
    itemCode: p.itemCode,
    packedQty: p.packedQty,
    stdQty: p.stdQty,
    shortfallQty: p.stdQty - p.packedQty,
    locationCode: p.locationCode || 'UNASSIGNED',
    closeReason: p.closeReason || 'Sudden Item Changeover',
    ageDays: p.ageDays || 1,
    status: p.status
  }));

  res.json({ success: true, halfPallets });
}

function executePutaway(req, res) {
  const palletNumber = req.body.palletNumber;
  const scannedLocationCode = req.body.scannedLocationCode || req.body.locationCode;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: 'Pallet not found' });
  }

  const location = store.locations.find(l => l.code === scannedLocationCode);
  if (!location) {
    return res.status(404).json({ success: false, message: 'Storage location code not found' });
  }

  // Free previous location if any
  if (pallet.locationCode) {
    const oldLoc = store.locations.find(l => l.code === pallet.locationCode);
    if (oldLoc) {
      oldLoc.currentPalletCode = null;
      oldLoc.status = 'empty';
    }
  }

  pallet.locationCode = scannedLocationCode;
  pallet.status = pallet.typeSeries === 'H' ? 'STORED_HALF' : 'STORED';

  location.currentPalletCode = palletNumber;
  location.status = 'occupied';

  saveStore();

  res.json({
    success: true,
    message: `Pallet ${palletNumber} successfully stored at location ${scannedLocationCode}`,
    pallet,
    location
  });
}

function relocatePallet(req, res) {
  const { palletNumber, newLocationCode, reason } = req.body;
  const store = getStore();

  const pallet = store.pallets.find(p => p.palletNumber === palletNumber);
  if (!pallet) {
    return res.status(404).json({ success: false, message: 'Pallet not found' });
  }

  const newLoc = store.locations.find(l => l.code === newLocationCode);
  if (!newLoc) {
    return res.status(404).json({ success: false, message: 'New location code not found' });
  }

  if (pallet.locationCode) {
    const oldLoc = store.locations.find(l => l.code === pallet.locationCode);
    if (oldLoc) {
      oldLoc.currentPalletCode = null;
      oldLoc.status = 'empty';
    }
  }

  pallet.locationCode = newLocationCode;
  newLoc.currentPalletCode = palletNumber;
  newLoc.status = 'occupied';

  saveStore();

  res.json({
    success: true,
    message: `Pallet ${palletNumber} relocated to ${newLocationCode} (Reason: ${reason || 'Manual relocation'})`,
    pallet
  });
}

module.exports = {
  getWarehouseMap,
  getHalfPalletRegister,
  executePutaway,
  relocatePallet
};
