const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateReturnableTag } = require('../utils/qr');

function getReturnableAssets(req, res) {
  const store = getStore();
  res.json({ success: true, assets: store.returnableAssets });
}

function registerReturnableAsset(req, res) {
  const { type, condition = 'Good', palletNumber = null, itemCode = null, customerName = null, locationCode = 'WH1-A-01-A2' } = req.body;
  const store = getStore();

  const assetNumber = formatNumber('RP');
  const assetTag = generateReturnableTag(assetNumber);

  const newAsset = {
    assetTag,
    assetNumber,
    type: type || 'STEEL-FRAME-A',
    palletNumber: palletNumber || (store.pallets && store.pallets[0] ? store.pallets[0].palletNumber : 'P26000101'),
    itemCode: itemCode || (store.items && store.items[0] ? store.items[0].itemCode : 'MXW-17-BLK'),
    condition,
    status: customerName ? 'With Customer' : 'In Stock (Empty)',
    locationCode,
    customerName: customerName || null,
    issueDate: customerName ? new Date().toISOString().split('T')[0] : null,
    expectedReturnDate: customerName ? new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0] : null,
    ageingDays: 0
  };

  store.returnableAssets.unshift(newAsset);
  saveStore();

  res.json({ success: true, message: 'Returnable asset registered successfully', asset: newAsset });
}

function receiveReturnAsset(req, res) {
  const { assetNumber, palletNumber, itemCode, customerName, condition = 'Good', reason = '' } = req.body;
  const store = getStore();

  let asset = store.returnableAssets.find(a => a.assetNumber === assetNumber || a.assetTag.includes(assetNumber));
  if (!asset) {
    // If not found, create a newly logged asset entry
    const newTag = assetNumber.startsWith('MWR|') ? assetNumber : generateReturnableTag(assetNumber || formatNumber('RP'));
    const resolvedNo = assetNumber.replace('MWR|', '') || formatNumber('RP');
    asset = {
      assetTag: newTag,
      assetNumber: resolvedNo,
      type: 'STEEL-FRAME-A',
      palletNumber: palletNumber || 'P26000101',
      itemCode: itemCode || 'MXW-17-BLK',
      condition,
      status: 'In Stock (Empty)',
      locationCode: 'WH1-A-01-A2',
      customerName: null,
      issueDate: null,
      expectedReturnDate: null,
      ageingDays: 0
    };
    store.returnableAssets.unshift(asset);
  } else {
    asset.condition = condition;
    if (palletNumber) asset.palletNumber = palletNumber;
    if (itemCode) asset.itemCode = itemCode;

    if (condition === 'Needs repair' || condition === 'Damaged (Minor)') {
      asset.status = 'In Repair';
    } else if (condition === 'Scrap' || condition === 'Damaged (Major)') {
      asset.status = 'Scrapped';
    } else {
      asset.status = 'In Stock (Empty)';
      asset.locationCode = 'WH1-A-01-A2';
    }

    asset.customerName = null;
    asset.issueDate = null;
    asset.expectedReturnDate = null;
    asset.ageingDays = 0;
  }

  saveStore();

  res.json({
    success: true,
    message: `Returnable asset ${asset.assetNumber} (Pallet: ${asset.palletNumber || 'N/A'}, Item: ${asset.itemCode || 'N/A'}) received back as ${condition}!`,
    asset
  });
}

function getCustomerStatement(req, res) {
  const store = getStore();
  const customerMap = {};

  store.returnableAssets.forEach(a => {
    if (a.customerName) {
      if (!customerMap[a.customerName]) {
        customerMap[a.customerName] = {
          customerName: a.customerName,
          totalSent: 0,
          totalReturned: 0,
          outstandingBalance: 0,
          assets: []
        };
      }
      customerMap[a.customerName].outstandingBalance++;
      customerMap[a.customerName].assets.push(a);
    }
  });

  const statements = Object.values(customerMap);
  res.json({ success: true, statements });
}

module.exports = {
  getReturnableAssets,
  registerReturnableAsset,
  receiveReturnAsset,
  getCustomerStatement
};
