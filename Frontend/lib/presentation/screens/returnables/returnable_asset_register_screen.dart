import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class ReturnableAssetRegisterScreen extends ConsumerStatefulWidget {
  const ReturnableAssetRegisterScreen({super.key});

  @override
  ConsumerState<ReturnableAssetRegisterScreen> createState() => _ReturnableAssetRegisterScreenState();
}

class _ReturnableAssetRegisterScreenState extends ConsumerState<ReturnableAssetRegisterScreen> {
  final _assetQrController = TextEditingController(text: 'RTN-TATA-PLT-0041');
  final _customerController = TextEditingController(text: 'Tata Motors Pune');
  String _condition = 'Good';

  List<dynamic>? _assets = [];
  List<dynamic> get assets => _assets ?? [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/returnables/assets');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _assets = (res['assets'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onReceiveAsset() async {
    final assetQr = _assetQrController.text.trim();
    final customer = _customerController.text.trim();
    if (assetQr.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/returnables/receive', {
      'assetNumber': assetQr,
      'customerName': customer,
      'condition': _condition,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Returnable asset logged & balance updated!'),
        ),
      );
      _fetchAssets();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Receipt failed')),
      );
    }
  }

  void _onExportStatement() {
    exportToExcel(
      context,
      'Customer Returnables Outstanding Statement',
      ['ASSET #', 'ASSET TYPE', 'CONDITION', 'STATUS', 'CUSTOMER', 'AGEING (DAYS)'],
      assets.map<List<String>>((a) => [
        '${a['assetNumber']}',
        '${a['type']}',
        '${a['condition']}',
        '${a['status']}',
        '${a['customerName'] ?? "In Stock"}',
        '${a['ageingDays'] ?? 0} days',
      ]).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 9 — Returnable Asset Register (Trolleys/Pallets) (SSR Section 6)'),
          const SizedBox(height: 8),
          Text(
            'Track customer returnable packaging assets (metal trolleys, plastic dunnage, special pallets). Scans barcode upon vehicle entry, logs condition, updates customer balance.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Log Returnable Receipt Form
              Expanded(
                flex: 5,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOG RETURNABLE PACKAGING RECEIPT',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _assetQrController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Returnable Asset Barcode / QR',
                          prefixIcon: const Icon(Icons.inventory, color: AppColors.ribbonPink),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customerController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Returning Customer / Vendor',
                          prefixIcon: const Icon(Icons.business_outlined, color: AppColors.ribbonPink),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _condition,
                        dropdownColor: context.bgSurfaceElevated,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Asset Condition Upon Gate Entry',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Good', child: Text('Good (Ready for Immediate Reuse)')),
                          DropdownMenuItem(value: 'Damaged (Minor)', child: Text('Damaged (Minor Repair Needed)')),
                          DropdownMenuItem(value: 'Damaged (Major)', child: Text('Damaged (Scrap / Supplier Claim)')),
                        ],
                        onChanged: (val) => setState(() => _condition = val!),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'LOG RECEIPT & CREDIT CUSTOMER BALANCE',
                              variant: AppButtonVariant.gradient,
                              isLoading: _isLoading,
                              onPressed: _onReceiveAsset,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            text: 'PRINT RECEIPT SLIP',
                            icon: Icons.print_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: () {
                              final qr = _assetQrController.text.trim();
                              PrintPreviewDialog.show(
                                context: context,
                                title: 'RETURNABLE ASSET RECEIPT SLIP PREVIEW',
                                documentType: PrintDocumentType.palletMaster,
                                qrData: 'RTN|$qr',
                                codeText: 'RTN|$qr',
                                itemCode: qr,
                                itemDescription: 'Customer Returnable Metal Trolley / DUNNAGE',
                                primaryDetail: 'Customer: ${_customerController.text}',
                                secondaryDetail: 'Condition: $_condition',
                                metadataFields: [
                                  {'ASSET #': qr},
                                  {'CONDITION': _condition},
                                  {'RECEIVED BY': 'Gate Security'},
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right: Returnables Balance & Outstanding Register Table
              Expanded(
                flex: 7,
                child: AppCard(
                  showGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CUSTOMER RETURNABLES OUTSTANDING REGISTER',
                            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          AppButton(
                            text: 'EXPORT STATEMENT EXCEL',
                            icon: Icons.table_chart_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onExportStatement,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ASSET #')),
                                  DataColumn(label: Text('TYPE')),
                                  DataColumn(label: Text('CONDITION')),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('CUSTOMER')),
                                  DataColumn(label: Text('AGEING')),
                                ],
                                rows: assets.map((a) {
                                  final isOverdue = (a['ageingDays'] ?? 0) > 30;
                                  return DataRow(cells: [
                                    DataCell(Text(a['assetNumber'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                                    DataCell(Text(a['type'] ?? '')),
                                    DataCell(Text(a['condition'] ?? 'Good')),
                                    DataCell(Text(a['status'] ?? 'In Stock', style: TextStyle(color: a['status'] == 'With Customer' ? AppColors.warn : AppColors.ok, fontWeight: FontWeight.w700))),
                                    DataCell(Text(a['customerName'] ?? 'In Stock (Plant)')),
                                    DataCell(Text('${a['ageingDays'] ?? 0} days', style: TextStyle(color: isOverdue ? AppColors.danger : AppColors.textSecondary))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
