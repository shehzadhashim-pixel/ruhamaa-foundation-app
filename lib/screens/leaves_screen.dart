import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedLeaveType = 'Casual Leave';
  final _reasonController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Annual Leave',
    'Emergency Leave',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xff4f46e5),
            colorScheme: const ColorScheme.light(primary: Color(0xff4f46e5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave start and end dates.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final String startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final String endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    try {
      final res = await state.submitLeaveRequest(
        leaveType: _selectedLeaveType,
        startDate: startStr,
        endDate: endStr,
        reason: _reasonController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(res['success'] ? 'Success' : 'Failed'),
          content: Text(res['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (res['success']) {
                  _resetForm();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _reasonController.clear();
      _startDate = null;
      _endDate = null;
      _selectedLeaveType = 'Casual Leave';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final balance = state.leaveBalance;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('Leave Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Balance Cards
            const Text(
              'My Leave Balance',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
            ),
            const SizedBox(height: 12),
            _buildBalanceGrid(balance),
            const SizedBox(height: 24),

            // Leave Request Form Card
            CustomCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apply for Leave',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a)),
                    ),
                    const Divider(height: 24),

                    // Leave Type Selection
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: const InputDecoration(labelText: 'Leave Category'),
                      items: _leaveTypes.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLeaveType = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date range picker trigger
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_outlined, color: Color(0xff4f46e5)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _startDate == null
                                    ? 'Select Leave Date Range'
                                    : '${DateFormat('MMM dd').format(_startDate!)}  to  ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                                style: TextStyle(
                                  color: _startDate == null ? Colors.grey.shade500 : const Color(0xff1e293b),
                                  fontWeight: _startDate == null ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason Field
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Justification / Reason'),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Reason of leave is required' : null,
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Submit Leave Application',
                      icon: Icons.send_outlined,
                      backgroundColor: const Color(0xff4f46e5),
                      onPressed: _submitting ? null : _submitLeave,
                      isLoading: _submitting,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // History List
            const Text(
              'My Leave History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
            ),
            const SizedBox(height: 12),
            _buildLeaveHistory(state.leaves),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceGrid(dynamic balance) {
    final List<Map<String, dynamic>> items = [
      {'label': 'Casual', 'value': '${balance?.casual ?? 10}', 'color': Colors.blue},
      {'label': 'Sick', 'value': '${balance?.sick ?? 8}', 'color': Colors.red},
      {'label': 'Annual', 'value': '${balance?.annual ?? 15}', 'color': Colors.green},
      {'label': 'Emergency', 'value': '${balance?.emergency ?? 5}', 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['value'] as String,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: item['color'] as Color),
              ),
              const SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveHistory(List<dynamic> leavesList) {
    if (leavesList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text('No leave applications filed.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leavesList.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final l = leavesList[i];
        final String status = l.status;

        String type = 'info';
        if (status == 'Approved') type = 'success';
        if (status == 'Rejected') type = 'danger';
        if (status == 'Cancelled') type = 'warning';

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.leaveType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1e293b)),
                  ),
                  StatusBadge(label: status, type: type),
                ],
              ),
              const Divider(height: 16),
              InfoRow(label: 'Duration', value: '${l.startDate} to ${l.endDate}', icon: Icons.calendar_today_outlined),
              InfoRow(label: 'Reason', value: l.reason, icon: Icons.help_outline),
              if (l.supervisorComments != null && l.supervisorComments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Text(
                    'Supervisor Comments: ${l.supervisorComments}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}
