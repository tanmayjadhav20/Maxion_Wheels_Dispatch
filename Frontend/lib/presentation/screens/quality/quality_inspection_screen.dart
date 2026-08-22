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

class QualityInspectionScreen extends ConsumerStatefulWidget {
  const QualityInspectionScreen({super.key});

  @override
  ConsumerState<QualityInspectionScreen> createState() => _QualityInspectionScreenState();
}

class _QualityInspectionScreenState extends ConsumerState<QualityInspectionScreen> {
  final _palletQrController = TextEditingController(text: 'P26000101');
  final _inspectionRefController = TextEditingController(text: 'QA-AUDIT-2026-01');
  final _removedWheelController = TextEditingController();
  final _reasonController = TextEditingController(text: 'IOC-QA Destructive Test & Surface Finish Audit');

  final List<String> _removedWheels = ['MW|P1|8912345-01|000001742|260819|A|PL2'];
  List<dynamic>? _historyList = [];
  List<dynamic> get historyList => _historyList ?? [];
  String _defectReason = 'Defect Found (Paint Blemish)';
  bool _isLoading = false;
  String _palletStatus = 'IDLE';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/qa/inspection-history');
    if (res['success'] == true && res['history'] != null) {
      setState(() {
        _historyList = (res['history'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onOpenPalletForInspection() async {
    final palletNo = _palletQrController.text.trim();
    if (palletNo.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/qa/open-inspection', {
      'palletNumber': palletNo,
      'inspectionRef': _inspectionRefController.text.trim(),
      'reason': _reasonController.text.trim(),
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _palletStatus = 'UNDER_QA_INSPECTION';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warn,
          content: Text(res['message'] ?? 'Pallet locked and Under QA Inspection!'),
        ),
      );
      _fetchHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Open failed')),
      );
    }
  }

  void _onAddRemovedWheel() {
    final qr = _removedWheelController.text.trim();
    if (qr.isNotEmpty && !_removedWheels.contains(qr)) {
      setState(() {
        _removedWheels.add(qr);
        _removedWheelController.clear();
      });
    }
  }

  void _onSwapWheels() async {
    final palletNo = _palletQrController.text.trim();
    if (palletNo.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/qa/inspect-pallet', {
      'palletNumber': palletNo,
      'removedWheelQrs': _removedWheels,
      'reason': _defectReason,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Wheels swapped from current production!'),
        ),
      );
      _fetchHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Swap failed')),
      );
    }
  }

  void _onCloseInspection(bool closeShort) async {
    final palletNo = _palletQrController.text.trim();
    if (palletNo.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/qa/close-inspection', {
      'palletNumber': palletNo,
      'closeShort': closeShort,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final updatedPallet = res['pallet'];
      final String palletNum = updatedPallet?['palletNumber'] ?? palletNo;
      final String revisionMark = updatedPallet?['revisionMark'] ?? 'R1';
      final bool isHalf = updatedPallet?['typeSeries'] == 'H' || closeShort;

      setState(() {
        _palletStatus = 'IDLE';
      });

      _fetchHistory();

      if (!mounted) return;
      PrintPreviewDialog.show(
        context: context,
        title: isHalf ? 'HALF PALLET RE-SEAL LABEL PRINT PREVIEW' : 'QA REVISION PALLET LABEL PRINT PREVIEW',
        documentType: PrintDocumentType.palletMaster,
        qrData: 'MWP|$palletNum',
        codeText: 'MWP|$palletNum',
        itemCode: 'MXW-17-BLK',
        itemDescription: isHalf ? 'Re-sealed Short Pallet (Queued for Top-up)' : 'Re-sealed Full Pallet with Quality Clearance Mark',
        primaryDetail: isHalf ? 'Series: H (Half Pallet)' : 'Revision Mark: $revisionMark (Cleared by QA)',
        secondaryDetail: 'QA Inspector: Standard User',
        metadataFields: [
          {'PALLET #': palletNum},
          {'DEFECT REASON': _defectReason},
          {'DATE': DateTime.now().toIso8601String().split('T')[0]},
          {'STATUS': isHalf ? 'STORED_FOR_TOP_UP' : 'STORED'},
        ],
      );
    }
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: QA Workflow Form
              Expanded(
                flex: 6,
                child: AppCard(
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
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 16),
                          Expanded(
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
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 12),
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
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'RE-SEAL FULL PALLET (REVISION LABEL R1/R2)',
                              variant: AppButtonVariant.gradient,
                              onPressed: () => _onCloseInspection(false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: 'CLOSE SHORT AS HALF PALLET (H)',
                              variant: AppButtonVariant.danger,
                              onPressed: () => _onCloseInspection(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Panel: Recent QA Audit Log & Rules Summary
              Expanded(
                flex: 4,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECTION 7.2 — RULES SUMMARY',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Q-01: Only QA role or Supervisor can open a pallet\n• Q-02: Pallet under inspection is locked from picking/allocation/merging/relocation\n• Q-04: Full pallet returning to original qty keeps number with revision mark (e.g. P26000148 / R1)\n• Q-05: Pallet closing short becomes Half Pallet with a new H number\n• Q-06: Removed wheels move to QA/rework location (WH1-QA-HOLD)',
                        style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 16),
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
                                historyList.map<List<String>>((h) => [
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
                      if (historyList.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text('No QA inspections logged yet.'))
                      else
                        Column(
                          children: historyList.map((h) {
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
