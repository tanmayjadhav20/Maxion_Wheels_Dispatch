import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/camera_scanner_dialog.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class HhtPickingExecutionScreen extends ConsumerStatefulWidget {
  const HhtPickingExecutionScreen({super.key});

  @override
  ConsumerState<HhtPickingExecutionScreen> createState() => _HhtPickingExecutionScreenState();
}

class _HhtPickingExecutionScreenState extends ConsumerState<HhtPickingExecutionScreen> {
  final _locationScanController = TextEditingController();
  final _palletScanController = TextEditingController();
  final _locationFocusNode = FocusNode();
  final _palletFocusNode = FocusNode();

  List<dynamic>? _pickLists = [];
  List<dynamic> get pickLists => _pickLists ?? [];
  bool _isLoading = false;
  int _selectedIndex = 0;
  String? _statusMessage;
  bool _isSuccessMessage = true;
  bool _showAllPicks = false;

  @override
  void initState() {
    super.initState();
    _fetchMyPickLists();
  }

  @override
  void dispose() {
    try {
      _locationScanController.dispose();
      _palletScanController.dispose();
      _locationFocusNode.dispose();
      _palletFocusNode.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetchMyPickLists() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    final userCode = user?.employeeCode ?? 'EMP005';

    final remoteApi = ref.read(remoteApiProvider);
    final query = _showAllPicks ? {'showAll': 'true'} : {'userCode': userCode};
    final res = await remoteApi.get('/picking/pick-lists', queryParameters: query);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _pickLists = (res['pickLists'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onExecutePickScan({String? specificPalletNo}) async {
    if (pickLists.isEmpty) return;
    final currentList = pickLists[_selectedIndex < pickLists.length ? _selectedIndex : 0];
    final pklNo = currentList['pickListNumber'];
    final items = (currentList['items'] as List<dynamic>?) ?? [];

    final unpickedItem = items.firstWhere((i) => i['isPicked'] != true, orElse: () => items.isNotEmpty ? items.first : null);
    final targetPallet = specificPalletNo ?? _palletScanController.text.trim();
    final finalPalletNo = targetPallet.isNotEmpty ? targetPallet : (unpickedItem?['palletNumber']?.toString() ?? '');
    final locCode = _locationScanController.text.trim().isNotEmpty 
        ? _locationScanController.text.trim() 
        : (unpickedItem?['locationCode']?.toString() ?? 'WH1-STG-01');

    if (finalPalletNo.isEmpty) {
      _showFeedback('Please scan or select a Pallet Master QR code', isSuccess: false);
      _palletFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.scanPick(pklNo, locCode, finalPalletNo);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      _showFeedback(res['message'] ?? 'Pallet $finalPalletNo picked successfully!', isSuccess: true);
      _locationScanController.clear();
      _palletScanController.clear();
      _fetchMyPickLists();
    } else {
      _showFeedback(res['message'] ?? 'Pick scan failed!', isSuccess: false);
    }
  }

  void _showFeedback(String msg, {required bool isSuccess}) {
    setState(() {
      _statusMessage = msg;
      _isSuccessMessage = isSuccess;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? AppColors.ok : AppColors.danger,
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  void _openCameraScannerDialog(String type, List<dynamic> items) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CameraScannerDialog(
          scanType: type,
          pendingItems: items.where((i) => i['isPicked'] != true).toList(),
          onScanComplete: (scannedValue) {
            setState(() {
              if (type == 'LOCATION') {
                _locationScanController.text = scannedValue;
                _palletFocusNode.requestFocus();
              } else {
                _palletScanController.text = scannedValue;
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currentList = pickLists.isNotEmpty ? pickLists[_selectedIndex < pickLists.length ? _selectedIndex : 0] : null;
    final items = (currentList?['items'] as List<dynamic>?) ?? [];
    final isCompleted = currentList?['status'] == 'COMPLETED';

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopHeader = constraints.maxWidth > 700;

              Widget filterPill = Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _showAllPicks = false);
                        _fetchMyPickLists();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_showAllPicks ? AppColors.pink : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MY ASSIGNED',
                          style: TextStyle(
                            color: !_showAllPicks ? Colors.white : context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() => _showAllPicks = true);
                        _fetchMyPickLists();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showAllPicks ? AppColors.pink : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ALL OPEN PICKS',
                          style: TextStyle(
                            color: _showAllPicks ? Colors.white : context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isDesktopHeader) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: 'HHT Mobile Scanner — Forklift Operator Terminal'),
                          const SizedBox(height: 4),
                          Text(
                            'Operator: ${user?.name ?? "Prakash (Forklift Operator)"} (${user?.employeeCode ?? "EMP005"})',
                            style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    filterPill,
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'REFRESH',
                      icon: Icons.refresh_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: _fetchMyPickLists,
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'HHT Mobile Scanner — Forklift Operator Terminal'),
                  const SizedBox(height: 4),
                  Text(
                    'Operator: ${user?.name ?? "Prakash (Forklift Operator)"} (${user?.employeeCode ?? "EMP005"})',
                    style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      filterPill,
                      AppButton(
                        text: 'REFRESH',
                        icon: Icons.refresh_outlined,
                        variant: AppButtonVariant.ghost,
                        onPressed: _fetchMyPickLists,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final listWidget = _buildPickListSelector();
              final scannerWidget = _buildScannerTerminal(currentList, items, isCompleted);

              if (isNarrow) {
                return Column(
                  children: [
                    listWidget,
                    const SizedBox(height: 20),
                    scannerWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: listWidget),
                  const SizedBox(width: 20),
                  Expanded(flex: 8, child: scannerWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPickListSelector() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSIGNED PICKLISTS',
            style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
          else if (pickLists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active picklists assigned to your login.'),
            )
          else
            Column(
              children: List.generate(pickLists.length, (idx) {
                final pkl = pickLists[idx];
                final isSel = idx == _selectedIndex;
                final status = pkl['status'] ?? 'OPEN';
                final isDone = status == 'COMPLETED';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedIndex = idx;
                      _locationScanController.clear();
                      _palletScanController.clear();
                    }),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.ribbonPink.withValues(alpha: 0.15) : context.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppColors.ribbonPink : Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkl['pickListNumber'] ?? '',
                                style: TextStyle(
                                  color: isSel ? AppColors.ribbonPink : context.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Indent: ${pkl['indentNumber'] ?? ""}',
                                style: TextStyle(color: context.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          StatusPill(
                            label: status,
                            variant: isDone ? PillVariant.ok : PillVariant.warn,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerTerminal(dynamic currentList, List<dynamic> items, bool isCompleted) {
    return AppCard(
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HHT SCANNER — ${currentList?['pickListNumber'] ?? "SELECT PICKLIST"}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Directed Pick Route (Physical Scan Required)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: context.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
              StatusPill(
                label: isCompleted ? 'COMPLETED' : 'READY TO SCAN',
                variant: isCompleted ? PillVariant.ok : PillVariant.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),

          // Status / Feedback Banner if present
          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isSuccessMessage ? AppColors.ok : AppColors.danger).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isSuccessMessage ? AppColors.ok : AppColors.danger),
              ),
              child: Row(
                children: [
                  Icon(_isSuccessMessage ? Icons.check_circle : Icons.error, color: _isSuccessMessage ? AppColors.ok : AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccessMessage ? AppColors.ok : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Physical / Camera Scanner Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ribbonPink.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                    SizedBox(width: 8),
                    Text(
                      'PHYSICAL / CAMERA BARCODE SCANNER',
                      style: TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Step 1: Scan Location Barcode (Bypassed / Optional)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      'STEP 1: LOCATION BARCODE',
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const StatusPill(label: 'BYPASSED (OPTIONAL)', variant: PillVariant.info),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationScanController,
                        focusNode: _locationFocusNode,
                        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Location scan bypassed (auto-assigned)',
                          prefixIcon: const Icon(Icons.place_outlined, color: AppColors.ribbonPink),
                          suffixIcon: _locationScanController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _locationScanController.clear()),
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: 'SCAN',
                      icon: Icons.camera_alt_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => _openCameraScannerDialog('LOCATION', items),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Step 2: Scan Pallet Master QR
                Text(
                  'STEP 2: SCAN PALLET MASTER QR CODE',
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _palletScanController,
                        focusNode: _palletFocusNode,
                        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Scan pallet master QR (e.g. P26000101)',
                          prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
                          suffixIcon: _palletScanController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _palletScanController.clear()),
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: 'SCAN',
                      icon: Icons.camera_alt_outlined,
                      variant: AppButtonVariant.gradient,
                      onPressed: () => _openCameraScannerDialog('PALLET', items),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Pick Scan Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: AppButton(
                    text: 'CONFIRM PICK PALLET',
                    icon: Icons.check_circle_outline,
                    variant: AppButtonVariant.gradient,
                    isLoading: _isLoading,
                    onPressed: isCompleted ? null : () => _onExecutePickScan(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Required Pallets Route Checklist
          Text(
            'REQUIRED PALLETS FOR THIS PICKLIST:',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('LOCATION')),
                DataColumn(label: Text('PALLET #')),
                DataColumn(label: Text('ITEM CODE')),
                DataColumn(label: Text('QTY')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: items.map((i) {
                final isPicked = i['isPicked'] == true;
                final loc = i['locationCode'] ?? 'WH1-A-01-A1';
                final pal = i['palletNumber'] ?? 'P26000101';

                return DataRow(cells: [
                  DataCell(Text(loc, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                  DataCell(Text(pal, style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w700))),
                  DataCell(Text('${i['itemCode'] ?? "MXW-17-BLK"}')),
                  DataCell(Text('${i['qty'] ?? 96}')),
                  DataCell(StatusPill(label: isPicked ? 'PICKED' : 'PENDING', variant: isPicked ? PillVariant.ok : PillVariant.warn)),
                  DataCell(
                    isPicked
                        ? const Icon(Icons.check_circle, color: AppColors.ok, size: 20)
                        : AppButton(
                            text: 'PICK',
                            icon: Icons.check,
                            variant: AppButtonVariant.gradient,
                            onPressed: () => _onExecutePickScan(specificPalletNo: pal),
                          ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
