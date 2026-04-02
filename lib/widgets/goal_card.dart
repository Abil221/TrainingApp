import 'package:flutter/material.dart';
import '../models/user_goal.dart';

class GoalCard extends StatelessWidget {
  final UserGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (goal.progress * 100).toStringAsFixed(0);
    final isCompleted = goal.isCompleted;
    final isOverdue = goal.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.shade50
              : isOverdue
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
          border: Border.all(
            color: isCompleted
                ? Colors.green
                : isOverdue
                    ? Colors.red
                    : Colors.blue.shade200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.goalType.displayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompleted)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Изменить'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue.toStringAsFixed(1)} ${goal.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '→ ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  isCompleted
                      ? Colors.green
                      : isOverdue
                          ? Colors.red
                          : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$progressPercent% выполнено',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  isCompleted
                      ? '✓ Выполнено'
                      : 'Осталось ${goal.daysRemaining} дней',
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.green
                        : isOverdue
                            ? Colors.red
                            : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
