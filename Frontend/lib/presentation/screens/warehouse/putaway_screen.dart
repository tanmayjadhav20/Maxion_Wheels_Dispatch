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

class PutawayScreen extends ConsumerStatefulWidget {
  const PutawayScreen({super.key});

  @override
  ConsumerState<PutawayScreen> createState() => _PutawayScreenState();
}

class _PutawayScreenState extends ConsumerState<PutawayScreen> {
  final _palletQrController = TextEditingController(text: 'P26000148');
  final _locationController = TextEditingController(text: 'WH1-A-01-A1');

  List<dynamic>? _locations = [];
  List<dynamic> get locations => _locations ?? [];
  bool _isLoading = false;
  String _recommendedZone = 'ZONE_A';
  String _suggestedBay = 'WH1-A-01-A1';

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/masters/locations');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _locations = (res['locations'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onScanPalletForPutaway() {
    final qr = _palletQrController.text.trim();
    if (qr.startsWith('H')) {
      setState(() {
        _recommendedZone = 'ZONE_HB (Half Pallet Dedicated Bay)';
        _suggestedBay = 'WH1-H-01-HB';
        _locationController.text = 'WH1-H-01-HB';
      });
    } else {
      setState(() {
        _recommendedZone = 'ZONE_A (Standard Racking Bay)';
        _suggestedBay = 'WH1-A-01-A1';
        _locationController.text = 'WH1-A-01-A1';
      });
    }
  }

  void _onConfirmPutaway() async {
    final palletNo = _palletQrController.text.trim();
    final locCode = _locationController.text.trim();
    if (palletNo.isEmpty || locCode.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/warehouse/putaway', {
      'palletNumber': palletNo,
      'locationCode': locCode,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Pallet stored successfully at $locCode!'),
        ),
      );
      _fetchLocations();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Putaway failed')),
      );
    }
  }

  void _onExportOccupancy() {
    exportToExcel(
      context,
      'Warehouse Occupancy Map',
      ['LOCATION', 'ZONE', 'TYPE', 'STORED PALLET', 'STATUS'],
      locations.map<List<String>>((l) => [
        '${l['code']}',
        '${l['zone']}',
        '${l['type']}',
        '${l['currentPalletCode'] ?? "-"}',
        '${l['status']}'.toUpperCase(),
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
          const SectionTitle(title: 'Module 6 — HHT Directed Putaway & Warehouse Management'),
          const SizedBox(height: 8),
          Text(
            'HHT directs forklift driver to optimal rack location. Full pallets (P/PM) go to Zone A/B/C/D. Half pallets (H) are routed directly to dedicated HB bays.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: HHT Directed Putaway Form Card
              Expanded(
                flex: 5,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HHT DIRECTED PUTAWAY EXECUTION',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _palletQrController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Pallet Master QR (P / H / PM)',
                          prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _onScanPalletForPutaway(),
                      ),
                      const SizedBox(height: 16),
                      // System Recommendation Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.infoTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SYSTEM DIRECTED RECOMMENDATION:', style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Target Zone: $_recommendedZone', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('Suggested Bay: $_suggestedBay', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _locationController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Scan Location Barcode (Rack / Bay)',
                          prefixIcon: const Icon(Icons.place_outlined, color: AppColors.ribbonPink),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'CONFIRM PUTAWAY & UPDATE STOCK',
                              variant: AppButtonVariant.gradient,
                              isLoading: _isLoading,
                              onPressed: _onConfirmPutaway,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            text: 'PRINT LOCATION BARCODE',
                            icon: Icons.print_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: () {
                              final loc = _locationController.text.trim();
                              PrintPreviewDialog.show(
                                context: context,
                                title: 'LOCATION RACK BARCODE PRINT PREVIEW',
                                documentType: PrintDocumentType.palletMaster,
                                qrData: 'LOC|$loc',
                                codeText: 'LOC|$loc',
                                itemCode: loc,
                                itemDescription: 'Warehouse Staging Location Rack Tag',
                                primaryDetail: 'Zone: $_recommendedZone',
                                secondaryDetail: 'Status: AVAILABLE FOR PUTAWAY',
                                metadataFields: [
                                  {'LOCATION': loc},
                                  {'ZONE': 'Zone A'},
                                  {'TYPE': 'Standard Bay'},
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

              // Right: Warehouse Occupancy Map Card
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
                            'LIVE WAREHOUSE OCCUPANCY MAP',
                            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          AppButton(
                            text: 'EXPORT MAP EXCEL',
                            icon: Icons.table_chart_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onExportOccupancy,
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
                                  DataColumn(label: Text('LOCATION')),
                                  DataColumn(label: Text('ZONE')),
                                  DataColumn(label: Text('TYPE')),
                                  DataColumn(label: Text('STORED PALLET')),
                                  DataColumn(label: Text('STATUS')),
                                ],
                                rows: locations.map((l) {
                                  final isOccupied = l['status'] == 'occupied';
                                  final isHalf = l['type'] == 'half_pallet_bay';
                                  return DataRow(cells: [
                                    DataCell(Text(l['code'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                                    DataCell(Text(l['zone'] ?? '')),
                                    DataCell(Text(l['type'] ?? '')),
                                    DataCell(Text(l['currentPalletCode'] ?? '-')),
                                    DataCell(
                                      StatusPill(
                                        label: isOccupied ? 'OCCUPIED' : 'AVAILABLE',
                                        variant: isOccupied ? (isHalf ? PillVariant.warn : PillVariant.purple) : PillVariant.ok,
                                      ),
                                    ),
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
