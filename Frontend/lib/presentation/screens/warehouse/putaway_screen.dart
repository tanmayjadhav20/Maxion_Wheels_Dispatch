import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PutawayScreen extends StatefulWidget {
  const PutawayScreen({super.key});

  @override
  State<PutawayScreen> createState() => _PutawayScreenState();
}

class _PutawayScreenState extends State<PutawayScreen> {
  final _palletQrController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  String _recommendedZone = 'Zone A (Main FG Racks)';
  String _suggestedBay = 'WH1-A-04-02';

  final List<Map<String, dynamic>> _bays = [
    {'code': 'WH1-A-01-01', 'zone': 'Zone A', 'isOccupied': true},
    {'code': 'WH1-A-02-01', 'zone': 'Zone A', 'isOccupied': true},
    {'code': 'WH1-A-04-02', 'zone': 'Zone A', 'isOccupied': false},
    {'code': 'WH1-B-01-01', 'zone': 'Zone B', 'isOccupied': false},
    {'code': 'WH1-H-01-HB', 'zone': 'HB Bays', 'isOccupied': true},
    {'code': 'WH1-H-02-HB', 'zone': 'HB Bays', 'isOccupied': false},
  ];

  @override
  void dispose() {
    _palletQrController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onScanPalletForPutaway() {
    final text = _palletQrController.text.trim().toUpperCase();
    if (text.contains('|H|') || text.startsWith('H')) {
      setState(() {
        _recommendedZone = 'Zone HB (Dedicated Half Pallet Bays)';
        _suggestedBay = 'WH1-H-02-HB';
        _locationController.text = 'WH1-H-02-HB';
      });
    } else {
      setState(() {
        _recommendedZone = 'Zone A (Main FG Racks)';
        _suggestedBay = 'WH1-A-04-02';
        _locationController.text = 'WH1-A-04-02';
      });
    }
  }

  void _onConfirmPutaway() {
    if (_palletQrController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan both Pallet QR and Location Rack Tag'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final bayCode = _locationController.text.trim();
          final bayIdx = _bays.indexWhere((b) => b['code'] == bayCode);
          if (bayIdx != -1) {
            _bays[bayIdx]['isOccupied'] = true;
          }
          _palletQrController.clear();
          _locationController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HHT Directed Putaway confirmed! Stock location updated in WMS.'), backgroundColor: AppColors.ok),
        );
      }
    });
  }

  void _onExportOccupancy() {
    exportToExcel(
      context,
      'Warehouse Bay Occupancy Report',
      ['BAY CODE', 'ZONE', 'OCCUPANCY STATUS'],
      _bays.map((b) => [
        b['code'] as String,
        b['zone'] as String,
        (b['isOccupied'] as bool) ? 'OCCUPIED' : 'FREE BAY',
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

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              final formCard = AppCard(
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'CONFIRM PUTAWAY & UPDATE STOCK',
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onConfirmPutaway,
                        ),
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
              );

              final occupancyCard = AppCard(
                showGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LIVE WAREHOUSE BAY OCCUPANCY MAP',
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _bays.map((bay) {
                          final isOcc = bay['isOccupied'] as bool;
                          final isRec = bay['code'] == _suggestedBay;

                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            width: 140,
                            decoration: BoxDecoration(
                              color: isRec
                                  ? AppColors.pink.withValues(alpha: 0.15)
                                  : (isOcc ? context.bgSurfaceElevated : Theme.of(context).cardColor),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRec
                                    ? AppColors.pink
                                    : (isOcc ? AppColors.line : Theme.of(context).dividerColor),
                                width: isRec ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bay['code'] as String,
                                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Zone: ${bay['zone']}',
                                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                StatusPill(
                                  label: isOcc ? 'OCCUPIED' : (isRec ? 'SUGGESTED' : 'FREE BAY'),
                                  variant: isOcc ? PillVariant.warn : (isRec ? PillVariant.purple : PillVariant.ok),
                                ),
                              ],
                            ),
                          );
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
                    Expanded(flex: 7, child: occupancyCard),
                  ],
                );
              }

              return Column(
                children: [
                  formCard,
                  const SizedBox(height: 24),
                  occupancyCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
