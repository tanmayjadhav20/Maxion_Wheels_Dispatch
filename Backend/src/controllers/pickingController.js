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
    let availablePallets = store.pallets.filter(p =>
      p.itemCode === item.itemCode &&
      !p.isHold &&
      (p.status === 'STORED' || p.status === 'STORED_HALF' || p.status === 'CLOSED_MERGED_FULL' || p.status === 'CLOSED_MERGED_HALF')
    );

    // Fallback: If no STORED pallets, also check any non-dispatched, non-consumed pallets with packedQty > 0
    if (availablePallets.length === 0) {
      availablePallets = store.pallets.filter(p =>
        p.itemCode === item.itemCode &&
        !p.isHold &&
        p.status !== 'PICKED' &&
        p.status !== 'DISPATCHED' &&
        p.status !== 'OPEN' &&
        p.status !== 'SPLIT_CONSUMED' &&
        p.status !== 'MERGED_CONSUMED' &&
        p.packedQty > 0
      );
    }

    // Sort: H and M series first, then by creation date ascending (FIFO)
    availablePallets.sort((a, b) => {
      const aScore = a.typeSeries === 'H' ? 0 : a.typeSeries === 'M' ? 1 : 2;
      const bScore = b.typeSeries === 'H' ? 0 : b.typeSeries === 'M' ? 1 : 2;
      if (aScore !== bScore) return aScore - bScore;
      return new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
    });

    let qtyNeeded = item.requestedQty;
    const allocatedPalletNumbers = [];

    for (const p of availablePallets) {
      if (qtyNeeded <= 0) break;
      allocatedPalletNumbers.push(p.palletNumber);
      p.status = 'RESERVED_FOR_PICK';
      qtyNeeded -= (p.packedQty || 4);
    }

    return {
      itemCode: item.itemCode,
      requestedQty: item.requestedQty,
      allocatedPalletNumbers
    };
  });

  // Dynamic Customer lookup
  const custMaster = (store.customers || []).find(c => c.customerName === customerName || c.customerCode === customerName);
  const resolvedCustomerName = custMaster ? custMaster.customerName : (customerName || (store.customers && store.customers[0] ? store.customers[0].customerName : 'Customer'));
  const resolvedAddress = shipToAddress || (custMaster ? custMaster.shipToAddress : '');

  // Dynamic Operator lookup
  const userMaster = (store.users || []).find(u => u.employeeCode === assignedToCode || u.name === assignedToName);
  const resolvedOperatorCode = userMaster ? userMaster.employeeCode : (assignedToCode || (store.users && store.users[0] ? store.users[0].employeeCode : 'EMP001'));
  const resolvedOperatorName = userMaster ? userMaster.name : (assignedToName || (userMaster ? userMaster.name : 'Assigned Picker'));

  const newIndent = {
    indentNumber,
    customerName: resolvedCustomerName,
    shipToAddress: resolvedAddress,
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
    pickerName: resolvedOperatorName,
    assignedToCode: resolvedOperatorCode,
    assignedToName: resolvedOperatorName,
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
  const { userCode, showAll } = req.query || {};
  let list = store.pickLists || [];

  if (userCode && showAll !== 'true' && showAll !== true) {
    const matching = list.filter(p => 
      p.assignedToCode === userCode || 
      (p.pickerName && p.pickerName.toLowerCase().includes(userCode.toLowerCase())) ||
      (p.assignedToName && p.assignedToName.toLowerCase().includes(userCode.toLowerCase()))
    );
    // If operator has explicitly assigned picklists, show them. Otherwise show all open picklists
    if (matching.length > 0) {
      list = matching;
    }
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

  let pickItem = pickList.items.find(i => i.palletNumber === scannedPalletNumber);
  if (!pickItem && (!scannedPalletNumber || scannedPalletNumber === 'AUTO')) {
    pickItem = pickList.items.find(i => !i.isPicked);
  }

  if (!pickItem) {
    return res.status(400).json({ success: false, message: `Pallet ${scannedPalletNumber || ''} is not on this pick list or already picked!` });
  }

  // Location check bypassed per requirement
  pickItem.isPicked = true;

  const pallet = store.pallets.find(p => p.palletNumber === pickItem.palletNumber);
  if (pallet) {
    pallet.status = 'PICKED';
  }

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
    message: `Pallet ${pickItem.palletNumber} picked successfully! (Location scan bypassed)`,
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
