import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_tile.dart';
import '../settings/settings_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _deleteWithUndo(BuildContext context, TaskModel task) async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.deleteTask(task);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.undoDelete(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSortSheet(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...TaskSort.values.map((s) => RadioListTile<TaskSort>(
                  title: Text(_sortLabel(s)),
                  secondary: Icon(_sortIcon(s)),
                  value: s,
                  groupValue: taskProvider.sort,
                  onChanged: (v) {
                    taskProvider.setSort(v!);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            RadioListTile<TaskCategory?>(
              title: const Text('All Categories'),
              secondary: const Text('📋'),
              value: null,
              groupValue: taskProvider.categoryFilter,
              onChanged: (v) { taskProvider.setCategoryFilter(v); Navigator.pop(ctx); },
            ),
            ...TaskCategory.values.map((c) => RadioListTile<TaskCategory?>(
                  title: Text(_categoryLabel(c)),
                  secondary: Text(_categoryEmoji(c)),
                  value: c,
                  groupValue: taskProvider.categoryFilter,
                  onChanged: (v) { taskProvider.setCategoryFilter(v); Navigator.pop(ctx); },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final scheme = Theme.of(context).colorScheme;
    final name = auth.user?.displayName;
    final greetingName = (name != null && name.trim().isNotEmpty) ? name.split(' ').first : 'there';
    final progress = taskProvider.totalCount == 0 ? 0.0 : taskProvider.doneCount / taskProvider.totalCount;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => taskProvider.setSearch(v),
              )
            : FadeInDown(child: const Text('Sailesh Task App')),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                taskProvider.setSearch('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: () => _showSortSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Category',
            onPressed: () => _showCategorySheet(context),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
              child: Icon(
                context.watch<ThemeProvider>().isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(context.watch<ThemeProvider>().isDark(context)),
              ),
            ),
            onPressed: () => context.read<ThemeProvider>().toggle(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const SettingsScreen(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => taskProvider.bindToUser(auth.user?.uid),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          ElasticIn(
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.seed.withValues(alpha: 0.12),
                              child: Text(greetingName[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.seed, fontWeight: FontWeight.w700, fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, $greetingName 👋', style: Theme.of(context).textTheme.titleMedium),
                              Text("Let's get things done!", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        children: [
                          _StatChip(label: 'Total', value: '${taskProvider.totalCount}', color: AppColors.seed),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Done', value: '${taskProvider.doneCount}', color: AppColors.success),
                          const SizedBox(width: 8),
                          _StatChip(label: '⭐', value: '${taskProvider.starredCount}', color: AppColors.warning),
                          if (taskProvider.overdueCount > 0) ...[
                            const SizedBox(width: 8),
                            _StatChip(label: 'Overdue', value: '${taskProvider.overdueCount}', color: AppColors.danger),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Progress card
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      child: _AnimatedProgressCard(progress: progress, taskProvider: taskProvider),
                    ),
                    const SizedBox(height: 14),
                    // Filter chips
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _FilterChips(current: taskProvider.filter),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (taskProvider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (taskProvider.errorMessage != null)
              SliverFillRemaining(child: _EmptyState(icon: Icons.cloud_off_outlined, message: taskProvider.errorMessage!))
            else if (taskProvider.tasks.isEmpty)
              const SliverFillRemaining(
                child: _EmptyState(icon: Icons.checklist_rounded, message: 'No tasks here.\nTap + to add one.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: AnimationLimiter(
                  child: SliverList.builder(
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 40,
                          child: FadeInAnimation(
                            child: TaskTile(
                              task: task,
                              onToggle: () => context.read<TaskProvider>().toggleDone(task),
                              onStar: () => context.read<TaskProvider>().toggleStar(task),
                              onTap: () => Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (_, a, b) => TaskFormScreen(existingTask: task),
                                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                              ),
                              onConfirmDelete: () => _confirmDelete(context),
                              onDeleted: () => _deleteWithUndo(context, task),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ElasticIn(
        delay: const Duration(milliseconds: 400),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const TaskFormScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task'),
        ),
      ),
    );
  }

  String _sortLabel(TaskSort s) {
    switch (s) {
      case TaskSort.newest: return 'Newest first';
      case TaskSort.oldest: return 'Oldest first';
      case TaskSort.priority: return 'By priority';
      case TaskSort.dueDate: return 'By due date';
    }
  }

  IconData _sortIcon(TaskSort s) {
    switch (s) {
      case TaskSort.newest: return Icons.arrow_downward_rounded;
      case TaskSort.oldest: return Icons.arrow_upward_rounded;
      case TaskSort.priority: return Icons.flag_rounded;
      case TaskSort.dueDate: return Icons.calendar_today_rounded;
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AnimatedProgressCard extends StatefulWidget {
  final double progress;
  final TaskProvider taskProvider;
  const _AnimatedProgressCard({required this.progress, required this.taskProvider});

  @override
  State<_AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<_AnimatedProgressCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressCard old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: old.progress, end: widget.progress)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Progress", style: Theme.of(context).textTheme.titleMedium),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Text('${(_anim.value * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.seed, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${widget.taskProvider.doneCount} of ${widget.taskProvider.totalCount} tasks completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _anim.value,
                  minHeight: 10,
                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progress == 1.0 ? AppColors.success : AppColors.seed,
                  ),
                ),
              ),
            ),
            if (widget.progress == 1.0 && widget.taskProvider.totalCount > 0) ...[
              const SizedBox(height: 10),
              BounceInDown(
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text('All tasks completed! 🎉',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TaskFilter current;
  const _FilterChips({required this.current});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TaskFilter value) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: current == value,
          onSelected: (_) => context.read<TaskProvider>().setFilter(value),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', TaskFilter.all),
          chip('Active', TaskFilter.active),
          chip('Done', TaskFilter.done),
          chip('⭐ Starred', TaskFilter.starred),
          chip('⚠️ Overdue', TaskFilter.overdue),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BounceInDown(child: Icon(icon, size: 72, color: scheme.onSurfaceVariant.withValues(alpha: 0.35))),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(message, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
