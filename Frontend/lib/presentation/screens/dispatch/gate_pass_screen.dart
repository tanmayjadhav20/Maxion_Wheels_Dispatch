import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/excel_upload_helper.dart';
import '../../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class GatePassScreen extends ConsumerStatefulWidget {
  const GatePassScreen({super.key});

  @override
  ConsumerState<GatePassScreen> createState() => _GatePassScreenState();
}

class _GatePassScreenState extends ConsumerState<GatePassScreen> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // --- Tab 1: Poka-Yoke Check Controllers ---
  final _gatePassNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _invoiceQtyController = TextEditingController();
  final _overrideAuthorizerController = TextEditingController(text: 'Dispatch Head');
  final _overrideReasonController = TextEditingController();
  final _securityGatePassQrController = TextEditingController();

  // --- Tab 2: Dump SAP Invoice Form Controllers ---
  final _dumpInvoiceNoController = TextEditingController();
  final _dumpInvoiceDateController = TextEditingController();
  final _dumpVehicleNoController = TextEditingController(text: 'MH 12 QW 8890');
  final _dumpBillingPlantController = TextEditingController(text: 'PL2 - Maxion Pune');
  final _dumpRawTextController = TextEditingController();
  
  String? _dumpSelectedCustomerCode;
  String? _dumpSelectedTransporter;
  String? _dumpSelectedGatePass;
  
  List<Map<String, dynamic>> _dumpLineItems = [
    {'itemCode': 'MXW-17-BLK', 'description': '17 Inch Steel Wheel - Gloss Black', 'quantity': 192, 'unitOfMeasure': 'EA', 'unitPrice': 950.0}
  ];

  // --- State Variables ---
  bool _isLoading = false;
  bool _isDumping = false;
  Map<String, dynamic>? _activeGatePass;
  List<dynamic> _gatePasses = [];
  List<dynamic> _sapInvoices = [];
  List<dynamic> _pokaYokeResults = [];
  String _pokaYokeStatus = 'PENDING_INVOICE';
  int _dumpCurrentPage = 0;
  final int _dumpPageSize = 20;

  // Master Data
  List<dynamic> _masterItems = [];
  List<dynamic> _masterCustomers = [];
  List<dynamic> _masterTransporters = [];

  @override
  void initState() {
    super.initState();
    _dumpInvoiceDateController.text = DateTime.now().toIso8601String().split('T')[0];
    _loadInitialData();
  }

  @override
  void dispose() {
    _gatePassNumberController.dispose();
    _invoiceNumberController.dispose();
    _itemCodeController.dispose();
    _invoiceQtyController.dispose();
    _overrideAuthorizerController.dispose();
    _overrideReasonController.dispose();
    _securityGatePassQrController.dispose();
    _dumpInvoiceNoController.dispose();
    _dumpInvoiceDateController.dispose();
    _dumpVehicleNoController.dispose();
    _dumpBillingPlantController.dispose();
    _dumpRawTextController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _fetchGatePasses();
    _fetchSapInvoices();
    _fetchMasters();
  }

  Future<void> _fetchMasters() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      
      final itemsRes = await remoteApi.getItemsMaster();
      if (itemsRes['success'] == true && itemsRes['items'] != null) {
        setState(() => _masterItems = itemsRes['items'] as List<dynamic>);
      }

      final custRes = await remoteApi.getCustomersMaster();
      if (custRes['success'] == true && custRes['customers'] != null) {
        final custs = custRes['customers'] as List<dynamic>;
        setState(() {
          _masterCustomers = custs;
          if (_masterCustomers.isNotEmpty && _dumpSelectedCustomerCode == null) {
            _dumpSelectedCustomerCode = _masterCustomers.first['customerCode'];
          }
        });
      }

      final transRes = await remoteApi.getTransportersMaster();
      if (transRes['success'] == true && transRes['transporters'] != null) {
        final trans = transRes['transporters'] as List<dynamic>;
        setState(() {
          _masterTransporters = trans;
          if (_masterTransporters.isNotEmpty && _dumpSelectedTransporter == null) {
            _dumpSelectedTransporter = _masterTransporters.first['transporterName'];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchGatePasses() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/dispatch/gate-passes');
    if (res['success'] == true && res['gatePasses'] != null && (res['gatePasses'] as List).isNotEmpty) {
      setState(() {
        _gatePasses = res['gatePasses'] as List<dynamic>;
        _activeGatePass = _gatePasses[0];
        if (_activeGatePass != null) {
          _gatePassNumberController.text = _activeGatePass!['gatePassNumber'] ?? '';
          _dumpSelectedGatePass = _activeGatePass!['gatePassNumber'];
          _securityGatePassQrController.text = _activeGatePass!['gatePassQr'] ?? 'MWG|${_activeGatePass!['gatePassNumber']}';
          _invoiceNumberController.text = _activeGatePass!['sapInvoiceNumber'] ?? 'INV-SAP-${DateTime.now().year}-${_activeGatePass!['gatePassNumber']?.replaceAll('GP', '')}';
          
          final totalWheels = _activeGatePass!['totalWheels'] ?? 192;
          _invoiceQtyController.text = totalWheels.toString();
          
          _pokaYokeStatus = _activeGatePass!['pokaYokeStatus'] ?? 'PENDING_INVOICE';
          _pokaYokeResults = _activeGatePass!['pokaYokeResults'] ?? [];
        }
      });
    }
  }

  Future<void> _fetchSapInvoices() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.getSapInvoices();
    if (res['success'] == true && res['invoices'] != null) {
      setState(() {
        _sapInvoices = res['invoices'] as List<dynamic>;
      });
    }
  }

  // --- Actions ---

  void _onUploadInvoiceAndCheck({bool simulateLoad = false}) async {
    final gpNo = _gatePassNumberController.text.trim();
    final invNo = _invoiceNumberController.text.trim();
    final itemCode = _itemCodeController.text.trim();
    final qty = int.tryParse(_invoiceQtyController.text.trim()) ?? 192;

    List<Map<String, dynamic>> itemsToSend = [];
    if (_dumpLineItems.isNotEmpty) {
      itemsToSend = _dumpLineItems.map((i) => {
        'itemCode': i['itemCode'],
        'quantity': i['quantity'] is int ? i['quantity'] : (int.tryParse(i['quantity'].toString()) ?? 192),
        'unitOfMeasure': 'EA'
      }).toList();
    } else if (itemCode.isNotEmpty) {
      itemsToSend = [
        {'itemCode': itemCode, 'quantity': qty, 'unitOfMeasure': 'EA'}
      ];
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/dispatch/upload-invoice', {
      'gatePassNumber': gpNo,
      'invoiceNumber': invNo,
      'invoiceItems': itemsToSend,
      'simulateLoad': simulateLoad,
    });
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _activeGatePass = res['gatePass'];
        _pokaYokeResults = res['pokaYokeResults'] ?? [];
        _pokaYokeStatus = _activeGatePass?['pokaYokeStatus'] ?? 'PENDING_INVOICE';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: res['allMatch'] == true ? AppColors.ok : AppColors.danger,
          content: Text(res['message'] ?? 'Invoice check complete'),
        ),
      );
      _fetchSapInvoices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Invoice check failed')),
      );
    }
  }

  void _onDumpSapInvoice() async {
    final invNo = _dumpInvoiceNoController.text.trim().isNotEmpty
        ? _dumpInvoiceNoController.text.trim()
        : 'INV-SAP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    final selectedCust = _masterCustomers.firstWhere(
      (c) => c['customerCode'] == _dumpSelectedCustomerCode,
      orElse: () => {'customerName': 'Tata Motors Pune'},
    );

    setState(() => _isDumping = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.dumpSapInvoice({
      'invoiceNumber': invNo,
      'invoiceDate': _dumpInvoiceDateController.text.trim(),
      'customerCode': _dumpSelectedCustomerCode,
      'customerName': selectedCust['customerName'],
      'vehicleNumber': _dumpVehicleNoController.text.trim(),
      'transporterName': _dumpSelectedTransporter,
      'gatePassNumber': _dumpSelectedGatePass,
      'billingPlant': _dumpBillingPlantController.text.trim(),
      'items': _dumpLineItems,
    });
    setState(() => _isDumping = false);

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'SAP Invoice dumped successfully into database!'),
        ),
      );
      _dumpInvoiceNoController.clear();
      _fetchSapInvoices();
      _fetchGatePasses();
      setState(() => _selectedTabIndex = 2); // Switch to Vault tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Failed to dump SAP Invoice')),
      );
    }
  }

  void _onUploadExcelFile() {
    final remoteApi = ref.read(remoteApiProvider);
    pickAndParseSapExcelFile(
      context: context,
      remoteApi: remoteApi,
      onParsed: (items, invNo, custName, vehNo) {
        setState(() {
          _dumpLineItems = items;
          if (invNo != null && invNo.isNotEmpty) {
            _dumpInvoiceNoController.text = invNo;
            _invoiceNumberController.text = invNo;
          }
          if (vehNo != null && vehNo.isNotEmpty) {
            _dumpVehicleNoController.text = vehNo;
          }
          if (items.isNotEmpty) {
            _itemCodeController.text = items.first['itemCode']?.toString() ?? '';
            final sumQty = items.fold<int>(0, (sum, i) => sum + (int.tryParse(i['quantity'].toString()) ?? 0));
            _invoiceQtyController.text = sumQty > 0 ? sumQty.toString() : (items.first['quantity']?.toString() ?? '192');
          }

          // Register any new items dynamically into master list
          for (var it in items) {
            final c = it['itemCode']?.toString() ?? '';
            if (c.isNotEmpty && !_masterItems.any((m) => m['itemCode'] == c)) {
              _masterItems.add({
                'itemCode': c,
                'description': it['description'] ?? 'Automotive Wheel Assembly',
                'standardPalletQty': it['quantity'] ?? 96,
              });
            }
          }

          // Register any new customer dynamically into master customers
          if (custName != null && custName.isNotEmpty) {
            final exists = _masterCustomers.any((c) => 
              c['customerCode'] == custName || 
              c['customerName'].toString().toLowerCase().contains(custName.toLowerCase()) ||
              custName.toLowerCase().contains(c['customerName'].toString().toLowerCase())
            );
            if (!exists) {
              final newCode = 'CUST-${custName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}';
              _masterCustomers.add({
                'customerCode': newCode,
                'customerName': custName,
                'city': 'Plant Site',
              });
            }
            final match = _masterCustomers.firstWhere(
              (c) => 
                c['customerCode'] == custName || 
                c['customerName'].toString().toLowerCase().contains(custName.toLowerCase()) ||
                custName.toLowerCase().contains(c['customerName'].toString().toLowerCase()),
              orElse: () => _masterCustomers.first,
            );
            _dumpSelectedCustomerCode = match['customerCode'];
          }
        });
      },
    );
  }

  void _onParseRawSapDump() {
    final raw = _dumpRawTextController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste raw SAP invoice text or CSV first'), backgroundColor: AppColors.warn),
      );
      return;
    }

    try {
      if (raw.startsWith('[') || raw.startsWith('{')) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final items = decoded.map((i) => Map<String, dynamic>.from(i)).toList();
          setState(() => _dumpLineItems = items);
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['items'] is List) {
            setState(() => _dumpLineItems = (decoded['items'] as List).map((i) => Map<String, dynamic>.from(i)).toList());
          }
          if (decoded['invoiceNumber'] != null) _dumpInvoiceNoController.text = decoded['invoiceNumber'].toString();
          if (decoded['vehicleNumber'] != null) _dumpVehicleNoController.text = decoded['vehicleNumber'].toString();
        }
      } else {
        final lines = raw.split('\n');
        final List<Map<String, dynamic>> parsedItems = [];
        for (var line in lines) {
          final parts = line.split(RegExp(r'[,;\t]')).map((s) => s.trim()).toList();
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            parsedItems.add({
              'itemCode': parts[0],
              'quantity': parts.length > 1 ? (int.tryParse(parts[1]) ?? 192) : 192,
              'unitPrice': parts.length > 2 ? (double.tryParse(parts[2]) ?? 950.0) : 950.0,
              'description': parts.length > 3 ? parts[3] : 'Automotive Wheel Assembly',
              'unitOfMeasure': 'EA',
              'hsnCode': '87087000',
            });
          }
        }
        if (parsedItems.isNotEmpty) {
          setState(() => _dumpLineItems = parsedItems);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.ok, content: Text('Parsed ${_dumpLineItems.length} line items from SAP dump!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('Error parsing SAP dump: $e')),
      );
    }
  }

  void _onOverrideMismatch() async {
    final gpNo = _gatePassNumberController.text.trim();
    final authorizer = _overrideAuthorizerController.text.trim();
    final reason = _overrideReasonController.text.trim();

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/dispatch/override-mismatch', {
      'gatePassNumber': gpNo,
      'authorizedBy': authorizer,
      'reason': reason,
    });
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _activeGatePass = res['gatePass'];
        _pokaYokeStatus = 'OVERRIDDEN';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warn,
          content: Text(res['message'] ?? 'Mismatch overridden by Manager'),
        ),
      );
    }
  }

  void _onVerifyGateOut(String action) async {
    final gpQr = _securityGatePassQrController.text.trim();
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/dispatch/verify-gate-out', {
      'gatePassNumber': gpQr,
      'action': action,
      'holdReason': 'Security Gate Inspection Discrepancy'
    });

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: action == 'RELEASE' ? AppColors.ok : AppColors.danger,
          content: Text(res['message'] ?? 'Gate Out processed'),
        ),
      );
      _fetchGatePasses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Gate Out blocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isSecurity = user?.role == UserRole.security;

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: isSecurity
                ? 'Module 10 — Security Gate Pass Verification & Gate Out'
                : 'Module 8 & 10 — Vehicle Loading, Gate Pass & SAP Invoice Management',
          ),
          const SizedBox(height: 8),
          Text(
            isSecurity
                ? 'Verify driver Gate Pass, cross-check paper invoice match, print Gate Pass document (PDF/ZPL), and release or hold vehicle.'
                : 'Upload SAP Invoices via Excel (.xlsx / .csv) or RFC -> Automated line-by-line Poka-Yoke check against physical loaded pallets -> Post & release Gate Pass.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // RESPONSIVE SEGMENTED BUTTONS / TABS (FOR WAREHOUSE MANAGER / ADMIN)
          if (!isSecurity) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.bgSurfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Tab',
                    color: _selectedTabIndex > 0 ? AppColors.ribbonPink : context.textMuted.withValues(alpha: 0.3),
                    onPressed: _selectedTabIndex > 0 ? () => setState(() => _selectedTabIndex--) : null,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabButton(0, Icons.verified_user_outlined, 'POKA-YOKE & GATE PASS'),
                          const SizedBox(width: 8),
                          _buildTabButton(1, Icons.cloud_upload_outlined, 'DUMP SAP INVOICE (EXCEL/RFC)'),
                          const SizedBox(width: 8),
                          _buildTabButton(2, Icons.receipt_long_outlined, 'SAP INVOICES DATABASE VAULT (${_sapInvoices.length})'),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Tab',
                    color: _selectedTabIndex < 2 ? AppColors.ribbonPink : context.textMuted.withValues(alpha: 0.3),
                    onPressed: _selectedTabIndex < 2 ? () => setState(() => _selectedTabIndex++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ACTIVE TAB CONTENT
          if (isSecurity || _selectedTabIndex == 0) _buildPokaYokeAndPassTab(context),
          if (!isSecurity && _selectedTabIndex == 1) _buildDumpInvoiceTab(context),
          if (!isSecurity && _selectedTabIndex == 2) _buildInvoicesVaultTab(context),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ribbonPink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : context.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: POKA YOKE & GATE PASS ---
  Widget _buildPokaYokeAndPassTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POKA-YOKE INVOICE CHECK TERMINAL
        AppCard(
          child: LayoutBuilder(
            builder: (context, cardConstraints) {
              final isNarrow = cardConstraints.maxWidth < 600;

              final gpField = TextField(
                controller: _gatePassNumberController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Gate Pass Number',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              final invField = TextField(
                controller: _invoiceNumberController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'SAP Invoice Number',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              final itemField = TextField(
                controller: _itemCodeController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Invoice Item Code',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              final qtyField = TextField(
                controller: _invoiceQtyController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Invoice Quantity (Wheels)',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'SECTION 10 — SAP INVOICE CROSS-CHECK TERMINAL',
                        style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          AppButton(
                            text: 'UPLOAD COMPANY EXCEL (.XLSX)',
                            icon: Icons.upload_file,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onUploadExcelFile,
                          ),
                          StatusPill(
                            label: _pokaYokeStatus == 'PASSED'
                                ? 'POKA-YOKE PASSED'
                                : _pokaYokeStatus == 'FAILED_MISMATCH'
                                    ? 'POKA-YOKE BLOCKED'
                                    : _pokaYokeStatus == 'OVERRIDDEN'
                                        ? 'OVERRIDDEN BY HEAD'
                                        : 'PENDING INVOICE',
                            variant: _pokaYokeStatus == 'PASSED'
                                ? PillVariant.ok
                                : _pokaYokeStatus == 'FAILED_MISMATCH'
                                    ? PillVariant.danger
                                    : _pokaYokeStatus == 'OVERRIDDEN'
                                        ? PillVariant.warn
                                        : PillVariant.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isNarrow) ...[
                    gpField,
                    const SizedBox(height: 12),
                    invField,
                    const SizedBox(height: 12),
                    itemField,
                    const SizedBox(height: 12),
                    qtyField,
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: gpField),
                        const SizedBox(width: 16),
                        Expanded(child: invField),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: itemField),
                        const SizedBox(width: 16),
                        Expanded(child: qtyField),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (isNarrow) ...[
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: _isLoading ? 'RUNNING CHECK...' : 'RUN BACKGROUND POKA-YOKE CHECK',
                        variant: AppButtonVariant.gradient,
                        isLoading: _isLoading,
                        onPressed: () => _onUploadInvoiceAndCheck(simulateLoad: false),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'AUTO-LOAD EXCEL ITEMS (FOR TESTING)',
                        icon: Icons.science_outlined,
                        variant: AppButtonVariant.ghost,
                        isLoading: _isLoading,
                        onPressed: () => _onUploadInvoiceAndCheck(simulateLoad: true),
                      ),
                    ),
                    if (_pokaYokeStatus == 'FAILED_MISMATCH') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: 'DISPATCH HEAD OVERRIDE',
                          variant: AppButtonVariant.danger,
                          onPressed: () => _showOverrideDialog(context),
                        ),
                      ),
                    ],
                  ] else ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        AppButton(
                          text: _isLoading ? 'RUNNING CHECK...' : 'RUN BACKGROUND POKA-YOKE CHECK',
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: () => _onUploadInvoiceAndCheck(simulateLoad: false),
                        ),
                        AppButton(
                          text: 'AUTO-LOAD EXCEL ITEMS (FOR TESTING)',
                          icon: Icons.science_outlined,
                          variant: AppButtonVariant.ghost,
                          isLoading: _isLoading,
                          onPressed: () => _onUploadInvoiceAndCheck(simulateLoad: true),
                        ),
                        if (_pokaYokeStatus == 'FAILED_MISMATCH')
                          AppButton(
                            text: 'DISPATCH HEAD OVERRIDE',
                            variant: AppButtonVariant.danger,
                            onPressed: () => _showOverrideDialog(context),
                          ),
                      ],
                    ),
                  ],
                  if (_pokaYokeResults.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 12),
                    Text('LINE-BY-LINE LOAD VS INVOICE COMPARISON:', style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ITEM CODE')),
                          DataColumn(label: Text('INVOICE QTY')),
                          DataColumn(label: Text('LOADED QTY')),
                          DataColumn(label: Text('DIFFERENCE')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: _pokaYokeResults.map((r) {
                          final isMatch = r['status'] == 'MATCH';
                          return DataRow(cells: [
                            DataCell(Text(r['itemCode'] ?? '')),
                            DataCell(Text('${r['invoiceQty']}')),
                            DataCell(Text('${r['loadedQty']}')),
                            DataCell(Text('${r['difference'] > 0 ? "+${r['difference']}" : r['difference']}')),
                            DataCell(
                              StatusPill(
                                label: r['status'] ?? '',
                                variant: isMatch ? PillVariant.ok : PillVariant.danger,
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // PRINTABLE GATE PASS & SECURITY TERMINAL ROW
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            Widget passCard = AppCard(
              showGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAXION WHEELS DISPATCH GATE PASS',
                              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'GATE PASS NO: ${_activeGatePass?['gatePassNumber'] ?? "GP26000208"}',
                              style: TextStyle(color: context.brandInk, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            if (_activeGatePass?['sapInvoiceNumber'] != null)
                              Text(
                                'SAP INVOICE NO: ${_activeGatePass!['sapInvoiceNumber']}',
                                style: TextStyle(color: context.okInk, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      QrImageView(
                        data: _activeGatePass?['gatePassQr'] ?? 'MWG|GP26000208',
                        version: QrVersions.auto,
                        size: 72.0,
                        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: qrColor),
                        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: qrColor),
                      ),
                    ],
                  ),
                  Divider(height: 32, color: Theme.of(context).dividerColor),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _buildField('Customer', _activeGatePass?['customerName'] ?? 'Tata Motors Pune'),
                      _buildField('Vehicle No', _activeGatePass?['vehicleNumber'] ?? 'MH 12 QW 8890'),
                      _buildField('Transporter', _activeGatePass?['transporterName'] ?? 'Vistar Logistics Express'),
                      _buildField('Driver Name', _activeGatePass?['driverName'] ?? 'Rajesh Kumar'),
                      _buildField('Driver Licence', _activeGatePass?['driverLicence'] ?? 'DL-99201928'),
                      _buildField('Driver Phone', _activeGatePass?['driverPhone'] ?? '+91 98765 43210'),
                      _buildField('Seal Number', _activeGatePass?['sealNumber'] ?? 'SEAL-9921'),
                      _buildField('Total Pallets', '${_activeGatePass?['totalPallets'] ?? 2}'),
                      _buildField('Total Wheels', '${_activeGatePass?['totalWheels'] ?? 192} (${_activeGatePass?['totalWeightKg'] ?? 1824} kg)'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'PRINT GATE PASS (PDF/ZPL)',
                        icon: Icons.print_outlined,
                        variant: AppButtonVariant.gradient,
                        onPressed: () {
                          final gpNo = _activeGatePass?['gatePassNumber'] ?? "GP26000208";
                          final invNo = _activeGatePass?['sapInvoiceNumber'] ?? "INV-SAP-2026-9921";
                          PrintPreviewDialog.show(
                            context: context,
                            title: 'DISPATCH GATE PASS #$gpNo',
                            documentType: PrintDocumentType.gatePassA4,
                            qrData: _activeGatePass?['gatePassQr'] ?? 'MWG|GP26000208',
                            codeText: 'MWG|$gpNo',
                            itemCode: 'SAP INVOICE: $invNo',
                            itemDescription: 'Official Maxion Wheels Dispatch Gate Pass Document',
                            primaryDetail: 'Customer: ${_activeGatePass?['customerName'] ?? "Tata Motors Pune"}',
                            secondaryDetail: 'Vehicle: ${_activeGatePass?['vehicleNumber'] ?? "MH 12 QW 8890"} • Transporter: ${_activeGatePass?['transporterName'] ?? "Vistar Logistics"}',
                            metadataFields: [
                              {'GATE PASS #': gpNo},
                              {'SAP INVOICE #': invNo},
                              {'DRIVER': _activeGatePass?['driverName'] ?? 'Rajesh Kumar'},
                              {'SEAL #': _activeGatePass?['sealNumber'] ?? 'SEAL-9921'},
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );

            Widget securityCard = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY GATE OUT TERMINAL (SEC 10.5)',
                    style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Security Guard scans Gate Pass QR at plant exit, verifies paper invoice in driver hand vs screen invoice number:',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _securityGatePassQrController,
                    decoration: const InputDecoration(
                      labelText: 'GATE PASS QR (MWG|...)',
                      prefixIcon: Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'RELEASE VEHICLE',
                          icon: Icons.check_circle,
                          variant: AppButtonVariant.gradient,
                          onPressed: () => _onVerifyGateOut('RELEASE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'RAISE HOLD',
                          icon: Icons.block,
                          variant: AppButtonVariant.danger,
                          onPressed: () => _onVerifyGateOut('HOLD'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: passCard),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: securityCard),
                ],
              );
            }

            return Column(
              children: [
                passCard,
                const SizedBox(height: 24),
                securityCard,
              ],
            );
          },
        ),
      ],
    );
  }

  // --- TAB 2: DUMP SAP INVOICE ---
  Widget _buildDumpInvoiceTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DUMP SAP INVOICE INTO DATABASE',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload SAP billing documents from Excel file (.xlsx / .csv) or manual entry into Dispatch store.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                    Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      AppButton(
                        icon: Icons.upload_file,
                        text: 'UPLOAD SAP EXCEL FILE (.XLSX / .CSV)',
                        variant: AppButtonVariant.gradient,
                        onPressed: _onUploadExcelFile,
                      ),
                      AppButton(
                        icon: Icons.auto_fix_high,
                        text: 'PASTE RAW TEXT',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => _showRawDumpDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),

              // INVOICE HEADER FORM
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _dumpInvoiceNoController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'SAP INVOICE NUMBER',
                        hintText: 'e.g. INV-SAP-2026-9922',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _dumpInvoiceDateController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'INVOICE DATE',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: _dumpSelectedCustomerCode,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'CUSTOMER (SOLD-TO)',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _masterCustomers.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['customerCode']?.toString(),
                          child: Text('${c['customerName']} (${c['customerCode']})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _dumpSelectedCustomerCode = val),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _dumpVehicleNoController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'VEHICLE NUMBER',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: _dumpSelectedTransporter,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'TRANSPORTER / CARRIER',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _masterTransporters.map((t) {
                        return DropdownMenuItem<String>(
                          value: t['transporterName']?.toString(),
                          child: Text(t['transporterName']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _dumpSelectedTransporter = val),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      value: _dumpSelectedGatePass,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'LINK TO GATE PASS',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _gatePasses.map((gp) {
                        return DropdownMenuItem<String>(
                          value: gp['gatePassNumber']?.toString(),
                          child: Text('${gp['gatePassNumber']} (${gp['customerName']})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _dumpSelectedGatePass = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // LINE ITEMS SECTION
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text('SAP INVOICE LINE ITEMS:', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                  TextButton.icon(
                    icon: Icon(Icons.add, color: context.okInk),
                    label: Text('Add Item Row', style: TextStyle(color: context.okInk)),
                    onPressed: () {
                      setState(() {
                        _dumpLineItems.add({
                          'itemCode': _masterItems.isNotEmpty ? _masterItems.first['itemCode'] : 'MXW-17-BLK',
                          'description': 'Wheel Assembly',
                          'quantity': 192,
                          'unitOfMeasure': 'EA',
                          'unitPrice': 950.0,
                        });
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // HIGH PERFORMANCE PAGINATED LINE ITEMS TABLE
              () {
                final totalItems = _dumpLineItems.length;
                final totalPages = (totalItems / _dumpPageSize).ceil();
                final safePage = _dumpCurrentPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
                final startIdx = safePage * _dumpPageSize;
                final endIdx = (startIdx + _dumpPageSize).clamp(0, totalItems);
                final visibleSlice = totalItems > 0 ? _dumpLineItems.sublist(startIdx, endIdx) : <Map<String, dynamic>>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ITEM CODE')),
                          DataColumn(label: Text('DESCRIPTION')),
                          DataColumn(label: Text('QTY (WHEELS)')),
                          DataColumn(label: Text('UNIT PRICE (₹)')),
                          DataColumn(label: Text('LINE TOTAL (₹)')),
                          DataColumn(label: Text('ACTION')),
                        ],
                        rows: visibleSlice.asMap().entries.map((entry) {
                          final sliceIdx = entry.key;
                          final actualIdx = startIdx + sliceIdx;
                          final item = entry.value;
                          final num qty = item['quantity'] is num ? item['quantity'] : (int.tryParse(item['quantity']?.toString() ?? '0') ?? 0);
                          final num price = item['unitPrice'] is num ? item['unitPrice'] : (double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0);
                          final total = (qty * price).toStringAsFixed(2);

                          return DataRow(cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.ribbonPink.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.ribbonPink.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  item['itemCode']?.toString() ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: context.brandInk, fontSize: 13),
                                ),
                              ),
                            ),
                            DataCell(Text(item['description']?.toString() ?? '')),
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  key: ValueKey('qty_${item['itemCode']}_$actualIdx'),
                                  initialValue: item['quantity']?.toString() ?? '192',
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  onChanged: (val) {
                                    _dumpLineItems[actualIdx]['quantity'] = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  key: ValueKey('price_${item['itemCode']}_$actualIdx'),
                                  initialValue: item['unitPrice']?.toString() ?? '950.0',
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  onChanged: (val) {
                                    _dumpLineItems[actualIdx]['unitPrice'] = double.tryParse(val) ?? 0.0;
                                  },
                                ),
                              ),
                            ),
                            DataCell(Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: context.dangerInk),
                                onPressed: () {
                                  if (_dumpLineItems.length > 1) {
                                    setState(() => _dumpLineItems.removeAt(actualIdx));
                                  }
                                },
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                    if (totalItems > _dumpPageSize) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${startIdx + 1}–$endIdx of $totalItems items',
                            style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                tooltip: 'Previous 20 items',
                                onPressed: safePage > 0
                                    ? () => setState(() => _dumpCurrentPage = safePage - 1)
                                    : null,
                              ),
                              Text(
                                'Page ${safePage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                                style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: 'Next 20 items',
                                onPressed: safePage < totalPages - 1
                                    ? () => setState(() => _dumpCurrentPage = safePage + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }(),
              const SizedBox(height: 24),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),

              // COMMIT BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: _isDumping ? 'DUMPING TO DATABASE...' : 'DUMP SAP INVOICE TO SYSTEM',
                    icon: Icons.save_alt,
                    variant: AppButtonVariant.gradient,
                    isLoading: _isDumping,
                    onPressed: _onDumpSapInvoice,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: SAP INVOICES DATABASE VAULT ---
  Widget _buildInvoicesVaultTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAP INVOICES DATABASE VAULT',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live record of all SAP Invoices dumped into the system store with line item breakdown.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.ribbonPink),
                    onPressed: _fetchSapInvoices,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),

              if (_sapInvoices.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No SAP Invoices dumped yet. Use the Dump tab to upload Excel files.')),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sapInvoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final inv = _sapInvoices[idx];
                    final invNo = inv['invoiceNumber'] ?? 'N/A';
                    final cust = inv['customerName'] ?? 'Tata Motors Pune';
                    final vehicle = inv['vehicleNumber'] ?? 'MH 12 QW 8890';
                    final gp = inv['gatePassNumber'] ?? 'Not Linked';
                    final totalWheels = inv['totalWheels'] ?? 192;
                    final amount = inv['totalAmount'] ?? 182400.0;
                    final status = (inv['status'] ?? 'DUMPED').toString();
                    final items = (inv['items'] as List<dynamic>?) ?? [];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt, color: AppColors.ribbonPink, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        invNo,
                                        style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusPill(
                                label: status,
                                variant: status.contains('MATCH') || status == 'PASSED'
                                    ? PillVariant.ok
                                    : status.contains('FAIL')
                                        ? PillVariant.danger
                                        : PillVariant.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _buildField('Customer', cust),
                              _buildField('Vehicle', vehicle),
                              _buildField('Linked Gate Pass', gp),
                              _buildField('Total Quantity', '$totalWheels Wheels'),
                              _buildField('Invoice Value', '₹$amount'),
                              _buildField('Dumped At', inv['dumpedAt'] != null ? inv['dumpedAt'].toString().substring(0, 10) : 'N/A'),
                            ],
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text('LINE ITEMS:', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: items.map((it) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${it['itemCode']} • Qty: ${it['quantity']} EA • ₹${it['unitPrice']}',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER DIALOGS ---

  void _showRawDumpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('PASTE RAW SAP INVOICE DUMP / CSV', style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste CSV or JSON payload (Format: ItemCode, Quantity, UnitPrice, Description):',
              style: TextStyle(color: ctx.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dumpRawTextController,
              maxLines: 6,
              style: TextStyle(color: ctx.textPrimary, fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'MXW-17-BLK, 192, 950.0, 17 Inch Steel Wheel\nMXW-18-SLV, 96, 1250.0, 18 Inch Alloy Wheel',
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          AppButton(
            text: 'PARSE & FILL TABLE',
            variant: AppButtonVariant.gradient,
            onPressed: () {
              Navigator.pop(ctx);
              _onParseRawSapDump();
            },
          ),
        ],
      ),
    );
  }

  void _showOverrideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('DISPATCH HEAD OVERRIDE', style: TextStyle(color: context.dangerInk, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Authorization required to override SAP Invoice mismatch and release gate pass:'),
            const SizedBox(height: 16),
            TextField(
              controller: _overrideAuthorizerController,
              decoration: const InputDecoration(labelText: 'Authorized By (Dispatch / Plant Head)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _overrideReasonController,
              decoration: const InputDecoration(labelText: 'Reason for Override'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          AppButton(
            text: 'CONFIRM OVERRIDE',
            variant: AppButtonVariant.danger,
            onPressed: () {
              Navigator.pop(ctx);
              _onOverrideMismatch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String val) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
