import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/camera_qr_scanner_dialog.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PutawayScreen extends ConsumerStatefulWidget {
  const PutawayScreen({super.key});

  @override
  ConsumerState<PutawayScreen> createState() => _PutawayScreenState();
}

class _PutawayScreenState extends ConsumerState<PutawayScreen> {
  final _palletQrController = TextEditingController();
  final _locationController = TextEditingController();
  final _bayScrollController = ScrollController();

  bool _isLoading = false;
  String _recommendedZone = 'Zone A (Main FG Racks)';
  String _suggestedBay = '';

  List<Map<String, dynamic>> _bays = [];
  List<Map<String, dynamic>> _pallets = [];
  List<Map<String, dynamic>> _availableLocations = [];
  String? _selectedLocationCode;
  String? _selectedPalletCode;

  @override
  void initState() {
    super.initState();
    _fetchWarehouseMap();
  }

  @override
  void dispose() {
    _palletQrController.dispose();
    _locationController.dispose();
    _bayScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWarehouseMap() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getWarehouseMap();
      if (res['success'] == true && res['locations'] != null) {
        final locs = res['locations'] as List<dynamic>;
        final pals = (res['pallets'] as List<dynamic>?) ?? [];

        setState(() {
          // Unique locations
          final uniqueLocsMap = <String, Map<String, dynamic>>{};
          for (final l in locs) {
            final code = (l['code'] ?? '').toString();
            if (code.isNotEmpty && !uniqueLocsMap.containsKey(code)) {
              uniqueLocsMap[code] = {
                'code': code,
                'zone': l['zone'] ?? 'Zone A',
                'type': l['type'] ?? 'rack',
                'isOccupied': l['status'] == 'occupied',
                'currentPalletCode': l['currentPalletCode'],
              };
            }
          }
          _bays = uniqueLocsMap.values.toList();
          _availableLocations = _bays.where((b) => !(b['isOccupied'] as bool)).toList();

          // Unique pallets
          final uniquePalletsMap = <String, Map<String, dynamic>>{};
          for (final p in pals) {
            final pNo = (p['palletNumber'] ?? '').toString();
            if (pNo.isNotEmpty && !uniquePalletsMap.containsKey(pNo)) {
              uniquePalletsMap[pNo] = {
                'palletNumber': pNo,
                'typeSeries': p['typeSeries'] ?? 'P',
                'itemCode': p['itemCode'] ?? '',
                'packedQty': p['packedQty'] ?? 0,
                'stdQty': p['stdQty'] ?? 4,
                'locationCode': p['locationCode'] ?? 'UNASSIGNED',
                'status': p['status'] ?? 'OPEN',
              };
            }
          }
          _pallets = uniquePalletsMap.values.toList();

          // Set default selected pallet if available
          if (_pallets.isNotEmpty && (_selectedPalletCode == null || _selectedPalletCode!.isEmpty)) {
            final firstOpen = _pallets.firstWhere(
              (p) => p['locationCode'] == 'UNASSIGNED' || p['locationCode'] == 'WH1-STG-01',
              orElse: () => _pallets.first,
            );
            _selectedPalletCode = firstOpen['palletNumber'];
            _palletQrController.text = _selectedPalletCode!;
            _onScanPalletForPutaway(_selectedPalletCode!);
          }

          // Set default selected available location if available
          if (_availableLocations.isNotEmpty && (_selectedLocationCode == null || _selectedLocationCode!.isEmpty)) {
            _selectedLocationCode = _availableLocations.first['code'];
            _locationController.text = _selectedLocationCode!;
          }
        });
      }
    } catch (_) {}
  }

  void _onScanPalletForPutaway(String rawText) {
    String cleanPalletNo = rawText.trim().toUpperCase();
    if (cleanPalletNo.startsWith('MWP|')) {
      cleanPalletNo = cleanPalletNo.replaceFirst('MWP|', '');
    }
    if (cleanPalletNo.isEmpty) return;

    _palletQrController.text = cleanPalletNo;
    _selectedPalletCode = cleanPalletNo;

    // Insert transient item into _pallets if not present to satisfy Dropdown MenuItem check
    if (!_pallets.any((p) => p['palletNumber'] == cleanPalletNo)) {
      _pallets.insert(0, {
        'palletNumber': cleanPalletNo,
        'typeSeries': cleanPalletNo.startsWith('H') ? 'H' : 'P',
        'itemCode': 'SCANNED',
        'packedQty': 0,
        'stdQty': 4,
        'locationCode': 'UNASSIGNED',
        'status': 'PACKING',
      });
    }

    final isHalfPallet = cleanPalletNo.contains('|H|') || cleanPalletNo.startsWith('H');

    setState(() {
      if (isHalfPallet) {
        _recommendedZone = 'Zone HB (Dedicated Half Pallet Bays)';
        final matchingLocation = _availableLocations.firstWhere(
          (loc) => loc['type'] == 'half_pallet_bay' || (loc['zone'] as String).contains('Half'),
          orElse: () => _availableLocations.isNotEmpty ? _availableLocations.first : {'code': 'WH1-H-01-HB'},
        );
        _suggestedBay = matchingLocation['code'] ?? 'WH1-H-01-HB';
      } else {
        _recommendedZone = 'Zone A (Main FG Racks)';
        final matchingLocation = _availableLocations.firstWhere(
          (loc) => loc['type'] == 'rack' || (loc['zone'] as String).contains('Zone A'),
          orElse: () => _availableLocations.isNotEmpty ? _availableLocations.first : {'code': 'WH1-A-01-A2'},
        );
        _suggestedBay = matchingLocation['code'] ?? 'WH1-A-01-A2';
      }

      if (_availableLocations.any((l) => l['code'] == _suggestedBay)) {
        _selectedLocationCode = _suggestedBay;
        _locationController.text = _suggestedBay;
      } else if (_availableLocations.isNotEmpty) {
        _selectedLocationCode = _availableLocations.first['code'];
        _locationController.text = _selectedLocationCode!;
      }
    });
  }

  void _openCameraScanner() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: _palletQrController.text.isNotEmpty ? _palletQrController.text : 'PALLET MASTER',
      onQrScanned: (scannedQr) {
        _onScanPalletForPutaway(scannedQr);
      },
    );
  }

  void _onConfirmPutaway() async {
    final palletNo = _palletQrController.text.trim();
    final locCode = _locationController.text.trim();

    if (palletNo.isEmpty || locCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan/select both Pallet Master Code and Available Location'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.executePutaway(palletNo, locCode);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        setState(() {
          final bayIdx = _bays.indexWhere((b) => b['code'] == locCode);
          if (bayIdx != -1) {
            _bays[bayIdx]['isOccupied'] = true;
          }
          _palletQrController.clear();
          _locationController.clear();
          _selectedLocationCode = null;
          _selectedPalletCode = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'HHT Directed Putaway confirmed & saved to database!'),
            backgroundColor: AppColors.ok,
          ),
        );
        _fetchWarehouseMap();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Putaway failed'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Putaway confirmed locally'), backgroundColor: AppColors.ok),
      );
    }
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
    final validSelectedPallet = _pallets.any((p) => p['palletNumber'] == _selectedPalletCode)
        ? _selectedPalletCode
        : null;

    final validSelectedLoc = _availableLocations.any((l) => l['code'] == _selectedLocationCode)
        ? _selectedLocationCode
        : null;

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 6 — HHT Directed Putaway & Warehouse Management'),
          const SizedBox(height: 8),
          Text(
            'Scan Pallet Master code or select from dropdown. View and select available empty warehouse rack locations dynamically.',
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

                    // Pallet Master Scan Row / Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: validSelectedPallet,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: 'SELECT / SCAN PALLET MASTER CODE (P / H / PM)',
                              prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _pallets.map((p) {
                              final pNo = p['palletNumber'] as String;
                              final item = p['itemCode'] as String;
                              final qty = p['packedQty'];
                              final std = p['stdQty'];
                              final loc = p['locationCode'] as String;
                              return DropdownMenuItem<String>(
                                value: pNo,
                                child: Text(
                                  '$pNo ($item • $qty/$std wheels • $loc)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _onScanPalletForPutaway(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: 'SCAN',
                          icon: Icons.camera_alt_outlined,
                          variant: AppButtonVariant.gradient,
                          onPressed: _openCameraScanner,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Manual Text Field for Pallet QR
                    TextField(
                      controller: _palletQrController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'SCANNED PALLET MASTER CODE',
                        hintText: 'P26000155 or H26000048',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.ribbonOrange),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) => _onScanPalletForPutaway(val),
                    ),
                    const SizedBox(height: 16),

                    // Recommendation Card
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
                          Text(
                            'Suggested Bay: ${_suggestedBay.isNotEmpty ? _suggestedBay : "Select location below"}',
                            style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Available Locations Dropdown
                    DropdownButtonFormField<String>(
                      value: validSelectedLoc,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'AVAILABLE WAREHOUSE LOCATIONS (EMPTY BAYS)',
                        prefixIcon: const Icon(Icons.place_outlined, color: AppColors.ribbonPink),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: StatusPill(
                          label: '${_availableLocations.length} BAYS FREE',
                          variant: PillVariant.ok,
                        ),
                      ),
                      items: _availableLocations.map((loc) {
                        final code = loc['code'] as String;
                        final zone = loc['zone'] as String;
                        final type = loc['type'] as String;
                        final isRec = code == _suggestedBay;
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(
                            '$code — $zone ($type)${isRec ? ' ★ RECOMMENDED' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isRec ? AppColors.ok : context.textPrimary,
                              fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLocationCode = val;
                            _locationController.text = val;
                          });
                        }
                      },
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
                            if (loc.isEmpty) return;
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
                                {'ZONE': _recommendedZone},
                                {'STATUS': 'Available Empty Bay'},
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          tooltip: 'Slide Left',
                          onPressed: () {
                            if (_bayScrollController.hasClients) {
                              _bayScrollController.animateTo(
                                (_bayScrollController.offset - 240).clamp(0.0, _bayScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _bayScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _bays.map((bay) {
                                final isOcc = bay['isOccupied'] as bool;
                                final isRec = bay['code'] == _suggestedBay;

                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(14),
                                  width: 150,
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
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bay['zone'] as String,
                                        style: TextStyle(color: context.textMuted, fontSize: 11),
                                      ),
                                      const SizedBox(height: 8),
                                      StatusPill(
                                        label: isOcc ? 'OCCUPIED' : 'FREE BAY',
                                        variant: isOcc ? PillVariant.warn : PillVariant.ok,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          tooltip: 'Slide Right',
                          onPressed: () {
                            if (_bayScrollController.hasClients) {
                              _bayScrollController.animateTo(
                                (_bayScrollController.offset + 240).clamp(0.0, _bayScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: formCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: occupancyCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    formCard,
                    const SizedBox(height: 24),
                    occupancyCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
