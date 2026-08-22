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

class IndentEntryScreen extends ConsumerStatefulWidget {
  const IndentEntryScreen({super.key});

  @override
  ConsumerState<IndentEntryScreen> createState() => _IndentEntryScreenState();
}

class _IndentEntryScreenState extends ConsumerState<IndentEntryScreen> {
  final _customerController = TextEditingController(text: 'Tata Motors Pune');
  final _itemController = TextEditingController(text: 'MXW-17-BLK');
  final _qtyController = TextEditingController(text: '192');
  String _selectedOperatorCode = 'EMP005';
  String _selectedOperatorName = 'John (HHT Forklift Operator 1)';

  List<dynamic>? _pickLists = [];
  List<dynamic> get pickLists => _pickLists ?? [];
  bool _isLoading = false;

  final List<Map<String, String>> _operators = const [
    {'code': 'EMP005', 'name': 'John (HHT Forklift Operator 1)'},
    {'code': 'EMP002', 'name': 'Ramesh (HHT Gun 2)'},
    {'code': 'EMP003', 'name': 'Suresh (Warehouse Manager)'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPickLists();
  }

  Future<void> _fetchPickLists() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/picking/pick-lists');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _pickLists = (res['pickLists'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onCreateIndent() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.createIndent({
      'customerName': _customerController.text.trim(),
      'assignedToCode': _selectedOperatorCode,
      'assignedToName': _selectedOperatorName,
      'items': [
        {'itemCode': _itemController.text.trim(), 'requestedQty': int.tryParse(_qtyController.text.trim()) ?? 192}
      ]
    });
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Indent raised & Pick List generated!'),
        ),
      );
      _fetchPickLists();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(res['message'] ?? 'Indent creation failed'),
        ),
      );
    }
  }

  void _onReassignOperator(String pickListNumber) {
    String newCode = _selectedOperatorCode;
    String newName = _selectedOperatorName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Reassign Pick List $pickListNumber', style: TextStyle(color: ctx.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Assign HHT Scanner Operator / Forklift Driver:', style: TextStyle(color: ctx.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: newCode,
              dropdownColor: ctx.bgSurfaceElevated,
              style: TextStyle(color: ctx.textPrimary),
              decoration: InputDecoration(
                labelText: 'Select HHT Operator',
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _operators.map((op) {
                return DropdownMenuItem(value: op['code'], child: Text(op['name']!));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  newCode = val;
                  newName = _operators.firstWhere((o) => o['code'] == val)['name']!;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ribbonPink),
            onPressed: () async {
              Navigator.pop(ctx);
              final remoteApi = ref.read(remoteApiProvider);
              final res = await remoteApi.reassignPickList(pickListNumber, newCode, newName);
              if (res['success'] == true) {
                _fetchPickLists();
              }
            },
            child: const Text('CONFIRM REASSIGNMENT'),
          ),
        ],
      ),
    );
  }

  void _onScanPick(String pickListNumber, String locationCode, String palletNumber) async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.scanPick(pickListNumber, locationCode, palletNumber);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Picked Pallet $palletNumber successfully!'),
        ),
      );
      _fetchPickLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePickList = pickLists.isNotEmpty ? pickLists[0] : null;
    final pickListNumber = activePickList?['pickListNumber'] ?? 'PKL26000455';
    final assignedOperator = activePickList?['assignedToName'] ?? activePickList?['pickerName'] ?? 'John (HHT Forklift Operator 1)';
    final items = (activePickList?['items'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 7 — Indent Entry, Pick List & Operator Assignment'),
          const SizedBox(height: 8),
          Text(
            'Enter shipment indent -> System auto-reserves pallets prioritizing Half (H) and Merged (M) pallets -> Assigns pick list to designated HHT Forklift Operator for directed scanning.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Indent Creation Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAISE NEW DISPATCH INDENT & ASSIGN OPERATOR',
                  style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _customerController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: const InputDecoration(labelText: 'CUSTOMER NAME'),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _itemController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: const InputDecoration(labelText: 'ITEM CODE'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.textPrimary),
                        decoration: const InputDecoration(labelText: 'REQUESTED WHEELS'),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        value: _selectedOperatorCode,
                        dropdownColor: context.bgSurfaceElevated,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'ASSIGN TO HHT OPERATOR',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _operators.map((op) {
                          return DropdownMenuItem(value: op['code'], child: Text(op['name']!));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedOperatorCode = val;
                              _selectedOperatorName = _operators.firstWhere((o) => o['code'] == val)['name']!;
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppButton(
                        text: 'RAISE INDENT & ASSIGN PICK LIST',
                        icon: Icons.list_alt,
                        isLoading: _isLoading,
                        onPressed: _onCreateIndent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Directed Pick List Execution Card
          AppCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENERATED PICK LIST ($pickListNumber) — OPTIMIZED WALK ROUTE',
                          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Assigned Operator: ', style: TextStyle(color: context.textMuted, fontSize: 12)),
                            Text(assignedOperator, style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _onReassignOperator(pickListNumber),
                              child: const Text('(Reassign)', style: TextStyle(color: AppColors.info, fontSize: 12, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: 'EXPORT EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: () {
                            exportToExcel(
                              context,
                              'Pick List $pickListNumber',
                              ['LOCATION', 'PALLET #', 'ITEM CODE', 'QTY', 'ASSIGNED TO', 'STATUS'],
                              items.map<List<String>>((i) => [
                                '${i['locationCode']}',
                                '${i['palletNumber']}',
                                '${i['itemCode']}',
                                '${i['qty']}',
                                assignedOperator,
                                i['isPicked'] == true ? 'PICKED' : 'PENDING PICK',
                              ]).toList(),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          text: 'PRINT PICK LIST',
                          icon: Icons.print_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: () {
                            PrintPreviewDialog.show(
                              context: context,
                              title: 'PICK LIST PRINT PREVIEW',
                              documentType: PrintDocumentType.jobCardSummary,
                              qrData: pickListNumber,
                              codeText: pickListNumber,
                              itemCode: 'DISPATCH PICK LIST',
                              itemDescription: 'Optimized Warehouse Picking Route Document',
                              primaryDetail: 'Indent: ${activePickList?['indentNumber'] ?? "IND26000391"}',
                              secondaryDetail: 'Customer: ${_customerController.text}',
                              metadataFields: [
                                {'PICK LIST #': pickListNumber},
                                {'INDENT #': activePickList?['indentNumber'] ?? 'IND26000391'},
                                {'DATE': DateTime.now().toIso8601String().split('T')[0]},
                                {'OPERATOR': assignedOperator},
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const StatusPill(label: 'HALF & MERGED PALLETS FIRST', variant: PillVariant.purple),
                      ],
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
                              DataCell(StatusPill(label: isPicked ? 'PICKED' : 'PENDING PICK', variant: isPicked ? PillVariant.ok : PillVariant.warn)),
                              DataCell(
                                isPicked
                                    ? const Icon(Icons.check_circle, color: AppColors.ok, size: 20)
                                    : AppButton(
                                        text: 'SCAN PICK',
                                        icon: Icons.qr_code_scanner,
                                        onPressed: () => _onScanPick(pickListNumber, loc, pal),
                                      ),
                              ),
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
