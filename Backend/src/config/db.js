const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../../data');
const DATA_FILE = path.join(DATA_DIR, 'db_store.json');

const defaultData = {
  users: [
    {
      id: 'usr-1',
      employeeCode: 'EMP001',
      badgeBarcode: 'BADGE001',
      name: 'Tanmay (Admin)',
      role: 'superAdmin',
      pin: '1234',
      permissions: [
        'PAINT_PLAN_MANAGE', 'PREPARATION_MANAGE', 'WHEEL_QR_PRINT', 'PALLET_PACK',
        'PALLET_CLOSE', 'PALLET_MERGE', 'PUTAWAY_EXECUTE', 'INDENT_CREATE',
        'PICKING_EXECUTE', 'LOADING_EXECUTE', 'GATEPASS_MANAGE', 'GATE_OUT_VERIFY',
        'RETURNABLES_MANAGE', 'TRACEABILITY_VIEW', 'REPORTS_VIEW', 'MASTERS_MANAGE',
        'QUALITY_HOLD_MANAGE'
      ]
    },
    {
      id: 'usr-2',
      employeeCode: 'EMP002',
      badgeBarcode: 'BADGE002',
      name: 'Ramesh (Pack Operator)',
      role: 'packOperator',
      pin: '1111',
      permissions: ['WHEEL_QR_PRINT', 'PALLET_PACK', 'PALLET_CLOSE', 'PALLET_MERGE', 'TRACEABILITY_VIEW']
    },
    {
      id: 'usr-3',
      employeeCode: 'EMP003',
      badgeBarcode: 'BADGE003',
      name: 'Suresh (Warehouse Manager)',
      role: 'warehouseManager',
      pin: '2222',
      permissions: ['PUTAWAY_EXECUTE', 'PICKING_EXECUTE', 'QUALITY_HOLD_MANAGE', 'REPORTS_VIEW', 'TRACEABILITY_VIEW']
    },
    {
      id: 'usr-4',
      employeeCode: 'EMP004',
      badgeBarcode: 'BADGE004',
      name: 'Vikram (Security Guard)',
      role: 'security',
      pin: '3333',
      permissions: ['GATE_OUT_VERIFY', 'RETURNABLES_MANAGE']
    }
  ],
  items: [
    {
      itemCode: 'MXW-17-BLK',
      description: '17 Inch Steel Wheel - Gloss Black',
      stdPalletQty: 96,
      wheelsPerLayer: 24,
      layersPerPallet: 4,
      palletType: 'STEEL-FRAME-A',
      separatorType: 'CORRUGATED-17',
      separatorQtyPerPallet: 3,
      unitWeightKg: 9.5,
      defaultCustomer: 'Tata Motors Pune',
      allowMerge: true
    },
    {
      itemCode: 'MXW-18-SLV',
      description: '18 Inch Alloy Wheel - Liquid Silver',
      stdPalletQty: 80,
      wheelsPerLayer: 20,
      layersPerPallet: 4,
      palletType: 'WOOD-PALLET-B',
      separatorType: 'FOAM-18',
      separatorQtyPerPallet: 3,
      unitWeightKg: 11.2,
      defaultCustomer: 'Mahindra Nashik',
      allowMerge: true
    },
    {
      itemCode: 'MXW-16-MAT',
      description: '16 Inch Heavy Truck Wheel - Matte Black',
      stdPalletQty: 64,
      wheelsPerLayer: 16,
      layersPerPallet: 4,
      palletType: 'HEAVY-STILLAGE-C',
      separatorType: 'RUBBER-16',
      separatorQtyPerPallet: 3,
      unitWeightKg: 14.8,
      defaultCustomer: 'Ashok Leyland Hosur',
      allowMerge: true
    }
  ],
  locations: [
    { code: 'WH1-A-01-A1', zone: 'Zone A', aisle: 'A1', type: 'rack', capacity: 2, currentPalletCode: 'P26000101', status: 'occupied' },
    { code: 'WH1-A-01-A2', zone: 'Zone A', aisle: 'A1', type: 'rack', capacity: 2, currentPalletCode: null, status: 'empty' },
    { code: 'WH1-A-02-B1', zone: 'Zone A', aisle: 'A2', type: 'rack', capacity: 2, currentPalletCode: 'M26000012', status: 'occupied' },
    { code: 'WH1-H-01-HB', zone: 'Half Pallet Bay', aisle: 'HB1', type: 'half_pallet_bay', capacity: 10, currentPalletCode: 'H26000037', status: 'occupied' },
    { code: 'WH1-STG-01', zone: 'Staging Area', aisle: 'STG', type: 'staging', capacity: 20, currentPalletCode: null, status: 'empty' },
    { code: 'WH1-DCK-01', zone: 'Loading Dock 1', aisle: 'DCK', type: 'dock', capacity: 10, currentPalletCode: null, status: 'empty' }
  ],
  paintPlans: [
    {
      planNumber: 'PLN26081103',
      date: '2026-08-19',
      shift: 'A',
      line: 'PL2',
      status: 'RELEASED',
      version: 1,
      releasedBy: 'Dispatch Planner',
      releasedAt: '2026-08-19T06:00:00Z',
      items: [
        { itemCode: 'MXW-17-BLK', plannedQty: 384, fullPalletsExpected: 4, looseWheelsExpected: 0, packedQty: 240 },
        { itemCode: 'MXW-18-SLV', plannedQty: 240, fullPalletsExpected: 3, looseWheelsExpected: 0, packedQty: 80 }
      ]
    }
  ],
  pallets: [
    {
      palletNumber: 'P26000101',
      typeSeries: 'P',
      itemCode: 'MXW-17-BLK',
      packedQty: 96,
      stdQty: 96,
      status: 'STORED',
      locationCode: 'WH1-A-01-A1',
      isHold: false,
      holdReason: null,
      createdAt: '2026-08-19T07:30:00Z',
      createdBy: 'Ramesh (Pack Operator)',
      oldHalfPalletNumber: null,
      wheels: []
    },
    {
      palletNumber: 'H26000037',
      typeSeries: 'H',
      itemCode: 'MXW-17-BLK',
      packedQty: 48,
      stdQty: 96,
      status: 'STORED_HALF',
      locationCode: 'WH1-H-01-HB',
      isHold: false,
      holdReason: null,
      closeReason: 'Sudden Item Changeover',
      createdAt: '2026-08-19T08:15:00Z',
      createdBy: 'Ramesh (Pack Operator)',
      oldHalfPalletNumber: null,
      ageDays: 1,
      wheels: []
    },
    {
      palletNumber: 'PM26000012',
      typeSeries: 'PM',
      itemCode: 'MXW-17-BLK',
      packedQty: 96,
      stdQty: 96,
      status: 'STORED',
      locationCode: 'WH1-A-02-B1',
      isHold: false,
      holdReason: null,
      createdAt: '2026-08-19T09:45:00Z',
      createdBy: 'Ramesh (Pack Operator)',
      oldHalfPalletNumber: 'H26000010',
      wheels: []
    }
  ],
  wheels: [
    {
      wheelQr: 'MW|P1|8912345-01|000001742|260811|A|PL2',
      itemCode: 'MXW-17-BLK',
      serialNumber: '000001742',
      palletNumber: 'P26000101',
      productionDate: '2026-08-19',
      shift: 'A',
      line: 'PL2',
      packedBy: 'Ramesh (Pack Operator)',
      packedAt: '2026-08-19T07:15:00Z'
    }
  ],
  indents: [
    {
      indentNumber: 'IND26000391',
      customerName: 'Tata Motors Pune',
      shipToAddress: 'Plot 45, Chakan Industrial Area, Pune 410501',
      requiredDate: '2026-08-20',
      priority: 'HIGH',
      status: 'PICK_IN_PROGRESS',
      items: [
        { itemCode: 'MXW-17-BLK', requestedQty: 192, allocatedPalletNumbers: ['P26000101', 'PM26000012'] }
      ],
      createdAt: '2026-08-19T10:00:00Z',
      createdBy: 'Dispatch Executive'
    }
  ],
  pickLists: [
    {
      pickListNumber: 'PKL26000455',
      indentNumber: 'IND26000391',
      pickerName: 'Suresh (Warehouse Manager)',
      status: 'IN_PROGRESS',
      items: [
        { locationCode: 'WH1-A-01-A1', palletNumber: 'P26000101', itemCode: 'MXW-17-BLK', qty: 96, isPicked: true },
        { locationCode: 'WH1-A-02-B1', palletNumber: 'PM26000012', itemCode: 'MXW-17-BLK', qty: 96, isPicked: false }
      ]
    }
  ],
  gatePasses: [
    {
      gatePassNumber: 'GP26000208',
      indentNumber: 'IND26000391',
      customerName: 'Tata Motors Pune',
      vehicleNumber: 'MH 12 QW 8890',
      transporterName: 'Vistar Logistics Express',
      driverName: 'Rajesh Kumar',
      driverLicence: 'DL-99201928',
      driverPhone: '+91 98765 43210',
      sealNumber: 'SEAL-9921',
      status: 'LOADING',
      totalPallets: 2,
      loadedPalletsCount: 1,
      totalWheels: 192,
      totalWeightKg: 1824,
      loadedPalletNumbers: ['P26000101'],
      returnableAssetsSent: ['RP0001842'],
      createdAt: '2026-08-19T11:00:00Z',
      gateOutAt: null
    }
  ],
  returnableAssets: [
    {
      assetTag: 'MWR|RP0001842',
      assetNumber: 'RP0001842',
      type: 'STEEL-FRAME-A',
      condition: 'Good',
      status: 'With Customer',
      customerName: 'Tata Motors Pune',
      issueDate: '2026-08-10',
      expectedReturnDate: '2026-09-09',
      ageingDays: 9
    },
    {
      assetTag: 'MWR|RP0001843',
      assetNumber: 'RP0001843',
      type: 'WOOD-PALLET-B',
      condition: 'Good',
      status: 'In Stock (Empty)',
      locationCode: 'WH1-A-01-A2',
      customerName: null,
      issueDate: null,
      expectedReturnDate: null,
      ageingDays: 0
    }
  ],
  qaInspections: [
    {
      inspectionId: 'QA-20260819-01',
      palletNumber: 'P26000101',
      inspectorName: 'IOC-QA Team (Inspector A)',
      removedWheelsCount: 2,
      replacedWheelsCount: 2,
      reason: 'Routine Production Quality Audit & Destructive Test',
      timestamp: '2026-08-19T09:00:00Z'
    }
  ],
  conversions: [
    {
      conversionId: 'CNV-20260819-01',
      type: 'PALLET_TO_BOXES',
      sourceType: 'OEM',
      targetType: 'SPD',
      sourcePalletNumber: 'P26000101',
      generatedBoxesCount: 24,
      convertedBy: 'SPD Planning Team',
      timestamp: '2026-08-19T10:15:00Z'
    }
  ],
  boxes: [],
  jobCards: [
    {
      jobCardNumber: 'JC26081901',
      date: '2026-08-19',
      shift: 'A',
      line: 'PL2',
      fullPalletsCount: 2,
      totalWheels: 192,
      status: 'BOOKED_TO_MAXION',
      maxionBookingRef: 'MXN-ERP-99210',
      submittedBy: 'Shift Supervisor',
      submittedAt: '2026-08-19T12:00:00Z',
      palletsIncluded: ['P26000101', 'PM26000012']
    }
  ],
  hhtDevices: [
    {
      deviceId: 'HHT-UNL-01',
      deviceCode: 'HHT-GUN-01',
      name: 'Unloading Gun 1',
      roleCategory: 'UNLOADING',
      assignedUser: 'Unloading Operator 1',
      location: 'Dock 1 - Inbound Unloading',
      status: 'ACTIVE',
      batteryLevel: 92,
      lastPing: new Date().toISOString()
    },
    {
      deviceId: 'HHT-UNL-02',
      deviceCode: 'HHT-GUN-02',
      name: 'Unloading Gun 2',
      roleCategory: 'UNLOADING',
      assignedUser: 'Unloading Operator 2',
      location: 'Dock 2 - Raw Stock Staging',
      status: 'ACTIVE',
      batteryLevel: 85,
      lastPing: new Date().toISOString()
    },
    {
      deviceId: 'HHT-LDG-01',
      deviceCode: 'HHT-GUN-03',
      name: 'Loading Gun 1',
      roleCategory: 'LOADING',
      assignedUser: 'Loading Operator 1',
      location: 'Dispatch Dock 1',
      status: 'ACTIVE',
      batteryLevel: 98,
      lastPing: new Date().toISOString()
    },
    {
      deviceId: 'HHT-MRG-01',
      deviceCode: 'HHT-GUN-04',
      name: 'Merging / Binning Gun 1',
      roleCategory: 'MERGING_BINNING',
      assignedUser: 'Warehouse Operator 1',
      location: 'Half Pallet Binning Bay',
      status: 'ACTIVE',
      batteryLevel: 78,
      lastPing: new Date().toISOString()
    }
  ],
  syncLogs: [
    { deviceId: 'HHT-UNL-01', pendingCount: 0, lastSyncTime: '2026-08-19T11:30:00Z', status: 'OK' }
  ],
  counters: {
    P: 148,
    H: 37,
    M: 12,
    PM: 12,
    RP: 1843,
    PLN: 104,
    IND: 392,
    PKL: 456,
    LD: 211,
    GP: 209,
    JC: 1,
    CNV: 1,
    BX: 24
  }
};

let store = null;

function loadStore() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
    if (fs.existsSync(DATA_FILE)) {
      const fileData = fs.readFileSync(DATA_FILE, 'utf8');
      store = JSON.parse(fileData);
      if (!store.qaInspections) store.qaInspections = defaultData.qaInspections;
      if (!store.conversions) store.conversions = defaultData.conversions;
      if (!store.boxes) store.boxes = defaultData.boxes;
      if (!store.spdRequests) store.spdRequests = [];
      if (!store.spdPacks) store.spdPacks = [];
      if (!store.jobCards) store.jobCards = defaultData.jobCards;
      if (!store.hhtDevices) store.hhtDevices = defaultData.hhtDevices;
      if (!store.counters) store.counters = defaultData.counters;
      if (!store.counters.PM) store.counters.PM = 12;
      if (!store.counters.SR) store.counters.SR = 38;
      if (!store.counters.SP) store.counters.SP = 411;
      if (!store.counters.QA) store.counters.QA = 114;
      if (!store.counters.JC) store.counters.JC = 1;
      if (!store.counters.CNV) store.counters.CNV = 1;
      if (!store.counters.BX) store.counters.BX = 24;
    } else {
      store = defaultData;
      saveStore();
    }
  } catch (err) {
    console.error('Error loading DB store, using default:', err);
    store = defaultData;
  }
}

function saveStore() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
    fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), 'utf8');
  } catch (err) {
    console.error('Error saving DB store:', err);
  }
}

loadStore();

module.exports = {
  getStore: () => store,
  saveStore
};
