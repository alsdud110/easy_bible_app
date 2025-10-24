import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_progress_provider.dart';
import '../models/plan_progress.dart';

class PlanExpansionCard extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;
  final void Function(BuildContext context, int planType) onPlanTap;

  const PlanExpansionCard({
    super.key,
    required this.expanded,
    required this.onTap,
    required this.onPlanTap,
  });

  @override
  State<PlanExpansionCard> createState() => _PlanExpansionCardState();
}

class _PlanExpansionCardState extends State<PlanExpansionCard>
    with TickerProviderStateMixin {
  late final AnimationController _boxFadeCtrl;
  late final Animation<double> _boxFadeAnim;

  @override
  void initState() {
    super.initState();
    _boxFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    _boxFadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _boxFadeCtrl, curve: Curves.easeInOut));
    if (widget.expanded) _boxFadeCtrl.value = 1;
  }

  @override
  void didUpdateWidget(covariant PlanExpansionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      _boxFadeCtrl.forward(from: 0);
    } else if (!widget.expanded && oldWidget.expanded) {
      _boxFadeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _boxFadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            child: Container(
              height: 98,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: cs.primary.withOpacity(0.12),
                    child: Icon(Icons.calendar_month_outlined,
                        color: cs.primary, size: 32),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      '성경일독(플랜)',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.ease,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: cs.onSurface.withOpacity(0.33),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SizeTransition으로 부드러운 확장/축소
          SizeTransition(
            sizeFactor: _boxFadeAnim,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _boxFadeAnim,
              child: _buildPlans(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titles = ["DAY60 플랜", "DAY120 플랜", "DAY180 플랜"];
    final values = [60, 120, 180];
    final planTypes = [PlanType.day60, PlanType.day120, PlanType.day180];

    return Consumer<PlanProgressProvider>(
      builder: (context, planProvider, _) {
        return Column(
          children: [
            ...List.generate(titles.length, (i) {
              // 이 타입의 플랜이 있는지 확인
              final isCurrentPlan = planProvider.hasPlan(planTypes[i]);
              final progressPercent =
                  isCurrentPlan ? planProvider.getProgressPercent(planTypes[i]) : 0;

              return AnimatedBuilder(
                animation: _boxFadeCtrl,
                builder: (context, child) {
                  // 각 버튼마다 약간의 지연 효과
                  final delay = i * 0.15;
                  final progress =
                      (_boxFadeCtrl.value - delay).clamp(0.0, 1.0) / (1 - delay);

                  return Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.97 + progress * 0.03,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            children: [
                              // 물 차오르는 배경 애니메이션
                              if (isCurrentPlan)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 800),
                                        curve: Curves.easeInOut,
                                        height: (progressPercent / 100) *
                                            56, // 버튼 높이 기준
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              cs.primary.withOpacity(0.15),
                                              cs.primary.withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // 버튼 본체
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: cs.primary,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isCurrentPlan
                                          ? cs.primary.withOpacity(0.3)
                                          : cs.primary.withOpacity(0.16),
                                      width: isCurrentPlan ? 1.5 : 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 16),
                                  textStyle: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () => widget.onPlanTap(context, values[i]),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        titles[i],
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentPlan) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withOpacity(0.15),
                                          border: Border.all(
                                            color: cs.primary.withOpacity(0.35),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '진행중 $progressPercent%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
