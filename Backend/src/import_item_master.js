const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');
const { getStore, saveStore } = require('./config/db');

const excelPath = path.join(__dirname, '../../Item_Master.xlsx');

if (!fs.existsSync(excelPath)) {
  console.error('Item Master Excel file not found at:', excelPath);
  process.exit(1);
}

const wb = XLSX.readFile(excelPath);
const sheetName = wb.SheetNames[0];
const ws = wb.Sheets[sheetName];
const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });

const db = getStore();
if (!db.items) {
  db.items = [];
}

const existingItemMap = new Map(db.items.map(i => [i.itemCode, i]));
let importedCount = 0;
let updatedCount = 0;

for (let i = 4; i < rows.length; i++) {
  const r = rows[i];
  if (!r || !r[0]) continue;

  const itemCode = String(r[0]).trim();
  const itemDesc = String(r[1] || '').trim();
  const technicalDesc = String(r[2] || '').trim();
  const classification = String(r[3] || 'Wheels').trim();
  const uom = String(r[4] || 'Numbers').trim();
  const warehouse = String(r[5] || 'PNAF-FG').trim();
  let hsn = String(r[6] || '87087000').trim();

  // Normalize HSN scientific notation like 8.7087e+007 -> 87087000
  if (hsn.includes('e+') || hsn.includes('E+')) {
    const num = Number(hsn);
    hsn = !isNaN(num) ? String(Math.round(num)) : '87087000';
  }
  if (!hsn || hsn === '0') {
    hsn = '87087000';
  }

  // Detect customer from description
  let customer = 'Maxion OE Fleet';
  const descUpper = (itemDesc + ' ' + technicalDesc).toUpperCase();
  if (descUpper.includes('SKODA')) customer = 'Skoda Auto India';
  else if (descUpper.includes('HONDA')) customer = 'Honda Cars India';
  else if (descUpper.includes('FCA') || descUpper.includes('JEEP')) customer = 'FCA India (Jeep)';
  else if (descUpper.includes('TATA')) customer = 'Tata Motors Pune';
  else if (descUpper.includes('MAHINDRA') || descUpper.includes('M&M')) customer = 'Mahindra Nashik';
  else if (descUpper.includes('MARUTI') || descUpper.includes('SUZUKI')) customer = 'Maruti Suzuki';
  else if (descUpper.includes('HYUNDAI') || descUpper.includes('KIA')) customer = 'Hyundai / Kia India';
  else if (descUpper.includes('RENAULT') || descUpper.includes('NISSAN')) customer = 'Renault Nissan';

  // Standard pallet capacity (default 96 for standard wheels, 80 for 18-19" wheels)
  let stdPalletQty = 96;
  if (descUpper.includes('18X') || descUpper.includes('18J') || descUpper.includes('19X') || descUpper.includes('19"')) {
    stdPalletQty = 80;
  } else if (descUpper.includes('15X') || descUpper.includes('15"')) {
    stdPalletQty = 96;
  }

  // Detect coating / finish
  let coatingType = 'Cathodic Electrodeposition (CED)';
  if (descUpper.includes('PIANO BLACK')) coatingType = 'Piano Black Premium';
  else if (descUpper.includes('SATIN SILVER') || descUpper.includes('SILVER')) coatingType = 'Satin Silver Painted';
  else if (descUpper.includes('GREY') || descUpper.includes('CHARCOAL')) coatingType = 'Charcoal Grey + DC';
  else if (descUpper.includes('FULLY PAINTED')) coatingType = 'Fully Painted OEM';
  else if (descUpper.includes('BERLINA BLACK') || descUpper.includes('BLACK')) coatingType = 'Berlina Black Gloss';

  const itemRecord = {
    itemCode,
    partNumber: itemCode,
    description: itemDesc || `Maxion Al Wheel ${itemCode}`,
    technicalDesc: technicalDesc || itemDesc,
    itemClassification: classification,
    uom: uom,
    warehouseDescription: warehouse,
    customer: customer,
    stdPalletQty: stdPalletQty,
    standardPalletQty: stdPalletQty,
    wheelsPerLayer: 24,
    layersPerPallet: 4,
    palletType: 'STEEL-FRAME-A',
    separatorType: 'CORRUGATED-17',
    hsnCode: hsn,
    unitWeightKg: descUpper.includes('18') || descUpper.includes('19') ? 11.8 : 9.6,
    coatingType: coatingType
  };

  if (existingItemMap.has(itemCode)) {
    const existing = existingItemMap.get(itemCode);
    Object.assign(existing, itemRecord);
    updatedCount++;
  } else {
    db.items.push(itemRecord);
    existingItemMap.set(itemCode, itemRecord);
    importedCount++;
  }
}

saveStore();

console.log(`\n======================================================`);
console.log(`MAXION WHEELS ITEM MASTER IMPORT COMPLETE`);
console.log(`======================================================`);
console.log(`- New Items Imported: ${importedCount}`);
console.log(`- Existing Items Updated: ${updatedCount}`);
console.log(`- Total Items in System: ${db.items.length}`);
console.log(`- Database file successfully updated at: ${path.join(__dirname, '../../data/db_store.json')}`);
console.log(`======================================================\n`);
