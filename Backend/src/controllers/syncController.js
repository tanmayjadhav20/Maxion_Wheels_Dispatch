const { getStore, saveStore } = require('../config/db');

function getSyncStatus(req, res) {
  const store = getStore();
  res.json({
    success: true,
    serverTime: new Date().toISOString(),
    devices: store.syncLogs
  });
}

function processOfflineSync(req, res) {
  const { deviceId, pendingTransactions = [] } = req.body;
  const store = getStore();

  let processedCount = 0;
  const errors = [];

  pendingTransactions.forEach((tx, idx) => {
    try {
      // Replay transaction in order
      if (tx.type === 'WHEEL_SCAN') {
        const pallet = store.pallets.find(p => p.palletNumber === tx.palletNumber);
        if (pallet && !pallet.wheels.includes(tx.wheelQr)) {
          pallet.wheels.push(tx.wheelQr);
          pallet.packedQty = pallet.wheels.length;
        }
      } else if (tx.type === 'PUTAWAY') {
        const pallet = store.pallets.find(p => p.palletNumber === tx.palletNumber);
        if (pallet) {
          pallet.locationCode = tx.locationCode;
          pallet.status = pallet.typeSeries === 'H' ? 'STORED_HALF' : 'STORED';
        }
      }
      processedCount++;
    } catch (err) {
      errors.push({ index: idx, error: err.message });
    }
  });

  // Update device log
  let devLog = store.syncLogs.find(d => d.deviceId === deviceId);
  if (!devLog) {
    devLog = { deviceId, pendingCount: 0, lastSyncTime: new Date().toISOString(), status: 'OK' };
    store.syncLogs.push(devLog);
  }
  devLog.lastSyncTime = new Date().toISOString();
  devLog.pendingCount = 0;

  saveStore();

  res.json({
    success: true,
    message: `Sync completed. ${processedCount} transactions applied.`,
    processedCount,
    errors,
    serverTime: new Date().toISOString()
  });
}

module.exports = {
  getSyncStatus,
  processOfflineSync
};
