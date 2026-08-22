const { getStore, saveStore } = require('../config/db');

function formatNumber(prefix, year = '26', customSuffix = '') {
  const store = getStore();
  const counterKey = prefix;
  if (!store.counters) {
    store.counters = {};
  }
  if (store.counters[counterKey] === undefined) {
    store.counters[counterKey] = 1;
  }
  const nextVal = store.counters[counterKey]++;
  saveStore();

  if (prefix === 'RP') {
    // Returnable pallet asset: RP + 7 digits (RP0001842)
    return `RP${String(nextVal).padStart(7, '0')}`;
  }
  if (prefix === 'PLN') {
    // Paint plan: PLN + YYMMDD + 2 digits
    const dateStr = new Date().toISOString().slice(2, 10).replace(/-/g, '');
    return `PLN${dateStr}${String(nextVal).padStart(2, '0')}`;
  }
  if (prefix === 'JC') {
    // Job card: JC + YYMMDD + shift
    const dateStr = new Date().toISOString().slice(2, 10).replace(/-/g, '');
    const shift = customSuffix || 'A';
    return `JC${dateStr}${shift}`;
  }
  if (prefix === 'QA' || prefix === 'SR') {
    // QA inspection: QA + YY + 5 digits, SPD request: SR + YY + 5 digits
    return `${prefix}${year}${String(nextVal).padStart(5, '0')}`;
  }

  // Standard P, H, PM, SP, IND, PKL, LD, GP: Prefix + YY + 6 digits
  const padded = String(nextVal).padStart(6, '0');
  return `${prefix}${year}${padded}`;
}

function generateWheelQr({ plant = 'P1', itemCode, serial, date = '260819', shift = 'A', line = 'PL2' }) {
  return `MW|${plant}|${itemCode}|${serial}|${date}|${shift}|${line}`;
}

function generatePalletQr(palletNumber) {
  return `MWP|${palletNumber}`;
}

function generateSpdPackQr(spdPackNumber) {
  return `MWS|${spdPackNumber}`;
}

function generateLocationQr(locationCode) {
  return `MWL|${locationCode}`;
}

function generateReturnableTag(assetNumber) {
  return `MWR|${assetNumber}`;
}

function generateGatePassQr(gatePassNumber) {
  return `MWG|${gatePassNumber}`;
}

module.exports = {
  formatNumber,
  generateWheelQr,
  generatePalletQr,
  generateSpdPackQr,
  generateLocationQr,
  generateReturnableTag,
  generateGatePassQr
};

