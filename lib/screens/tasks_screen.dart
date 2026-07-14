import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state_provider.dart';
import '../models/task.dart';
import '../widgets/custom_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final activeTasks = state.tasks.where((t) => t.status != 'Completed').toList();
    final completedTasks = state.tasks.where((t) => t.status == 'Completed').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        appBar: AppBar(
          title: const Text('My Work Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          backgroundColor: const Color(0xff4f46e5),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xffc7d2fe),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Active Tasks'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTaskList(context, activeTasks, false),
            _buildTaskList(context, completedTasks, true),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> list, bool isCompletedTab) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                isCompletedTab ? 'No completed tasks yet.' : 'All caught up! No active tasks.',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: list.length,
      separatorBuilder: (context, i) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final t = list[i];
        return _TaskCardItem(task: t);
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }
}

class _TaskCardItem extends StatefulWidget {
  final Task task;
  const _TaskCardItem({required this.task});

  @override
  State<_TaskCardItem> createState() => _TaskCardItemState();
}

class _TaskCardItemState extends State<_TaskCardItem> {
  final _picker = ImagePicker();
  final _remarksController = TextEditingController();
  bool _completing = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _triggerCompleteFlow() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Ask for Remarks first inside a dialog
    final remarks = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Task Remarks'),
        content: TextField(
          controller: _remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observations / Deliverables Done',
            hintText: 'e.g., Audited books, principal interviewed.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff10b981)),
            onPressed: () {
              Navigator.pop(ctx, _remarksController.text.trim());
            },
            child: const Text('Proceed to Photo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (remarks == null || remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks are required to close tasks.')),
      );
      return;
    }

    // Capture task completion selfie to prove active field execution
    final XFile? selfie = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task closure verification photo is required.')),
      );
      return;
    }

    setState(() {
      _completing = true;
    });

    try {
      final Uint8List bytes = await selfie.readAsBytes();
      final res = await state.completeTask(
        taskId: widget.task.id,
        remarks: remarks,
        selfieBytes: bytes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
    } finally {
      setState(() {
        _completing = false;
        _remarksController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final state = Provider.of<AppStateProvider>(context, listen: false);

    Color priorityColor;
    switch (t.priority) {
      case 'Urgent':
        priorityColor = Colors.red.shade700;
        break;
      case 'High':
        priorityColor = Colors.orange.shade700;
        break;
      case 'Medium':
        priorityColor = Colors.blue.shade700;
        break;
      default:
        priorityColor = Colors.grey.shade700;
    }

    final bool isCompleted = t.status == 'Completed';
    final bool isProgress = t.status == 'In Progress';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${t.priority} Priority',
                  style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              StatusBadge(
                label: t.status,
                type: isCompleted
                    ? 'success'
                    : isProgress
                        ? 'info'
                        : 'warning',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a)),
          ),
          const SizedBox(height: 4),
          Text(
            t.description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const Divider(height: 24),
          InfoRow(label: 'Due Date', value: '${t.dueDate} @ ${t.dueTime}', icon: Icons.calendar_today_outlined),
          
          if (t.calculatedDurationMinutes != null)
            InfoRow(label: 'Time Worked', value: '${t.calculatedDurationMinutes} mins', icon: Icons.timer_outlined),

          if (!isCompleted) ...[
            const SizedBox(height: 16),
            _completing
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isProgress ? Colors.amber.shade700 : const Color(0xff4f46e5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(isProgress ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                          label: Text(isProgress ? 'Pause Task' : 'Start Task', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => state.toggleTaskStatus(t.id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10b981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _triggerCompleteFlow,
                        ),
                      ),
                    ],
                  ),
          ] else ...[
            if (t.remarks.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                'Completion Remarks:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                t.remarks,
                style: const TextStyle(fontSize: 13, color: Color(0xff334155), fontStyle: FontStyle.italic),
              ),
            ],
            if (t.completionSelfies.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  t.completionSelfies.first,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ]
          ]
        ],
      ),
    );
  }
}
