import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class ReturnableAssetRegisterScreen extends StatefulWidget {
  const ReturnableAssetRegisterScreen({super.key});

  @override
  State<ReturnableAssetRegisterScreen> createState() => _ReturnableAssetRegisterScreenState();
}

class _ReturnableAssetRegisterScreenState extends State<ReturnableAssetRegisterScreen> {
  final _assetQrController = TextEditingController();
  final _customerController = TextEditingController();

  bool _isLoading = false;
  String _condition = 'Good';

  final List<Map<String, dynamic>> _register = [
    {'customer': 'Tata Motors Pune', 'dispatchedQty': 450, 'returnedQty': 320, 'outstandingQty': 130},
    {'customer': 'Mahindra Chakan', 'dispatchedQty': 280, 'returnedQty': 110, 'outstandingQty': 170},
    {'customer': 'Ashok Leyland Hosur', 'dispatchedQty': 600, 'returnedQty': 580, 'outstandingQty': 20},
    {'customer': 'Volvo Eicher Pithampur', 'dispatchedQty': 190, 'returnedQty': 190, 'outstandingQty': 0},
  ];

  @override
  void dispose() {
    _assetQrController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _onReceiveAsset() {
    final assetQr = _assetQrController.text.trim();
    final customer = _customerController.text.trim();

    if (assetQr.isEmpty || customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Asset Barcode and Customer name'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final idx = _register.indexWhere((r) => (r['customer'] as String).toLowerCase().contains(customer.toLowerCase()));
          if (idx != -1) {
            _register[idx]['returnedQty'] = (_register[idx]['returnedQty'] as int) + 1;
            _register[idx]['outstandingQty'] = (_register[idx]['outstandingQty'] as int) - 1;
          } else {
            _register.add({
              'customer': customer,
              'dispatchedQty': 1,
              'returnedQty': 1,
              'outstandingQty': 0,
            });
          }
          _assetQrController.clear();
          _customerController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Returnable Packaging asset received and credited to customer ledger!'), backgroundColor: AppColors.ok),
        );
      }
    });
  }

  void _onExportReturnablesExcel() {
    exportToExcel(
      context,
      'Returnable Asset Register',
      ['CUSTOMER / VENDOR', 'DISPATCHED OUT', 'RETURNED IN', 'OUTSTANDING BALANCE', 'STATUS'],
      _register.map((r) => [
        r['customer'] as String,
        '${r['dispatchedQty']} units',
        '${r['returnedQty']} units',
        '${r['outstandingQty']} units',
        (r['outstandingQty'] as int) > 150 ? 'OVERDUE ALERT' : 'BALANCED',
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

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              final formCard = AppCard(
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'LOG RECEIPT & CREDIT CUSTOMER BALANCE',
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onReceiveAsset,
                        ),
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
              );

              final balanceCard = AppCard(
                showGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CUSTOMER RETURNABLE PACKAGING BALANCE',
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        AppButton(
                          text: 'EXPORT REGISTER EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onExportReturnablesExcel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('CUSTOMER / VENDOR')),
                          DataColumn(label: Text('DISPATCHED OUT')),
                          DataColumn(label: Text('RETURNED IN')),
                          DataColumn(label: Text('OUTSTANDING')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: _register.map((r) {
                          final out = r['dispatchedQty'] as int;
                          final ret = r['returnedQty'] as int;
                          final bal = r['outstandingQty'] as int;
                          final isOverdue = bal > 150;

                          return DataRow(cells: [
                            DataCell(Text(r['customer'] as String, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                            DataCell(Text('$out units')),
                            DataCell(Text('$ret units', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700))),
                            DataCell(Text('$bal units', style: TextStyle(color: isOverdue ? AppColors.danger : AppColors.warn, fontWeight: FontWeight.w800))),
                            DataCell(StatusPill(
                              label: isOverdue ? 'OVERDUE ALERT' : 'BALANCED',
                              variant: isOverdue ? PillVariant.danger : PillVariant.ok,
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: formCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 7, child: balanceCard),
                  ],
                );
              }

              return Column(
                children: [
                  formCard,
                  const SizedBox(height: 24),
                  balanceCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
