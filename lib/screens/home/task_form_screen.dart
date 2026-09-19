import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

/// Single screen for both Create and Update — when [existingTask] is
/// provided the form is pre-filled and saving calls `updateTask`, otherwise
/// it calls `addTask`.
class TaskFormScreen extends StatefulWidget {
  final TaskModel? existingTask;
  const TaskFormScreen({super.key, this.existingTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingTask?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existingTask?.description ?? '');
    _priority = widget.existingTask?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final taskProvider = context.read<TaskProvider>();
      if (_isEditing) {
        final updated = widget.existingTask!.copyWith(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          priority: _priority,
        );
        await taskProvider.updateTask(updated);
      } else {
        await taskProvider.addTask(
          uid: uid,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          priority: _priority,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save task. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _titleCtrl,
                  label: 'Title',
                  icon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descCtrl,
                  label: 'Description (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: TaskPriority.values.map((p) {
                    final selected = p == _priority;
                    return ChoiceChip(
                      label: Text(_labelFor(p)),
                      selected: selected,
                      avatar: CircleAvatar(backgroundColor: _colorFor(p)),
                      onSelected: (_) => setState(() => _priority = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: _isEditing ? 'Save Changes' : 'Add Task',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color _colorFor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.accent;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.danger;
    }
  }
}
