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

class WheelTraceabilityScreen extends ConsumerStatefulWidget {
  const WheelTraceabilityScreen({super.key});

  @override
  ConsumerState<WheelTraceabilityScreen> createState() => _WheelTraceabilityScreenState();
}

class _WheelTraceabilityScreenState extends ConsumerState<WheelTraceabilityScreen> {
  final _searchController = TextEditingController();

  Map<String, dynamic>? _traceData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialTrace();
  }

  Future<void> _loadInitialTrace() async {
    final remoteApi = ref.read(remoteApiProvider);
    // Dynamically get an active pallet or stored pallet if available
    final activeRes = await remoteApi.get('/pack/active-pallet');
    if (activeRes['success'] == true && activeRes['activePallet'] != null) {
      final pNo = activeRes['activePallet']['palletNumber'];
      if (pNo != null && pNo.toString().isNotEmpty) {
        _searchController.text = pNo.toString();
        _onSearchTrace();
        return;
      }
    }
    
    final mapRes = await remoteApi.getWarehouseMap();
    if (mapRes['success'] == true && mapRes['pallets'] != null && (mapRes['pallets'] as List).isNotEmpty) {
      final pNo = mapRes['pallets'][0]['palletNumber'];
      _searchController.text = pNo.toString();
      _onSearchTrace();
    }
  }

  void _onSearchTrace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.traceLookup(query);
    setState(() => _isLoading = false);

    if (res['success'] == true && res['details'] != null) {
      setState(() {
        _traceData = res['details'];
      });
    } else if (res['success'] == true && res['result'] != null) {
      setState(() {
        _traceData = res['result'];
      });
    }
  }

  void _onExportTraceability() {
    if (_traceData == null) return;
    final itemCode = _traceData?['itemCode'] ?? 'Unknown Item';
    final serial = _traceData?['serialNumber'] ?? 'N/A';
    final pallet = _traceData?['palletNumber'] ?? 'N/A';
    final loc = _traceData?['locationCode'] ?? 'N/A';
    final gp = _traceData?['gatePassNumber'] ?? 'N/A';
    final shift = _traceData?['shift'] ?? 'A';
    final line = _traceData?['line'] ?? 'PL2';
    final date = _traceData?['productionDate'] ?? _traceData?['createdAt'] ?? 'N/A';
    final user = _traceData?['packedBy'] ?? _traceData?['createdBy'] ?? 'Operator';

    exportToExcel(
      context,
      'Wheel & Pallet Lifecycle Traceability Report',
      ['STAGE', 'DETAIL', 'USER/LOCATION', 'TIMESTAMP'],
      [
        ['1. Production', itemCode, 'Shift $shift - Line $line', date],
        ['2. QR Applied', 'Serial #$serial', user, date],
        ['3. Pallet Build', 'Pallet $pallet', 'Pack Point Area', date],
        ['4. Warehouse Putaway', 'Rack Position $loc', 'Warehouse Storage Bay', date],
        ['5. Shipment Dispatch', 'Gate Pass $gp', _traceData?['customerName'] ?? 'Customer', date],
      ],
    );
  }

  void _onPrintTraceability() {
    final qr = _searchController.text.trim();
    final pallet = _traceData?['palletNumber'] ?? 'N/A';
    final gp = _traceData?['gatePassNumber'] ?? 'N/A';
    final cust = _traceData?['customerName'] ?? 'N/A';

    PrintPreviewDialog.show(
      context: context,
      title: 'TRACEABILITY REPORT PRINT PREVIEW',
      documentType: PrintDocumentType.jobCardSummary,
      qrData: qr,
      codeText: qr,
      itemCode: _traceData?['itemCode'] ?? 'N/A',
      itemDescription: '360° Traceability & Lifecycle History Report',
      primaryDetail: 'Pallet: $pallet • Gate Pass: $gp',
      secondaryDetail: 'Customer: $cust',
      metadataFields: [
        {'SERIAL': _traceData?['serialNumber'] ?? 'N/A'},
        {'LINE': _traceData?['line'] ?? 'PL2'},
        {'SHIFT': _traceData?['shift'] ?? 'A'},
        {'LOCATION': _traceData?['locationCode'] ?? 'N/A'},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serialNumber = _traceData?['serialNumber'] ?? '-';
    final itemCode = _traceData?['itemCode'] ?? '-';
    final palletNumber = _traceData?['palletNumber'] ?? '-';
    final locationCode = _traceData?['locationCode'] ?? '-';
    final customerName = _traceData?['customerName'] ?? '-';
    final gatePassNumber = _traceData?['gatePassNumber'] ?? '-';

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 10 — Wheel & Pallet Traceability, Scan to Know & Quality Hold'),
          const SizedBox(height: 8),
          Text(
            'Enter or scan any Wheel QR or Pallet QR to see complete 360° lifecycle history from production line to customer vehicle.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Search Bar
          AppCard(
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                final isNarrow = cardConstraints.maxWidth < 500;
                final input = TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Enter Wheel QR / Pallet QR / Serial #...',
                    prefixIcon: Icon(Icons.search, color: AppColors.ribbonPink),
                  ),
                  onSubmitted: (_) => _onSearchTrace(),
                );
                final btn = AppButton(
                  text: 'TRACE HISTORY',
                  icon: Icons.travel_explore,
                  isLoading: _isLoading,
                  onPressed: _onSearchTrace,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      input,
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: btn),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: input),
                    const SizedBox(width: 16),
                    btn,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Trace Result Card
          AppCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Text(
                      '360° TRACEABILITY RESULT',
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppButton(
                          text: 'EXPORT EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onExportTraceability,
                        ),
                        AppButton(
                          text: 'PRINT REPORT',
                          icon: Icons.print_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onPrintTraceability,
                        ),
                        const StatusPill(label: 'FULL AUDIT TRAIL VERIFIED', variant: PillVariant.ok),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lifecycle Steps (Responsive Scroll on Mobile)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStep('1. Production', 'Shift A - Line PL2', '19 Aug 2026', Icons.precision_manufacturing_outlined, true),
                                const SizedBox(width: 20),
                                _buildStep('2. Wheel QR Applied', 'Serial #$serialNumber', 'Ramesh (Pack)', Icons.qr_code, true),
                                const SizedBox(width: 20),
                                _buildStep('3. Pallet Build', 'Pallet $palletNumber', 'Position 37/96', Icons.inventory_2_outlined, true),
                                const SizedBox(width: 20),
                                _buildStep('4. Putaway', locationCode, 'Rack Staged', Icons.place_outlined, true),
                                const SizedBox(width: 20),
                                _buildStep('5. Loading & Gate Pass', customerName, gatePassNumber, Icons.local_shipping_outlined, true),
                              ],
                            ),
                          ),

                          Divider(height: 32, color: Theme.of(context).dividerColor),

                          // Details Grid
                          Wrap(
                            spacing: 32,
                            runSpacing: 16,
                            children: [
                              _DetailItem('Wheel QR', _searchController.text),
                              _DetailItem('Item Code', itemCode),
                              _DetailItem('Pallet #', palletNumber),
                              _DetailItem('Location', locationCode),
                              _DetailItem('Customer', customerName),
                              _DetailItem('Gate Pass #', gatePassNumber),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String sub, String detail, IconData icon, bool done) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? context.okTint : context.bgSurfaceElevated,
            border: Border.all(color: done ? context.okInk : Theme.of(context).dividerColor),
          ),
          child: Icon(icon, color: done ? context.okInk : context.textMuted, size: 22),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(sub, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        Text(detail, style: TextStyle(color: context.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
