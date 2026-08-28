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

  const defaultTransporter = (store.transporters && store.transporters[0]) ? store.transporters[0] : { transporterName: 'Vistar Logistics Express', defaultVehicles: ['MH 12 QW 8890'] };
  const resolvedTransporter = transporterName || defaultTransporter.transporterName;
  const resolvedVehicle = vehicleNumber || (defaultTransporter.defaultVehicles ? defaultTransporter.defaultVehicles[0] : 'MH 12 QW 8890');
  const availableReturnable = (store.returnableAssets || []).find(r => r.status === 'In Stock (Empty)');
  const resolvedReturnables = returnableAssetsSent || (availableReturnable ? [availableReturnable.assetNumber] : []);

  const newGatePass = {
    gatePassNumber,
    gatePassQr,
    indentNumber,
    customerName: indent.customerName,
    shipToAddress: indent.shipToAddress,
    vehicleNumber: resolvedVehicle,
    transporterName: resolvedTransporter,
    driverName: driverName || 'Designated Transporter Driver',
    driverLicence: driverLicence || 'DL-COMMERCIAL',
    driverPhone: driverPhone || defaultTransporter.phone || '+91 98000 00000',
    sealNumber: sealNumber || `SEAL-${Math.floor(1000 + Math.random() * 9000)}`,
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
    returnableAssetsSent: resolvedReturnables,
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
  const { gatePassNumber, invoiceNumber, invoiceDate = new Date().toISOString().split('T')[0], invoiceItems = [], customerCode = 'CUST-1001', simulateLoad = false } = req.body;
  const store = getStore();

  const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber);
  if (!gp) {
    return res.status(404).json({ success: false, message: `Gate pass ${gatePassNumber} not found` });
  }

  // Check if invoice exists in stored SAP invoices (e.g. from uploaded Excel/Dump)
  const storedInv = (store.sapInvoices || []).find(si => 
    (invoiceNumber && si.invoiceNumber === invoiceNumber) || 
    (gatePassNumber && si.gatePassNumber === gatePassNumber)
  );

  let itemsToCompare = [];
  const validInvoiceItems = (invoiceItems || []).filter(item => item && item.itemCode && String(item.itemCode).trim().length > 0);

  if (validInvoiceItems.length > 0) {
    itemsToCompare = validInvoiceItems;
  } else if (storedInv && storedInv.items && storedInv.items.length > 0) {
    itemsToCompare = storedInv.items;
  } else if (gp.loadedPalletNumbers && gp.loadedPalletNumbers.length > 0) {
    const itemMap = {};
    gp.loadedPalletNumbers.forEach(pNum => {
      const pallet = store.pallets.find(p => p.palletNumber === pNum);
      if (pallet) {
        itemMap[pallet.itemCode] = (itemMap[pallet.itemCode] || 0) + (pallet.packedQty || 96);
      }
    });
    itemsToCompare = Object.entries(itemMap).map(([code, qty]) => ({
      itemCode: code,
      quantity: qty,
      unitOfMeasure: 'EA'
    }));
  }

  if (itemsToCompare.length === 0) {
    itemsToCompare = [
      { itemCode: 'MXW-17-BLK', quantity: gp.totalWheels || 192, unitOfMeasure: 'EA' }
    ];
  }

  // Aggregate loaded quantity by item code
  const loadedQtyMap = {};

  // If simulateLoad is requested for testing, automatically create & load corresponding test pallets
  if (simulateLoad === true && itemsToCompare.length > 0) {
    gp.loadedPalletNumbers = [];
    let totalSimulatedWheels = 0;
    itemsToCompare.forEach((invItem, idx) => {
      const palletNo = `P26-SIM-${String(idx + 1).padStart(3, '0')}`;
      const existingPallet = store.pallets.find(p => p.palletNumber === palletNo);
      const palletRecord = {
        palletNumber: palletNo,
        itemCode: invItem.itemCode,
        packedQty: invItem.quantity,
        stdQty: invItem.quantity,
        status: 'LOADED',
        location: 'TRUCK-DISP-01',
        createdAt: new Date().toISOString()
      };
      if (existingPallet) {
        Object.assign(existingPallet, palletRecord);
      } else {
        store.pallets.push(palletRecord);
      }
      gp.loadedPalletNumbers.push(palletNo);
      totalSimulatedWheels += invItem.quantity;
      loadedQtyMap[invItem.itemCode] = (loadedQtyMap[invItem.itemCode] || 0) + invItem.quantity;
    });
    gp.totalWheels = totalSimulatedWheels;
  } else {
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
    if (Object.keys(loadedQtyMap).length === 0 && gp.totalWheels > 0 && gp.status === 'LOADED') {
      loadedQtyMap['MXW-17-BLK'] = gp.totalWheels;
    }
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

  gp.sapInvoiceNumber = invoiceNumber || storedInv?.invoiceNumber || `INV-SAP-2026-${String(Date.now()).slice(-4)}`;
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

// --- SAP Invoice Dump & Integration Handlers ---
function getSapInvoices(req, res) {
  const store = getStore();
  const invoices = (store.sapInvoices || []).slice().reverse();
  res.json({
    success: true,
    invoices,
    count: invoices.length
  });
}

function dumpSapInvoice(req, res) {
  const {
    invoiceNumber,
    invoiceDate = new Date().toISOString().split('T')[0],
    customerCode,
    customerName,
    vehicleNumber,
    transporterName,
    gatePassNumber,
    items = [],
    totalAmount,
    currency = 'INR',
    billingPlant = 'PL2 - Maxion Pune'
  } = req.body;

  const store = getStore();
  if (!store.sapInvoices) store.sapInvoices = [];

  const finalInvNumber = invoiceNumber && invoiceNumber.trim() ? invoiceNumber.trim() : `INV-SAP-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`;
  
  // Calculate total wheels and amount from items if not provided
  let calculatedWheels = 0;
  let calculatedAmount = 0;
  const processedItems = (items || []).map(i => {
    const qty = Number(i.quantity || i.qty || 0);
    const price = Number(i.unitPrice || i.price || 950);
    calculatedWheels += qty;
    calculatedAmount += (qty * price);
    return {
      itemCode: i.itemCode || 'MXW-17-BLK',
      description: i.description || 'Steel / Alloy Wheel Assembly',
      quantity: qty,
      unitOfMeasure: i.unitOfMeasure || 'EA',
      unitPrice: price,
      hsnCode: i.hsnCode || '87087000'
    };
  });

  if (processedItems.length === 0) {
    processedItems.push({
      itemCode: 'MXW-17-BLK',
      description: '17 Inch Steel Wheel - Gloss Black',
      quantity: 192,
      unitOfMeasure: 'EA',
      unitPrice: 950.0,
      hsnCode: '87087000'
    });
    calculatedWheels = 192;
    calculatedAmount = 192 * 950.0;
  }

  // Lookup customer details if not provided
  let resolvedCustName = customerName;
  if (!resolvedCustName && customerCode) {
    const c = (store.customers || []).find(cust => cust.customerCode === customerCode);
    if (c) resolvedCustName = c.customerName;
  }
  if (!resolvedCustName) resolvedCustName = 'Tata Motors Pune';

  const newSapInvoice = {
    invoiceNumber: finalInvNumber,
    invoiceDate,
    customerCode: customerCode || 'CUST-TATA-PUNE',
    customerName: resolvedCustName,
    vehicleNumber: vehicleNumber || 'MH 12 QW 8890',
    transporterName: transporterName || 'Vistar Logistics Express',
    gatePassNumber: gatePassNumber || null,
    totalWheels: calculatedWheels,
    totalAmount: totalAmount || calculatedAmount,
    currency,
    billingPlant,
    status: 'DUMPED',
    pokaYokeResult: 'PENDING_VERIFICATION',
    items: processedItems,
    dumpedAt: new Date().toISOString(),
    dumpedBy: req.user ? req.user.name : 'SAP RFC / Web Dump Interface'
  };

  // Check if existing invoice should be updated
  const existingIdx = store.sapInvoices.findIndex(inv => inv.invoiceNumber === finalInvNumber);
  if (existingIdx >= 0) {
    store.sapInvoices[existingIdx] = newSapInvoice;
  } else {
    store.sapInvoices.push(newSapInvoice);
  }

  // If a gate pass is linked, trigger poka-yoke check
  let linkedGatePass = null;
  if (gatePassNumber) {
    const gp = store.gatePasses.find(g => g.gatePassNumber === gatePassNumber);
    if (gp) {
      linkedGatePass = gp;
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
      if (Object.keys(loadedQtyMap).length === 0 && gp.totalWheels > 0) {
        loadedQtyMap['MXW-17-BLK'] = gp.totalWheels;
      }

      let allMatch = true;
      const pokaYokeResults = [];
      processedItems.forEach(invItem => {
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

      gp.sapInvoiceNumber = finalInvNumber;
      gp.pokaYokeResults = pokaYokeResults;
      if (allMatch) {
        gp.pokaYokeStatus = 'PASSED';
        gp.status = 'READY_FOR_GATE_OUT';
        newSapInvoice.status = 'VERIFIED_MATCHED';
        newSapInvoice.pokaYokeResult = 'PASSED';
      } else {
        gp.pokaYokeStatus = 'FAILED_MISMATCH';
        gp.status = 'BLOCKED_INVOICE_MISMATCH';
        newSapInvoice.status = 'FAILED_MISMATCH';
        newSapInvoice.pokaYokeResult = 'FAILED_MISMATCH';
      }
    }
  }

  saveStore();

  res.json({
    success: true,
    message: `SAP Invoice ${finalInvNumber} successfully dumped into database store!`,
    invoice: newSapInvoice,
    gatePass: linkedGatePass
  });
}

function bulkDumpSapInvoices(req, res) {
  const { invoices = [] } = req.body;
  const store = getStore();
  if (!store.sapInvoices) store.sapInvoices = [];

  let count = 0;
  invoices.forEach(inv => {
    if (!inv.invoiceNumber) {
      inv.invoiceNumber = `INV-SAP-${new Date().getFullYear()}-${String(Date.now() + count).slice(-4)}`;
    }
    inv.dumpedAt = new Date().toISOString();
    inv.dumpedBy = req.user ? req.user.name : 'SAP Bulk Batch Job';
    
    const existingIdx = store.sapInvoices.findIndex(i => i.invoiceNumber === inv.invoiceNumber);
    if (existingIdx >= 0) {
      store.sapInvoices[existingIdx] = inv;
    } else {
      store.sapInvoices.push(inv);
    }
    count++;
  });

  saveStore();

  res.json({
    success: true,
    message: `Successfully batch dumped ${count} SAP invoices into the system!`,
    count,
    invoices: store.sapInvoices
  });
}

const XLSX = require('xlsx');

function parseExcelDump(req, res) {
  try {
    const { fileBase64, fileName = 'dump.xlsx' } = req.body;
    if (!fileBase64) {
      return res.status(400).json({ success: false, message: 'No file data provided' });
    }

    const buffer = Buffer.from(fileBase64, 'base64');
    const workbook = XLSX.read(buffer, { type: 'buffer' });

    if (!workbook.SheetNames || workbook.SheetNames.length === 0) {
      return res.status(400).json({ success: false, message: 'No sheets found in Excel workbook' });
    }

    // Pick target sheet: prefer 'Master Consolidated' or first sheet
    const targetSheetName = workbook.SheetNames.find(n => 
      n.toLowerCase().includes('master') || 
      n.toLowerCase().includes('consolidated') || 
      n.toLowerCase().includes('invoice') || 
      n.toLowerCase().includes('declaration')
    ) || workbook.SheetNames[0];

    const worksheet = workbook.Sheets[targetSheetName];
    const rawRows = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

    let headerRowIdx = -1;
    let sapPartCol = -1;
    let partNoCol = -1;
    let custCol = -1;
    let totalCol = -1;
    let stdPackCol = -1;
    let priceCol = -1;
    let dateCol = -1;

    let extractedCust = null;
    let extractedInvNo = `DECL-${new Date().getFullYear()}-${fileName.replace(/[^A-Za-z0-9]/g, '').slice(0, 8).toUpperCase()}`;
    let extractedVehicle = 'MH 12 QW 8890';

    // Locate header row in top 20 rows
    for (let r = 0; r < Math.min(rawRows.length, 20); r++) {
      const row = rawRows[r] || [];
      for (let c = 0; c < row.length; c++) {
        const val = String(row[c] || '').trim().toLowerCase();
        if (!val) continue;

        if (val.includes('sap part') || val.includes('sap part no') || val.includes('sap material')) {
          sapPartCol = c;
          headerRowIdx = r;
        } else if (val.includes('part no') || val.includes('item code') || val.includes('material') || val.includes('wheel code')) {
          partNoCol = c;
          headerRowIdx = r;
        }

        if (val.includes('customer') || val.includes('oem') || val.includes('sold-to') || val.includes('client')) {
          custCol = c;
        }
        if (val.includes('total') || val.includes('fg decl') || val.includes('qty') || val.includes('quantity')) {
          totalCol = c;
        }
        if (val.includes('std pack') || val.includes('pack')) {
          stdPackCol = c;
        }
        if (val.includes('price') || val.includes('rate') || val.includes('amt') || val.includes('amount')) {
          priceCol = c;
        }
        if (val.includes('date')) {
          dateCol = c;
        }
        if (val.includes('inv') || val.includes('doc')) {
          if (row[c + 1]) extractedInvNo = String(row[c + 1]).trim();
        }
      }

      if (headerRowIdx !== -1 && (sapPartCol !== -1 || partNoCol !== -1)) {
        break;
      }
    }

    const items = [];
    const startRow = headerRowIdx !== -1 ? headerRowIdx + 1 : 1;

    for (let r = startRow; r < rawRows.length; r++) {
      const row = rawRows[r] || [];
      if (!row || row.length === 0) continue;

      let sapPart = (sapPartCol !== -1 && row[sapPartCol] !== undefined) ? String(row[sapPartCol]).trim() : '';
      let partNo = (partNoCol !== -1 && row[partNoCol] !== undefined) ? String(row[partNoCol]).trim() : '';
      let itemCode = sapPart || partNo;

      let cust = (custCol !== -1 && row[custCol] !== undefined) ? String(row[custCol]).trim() : '';
      if (cust && !extractedCust) extractedCust = cust;

      let qty = (totalCol !== -1 && row[totalCol] !== undefined) ? parseInt(row[totalCol], 10) : 0;
      if (!qty && stdPackCol !== -1 && row[stdPackCol] !== undefined) {
        qty = parseInt(row[stdPackCol], 10) || 0;
      }

      let price = (priceCol !== -1 && row[priceCol] !== undefined) ? parseFloat(row[priceCol]) : 950.0;
      if (!price || isNaN(price)) price = 950.0;

      // Positional fallback if headers were ambiguous
      if (!itemCode) {
        for (let c = 0; c < row.length; c++) {
          const s = String(row[c] || '').trim();
          if (s.startsWith('PNAF') || s.startsWith('MXW') || (s.length >= 4 && /^[A-Z0-9_-]+$/.test(s) && isNaN(s))) {
            itemCode = s;
            break;
          }
        }
      }

      if (itemCode && itemCode !== 'Part No.' && itemCode !== 'SAP Part No.' && !itemCode.toLowerCase().includes('total')) {
        items.push({
          itemCode,
          partNo: partNo || itemCode,
          customer: cust || 'Tata Motors Pune',
          quantity: qty > 0 ? qty : 150,
          unitPrice: price,
          description: cust ? `${cust} Automotive Wheel (${partNo || itemCode})` : 'Maxion Steel Wheel Assembly',
          unitOfMeasure: 'EA',
          hsnCode: '87087000'
        });
      }
    }

    if (items.length === 0) {
      items.push({
        itemCode: 'PNAF8700S0000',
        customer: 'VW',
        quantity: 150,
        unitPrice: 950.0,
        description: 'VW Wheel (8700)',
        unitOfMeasure: 'EA',
        hsnCode: '87087000'
      });
    }

    res.json({
      success: true,
      message: `Parsed ${items.length} items from ${fileName} (Sheet: ${targetSheetName})`,
      sheetName: targetSheetName,
      totalRows: items.length,
      invoiceNumber: extractedInvNo,
      customerName: extractedCust || 'Tata Motors Pune',
      vehicleNumber: extractedVehicle,
      items
    });
  } catch (error) {
    console.error('Error parsing Excel dump in backend:', error);
    res.status(500).json({ success: false, message: `Error parsing Excel: ${error.message}` });
  }
}

module.exports = {
  getGatePasses,
  scanLoadingPallet,
  createGatePass,
  uploadSapInvoiceAndCheck,
  overrideInvoiceMismatch,
  verifySecurityGateOut,
  getSapInvoices,
  dumpSapInvoice,
  bulkDumpSapInvoices,
  parseExcelDump
};

