const XLSX = require('xlsx');
const fs = require('fs');
const { getStore, saveStore } = require('./config/db');

const excelPath = 'C:\\Users\\Tanmay\\Downloads\\Finish_Goods_Job_Card_Declaration.xlsx';

if (!fs.existsSync(excelPath)) {
  console.log('Excel file not found at:', excelPath);
  process.exit(1);
}

const wb = XLSX.readFile(excelPath);
const ws = wb.Sheets['Master Consolidated'];
const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });

const db = getStore();

const existingItemCodes = new Set(db.items.map(i => i.itemCode));
const existingCustCodes = new Set(db.customers.map(c => c.customerCode));

for (let i = 2; i < rows.length; i++) {
  const r = rows[i];
  if (!r || r.length < 4) continue;
  const custName = String(r[1] || '').trim();
  const partNo = String(r[2] || '').trim();
  const sapPartNo = String(r[3] || '').trim();
  const stdPack = parseInt(r[4], 10) || 30;

  if (custName) {
    const custCode = 'CUST-' + custName.toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (!existingCustCodes.has(custCode)) {
      db.customers.push({
        customerCode: custCode,
        customerName: custName,
        city: 'Pune/India',
        pincode: '411018',
        dispatchBayPreference: 'BAY-01'
      });
      existingCustCodes.add(custCode);
    }
  }

  const itemCode = sapPartNo || partNo;
  if (itemCode && !existingItemCodes.has(itemCode)) {
    db.items.push({
      itemCode,
      partNumber: partNo || itemCode,
      description: `${custName} Wheel Assembly (${partNo || itemCode})`,
      customer: custName || 'Tata Motors',
      standardPalletQty: stdPack > 0 ? stdPack : 96,
      hsnCode: '87087000',
      unitWeightKg: 10.5,
      coatingType: 'Cathodic Electrodeposition (CED)'
    });
    existingItemCodes.add(itemCode);
  }
}

saveStore();
console.log('Successfully seeded database! Total Items:', db.items.length, 'Total Customers:', db.customers.length);
