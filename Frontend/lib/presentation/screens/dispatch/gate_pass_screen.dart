import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
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

class _GatePassScreenState extends ConsumerState<GatePassScreen> {
  final _gatePassNumberController = TextEditingController(text: 'GP26000208');
  final _invoiceNumberController = TextEditingController(text: 'INV-SAP-2026-9921');
  final _itemCodeController = TextEditingController(text: 'MXW-17-BLK');
  final _invoiceQtyController = TextEditingController(text: '192');
  final _overrideAuthorizerController = TextEditingController(text: 'Dispatch Head');
  final _overrideReasonController = TextEditingController(text: 'Approved deviation per customer schedule change');

  final _securityGatePassQrController = TextEditingController(text: 'MWG|GP26000208');

  bool _isLoading = false;
  Map<String, dynamic>? _activeGatePass;
  List<dynamic> _pokaYokeResults = [];
  String _pokaYokeStatus = 'PENDING_INVOICE'; // PENDING_INVOICE, PASSED, FAILED_MISMATCH, OVERRIDDEN

  @override
  void initState() {
    super.initState();
    _fetchGatePasses();
  }

  void _fetchGatePasses() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/dispatch/gate-passes');
    if (res['success'] == true && res['gatePasses'] != null && (res['gatePasses'] as List).isNotEmpty) {
      setState(() {
        _activeGatePass = res['gatePasses'][0];
        if (_activeGatePass != null) {
          _pokaYokeStatus = _activeGatePass!['pokaYokeStatus'] ?? 'PENDING_INVOICE';
          _pokaYokeResults = _activeGatePass!['pokaYokeResults'] ?? [];
        }
      });
    }
  }

  void _onUploadInvoiceAndCheck() async {
    final gpNo = _gatePassNumberController.text.trim();
    final invNo = _invoiceNumberController.text.trim();
    final itemCode = _itemCodeController.text.trim();
    final qty = int.tryParse(_invoiceQtyController.text.trim()) ?? 192;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/dispatch/upload-invoice', {
      'gatePassNumber': gpNo,
      'invoiceNumber': invNo,
      'invoiceItems': [
        {'itemCode': itemCode, 'quantity': qty, 'unitOfMeasure': 'EA'}
      ]
    });
    setState(() => _isLoading = false);

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Invoice check failed')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrColor = isDark ? Colors.white : Colors.black;

    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 8 & 10 — Vehicle Loading, Gate Pass & SAP Invoice Poka-Yoke'),
          const SizedBox(height: 8),
          Text(
            'Section 10: Upload SAP invoice file at vehicle release -> background line-by-line cross-check against loaded pallets/SPD packs -> post & release gate pass if tallies, or block posting if mismatch. Override by Dispatch/Plant Head only.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // POKA-YOKE INVOICE CHECK TERMINAL
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SECTION 10 — SAP INVOICE UPLOAD & POKA-YOKE CROSS-CHECK',
                      style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gatePassNumberController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Gate Pass Number',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _invoiceNumberController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'SAP Invoice Number',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemCodeController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Invoice Item Code',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _invoiceQtyController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Invoice Quantity (Wheels)',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: _isLoading ? 'RUNNING CHECK...' : 'UPLOAD SAP DUMP & RUN BACKGROUND POKA-YOKE CHECK',
                        variant: AppButtonVariant.gradient,
                        isLoading: _isLoading,
                        onPressed: _onUploadInvoiceAndCheck,
                      ),
                    ),
                    if (_pokaYokeStatus == 'FAILED_MISMATCH') ...[
                      const SizedBox(width: 16),
                      AppButton(
                        text: 'DISPATCH HEAD OVERRIDE',
                        variant: AppButtonVariant.danger,
                        onPressed: () => _showOverrideDialog(context),
                      ),
                    ],
                  ],
                ),

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
            ),
          ),
          const SizedBox(height: 24),
          // PRINTABLE GATE PASS & SECURITY TERMINAL ROW (RESPONSIVE)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAXION WHEELS DISPATCH GATE PASS',
                              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'GATE PASS NO: ${_activeGatePass?['gatePassNumber'] ?? "GP26000208"}',
                              style: const TextStyle(color: AppColors.ribbonPink, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            if (_activeGatePass?['sapInvoiceNumber'] != null)
                              Text(
                                'SAP INVOICE NO: ${_activeGatePass!['sapInvoiceNumber']}',
                                style: const TextStyle(color: AppColors.ok, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
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
      ),
    );
  }

  void _showOverrideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('DISPATCH HEAD OVERRIDE', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
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
