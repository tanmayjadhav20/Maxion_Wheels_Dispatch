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
  final _searchController = TextEditingController(text: 'MW|P1|8912345-01|000001742|260811|A|PL2');

  Map<String, dynamic>? _traceData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _onSearchTrace();
  }

  void _onSearchTrace() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.traceLookup(_searchController.text.trim());
    setState(() => _isLoading = false);

    if (res['success'] == true && res['result'] != null) {
      setState(() {
        _traceData = res['result'];
      });
    }
  }

  void _onExportTraceability() {
    exportToExcel(
      context,
      'Wheel & Pallet Lifecycle Traceability Report',
      ['STAGE', 'DETAIL', 'USER/LOCATION', 'TIMESTAMP'],
      [
        ['1. Production', '17 Inch Steel Wheel (MXW-17-BLK)', 'Shift A - Line PL2', '19 Aug 2026 06:00'],
        ['2. Wheel QR Applied', 'Serial #${_traceData?['serialNumber'] ?? "000001742"}', 'Ramesh (Pack)', '19 Aug 2026 07:15'],
        ['3. Pallet Build', 'Pallet ${_traceData?['palletNumber'] ?? "P26000101"}', 'Pack Point #1', '19 Aug 2026 07:30'],
        ['4. Putaway', 'Rack Position ${_traceData?['locationCode'] ?? "WH1-A-01-A1"}', 'Zone A - Aisle A1', '19 Aug 2026 08:00'],
        ['5. Loading & Gate Pass', 'Vehicle MH 12 QW 8890', 'Gate Pass ${_traceData?['gatePassNumber'] ?? "GP26000208"}', '19 Aug 2026 11:00'],
      ],
    );
  }

  void _onPrintTraceability() {
    final qr = _searchController.text.trim();
    PrintPreviewDialog.show(
      context: context,
      title: 'TRACEABILITY REPORT PRINT PREVIEW',
      documentType: PrintDocumentType.jobCardSummary,
      qrData: qr,
      codeText: qr,
      itemCode: _traceData?['itemCode'] ?? 'MXW-17-BLK',
      itemDescription: '360° Traceability & Lifecycle History Report',
      primaryDetail: 'Pallet: ${_traceData?['palletNumber'] ?? "P26000101"} • Gate Pass: ${_traceData?['gatePassNumber'] ?? "GP26000208"}',
      secondaryDetail: 'Customer: Tata Motors Pune',
      metadataFields: [
        {'SERIAL': _traceData?['serialNumber'] ?? '000001742'},
        {'LINE': _traceData?['line'] ?? 'PL2'},
        {'SHIFT': _traceData?['shift'] ?? 'A'},
        {'LOCATION': _traceData?['locationCode'] ?? 'WH1-A-01-A1'},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serialNumber = _traceData?['serialNumber'] ?? '000001742';
    final itemCode = _traceData?['itemCode'] ?? 'MXW-17-BLK';
    final palletNumber = _traceData?['palletNumber'] ?? 'P26000101';
    final locationCode = _traceData?['locationCode'] ?? 'WH1-A-01-A1';
    final customerName = _traceData?['customerName'] ?? 'Tata Motors Pune';
    final gatePassNumber = _traceData?['gatePassNumber'] ?? 'GP26000208';

    return SingleChildScrollView(
      padding: AppTokens.pScreen,
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter Wheel QR / Pallet QR / Serial #...',
                      prefixIcon: Icon(Icons.search, color: AppColors.ribbonPink),
                    ),
                    onSubmitted: (_) => _onSearchTrace(),
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'TRACE HISTORY',
                  icon: Icons.travel_explore,
                  isLoading: _isLoading,
                  onPressed: _onSearchTrace,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trace Result Card
          AppCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '360° TRACEABILITY RESULT',
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: 'EXPORT EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onExportTraceability,
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          text: 'PRINT REPORT',
                          icon: Icons.print_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onPrintTraceability,
                        ),
                        const SizedBox(width: 12),
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
                          // Lifecycle Steps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStep('1. Production', 'Shift A - Line PL2', '19 Aug 2026', Icons.precision_manufacturing_outlined, true),
                              _buildStep('2. Wheel QR Applied', 'Serial #$serialNumber', 'Ramesh (Pack)', Icons.qr_code, true),
                              _buildStep('3. Pallet Build', 'Pallet $palletNumber', 'Position 37/96', Icons.inventory_2_outlined, true),
                              _buildStep('4. Putaway', locationCode, 'Rack Staged', Icons.place_outlined, true),
                              _buildStep('5. Loading & Gate Pass', customerName, gatePassNumber, Icons.local_shipping_outlined, true),
                            ],
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
            color: done ? AppColors.okTint : context.bgSurfaceElevated,
            border: Border.all(color: done ? AppColors.ok : Theme.of(context).dividerColor),
          ),
          child: Icon(icon, color: done ? AppColors.ok : context.textMuted, size: 22),
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
