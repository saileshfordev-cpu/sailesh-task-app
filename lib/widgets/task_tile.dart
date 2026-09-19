import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _handleToggle() async {
    if (_isFlipping) return;
    setState(() => _isFlipping = true);
    await _flipCtrl.forward();
    widget.onToggle();
    await _flipCtrl.reverse();
    if (mounted) setState(() => _isFlipping = false);
  }

  Color _priorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  String _priorityLabel() {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return '🔴 High';
      case TaskPriority.medium:
        return '🟡 Medium';
      case TaskPriority.low:
        return '🟢 Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => widget.onConfirmDelete(),
      onDismissed: (_) => widget.onDeleted(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (context, child) {
            final angle = _flipAnim.value * pi;
            final isBack = angle > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isBack
                  ? Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: widget.task.isDone ? AppColors.success.withValues(alpha: 0.15) : AppColors.seed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.task.isDone ? AppColors.success : AppColors.seed, width: 1.5),
                      ),
                      child: Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: Icon(
                            widget.task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: widget.task.isDone ? AppColors.success : AppColors.seed,
                            size: 36,
                          ),
                        ),
                      ),
                    )
                  : child!,
            );
          },
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated circular checkbox
                    GestureDetector(
                      onTap: _handleToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.task.isDone ? AppColors.success : Colors.transparent,
                          border: Border.all(
                            color: widget.task.isDone ? AppColors.success : scheme.outlineVariant,
                            width: 2,
                          ),
                          boxShadow: widget.task.isDone
                              ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
                              : [],
                        ),
                        child: widget.task.isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                                    decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
                                    color: widget.task.isDone ? scheme.onSurfaceVariant : scheme.onSurface,
                                  ),
                                  child: Text(widget.task.title),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _priorityColor().withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _priorityLabel(),
                                  style: TextStyle(color: _priorityColor(), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (widget.task.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, y').format(widget.task.createdAt),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                              ),
                              if (widget.task.isDone) ...[
                                const SizedBox(width: 8),
                                FadeIn(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('✓ Done',
                                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const Spacer(),
                                // Delete button on completed tasks
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await widget.onConfirmDelete();
                                    if (confirm) widget.onDeleted();
                                  },
                                  child: ZoomIn(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 14),
                                          SizedBox(width: 3),
                                          Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
