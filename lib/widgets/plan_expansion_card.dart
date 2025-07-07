import 'package:flutter/material.dart';

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
    _boxFadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _boxFadeCtrl, curve: Curves.easeIn));
    if (widget.expanded) _boxFadeCtrl.value = 1;
  }

  @override
  void didUpdateWidget(covariant PlanExpansionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      _boxFadeCtrl.forward(from: 0);
    } else if (!widget.expanded && oldWidget.expanded) {
      _boxFadeCtrl.value = 0;
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
          // Fade + 펼침
          SizeTransition(
            sizeFactor: _boxFadeAnim,
            axisAlignment: -1,
            child: (widget.expanded)
                ? FadeTransition(
                    opacity: _boxFadeAnim,
                    child: _buildPlans(context),
                  )
                : const SizedBox.shrink(),
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
    return Column(
      children: List.generate(titles.length, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.expanded ? 1 : 0),
          duration: Duration(milliseconds: 160 + i * 80),
          curve: Curves.easeIn,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.97 + value * 0.03,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.surface,
                        foregroundColor: cs.primary,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: cs.primary.withOpacity(0.16),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () => widget.onPlanTap(context, values[i]),
                      child: Text(
                        titles[i],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      })
        ..add(const SizedBox(height: 10)),
    );
  }
}
