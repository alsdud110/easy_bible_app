import 'package:flutter/material.dart';

class PlanExpansionCard extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;
  final void Function(int planType) onPlanTap;

  const PlanExpansionCard({
    super.key,
    required this.expanded,
    required this.onTap,
    required this.onPlanTap,
  });

  @override
  State<PlanExpansionCard> createState() => _PlanExpansionCardState();
}

class _PlanExpansionCardState extends State<PlanExpansionCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      decoration: BoxDecoration(
        // "우드" 감성: gradient는 거의 투명하게!
        gradient: LinearGradient(
          colors: [
            cs.surface.withOpacity(0.32),
            cs.surface.withOpacity(0.64),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.10),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
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
                  Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: cs.onSurface.withOpacity(0.33),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeInOutCubic,
            child: widget.expanded
                ? _buildPlans(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        _fadeInBtn(
          context,
          "DAY60 플랜",
          cs.primary, // 테두리(동일)
          cs.surface, // 배경
          cs.primary, // 진한 텍스트
          () => widget.onPlanTap(60),
          delay: 0,
        ),
        _fadeInBtn(
          context,
          "DAY120 플랜",
          cs.primary, // 테두리(동일)
          cs.surface, // 배경
          cs.primary, // 진한 텍스트
          () => widget.onPlanTap(120),
          delay: 70,
        ),
        _fadeInBtn(
          context,
          "DAY180 플랜",
          cs.primary, // 테두리(동일)
          cs.surface, // 배경
          cs.primary, // 진한 텍스트
          () => widget.onPlanTap(180),
          delay: 140,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _fadeInBtn(
    BuildContext context,
    String title,
    Color borderColor,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    int delay = 0,
  }) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.expanded ? 1 : 0),
      duration: Duration(milliseconds: 220 + delay),
      curve: Curves.easeIn,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: borderColor.withOpacity(0.14),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              onPressed: onTap,
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
