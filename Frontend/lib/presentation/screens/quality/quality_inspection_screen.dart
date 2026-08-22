import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class QualityInspectionScreen extends StatefulWidget {
  const QualityInspectionScreen({super.key});

  @override
  State<QualityInspectionScreen> createState() => _QualityInspectionScreenState();
}

class _QualityInspectionScreenState extends State<QualityInspectionScreen> {
  final _palletQrController = TextEditingController();
  final _inspectionRefController = TextEditingController();
  final _removedWheelController = TextEditingController();

  bool _isLoading = false;
  String _palletStatus = 'AVAILABLE';
  String _defectReason = 'Sample Taken (Destructive Test)';

  final List<Map<String, dynamic>> _qaHistory = [
    {'palletNumber': 'P26081101', 'reason': 'Sample Taken (Destructive Test)', 'inspectorName': 'QA Tech 1', 'replacedWheelsCount': 2},
    {'palletNumber': 'P26081102', 'reason': 'Defect Found (Paint Blemish)', 'inspectorName': 'QA Tech 2', 'replacedWheelsCount': 1},
  ];

  @override
  void dispose() {
    _palletQrController.dispose();
    _inspectionRefController.dispose();
    _removedWheelController.dispose();
    super.dispose();
  }

  void _onOpenPalletForInspection() {
    if (_palletQrController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan Pallet Master QR first'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _palletStatus = 'UNDER_QA_INSPECTION';
          _inspectionRefController.text = 'QA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pallet state set to UNDER_QA_INSPECTION and locked from picking/movements.'), backgroundColor: AppColors.warn),
        );
      }
    });
  }

  void _onAddRemovedWheel() {
    if (_removedWheelController.text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed wheel ${_removedWheelController.text} logged under $_defectReason.'), backgroundColor: AppColors.info),
    );
    _removedWheelController.clear();
  }

  void _onSwapWheels() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replacement wheels scanned in from current production batch.'), backgroundColor: AppColors.ok),
    );
  }

  void _onCloseInspection(bool closeAsShort) {
    if (_palletQrController.text.isEmpty) return;

    final palletNum = _palletQrController.text.trim();

    setState(() {
      _palletStatus = 'AVAILABLE';
      _qaHistory.insert(0, {
        'palletNumber': palletNum,
        'reason': _defectReason,
        'inspectorName': 'QA Tech Supervisor',
        'replacedWheelsCount': closeAsShort ? 0 : 2,
      });
      _palletQrController.clear();
      _inspectionRefController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(closeAsShort
            ? 'QA Inspection closed short! Issued new Half Pallet H-Series ID.'
            : 'QA Inspection closed! Pallet re-sealed with Revision Label (R1).'),
        backgroundColor: AppColors.ok,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 11 — Quality Inspection & Wheel Replacement (SSR Section 7)'),
          const SizedBox(height: 8),
          Text(
            'Opening a pallet becomes a recorded transaction: locks pallet (UNDER_QA_INSPECTION), records removed wheel defect reasons (sample/defect/rework/scrap), scans replacement wheels, and re-seals pallet with a revision label (P26000148 / R1) or issues a new Half Pallet (H) if closed short.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              final qaCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP 1 — OPEN PALLET FOR QA INSPECTION',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        StatusPill(
                          label: _palletStatus == 'UNDER_QA_INSPECTION' ? 'LOCKED (UNDER QA)' : 'AVAILABLE',
                          variant: _palletStatus == 'UNDER_QA_INSPECTION' ? PillVariant.warn : PillVariant.ok,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isDesktop ? 220 : double.infinity,
                          child: TextField(
                            controller: _palletQrController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Pallet Master QR (P / H / PM)',
                              prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isDesktop ? 220 : double.infinity,
                          child: TextField(
                            controller: _inspectionRefController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'QA Inspection Ref (QA...)',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: _isLoading ? 'LOCKING...' : 'OPEN PALLET & LOCK FROM PICKING / MOVEMENTS',
                      variant: AppButtonVariant.gradient,
                      isLoading: _isLoading,
                      onPressed: _onOpenPalletForInspection,
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    Text(
                      'STEP 2 & 3 — SCAN OUT REMOVED WHEELS & SCAN IN REPLACEMENTS',
                      style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isDesktop ? 280 : double.infinity,
                          child: TextField(
                            controller: _removedWheelController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Scan wheel QR removed for inspection...',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        AppButton(
                          text: 'ADD WHEEL',
                          variant: AppButtonVariant.secondary,
                          onPressed: _onAddRemovedWheel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _defectReason,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Defect / Removal Reason',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sample Taken (Destructive Test)', child: Text('Sample Taken (Destructive Test)')),
                        DropdownMenuItem(value: 'Defect Found (Paint Blemish)', child: Text('Defect Found (Paint Blemish)')),
                        DropdownMenuItem(value: 'Sent for Rework', child: Text('Sent for Rework')),
                        DropdownMenuItem(value: 'Scrap', child: Text('Scrap')),
                      ],
                      onChanged: (val) => setState(() => _defectReason = val!),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'SWAP WHEELS FROM CURRENT PRODUCTION',
                      variant: AppButtonVariant.gradient,
                      onPressed: _onSwapWheels,
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    Text(
                      'STEP 4 — CLOSE QA INSPECTION & RE-SEAL PALLET',
                      style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'RE-SEAL FULL PALLET (REVISION LABEL R1/R2)',
                          variant: AppButtonVariant.gradient,
                          onPressed: () => _onCloseInspection(false),
                        ),
                        AppButton(
                          text: 'CLOSE SHORT AS HALF PALLET (H)',
                          variant: AppButtonVariant.danger,
                          onPressed: () => _onCloseInspection(true),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final historyCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT QA AUDIT LOG',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        AppButton(
                          text: 'EXPORT QA LOG EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: () {
                            exportToExcel(
                              context,
                              'QA Audit & Inspection Log',
                              ['PALLET #', 'DEFECT REASON', 'WHEELS REPLACED', 'INSPECTOR', 'RE-SEAL RESULT'],
                              _qaHistory.map<List<String>>((h) => [
                                '${h['palletNumber']}',
                                '${h['reason']}',
                                '${h['replacedWheelsCount'] ?? 2} Wheels',
                                '${h['inspectorName']}',
                                'COMPLETED',
                              ]).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_qaHistory.isEmpty)
                      const Padding(padding: EdgeInsets.all(16), child: Text('No QA inspections logged yet.'))
                    else
                      Column(
                        children: _qaHistory.map((h) {
                          return ListTile(
                            leading: const Icon(Icons.verified, color: AppColors.ok),
                            title: Text('Pallet ${h['palletNumber'] ?? ""}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                            subtitle: Text('${h['reason']} • ${h['inspectorName']}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                            trailing: const StatusPill(label: 'COMPLETED', variant: PillVariant.ok),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: qaCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: historyCard),
                  ],
                );
              }

              return Column(
                children: [
                  qaCard,
                  const SizedBox(height: 24),
                  historyCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
