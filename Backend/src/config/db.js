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
      permissions: [
        'PAINT_PLAN_MANAGE', 'PREPARATION_MANAGE', 'INDENT_CREATE', 'PUTAWAY_EXECUTE',
        'PICKING_EXECUTE', 'LOADING_EXECUTE', 'GATEPASS_MANAGE', 'GATE_OUT_VERIFY',
        'RETURNABLES_MANAGE', 'QUALITY_HOLD_MANAGE', 'REPORTS_VIEW', 'TRACEABILITY_VIEW',
        'MASTERS_MANAGE'
      ]
    },
    {
      id: 'usr-4',
      employeeCode: 'EMP004',
      badgeBarcode: 'BADGE004',
      name: 'Vikram (Security Guard)',
      role: 'security',
      pin: '3333',
      permissions: [
        'GATE_OUT_VERIFY', 'GATEPASS_MANAGE', 'LOADING_EXECUTE', 'RETURNABLES_MANAGE',
        'TRACEABILITY_VIEW'
      ]
    },
    {
      id: 'usr-5',
      employeeCode: 'EMP005',
      badgeBarcode: 'BADGE005',
      name: 'John (HHT Forklift Operator 1)',
      role: 'picker',
      pin: '4444',
      permissions: [
        'PUTAWAY_EXECUTE',
        'PICKING_EXECUTE',
        'LOADING_EXECUTE',
        'TRACEABILITY_VIEW'
      ]
    },
    {
      id: 'usr-6',
      employeeCode: 'EMP006',
      badgeBarcode: 'BADGE006',
      name: 'Pooja (SPD Planning Team)',
      role: 'supervisor',
      pin: '5555',
      permissions: ['PAINT_PLAN_MANAGE', 'INDENT_CREATE', 'REPORTS_VIEW', 'TRACEABILITY_VIEW']
    },
    {
      id: 'usr-7',
      employeeCode: 'EMP007',
      badgeBarcode: 'BADGE007',
      name: 'Anand (IOC-QA Inspector)',
      role: 'supervisor',
      pin: '6666',
      permissions: ['QUALITY_HOLD_MANAGE', 'TRACEABILITY_VIEW', 'REPORTS_VIEW']
    }
  ],
  customers: [
    {
      customerCode: 'CUST-TATA-PUNE',
      customerName: 'Tata Motors Pune',
      shipToAddress: 'Plot 45, Chakan Industrial Area, Phase II, Pune 410501',
      contactPerson: 'Milind Shinde',
      phone: '+91 98230 11223',
      defaultItemCodes: ['MXW-17-BLK', 'MXW-16-BLK']
    },
    {
      customerCode: 'CUST-MAH-NASHIK',
      customerName: 'Mahindra Nashik',
      shipToAddress: 'MIDC Satpur, Plant 1 Logistics Gate, Nashik 422007',
      contactPerson: 'Sanjay Deshmukh',
      phone: '+91 98220 44556',
      defaultItemCodes: ['MXW-18-SLV', 'MXW-19-WHT']
    },
    {
      customerCode: 'CUST-ASHOK-HOSUR',
      customerName: 'Ashok Leyland Hosur',
      shipToAddress: 'SIPCOT Industrial Complex, Phase 1, Hosur, Tamil Nadu 635126',
      contactPerson: 'V. Ramanathan',
      phone: '+91 94430 99887',
      defaultItemCodes: ['MXW-16-MAT']
    },
    {
      customerCode: 'CUST-SPD-PUNE',
      customerName: 'SPD Aftermarket Pune',
      shipToAddress: 'Plant 2 Warehouse, Chakan Midc, Pune 410501',
      contactPerson: 'Rahul More',
      phone: '+91 98900 33445',
      defaultItemCodes: ['MXW-17-BLK', 'MXW-18-SLV']
    },
    {
      customerCode: 'CUST-MARUTI-MANESAR',
      customerName: 'Maruti Suzuki Manesar',
      shipToAddress: 'Plot 1, Phase 3A, IMT Manesar, Gurugram 122051',
      contactPerson: 'Rajiv Mehra',
      phone: '+91 98110 55667',
      defaultItemCodes: ['MXW-16-BLK']
    }
  ],
  transporters: [
    {
      transporterCode: 'TR-VISTAR',
      transporterName: 'Vistar Logistics Express',
      contactPerson: 'Sunil Patil',
      phone: '+91 98765 43210',
      defaultVehicles: ['MH 12 QW 8890', 'MH 14 AB 1234', 'MH 12 TR 9988']
    },
    {
      transporterCode: 'TR-MAXION',
      transporterName: 'Maxion Dedicated Fleet',
      contactPerson: 'Kailash Kadam',
      phone: '+91 98811 22334',
      defaultVehicles: ['MH 12 CD 5678', 'MH 12 EF 9012']
    },
    {
      transporterCode: 'TR-ALLINDIA',
      transporterName: 'All India Roadways Corp',
      contactPerson: 'Harpreet Singh',
      phone: '+91 98140 77889',
      defaultVehicles: ['HR 55 XY 3344', 'DL 01 GH 6677']
    }
  ],
  palletMasters: [
    {
      palletType: 'STEEL-FRAME-A',
      description: 'Heavy Duty Returnable Steel Stillage Frame A',
      capacity: 4,
      layers: 4,
      wheelsPerLayer: 1,
      separatorType: 'CORRUGATED-17',
      separatorQty: 3,
      tareWeightKg: 45.0,
      returnable: true
    },
    {
      palletType: 'WOOD-PALLET-B',
      description: 'Standard Export Wooden Pallet B',
      capacity: 4,
      layers: 4,
      wheelsPerLayer: 1,
      separatorType: 'FOAM-18',
      separatorQty: 3,
      tareWeightKg: 22.5,
      returnable: true
    },
    {
      palletType: 'HEAVY-STILLAGE-C',
      description: 'Industrial Commercial Truck Wheel Stillage C',
      capacity: 4,
      layers: 4,
      wheelsPerLayer: 1,
      separatorType: 'RUBBER-16',
      separatorQty: 3,
      tareWeightKg: 65.0,
      returnable: true
    }
  ],
  items: [
    {
      itemCode: 'MXW-17-BLK',
      description: '17 Inch Steel Wheel - Gloss Black',
      stdPalletQty: 4,
      wheelsPerLayer: 1,
      layersPerPallet: 4,
      palletType: 'STEEL-FRAME-A',
      separatorType: 'CORRUGATED-17',
      separatorQtyPerPallet: 3,
      unitWeightKg: 9.5,
      defaultCustomer: 'Tata Motors Pune',
      allowMerge: true
    },
    {
      itemCode: 'MXW-16-BLK',
      description: '16 Inch Steel Wheel - Gloss Black',
      stdPalletQty: 4,
      wheelsPerLayer: 1,
      layersPerPallet: 4,
      palletType: 'STEEL-FRAME-A',
      separatorType: 'CORRUGATED-16',
      separatorQtyPerPallet: 3,
      unitWeightKg: 8.8,
      defaultCustomer: 'Tata Motors Pune',
      allowMerge: true
    },
    {
      itemCode: 'MXW-18-SLV',
      description: '18 Inch Alloy Wheel - Liquid Silver',
      stdPalletQty: 4,
      wheelsPerLayer: 1,
      layersPerPallet: 4,
      palletType: 'WOOD-PALLET-B',
      separatorType: 'FOAM-18',
      separatorQtyPerPallet: 3,
      unitWeightKg: 11.2,
      defaultCustomer: 'Mahindra Nashik',
      allowMerge: true
    },
    {
      itemCode: 'MXW-19-WHT',
      description: '19 Inch Alloy Wheel - Polar White',
      stdPalletQty: 4,
      wheelsPerLayer: 1,
      layersPerPallet: 4,
      palletType: 'WOOD-PALLET-B',
      separatorType: 'FOAM-19',
      separatorQtyPerPallet: 3,
      unitWeightKg: 12.0,
      defaultCustomer: 'Mahindra Nashik',
      allowMerge: true
    },
    {
      itemCode: 'MXW-16-MAT',
      description: '16 Inch Heavy Truck Wheel - Matte Black',
      stdPalletQty: 4,
      wheelsPerLayer: 1,
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
      pickerName: 'John (HHT Forklift Operator 1)',
      assignedToCode: 'EMP005',
      assignedToName: 'John (HHT Forklift Operator 1)',
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
      palletNumber: 'P26000101',
      itemCode: 'MXW-17-BLK',
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
      palletNumber: 'PM26000012',
      itemCode: 'MXW-17-BLK',
      type: 'WOOD-PALLET-B',
      condition: 'Good',
      status: 'In Stock (Empty)',
      locationCode: 'WH1-A-01-A2',
      customerName: null,
      issueDate: null,
      expectedReturnDate: null,
      ageingDays: 0
    },
    {
      assetTag: 'MWR|RP0001844',
      assetNumber: 'RP0001844',
      palletNumber: 'P26000105',
      itemCode: 'MXW-18-SLV',
      type: 'STEEL-FRAME-A',
      condition: 'Good',
      status: 'With Customer',
      customerName: 'Mahindra Nashik',
      issueDate: '2026-08-14',
      expectedReturnDate: '2026-09-13',
      ageingDays: 5
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
  sapInvoices: [
    {
      invoiceNumber: 'INV-SAP-2026-9921',
      invoiceDate: '2026-08-19',
      customerCode: 'CUST-TATA-PUNE',
      customerName: 'Tata Motors Pune',
      vehicleNumber: 'MH 12 QW 8890',
      transporterName: 'Vistar Logistics Express',
      gatePassNumber: 'GP26000208',
      totalWheels: 192,
      totalAmount: 182400.0,
      currency: 'INR',
      status: 'VERIFIED_MATCHED',
      pokaYokeResult: 'PASSED',
      items: [
        { itemCode: 'MXW-17-BLK', description: '17 Inch Steel Wheel - Gloss Black', quantity: 192, unitOfMeasure: 'EA', unitPrice: 950.0 }
      ],
      dumpedAt: '2026-08-19T10:45:00Z',
      dumpedBy: 'SAP Integration Service'
    }
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
    BX: 24,
    SR: 38,
    SP: 411,
    QA: 114
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
      
      // Ensure all master collections are initialized
      if (!store.users) store.users = defaultData.users;
      else {
        // Merge any default users that might be missing (e.g. EMP005)
        defaultData.users.forEach(defUser => {
          if (!store.users.some(u => u.employeeCode === defUser.employeeCode)) {
            store.users.push(defUser);
          }
        });
      }

      if (!store.customers) store.customers = defaultData.customers;
      if (!store.transporters) store.transporters = defaultData.transporters;
      if (!store.palletMasters) store.palletMasters = defaultData.palletMasters;
      if (!store.items) store.items = defaultData.items;
      if (!store.locations) store.locations = defaultData.locations;

      if (!store.qaInspections) store.qaInspections = defaultData.qaInspections;
      if (!store.conversions) store.conversions = defaultData.conversions;
      if (!store.boxes) store.boxes = defaultData.boxes;
      if (!store.spdRequests) store.spdRequests = [];
      if (!store.spdPacks) store.spdPacks = [];
      if (!store.jobCards) store.jobCards = defaultData.jobCards;
      if (!store.hhtDevices) store.hhtDevices = defaultData.hhtDevices;
      if (!store.syncLogs) store.syncLogs = defaultData.syncLogs;
      if (!store.sapInvoices) store.sapInvoices = defaultData.sapInvoices;
      if (!store.counters) store.counters = defaultData.counters;
      if (!store.counters.PM) store.counters.PM = 12;
      if (!store.counters.SR) store.counters.SR = 38;
      if (!store.counters.SP) store.counters.SP = 411;
      if (!store.counters.QA) store.counters.QA = 114;
      if (!store.counters.JC) store.counters.JC = 1;
      if (!store.counters.CNV) store.counters.CNV = 1;
      if (!store.counters.BX) store.counters.BX = 24;
      
      saveStore();
    } else {
      store = defaultData;
      saveStore();
    }
  } catch (err) {
    console.error('Error loading DB store, using default:', err);
    store = defaultData;
  }
}

let saveTimeout = null;
let isSaving = false;
let pendingSave = false;

function saveStore(immediate = false) {
  if (immediate) {
    try {
      if (!fs.existsSync(DATA_DIR)) {
        fs.mkdirSync(DATA_DIR, { recursive: true });
      }
      fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), 'utf8');
    } catch (err) {
      console.error('Error saving DB store immediately:', err);
    }
    return;
  }

  if (saveTimeout) {
    clearTimeout(saveTimeout);
  }

  saveTimeout = setTimeout(() => {
    if (isSaving) {
      pendingSave = true;
      return;
    }

    isSaving = true;
    try {
      if (!fs.existsSync(DATA_DIR)) {
        fs.mkdirSync(DATA_DIR, { recursive: true });
      }
      fs.writeFile(DATA_FILE, JSON.stringify(store, null, 2), 'utf8', (err) => {
        isSaving = false;
        if (err) {
          console.error('Error saving DB store:', err);
        }
        if (pendingSave) {
          pendingSave = false;
          saveStore();
        }
      });
    } catch (err) {
      isSaving = false;
      console.error('Error initiating save:', err);
    }
  }, 50);
}

process.on('SIGINT', () => { saveStore(true); process.exit(0); });
process.on('SIGTERM', () => { saveStore(true); process.exit(0); });

loadStore();

module.exports = {
  getStore: () => store,
  saveStore
};

