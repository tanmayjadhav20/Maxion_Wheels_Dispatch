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

class JobCardReportScreen extends ConsumerStatefulWidget {
  const JobCardReportScreen({super.key});

  @override
  ConsumerState<JobCardReportScreen> createState() => _JobCardReportScreenState();
}

class _JobCardReportScreenState extends ConsumerState<JobCardReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic>? _jobCards = [];
  List<dynamic> get jobCards => _jobCards ?? [];

  List<dynamic>? _pendingPallets = [];
  List<dynamic> get pendingPallets => _pendingPallets ?? [];

  List<dynamic>? _variancePallets = [];
  List<dynamic> get variancePallets => _variancePallets ?? [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchJobCards();
  }

  void _fetchJobCards() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/job-cards');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _jobCards = (res['jobCards'] as List<dynamic>?) ?? [];
        _pendingPallets = (res['pendingBookingReport'] as List<dynamic>?) ?? [];
        _variancePallets = (res['varianceReport'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onGenerateJobCard() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/job-cards/generate', {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'shift': 'A',
      'line': 'PL2',
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Job Card generated successfully!'),
        ),
      );
      _fetchJobCards();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(res['message'] ?? 'Generation failed'),
        ),
      );
    }
  }

  void _onApproveJobCard(String jobCardNumber) async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/job-cards/approve', {
      'jobCardNumber': jobCardNumber,
      'approvedBy': 'Dispatch Head',
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Job Card approved!'),
        ),
      );
      _fetchJobCards();
    }
  }

  void _onSubmitJobCard(String jobCardNumber) async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/job-cards/submit', {
      'jobCardNumber': jobCardNumber,
      'maxionBookingRef': 'MXN-ERP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Submitted to Maxion ERP Stock Booking!'),
        ),
      );
      _fetchJobCards();
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
                          const SectionTitle(title: 'Module 13 — Job Card Report for Stock Booking (SSR Section 9)'),
                          const SizedBox(height: 4),
                          Text(
                            'Full pallet production (P pallets & PM-Full pallets) is collected automatically at shift end for SAP stock booking. Excludes half pallets.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: '+ GENERATE SHIFT JOB CARD (JC...)',
                      variant: AppButtonVariant.gradient,
                      onPressed: _onGenerateJobCard,
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Module 13 — Job Card Report for Stock Booking (SSR Section 9)'),
                  const SizedBox(height: 4),
                  Text(
                    'Full pallet production (P pallets & PM-Full pallets) is collected automatically at shift end for SAP stock booking. Excludes half pallets.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: '+ GENERATE SHIFT JOB CARD (JC...)',
                    variant: AppButtonVariant.gradient,
                    onPressed: _onGenerateJobCard,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.ribbonPink,
            labelColor: AppColors.ribbonPink,
            unselectedLabelColor: context.textMuted,
            tabs: [
              Tab(icon: const Icon(Icons.assignment_outlined), text: 'JOB CARDS REGISTER (${jobCards.length})'),
              Tab(icon: const Icon(Icons.pending_actions_outlined), text: 'PENDING BOOKING REPORT (${pendingPallets.length})'),
              Tab(icon: const Icon(Icons.warning_amber_outlined), text: 'VARIANCE REPORT (${variancePallets.length})'),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 580,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Job Cards Register
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
                    : jobCards.isEmpty
                        ? AppCard(child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No Job Card reports generated yet.', style: TextStyle(color: context.textMuted)))))
                        : ListView.builder(
                            itemCount: jobCards.length,
                            itemBuilder: (ctx, i) {
                              final jc = jobCards[i];
                              final status = jc['status'] ?? 'DRAFT';
                              final isSubmitted = status == 'SUBMITTED_TO_MAXION';
                              final isApproved = status == 'APPROVED';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AppCard(
                                  showGlow: isSubmitted,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.assignment_outlined, color: AppColors.ribbonPink, size: 24),
                                              const SizedBox(width: 12),
                                              Text(
                                                jc['jobCardNumber'] ?? '',
                                                style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                              ),
                                              const SizedBox(width: 12),
                                              StatusPill(
                                                label: isSubmitted
                                                    ? 'SUBMITTED TO MAXION'
                                                    : isApproved
                                                        ? 'APPROVED'
                                                        : 'DRAFT REPORT',
                                                variant: isSubmitted
                                                    ? PillVariant.ok
                                                    : isApproved
                                                        ? PillVariant.info
                                                        : PillVariant.warn,
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
                                                    'Job Card ${jc['jobCardNumber']}',
                                                    ['JOB CARD #', 'DATE', 'SHIFT', 'FULL PALLETS', 'TOTAL WHEELS', 'STATUS', 'MAXION REF'],
                                                    [
                                                      ['${jc['jobCardNumber']}', '${jc['date']}', '${jc['shift']}', '${jc['fullPalletsCount']}', '${jc['totalWheels']}', '${jc['status']}', '${jc['maxionBookingRef'] ?? "Pending"}'],
                                                    ],
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              AppButton(
                                                text: 'PRINT JOB CARD',
                                                icon: Icons.print_outlined,
                                                variant: AppButtonVariant.ghost,
                                                onPressed: () {
                                                  PrintPreviewDialog.show(
                                                    context: context,
                                                    title: 'JOB CARD REPORT PRINT PREVIEW',
                                                    documentType: PrintDocumentType.jobCardSummary,
                                                    qrData: jc['jobCardNumber'] ?? 'JC260822A',
                                                    codeText: jc['jobCardNumber'] ?? 'JC260822A',
                                                    itemCode: 'STOCK BOOKING JOB CARD',
                                                    itemDescription: 'Full Pallet Production Report for Stock Booking',
                                                    primaryDetail: 'Full Pallets: ${jc['fullPalletsCount']} • Total Wheels: ${jc['totalWheels']}',
                                                    secondaryDetail: 'Status: ${jc['status']}',
                                                    metadataFields: [
                                                      {'JOB CARD #': jc['jobCardNumber'] ?? ''},
                                                      {'DATE': jc['date'] ?? ''},
                                                      {'SHIFT': jc['shift'] ?? 'A'},
                                                      {'PREPARED BY': jc['submittedBy'] ?? 'Supervisor'},
                                                    ],
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              if (status == 'DRAFT')
                                                AppButton(
                                                  text: 'APPROVE',
                                                  variant: AppButtonVariant.secondary,
                                                  onPressed: () => _onApproveJobCard(jc['jobCardNumber']),
                                                ),
                                              if (isApproved)
                                                AppButton(
                                                  text: 'SUBMIT TO MAXION ERP',
                                                  variant: AppButtonVariant.gradient,
                                                  onPressed: () => _onSubmitJobCard(jc['jobCardNumber']),
                                                ),
                                              if (isSubmitted)
                                                Text(
                                                  'MAXION REF: ${jc['maxionBookingRef'] ?? ''}',
                                                  style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700, fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(color: Theme.of(context).dividerColor),
                                      const SizedBox(height: 12),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Date: ${jc['date']} (Shift ${jc['shift']})', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                                          Text('Full Pallets: ${jc['fullPalletsCount']}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                                          Text('Total Wheels: ${jc['totalWheels']}', style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w800)),
                                          Text('Prepared By: ${jc['submittedBy'] ?? "Supervisor"}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // HALF PALLETS NOTE (Section 9.1)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: context.bgSurfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Theme.of(context).dividerColor),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'HALF PALLETS NOTE: Half pallets produced in the same period are shown separately for information and are NOT part of the stock booking figure.',
                                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                // Tab 2: Pending Booking Report
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PENDING BOOKING REPORT — FULL PALLETS PRODUCED BUT NOT YET BOOKED',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text('This report prevents production from going unbooked in ERP:', style: TextStyle(color: context.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('PALLET #')),
                            DataColumn(label: Text('TYPE')),
                            DataColumn(label: Text('ITEM CODE')),
                            DataColumn(label: Text('PACKED QTY')),
                            DataColumn(label: Text('LOCATION')),
                          ],
                          rows: pendingPallets.map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p['palletNumber'] ?? '')),
                              DataCell(StatusPill(label: p['typeSeries'] ?? 'P', variant: PillVariant.info)),
                              DataCell(Text(p['itemCode'] ?? '')),
                              DataCell(Text('${p['packedQty']}/${p['stdQty'] ?? 96}')),
                              DataCell(Text(p['locationCode'] ?? 'WH1-STG-01')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab 3: Variance Report
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JOB CARD VARIANCE REPORT — REPORTED PALLETS MODIFIED BY QA / CONVERSION',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text('Pallets that were booked on a Job Card and later opened by QA or split for SPD:', style: TextStyle(color: context.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('PALLET #')),
                            DataColumn(label: Text('ITEM CODE')),
                            DataColumn(label: Text('CURRENT STATUS')),
                            DataColumn(label: Text('REASON / POINTER')),
                          ],
                          rows: variancePallets.map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p['palletNumber'] ?? '')),
                              DataCell(Text(p['itemCode'] ?? '')),
                              DataCell(StatusPill(label: p['status'] ?? '', variant: PillVariant.danger)),
                              DataCell(Text(p['closedAs'] ?? p['closeReason'] ?? 'Opened by QA')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
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
