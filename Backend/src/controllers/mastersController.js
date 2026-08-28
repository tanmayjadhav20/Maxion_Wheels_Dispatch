const { getStore, saveStore } = require('../config/db');

// --- ITEMS CRUD ---
function getItems(req, res) {
  const store = getStore();
  const itemMap = new Map();

  // 1. Registered Master Items
  (store.items || []).forEach(item => {
    itemMap.set(item.itemCode, {
      ...item,
      source: 'MASTER'
    });
  });

  // 2. Active Paint Plan items
  (store.paintPlans || []).forEach(plan => {
    (plan.items || []).forEach(pi => {
      if (pi.itemCode && !itemMap.has(pi.itemCode)) {
        itemMap.set(pi.itemCode, {
          itemCode: pi.itemCode,
          description: pi.description || `Planned in Paint Plan ${plan.planNumber}`,
          stdPalletQty: 4,
          source: 'PAINT_PLAN'
        });
      }
    });
  });

  // 3. Warehouse Pallet Stock
  (store.pallets || []).forEach(pallet => {
    if (pallet.itemCode && !itemMap.has(pallet.itemCode)) {
      itemMap.set(pallet.itemCode, {
        itemCode: pallet.itemCode,
        description: `Warehouse Stock (Pallet ${pallet.palletNumber})`,
        stdPalletQty: pallet.stdQty || 4,
        source: 'WAREHOUSE'
      });
    }
  });

  // 4. SAP Invoice items
  (store.sapInvoices || []).forEach(inv => {
    (inv.items || []).forEach(it => {
      if (it.itemCode && !itemMap.has(it.itemCode)) {
        itemMap.set(it.itemCode, {
          itemCode: it.itemCode,
          description: it.description || `SAP Item ${it.itemCode}`,
          stdPalletQty: 4,
          source: 'ERP_INVOICE'
        });
      }
    });
  });

  res.json({ success: true, items: Array.from(itemMap.values()) });
}

function createItem(req, res) {
  const { itemCode, description, stdPalletQty = 4, wheelsPerLayer = 1, layersPerPallet = 4, palletType = 'STEEL-FRAME-A', separatorType = 'CORRUGATED-17', separatorQtyPerPallet = 3, unitWeightKg = 10, defaultCustomer = 'Tata Motors Pune', allowMerge = true } = req.body;
  const store = getStore();

  if (!itemCode) {
    return res.status(400).json({ success: false, message: 'Item code is required' });
  }

  const existing = (store.items || []).find(i => i.itemCode === itemCode);
  if (existing) {
    return res.status(400).json({ success: false, message: `Item code ${itemCode} already exists` });
  }

  const newItem = {
    itemCode,
    description: description || itemCode,
    stdPalletQty: Number(stdPalletQty),
    wheelsPerLayer: Number(wheelsPerLayer),
    layersPerPallet: Number(layersPerPallet),
    palletType,
    separatorType,
    separatorQtyPerPallet: Number(separatorQtyPerPallet),
    unitWeightKg: Number(unitWeightKg),
    defaultCustomer,
    allowMerge: Boolean(allowMerge)
  };

  if (!store.items) store.items = [];
  store.items.push(newItem);
  saveStore();

  res.json({ success: true, message: `Item ${itemCode} created successfully`, item: newItem });
}

function updateItem(req, res) {
  const { itemCode } = req.params;
  const store = getStore();

  const item = (store.items || []).find(i => i.itemCode === itemCode);
  if (!item) {
    return res.status(404).json({ success: false, message: `Item ${itemCode} not found` });
  }

  Object.assign(item, req.body);
  saveStore();

  res.json({ success: true, message: `Item ${itemCode} updated successfully`, item });
}

function deleteItem(req, res) {
  const { itemCode } = req.params;
  const store = getStore();

  const index = (store.items || []).findIndex(i => i.itemCode === itemCode);
  if (index === -1) {
    return res.status(404).json({ success: false, message: `Item ${itemCode} not found` });
  }

  store.items.splice(index, 1);
  saveStore();

  res.json({ success: true, message: `Item ${itemCode} deleted successfully` });
}

// --- LOCATIONS CRUD ---
function getLocations(req, res) {
  const store = getStore();
  res.json({ success: true, locations: store.locations || [] });
}

function createLocation(req, res) {
  const { code, zone = 'Zone A', aisle = 'A1', type = 'rack', capacity = 2, status = 'empty' } = req.body;
  const store = getStore();

  if (!code) {
    return res.status(400).json({ success: false, message: 'Location code is required' });
  }

  const existing = (store.locations || []).find(l => l.code === code);
  if (existing) {
    return res.status(400).json({ success: false, message: `Location ${code} already exists` });
  }

  const newLocation = {
    code,
    zone,
    aisle,
    type,
    capacity: Number(capacity),
    currentPalletCode: null,
    status
  };

  if (!store.locations) store.locations = [];
  store.locations.push(newLocation);
  saveStore();

  res.json({ success: true, message: `Location ${code} created successfully`, location: newLocation });
}

function updateLocation(req, res) {
  const { code } = req.params;
  const store = getStore();

  const loc = (store.locations || []).find(l => l.code === code);
  if (!loc) {
    return res.status(404).json({ success: false, message: `Location ${code} not found` });
  }

  Object.assign(loc, req.body);
  saveStore();

  res.json({ success: true, message: `Location ${code} updated successfully`, location: loc });
}

function deleteLocation(req, res) {
  const { code } = req.params;
  const store = getStore();

  const index = (store.locations || []).findIndex(l => l.code === code);
  if (index === -1) {
    return res.status(404).json({ success: false, message: `Location ${code} not found` });
  }

  store.locations.splice(index, 1);
  saveStore();

  res.json({ success: true, message: `Location ${code} deleted successfully` });
}

// --- CUSTOMERS CRUD ---
function getCustomers(req, res) {
  const store = getStore();
  res.json({ success: true, customers: store.customers || [] });
}

function createCustomer(req, res) {
  const { customerCode, customerName, shipToAddress, contactPerson = '', phone = '', defaultItemCodes = [] } = req.body;
  const store = getStore();

  if (!customerCode || !customerName) {
    return res.status(400).json({ success: false, message: 'Customer code and name are required' });
  }

  const existing = (store.customers || []).find(c => c.customerCode === customerCode || c.customerName === customerName);
  if (existing) {
    return res.status(400).json({ success: false, message: `Customer already exists` });
  }

  const newCustomer = {
    customerCode,
    customerName,
    shipToAddress: shipToAddress || '',
    contactPerson,
    phone,
    defaultItemCodes: Array.isArray(defaultItemCodes) ? defaultItemCodes : [defaultItemCodes]
  };

  if (!store.customers) store.customers = [];
  store.customers.push(newCustomer);
  saveStore();

  res.json({ success: true, message: `Customer ${customerName} created successfully`, customer: newCustomer });
}

function updateCustomer(req, res) {
  const { customerCode } = req.params;
  const store = getStore();

  const cust = (store.customers || []).find(c => c.customerCode === customerCode || c.customerName === customerCode);
  if (!cust) {
    return res.status(404).json({ success: false, message: `Customer ${customerCode} not found` });
  }

  Object.assign(cust, req.body);
  saveStore();

  res.json({ success: true, message: `Customer ${cust.customerName} updated successfully`, customer: cust });
}

function deleteCustomer(req, res) {
  const { customerCode } = req.params;
  const store = getStore();

  const index = (store.customers || []).findIndex(c => c.customerCode === customerCode || c.customerName === customerCode);
  if (index === -1) {
    return res.status(404).json({ success: false, message: `Customer ${customerCode} not found` });
  }

  store.customers.splice(index, 1);
  saveStore();

  res.json({ success: true, message: `Customer deleted successfully` });
}

// --- TRANSPORTERS CRUD ---
function getTransporters(req, res) {
  const store = getStore();
  res.json({ success: true, transporters: store.transporters || [] });
}

function createTransporter(req, res) {
  const { transporterCode, transporterName, contactPerson = '', phone = '', defaultVehicles = [] } = req.body;
  const store = getStore();

  if (!transporterCode || !transporterName) {
    return res.status(400).json({ success: false, message: 'Transporter code and name are required' });
  }

  const newTransporter = {
    transporterCode,
    transporterName,
    contactPerson,
    phone,
    defaultVehicles: Array.isArray(defaultVehicles) ? defaultVehicles : [defaultVehicles]
  };

  if (!store.transporters) store.transporters = [];
  store.transporters.push(newTransporter);
  saveStore();

  res.json({ success: true, message: `Transporter ${transporterName} created successfully`, transporter: newTransporter });
}

// --- PALLET MASTERS CRUD ---
function getPalletMasters(req, res) {
  const store = getStore();
  res.json({ success: true, palletMasters: store.palletMasters || [] });
}

function createPalletMaster(req, res) {
  const { palletType, description, capacity = 4, layers = 4, wheelsPerLayer = 1, separatorType = 'CORRUGATED-17', separatorQty = 3, tareWeightKg = 30.0, returnable = true } = req.body;
  const store = getStore();

  if (!palletType) {
    return res.status(400).json({ success: false, message: 'Pallet type is required' });
  }

  const newMaster = {
    palletType,
    description: description || palletType,
    capacity: Number(capacity),
    layers: Number(layers),
    wheelsPerLayer: Number(wheelsPerLayer),
    separatorType,
    separatorQty: Number(separatorQty),
    tareWeightKg: Number(tareWeightKg),
    returnable: Boolean(returnable)
  };

  if (!store.palletMasters) store.palletMasters = [];
  store.palletMasters.push(newMaster);
  saveStore();

  res.json({ success: true, message: `Pallet type ${palletType} created successfully`, palletMaster: newMaster });
}

// --- USERS CRUD ---
function getUsers(req, res) {
  const store = getStore();
  res.json({ success: true, users: store.users || [] });
}

function createUser(req, res) {
  const { employeeCode, badgeBarcode, name, role = 'picker', pin = '1111', permissions = [] } = req.body;
  const store = getStore();

  if (!employeeCode || !name) {
    return res.status(400).json({ success: false, message: 'Employee code and name are required' });
  }

  const existing = (store.users || []).find(u => u.employeeCode === employeeCode);
  if (existing) {
    return res.status(400).json({ success: false, message: `User ${employeeCode} already exists` });
  }

  const newUser = {
    id: `usr-${Date.now()}`,
    employeeCode,
    badgeBarcode: badgeBarcode || employeeCode,
    name,
    role,
    pin,
    permissions: Array.isArray(permissions) ? permissions : ['TRACEABILITY_VIEW']
  };

  if (!store.users) store.users = [];
  store.users.push(newUser);
  saveStore();

  res.json({ success: true, message: `User ${name} (${employeeCode}) created successfully`, user: newUser });
}

module.exports = {
  getItems,
  createItem,
  updateItem,
  deleteItem,
  getLocations,
  createLocation,
  updateLocation,
  deleteLocation,
  getCustomers,
  createCustomer,
  updateCustomer,
  deleteCustomer,
  getTransporters,
  createTransporter,
  getPalletMasters,
  createPalletMaster,
  getUsers,
  createUser
};
