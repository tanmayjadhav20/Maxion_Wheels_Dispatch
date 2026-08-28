const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const dashboardController = require('../controllers/dashboardController');
const paintPlanController = require('../controllers/paintPlanController');
const preparationController = require('../controllers/preparationController');
const packPointController = require('../controllers/packPointController');
const warehouseController = require('../controllers/warehouseController');
const pickingController = require('../controllers/pickingController');
const dispatchController = require('../controllers/dispatchController');
const returnablesController = require('../controllers/returnablesController');
const traceabilityController = require('../controllers/traceabilityController');
const syncController = require('../controllers/syncController');
const qaController = require('../controllers/qaController');
const conversionController = require('../controllers/conversionController');
const jobCardController = require('../controllers/jobCardController');
const hhtController = require('../controllers/hhtController');

const mastersController = require('../controllers/mastersController');

const { authMiddleware, requirePermission } = require('../middleware/auth');
const { PERMISSIONS } = require('../config/constants');
const { getStore } = require('../config/db');

// --- Auth Routes ---
router.post('/auth/login', authController.login);
router.get('/auth/users', authController.getPublicUsers);
router.get('/auth/me', authMiddleware, authController.getCurrentUser);
router.get('/dashboard/stats', authMiddleware, dashboardController.getDashboardStats);

// --- Master Data Routes (Dynamic Database-Driven CRUD) ---
router.get('/masters/items', authMiddleware, mastersController.getItems);
router.post('/masters/items', authMiddleware, mastersController.createItem);
router.put('/masters/items/:itemCode', authMiddleware, mastersController.updateItem);
router.delete('/masters/items/:itemCode', authMiddleware, mastersController.deleteItem);

router.get('/masters/locations', authMiddleware, mastersController.getLocations);
router.post('/masters/locations', authMiddleware, mastersController.createLocation);
router.put('/masters/locations/:code', authMiddleware, mastersController.updateLocation);
router.delete('/masters/locations/:code', authMiddleware, mastersController.deleteLocation);

router.get('/masters/customers', authMiddleware, mastersController.getCustomers);
router.post('/masters/customers', authMiddleware, mastersController.createCustomer);
router.put('/masters/customers/:customerCode', authMiddleware, mastersController.updateCustomer);
router.delete('/masters/customers/:customerCode', authMiddleware, mastersController.deleteCustomer);

router.get('/masters/transporters', authMiddleware, mastersController.getTransporters);
router.post('/masters/transporters', authMiddleware, mastersController.createTransporter);

router.get('/masters/pallet-types', authMiddleware, mastersController.getPalletMasters);
router.post('/masters/pallet-types', authMiddleware, mastersController.createPalletMaster);

router.get('/masters/users', authMiddleware, mastersController.getUsers);
router.post('/masters/users', authMiddleware, mastersController.createUser);


// --- Module 1: Paint Plan ---
router.get('/paint-plan', authMiddleware, paintPlanController.getPaintPlans);
router.post('/paint-plan', authMiddleware, requirePermission(PERMISSIONS.PAINT_PLAN_MANAGE), paintPlanController.createOrUpdatePaintPlan);
router.get('/paint-plan/plan-vs-actual', authMiddleware, paintPlanController.getPlanVsActual);

// --- Module 2: Preparation ---
router.get('/preparation/checklist', authMiddleware, preparationController.getPreparationChecklist);

// --- Modules 3, 4, 5: Pack Point & Pallet Build ---
router.post('/pack/print-wheel-qr', authMiddleware, packPointController.printWheelQr);
router.get('/pack/active-pallet', authMiddleware, packPointController.getActivePallet);
router.get('/pack/half-pallets', authMiddleware, packPointController.getHalfPallets);
router.post('/pack/scan-wheel', authMiddleware, packPointController.startOrScanWheel);
router.post('/pack/close-pallet', authMiddleware, packPointController.closePallet);
router.post('/pack/resume-half-pallet', authMiddleware, packPointController.loadAndResumeHalfPallet);

// --- Module 6: Warehouse & Storage ---
router.get('/warehouse/map', authMiddleware, warehouseController.getWarehouseMap);
router.get('/warehouse/half-pallet-register', authMiddleware, warehouseController.getHalfPalletRegister);
router.post('/warehouse/putaway', authMiddleware, warehouseController.executePutaway);
router.post('/warehouse/relocate', authMiddleware, warehouseController.relocatePallet);

// --- Module 7: Indent, Pick List & Picking ---
router.get('/picking/indents', authMiddleware, pickingController.getIndents);
router.post('/picking/indents', authMiddleware, requirePermission(PERMISSIONS.INDENT_CREATE), pickingController.createIndent);
router.get('/picking/pick-lists', authMiddleware, pickingController.getPickLists);
router.post('/picking/reassign-picklist', authMiddleware, pickingController.reassignPickList);
router.post('/picking/scan-pick', authMiddleware, pickingController.executePickScan);

// --- Module 8 & 10: Loading, Gate Pass & SAP Invoice Poka-Yoke ---
router.get('/dispatch/gate-passes', authMiddleware, dispatchController.getGatePasses);
router.post('/dispatch/create-gate-pass', authMiddleware, dispatchController.createGatePass);
router.post('/dispatch/scan-loading', authMiddleware, dispatchController.scanLoadingPallet);
router.post('/dispatch/upload-invoice', authMiddleware, dispatchController.uploadSapInvoiceAndCheck);
router.get('/dispatch/sap-invoices', authMiddleware, dispatchController.getSapInvoices);
router.post('/dispatch/sap-invoices/dump', authMiddleware, dispatchController.dumpSapInvoice);
router.post('/dispatch/sap-invoices/bulk-dump', authMiddleware, dispatchController.bulkDumpSapInvoices);
router.post('/dispatch/parse-excel-dump', authMiddleware, dispatchController.parseExcelDump);
router.post('/dispatch/override-mismatch', authMiddleware, dispatchController.overrideInvoiceMismatch);
router.post('/dispatch/verify-gate-out', authMiddleware, dispatchController.verifySecurityGateOut);

// --- Module 9: Returnable Assets & Packaging ---
router.get('/returnables/assets', authMiddleware, returnablesController.getReturnableAssets);
router.post('/returnables/register', authMiddleware, returnablesController.registerReturnableAsset);
router.post('/returnables/receive', authMiddleware, returnablesController.receiveReturnAsset);
router.get('/returnables/statements', authMiddleware, returnablesController.getCustomerStatement);

// --- Module 10: Traceability, Stock & Audit ---
router.get('/traceability/lookup', authMiddleware, traceabilityController.traceWheelOrPallet);
router.post('/traceability/scan-to-know', authMiddleware, traceabilityController.scanToKnow);
router.post('/traceability/quality-hold', authMiddleware, requirePermission(PERMISSIONS.QUALITY_HOLD_MANAGE), traceabilityController.setQualityHold);

// --- Module 11 (Section 7): Quality Inspection & Wheel Replacement ---
router.post('/qa/open-inspection', authMiddleware, qaController.openPalletForInspection);
router.post('/qa/inspect-pallet', authMiddleware, qaController.inspectAndReplaceWheels);
router.post('/qa/close-inspection', authMiddleware, qaController.closeQaInspection);
router.get('/qa/inspection-history', authMiddleware, qaController.getInspectionHistory);

// --- Module 12 (Section 8): SPD Conversion (Partial Take & SP Packs) ---
router.post('/conversion/spd-request', authMiddleware, conversionController.createSpdRequest);
router.post('/conversion/generate-stickers', authMiddleware, conversionController.generateSpdStickers);
router.get('/conversion/proposed-pallet', authMiddleware, conversionController.getProposedPallet);
router.post('/conversion/pack-spd-wheel', authMiddleware, conversionController.packSpdWheel);
router.post('/conversion/finish-spd-job', authMiddleware, conversionController.finishSpdJob);
router.post('/conversion/spd-to-pallet', authMiddleware, conversionController.convertSpdToPallet);
router.get('/conversion/spd-requests', authMiddleware, conversionController.getSpdRequests);
router.get('/conversion/history', authMiddleware, conversionController.getConversionHistory);

// --- Module 13 (Section 9): Job Card Report for Maxion Stock Booking ---
router.get('/job-cards', authMiddleware, jobCardController.getJobCards);
router.post('/job-cards/generate', authMiddleware, jobCardController.generateJobCard);
router.post('/job-cards/approve', authMiddleware, jobCardController.approveJobCard);
router.post('/job-cards/submit', authMiddleware, jobCardController.submitJobCardToMaxion);

// --- HHT & Sync Routes ---
router.get('/hht/devices', authMiddleware, hhtController.getHhtDevices);
router.post('/hht/assign-role', authMiddleware, hhtController.assignHhtRole);
router.post('/hht/heartbeat', authMiddleware, hhtController.hhtHeartbeat);

router.get('/sync/status', authMiddleware, syncController.getSyncStatus);
router.post('/sync/process', authMiddleware, syncController.processOfflineSync);

module.exports = router;
