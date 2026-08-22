const { getStore, saveStore } = require('../config/db');

/**
 * Handheld Devices (HHT) Gun Allocation & Device Management Controller
 * Minimum 4 HHT guns required: Unloading: 2, Loading: 1, Merging/Binning: 1.
 */

function getHhtDevices(req, res) {
  const store = getStore();
  res.json({
    success: true,
    devices: store.hhtDevices || [],
    gunsSummary: {
      totalGuns: (store.hhtDevices || []).length,
      unloadingGuns: (store.hhtDevices || []).filter(d => d.roleCategory === 'UNLOADING').length,
      loadingGuns: (store.hhtDevices || []).filter(d => d.roleCategory === 'LOADING').length,
      mergingBinningGuns: (store.hhtDevices || []).filter(d => d.roleCategory === 'MERGING_BINNING').length
    }
  });
}

function assignHhtRole(req, res) {
  const { deviceId, assignedUser, roleCategory, status, location } = req.body;
  const store = getStore();

  const device = (store.hhtDevices || []).find(d => d.deviceId === deviceId || d.deviceCode === deviceId);
  if (!device) {
    return res.status(404).json({ success: false, message: `HHT Gun ${deviceId} not found` });
  }

  if (assignedUser) device.assignedUser = assignedUser;
  if (roleCategory) device.roleCategory = roleCategory;
  if (status) device.status = status;
  if (location) device.location = location;
  device.lastPing = new Date().toISOString();

  saveStore();

  res.json({
    success: true,
    message: `HHT Gun ${device.name} assigned to ${device.assignedUser} (${device.roleCategory})`,
    device
  });
}

function hhtHeartbeat(req, res) {
  const { deviceId, batteryLevel, activeMode } = req.body;
  const store = getStore();

  const device = (store.hhtDevices || []).find(d => d.deviceId === deviceId || d.deviceCode === deviceId);
  if (device) {
    if (batteryLevel !== undefined) device.batteryLevel = batteryLevel;
    if (activeMode) device.activeMode = activeMode;
    device.lastPing = new Date().toISOString();
    saveStore();
  }

  res.json({ success: true, message: 'Heartbeat received' });
}

module.exports = {
  getHhtDevices,
  assignHhtRole,
  hhtHeartbeat
};
