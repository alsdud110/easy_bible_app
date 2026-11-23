import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plan_progress.dart';
import '../providers/plan_progress_provider.dart';

/// 성경일독 리스트 위(AppBar bottom)에 붙는 진행률: "N / 전체일 완료" + 막대
class PlanProgressHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const PlanProgressHeader({super.key, required this.type});

  final PlanType type;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<PlanProgressProvider>();
    final done = provider.getCompletedDaysCount(type);
    final percent = provider.getProgressPercent(type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$done / ${type.totalDays}일 완료',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: provider.getProgressPercentage(type),
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}
