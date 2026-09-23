import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

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
  late TaskCategory _category;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingTask?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existingTask?.description ?? '');
    _priority = widget.existingTask?.priority ?? TaskPriority.medium;
    _category = widget.existingTask?.category ?? TaskCategory.personal;
    _dueDate = widget.existingTask?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
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
          category: _category,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
        await taskProvider.updateTask(updated);
      } else {
        await taskProvider.addTask(
          uid: uid,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          priority: _priority,
          category: _category,
          dueDate: _dueDate,
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
    final scheme = Theme.of(context).colorScheme;

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
                FadeInDown(
                  child: CustomTextField(
                    controller: _titleCtrl,
                    label: 'Title',
                    icon: Icons.title_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: CustomTextField(
                    controller: _descCtrl,
                    label: 'Description (optional)',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 20),
                // Due Date
                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Due Date', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickDueDate,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _dueDate != null ? AppColors.seed : scheme.outlineVariant,
                              width: _dueDate != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: _dueDate != null ? AppColors.seed : scheme.onSurfaceVariant, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dueDate != null
                                      ? DateFormat('EEE, MMM d, y').format(_dueDate!)
                                      : 'No due date',
                                  style: TextStyle(
                                    color: _dueDate != null ? scheme.onSurface : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (_dueDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _dueDate = null),
                                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Category
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskCategory.values.map((c) {
                          final selected = c == _category;
                          return ChoiceChip(
                            label: Text(_categoryLabel(c)),
                            avatar: Text(_categoryEmoji(c)),
                            selected: selected,
                            onSelected: (_) => setState(() => _category = c),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Priority
                FadeInDown(
                  delay: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: TaskPriority.values.map((p) {
                          final selected = p == _priority;
                          return ChoiceChip(
                            label: Text(_priorityLabel(p)),
                            avatar: CircleAvatar(backgroundColor: _priorityColor(p), radius: 8),
                            selected: selected,
                            onSelected: (_) => setState(() => _priority = p),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  child: GradientButton(
                    label: _isEditing ? 'Save Changes' : 'Add Task',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return AppColors.success;
      case TaskPriority.medium: return AppColors.warning;
      case TaskPriority.high: return AppColors.danger;
    }
  }

  String _categoryLabel(TaskCategory c) {
    switch (c) {
      case TaskCategory.personal: return 'Personal';
      case TaskCategory.work: return 'Work';
      case TaskCategory.shopping: return 'Shopping';
      case TaskCategory.health: return 'Health';
      case TaskCategory.other: return 'Other';
    }
  }

  String _categoryEmoji(TaskCategory c) {
    switch (c) {
      case TaskCategory.personal: return '👤';
      case TaskCategory.work: return '💼';
      case TaskCategory.shopping: return '🛒';
      case TaskCategory.health: return '❤️';
      case TaskCategory.other: return '📌';
    }
  }
}
