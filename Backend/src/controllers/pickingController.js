const { getStore, saveStore } = require('../config/db');
const { formatNumber } = require('../utils/qr');

function getIndents(req, res) {
  const store = getStore();
  res.json({ success: true, indents: store.indents });
}

function createIndent(req, res) {
  const { customerName, shipToAddress, requiredDate, priority, items, assignedToCode, assignedToName } = req.body;
  const store = getStore();

  const indentNumber = formatNumber('IND');

  const processedItems = items.map(item => {
    // Pick pallets algorithm: Half & Merged first, then oldest Full pallets
    const availablePallets = store.pallets.filter(p =>
      p.itemCode === item.itemCode &&
      !p.isHold &&
      (p.status === 'STORED' || p.status === 'STORED_HALF' || p.status === 'CLOSED_MERGED_FULL' || p.status === 'CLOSED_MERGED_HALF')
    );

    // Sort: H and M series first, then by creation date ascending (FIFO)
    availablePallets.sort((a, b) => {
      const aScore = a.typeSeries === 'H' ? 0 : a.typeSeries === 'M' ? 1 : 2;
      const bScore = b.typeSeries === 'H' ? 0 : b.typeSeries === 'M' ? 1 : 2;
      if (aScore !== bScore) return aScore - bScore;
      return new Date(a.createdAt) - new Date(b.createdAt);
    });

    let qtyNeeded = item.requestedQty;
    const allocatedPalletNumbers = [];

    for (const p of availablePallets) {
      if (qtyNeeded <= 0) break;
      allocatedPalletNumbers.push(p.palletNumber);
      p.status = 'RESERVED_FOR_PICK';
      qtyNeeded -= p.packedQty;
    }

    return {
      itemCode: item.itemCode,
      requestedQty: item.requestedQty,
      allocatedPalletNumbers
    };
  });

  const newIndent = {
    indentNumber,
    customerName: customerName || 'Tata Motors Pune',
    shipToAddress: shipToAddress || 'Plot 45, Chakan Industrial Area, Pune 410501',
    requiredDate: requiredDate || new Date().toISOString().split('T')[0],
    priority: priority || 'NORMAL',
    status: 'OPEN',
    items: processedItems,
    createdAt: new Date().toISOString(),
    createdBy: req.user ? req.user.name : 'Dispatch Executive'
  };

  store.indents.unshift(newIndent);

  // Automatically generate pick list
  const pickListNumber = formatNumber('PKL');
  const pickListItems = [];

  processedItems.forEach(i => {
    i.allocatedPalletNumbers.forEach(pNum => {
      const pallet = store.pallets.find(p => p.palletNumber === pNum);
      if (pallet) {
        pickListItems.push({
          locationCode: pallet.locationCode || 'WH1-STG-01',
          palletNumber: pallet.palletNumber,
          itemCode: pallet.itemCode,
          qty: pallet.packedQty,
          isPicked: false
        });
      }
    });
  });

  const newPickList = {
    pickListNumber,
    indentNumber,
    pickerName: assignedToName || 'John (HHT Forklift Operator 1)',
    assignedToCode: assignedToCode || 'EMP005',
    assignedToName: assignedToName || 'John (HHT Forklift Operator 1)',
    status: 'OPEN',
    createdAt: new Date().toISOString(),
    items: pickListItems
  };

  store.pickLists.unshift(newPickList);
  saveStore();

  res.json({
    success: true,
    message: `Indent created & Pick List ${pickListNumber} assigned to ${newPickList.assignedToName}!`,
    indent: newIndent,
    pickList: newPickList
  });
}

function getPickLists(req, res) {
  const store = getStore();
  const { userCode } = req.query;
  let list = store.pickLists;
  if (userCode) {
    list = list.filter(p => p.assignedToCode === userCode || p.pickerName.includes(userCode));
  }
  res.json({ success: true, pickLists: list });
}

function reassignPickList(req, res) {
  const { pickListNumber, assignedToCode, assignedToName } = req.body;
  const store = getStore();

  const pickList = store.pickLists.find(p => p.pickListNumber === pickListNumber);
  if (!pickList) {
    return res.status(404).json({ success: false, message: 'Pick list not found' });
  }

  pickList.assignedToCode = assignedToCode;
  pickList.assignedToName = assignedToName;
  pickList.pickerName = assignedToName;
  saveStore();

  res.json({
    success: true,
    message: `Pick list ${pickListNumber} reassigned to ${assignedToName}!`,
    pickList
  });
}

function executePickScan(req, res) {
  const { pickListNumber, scannedLocationCode, scannedPalletNumber } = req.body;
  const store = getStore();

  const pickList = store.pickLists.find(p => p.pickListNumber === pickListNumber);
  if (!pickList) {
    return res.status(404).json({ success: false, message: 'Pick list not found' });
  }

  const pickItem = pickList.items.find(i => i.palletNumber === scannedPalletNumber);
  if (!pickItem) {
    return res.status(400).json({ success: false, message: `WRONG PALLET: Pallet ${scannedPalletNumber} is not on this pick list!` });
  }

  if (pickItem.locationCode !== scannedLocationCode) {
    return res.status(400).json({ success: false, message: `WRONG LOCATION: Pallet is expected at ${pickItem.locationCode}, scanned ${scannedLocationCode}` });
  }

  pickItem.isPicked = true;

  // Check if all items picked
  const allPicked = pickList.items.every(i => i.isPicked);
  if (allPicked) {
    pickList.status = 'COMPLETED';
    const indent = store.indents.find(i => i.indentNumber === pickList.indentNumber);
    if (indent) {
      indent.status = 'READY_FOR_LOADING';
    }
  } else {
    pickList.status = 'IN_PROGRESS';
  }

  saveStore();

  res.json({
    success: true,
    message: `Pallet ${scannedPalletNumber} picked successfully!`,
    pickList
  });
}

module.exports = {
  getIndents,
  createIndent,
  getPickLists,
  reassignPickList,
  executePickScan
};
