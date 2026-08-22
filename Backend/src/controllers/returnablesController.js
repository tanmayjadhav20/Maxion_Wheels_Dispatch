const { getStore, saveStore } = require('../config/db');
const { formatNumber, generateReturnableTag } = require('../utils/qr');

function getReturnableAssets(req, res) {
  const store = getStore();
  res.json({ success: true, assets: store.returnableAssets });
}

function registerReturnableAsset(req, res) {
  const { type, condition = 'Good' } = req.body;
  const store = getStore();

  const assetNumber = formatNumber('RP');
  const assetTag = generateReturnableTag(assetNumber);

  const newAsset = {
    assetTag,
    assetNumber,
    type: type || 'STEEL-FRAME-A',
    condition,
    status: 'In Stock (Empty)',
    locationCode: 'WH1-A-01-A2',
    customerName: null,
    issueDate: null,
    expectedReturnDate: null,
    ageingDays: 0
  };

  store.returnableAssets.unshift(newAsset);
  saveStore();

  res.json({ success: true, message: 'Returnable asset registered successfully', asset: newAsset });
}

function receiveReturnAsset(req, res) {
  const { assetNumber, condition = 'Good', reason = '' } = req.body;
  const store = getStore();

  const asset = store.returnableAssets.find(a => a.assetNumber === assetNumber || a.assetTag.includes(assetNumber));
  if (!asset) {
    return res.status(404).json({ success: false, message: 'Returnable asset tag not found' });
  }

  asset.condition = condition;
  if (condition === 'Needs repair') {
    asset.status = 'In Repair';
  } else if (condition === 'Scrap') {
    asset.status = 'Scrapped';
  } else {
    asset.status = 'In Stock (Empty)';
    asset.locationCode = 'WH1-A-01-A2';
  }

  asset.customerName = null;
  asset.issueDate = null;
  asset.expectedReturnDate = null;
  asset.ageingDays = 0;

  saveStore();

  res.json({
    success: true,
    message: `Returnable asset ${assetNumber} received back as ${condition}!`,
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
