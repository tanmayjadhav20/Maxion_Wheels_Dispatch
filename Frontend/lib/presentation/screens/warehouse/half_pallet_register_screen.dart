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

class HalfPalletRegisterScreen extends ConsumerStatefulWidget {
  const HalfPalletRegisterScreen({super.key});

  @override
  ConsumerState<HalfPalletRegisterScreen> createState() => _HalfPalletRegisterScreenState();
}

class _HalfPalletRegisterScreenState extends ConsumerState<HalfPalletRegisterScreen> {
  List<dynamic>? _halfPallets = [];
  List<dynamic> get halfPallets => _halfPallets ?? [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHalfPallets();
  }

  Future<void> _fetchHalfPallets() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/warehouse/half-pallet-register');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _halfPallets = (res['halfPallets'] as List<dynamic>?) ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopHeader = constraints.maxWidth > 750;

              if (isDesktopHeader) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: 'Module 5 — Stored Half Pallet Register & Ageing Alert'),
                          const SizedBox(height: 8),
                          Text(
                            'Track open short pallets (H series) stored in HB bays. Shows age in days and highlights ageing pallets (>3 days) to force FIFO recall.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'EXPORT HALF PALLETS EXCEL',
                      icon: Icons.table_chart_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        exportToExcel(
                          context,
                          'Half Pallet Register',
                          ['PALLET #', 'ITEM CODE', 'PACKED QTY', 'LOCATION', 'AGE (DAYS)', 'STATUS'],
                          (_halfPallets ?? []).map<List<String>>((h) => [
                            '${h['palletNumber'] ?? h['palletId']}',
                            '${h['itemCode']}',
                            '${h['packedQty'] ?? h['quantity']}',
                            '${h['locationCode'] ?? h['location'] ?? "WH1-H-01-HB"}',
                            '${h['ageDays'] ?? 1}',
                            (h['ageDays'] ?? 0) >= 3 ? "AGEING WARNING" : "NORMAL STORED",
                          ]).toList(),
                        );
                      },
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Module 5 — Stored Half Pallet Register & Ageing Alert'),
                  const SizedBox(height: 8),
                  Text(
                    'Track open short pallets (H series) stored in HB bays. Shows age in days and highlights ageing pallets (>3 days) to force FIFO recall.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'EXPORT HALF PALLETS EXCEL',
                    icon: Icons.table_chart_outlined,
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      exportToExcel(
                        context,
                        'Half Pallet Register',
                        ['PALLET #', 'ITEM CODE', 'PACKED QTY', 'LOCATION', 'AGE (DAYS)', 'STATUS'],
                        (_halfPallets ?? []).map<List<String>>((h) => [
                          '${h['palletNumber'] ?? h['palletId']}',
                          '${h['itemCode']}',
                          '${h['packedQty'] ?? h['quantity']}',
                          '${h['locationCode'] ?? h['location'] ?? "WH1-H-01-HB"}',
                          '${h['ageDays'] ?? 1}',
                          (h['ageDays'] ?? 0) >= 3 ? "AGEING WARNING" : "NORMAL STORED",
                        ]).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          AppCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE HALF PALLETS & AGEING CONTROL',
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    AppButton(
                      text: 'PRINT HALF PALLET QR',
                      icon: Icons.print_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        final firstHalf = halfPallets.isNotEmpty ? halfPallets[0]['palletNumber'] : 'H26000037';
                        PrintPreviewDialog.show(
                          context: context,
                          title: 'HALF PALLET QR LABEL PRINT PREVIEW',
                          documentType: PrintDocumentType.palletMaster,
                          qrData: 'MWP|$firstHalf',
                          codeText: 'MWP|$firstHalf',
                          itemCode: 'MXW-17-BLK',
                          itemDescription: 'Stored Half Pallet (48/96 wheels packed)',
                          primaryDetail: 'Series: H (Half Pallet) • Location: WH1-H-01-HB',
                          secondaryDetail: 'Reason: Sudden Item Changeover',
                          metadataFields: [
                            {'PALLET #': '$firstHalf'},
                            {'PACKED QTY': '48 / 96'},
                            {'AGE': '1 Day'},
                            {'STATUS': 'STORED_FOR_TOP_UP'},
                          ],
                        );
                      },
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
                            DataColumn(label: Text('PALLET #')),
                            DataColumn(label: Text('ITEM CODE')),
                            DataColumn(label: Text('PACKED QTY')),
                            DataColumn(label: Text('SHORTFALL')),
                            DataColumn(label: Text('LOCATION')),
                            DataColumn(label: Text('CLOSE REASON')),
                            DataColumn(label: Text('AGE (DAYS)')),
                            DataColumn(label: Text('STATUS')),
                          ],
                          rows: halfPallets.map((h) {
                            final age = h['ageDays'] ?? 1;
                            final isAgeing = age >= 3;
                            final stdQty = h['stdQty'] ?? 96;
                            final packedQty = h['packedQty'] ?? 0;
                            final short = stdQty - packedQty;

                            return DataRow(cells: [
                              DataCell(Text(h['palletNumber'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: isAgeing ? AppColors.danger : AppColors.warn))),
                              DataCell(Text(h['itemCode'] ?? '')),
                              DataCell(Text('$packedQty / $stdQty')),
                              DataCell(Text('$short wheels short')),
                              DataCell(Text(h['locationCode'] ?? 'WH1-H-01-HB')),
                              DataCell(Text(h['closeReason'] ?? 'Sudden Item Changeover')),
                              DataCell(Text('$age day${age > 1 ? "s" : ""}', style: TextStyle(color: isAgeing ? AppColors.danger : AppColors.ok, fontWeight: FontWeight.w700))),
                              DataCell(StatusPill(label: isAgeing ? 'AGEING ALERT' : 'STORED HALF', variant: isAgeing ? PillVariant.danger : PillVariant.warn)),
                            ]);
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
