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
  final _customerController = TextEditingController();
  String? _selectedItemCode;
  final _qtyController = TextEditingController(text: '4');
  String? _selectedOperatorCode;
  String? _selectedOperatorName;

  List<dynamic>? _pickLists = [];
  List<dynamic> get pickLists => _pickLists ?? [];
  bool _isLoading = false;
  int _selectedPickListIndex = 0;

  List<Map<String, String>> _availableItems = [];
  List<Map<String, String>> _operators = [];
  List<Map<String, String>> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    _fetchPickLists();
  }

  Future<void> _loadMasterData() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      
      // Load items
      final itemsRes = await remoteApi.getItemsMaster();
      if (itemsRes['success'] == true && itemsRes['items'] != null) {
        final rawItems = itemsRes['items'] as List<dynamic>;
        setState(() {
          _availableItems = rawItems.map((i) {
            final code = (i['itemCode'] ?? '').toString();
            final desc = (i['description'] ?? '').toString();
            final source = (i['source'] ?? '').toString();
            final suffix = source == 'PAINT_PLAN' 
                ? ' [PLANNED]' 
                : (source == 'WAREHOUSE' ? ' [IN STOCK]' : (source == 'ERP_INVOICE' ? ' [SAP INVOICE]' : ''));
            return {
              'code': code,
              'label': '$code ($desc)$suffix',
            };
          }).toList();
          if (_availableItems.isNotEmpty && _selectedItemCode == null) {
            _selectedItemCode = _availableItems.first['code'];
          }
        });
      }

      // Load users/operators
      final usersRes = await remoteApi.getUsersMaster();
      if (usersRes['success'] == true && usersRes['users'] != null) {
        final rawUsers = usersRes['users'] as List<dynamic>;
        setState(() {
          _operators = rawUsers.map((u) => {
            'code': (u['employeeCode'] ?? '').toString(),
            'name': '${u['name']} (${u['employeeCode']})',
          }).toList();
          if (_operators.isNotEmpty && _selectedOperatorCode == null) {
            _selectedOperatorCode = _operators.first['code'];
            _selectedOperatorName = _operators.first['name'];
          }
        });
      }

      // Load customers
      final custRes = await remoteApi.getCustomersMaster();
      if (custRes['success'] == true && custRes['customers'] != null) {
        final rawCust = custRes['customers'] as List<dynamic>;
        setState(() {
          _customers = rawCust.map((c) => {
            'code': (c['customerCode'] ?? '').toString(),
            'name': (c['customerName'] ?? '').toString(),
            'address': (c['shipToAddress'] ?? '').toString(),
          }).toList();
          if (_customers.isNotEmpty && _customerController.text.isEmpty) {
            _customerController.text = _customers.first['name'] ?? '';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPickLists() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/picking/pick-lists');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _pickLists = (res['pickLists'] as List<dynamic>?) ?? [];
        if (_selectedPickListIndex >= (_pickLists?.length ?? 0)) {
          _selectedPickListIndex = 0;
        }
      });
    }
  }

  void _onCreateIndent() async {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 4;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.danger, content: Text('Please enter a valid requested quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.createIndent({
      'customerName': _customerController.text.trim(),
      'assignedToCode': _selectedOperatorCode,
      'assignedToName': _selectedOperatorName,
      'items': [
        {'itemCode': _selectedItemCode, 'requestedQty': qty}
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
      setState(() => _selectedPickListIndex = 0);
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
    String newCode = _selectedOperatorCode ?? (_operators.isNotEmpty ? _operators.first['code'] ?? '' : '');
    String newName = _selectedOperatorName ?? (_operators.isNotEmpty ? _operators.first['name'] ?? '' : '');

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
              initialValue: newCode.isNotEmpty ? newCode : null,
              isExpanded: true,
              dropdownColor: ctx.bgSurfaceElevated,
              style: TextStyle(color: ctx.textPrimary),
              decoration: InputDecoration(
                labelText: 'Select HHT Operator',
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _operators.map((op) {
                return DropdownMenuItem(value: op['code'], child: Text(op['name'] ?? '', overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  newCode = val;
                  final match = _operators.firstWhere((o) => o['code'] == val, orElse: () => {'name': val});
                  newName = match['name'] ?? val;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          AppButton(
            text: 'CONFIRM REASSIGNMENT',
            variant: AppButtonVariant.gradient,
            onPressed: () async {
              Navigator.pop(ctx);
              final remoteApi = ref.read(remoteApiProvider);
              final res = await remoteApi.reassignPickList(pickListNumber, newCode, newName);
              if (res['success'] == true) {
                _fetchPickLists();
              }
            },
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
    final activePickList = pickLists.isNotEmpty && _selectedPickListIndex < pickLists.length ? pickLists[_selectedPickListIndex] : (pickLists.isNotEmpty ? pickLists[0] : null);
    final pickListNumber = activePickList?['pickListNumber'] ?? 'PKL26000455';
    final assignedOperator = activePickList?['assignedToName'] ?? activePickList?['pickerName'] ?? 'John (HHT Forklift Operator 1)';
    final items = (activePickList?['items'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
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
                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final isNarrow = cardConstraints.maxWidth < 600;
                    final fieldWidth = (double targetWidth) => isNarrow ? double.infinity : targetWidth;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: fieldWidth(240),
                          child: TextField(
                            controller: _customerController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: const InputDecoration(labelText: 'CUSTOMER NAME'),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth(240),
                          child: DropdownButtonFormField<String>(
                            value: _selectedItemCode,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'SELECT ITEM CODE',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _availableItems.map((item) {
                              return DropdownMenuItem(
                                value: item['code'],
                                child: Text(item['label']!, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedItemCode = val);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth(160),
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: context.textPrimary),
                            decoration: const InputDecoration(labelText: 'REQUESTED WHEELS'),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth(260),
                          child: DropdownButtonFormField<String>(
                            value: _selectedOperatorCode,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'ASSIGN TO HHT OPERATOR',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _operators.map((op) {
                              return DropdownMenuItem(value: op['code'], child: Text(op['name']!, overflow: TextOverflow.ellipsis));
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
                        SizedBox(
                          width: isNarrow ? double.infinity : null,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AppButton(
                              text: 'RAISE INDENT & ASSIGN PICK LIST',
                              icon: Icons.list_alt,
                              isLoading: _isLoading,
                              onPressed: _onCreateIndent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'PICK LIST: $pickListNumber',
                              style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 12),
                            StatusPill(
                              label: activePickList?['status'] ?? 'OPEN',
                              variant: activePickList?['status'] == 'COMPLETED' ? PillVariant.ok : PillVariant.warn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text('Indent: ', style: TextStyle(color: context.textMuted, fontSize: 12)),
                            Text(activePickList?['indentNumber'] ?? 'IND26000391', style: TextStyle(color: context.infoInk, fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(width: 12),
                            Text('Assigned Operator: ', style: TextStyle(color: context.textMuted, fontSize: 12)),
                            Text(assignedOperator, style: TextStyle(color: context.brandInk, fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _onReassignOperator(pickListNumber),
                              child: Text('(Reassign)', style: TextStyle(color: context.infoInk, fontSize: 12, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (pickLists.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderLine),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 18),
                                  tooltip: 'Previous Pick List',
                                  color: _selectedPickListIndex > 0 ? AppColors.ribbonPink : context.textMuted.withValues(alpha: 0.3),
                                  onPressed: _selectedPickListIndex > 0
                                      ? () => setState(() => _selectedPickListIndex--)
                                      : null,
                                ),
                                DropdownButton<int>(
                                  value: _selectedPickListIndex,
                                  underline: const SizedBox(),
                                  dropdownColor: context.bgSurfaceElevated,
                                  style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                  items: List.generate(pickLists.length, (idx) {
                                    final pl = pickLists[idx];
                                    return DropdownMenuItem<int>(
                                      value: idx,
                                      child: Text('${pl['pickListNumber']} (${pl['indentNumber']})'),
                                    );
                                  }),
                                  onChanged: (idx) {
                                    if (idx != null) {
                                      setState(() => _selectedPickListIndex = idx);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 18),
                                  tooltip: 'Next Pick List',
                                  color: _selectedPickListIndex < pickLists.length - 1 ? AppColors.ribbonPink : context.textMuted.withValues(alpha: 0.3),
                                  onPressed: _selectedPickListIndex < pickLists.length - 1
                                      ? () => setState(() => _selectedPickListIndex++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
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
                    : items.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderLine),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, color: context.textMuted, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  'No pallets currently allocated for $pickListNumber',
                                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All warehouse pallets for this item were already picked, or select another Pick List from the dropdown.',
                                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          )
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
                                  DataCell(Text(pal, style: TextStyle(color: context.brandInk, fontWeight: FontWeight.w700))),
                                  DataCell(Text('${i['itemCode'] ?? "MXW-17-BLK"}')),
                                  DataCell(Text('${i['qty'] ?? 4}')),
                                  DataCell(StatusPill(label: isPicked ? 'PICKED' : 'PENDING PICK', variant: isPicked ? PillVariant.ok : PillVariant.warn)),
                                  DataCell(
                                    isPicked
                                        ? Icon(Icons.check_circle, color: context.okInk, size: 20)
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
