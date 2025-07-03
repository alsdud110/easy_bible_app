import 'package:flutter/material.dart';

class ProfileCard extends StatefulWidget {
  final String empNm;
  final String dptNm;
  final String empNo;

  const ProfileCard({
    super.key,
    required this.empNm,
    required this.dptNm,
    required this.empNo,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _opacityAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.22 + (_opacityAnim.value - 0.85)),
              blurRadius: 14,
              offset: const Offset(3, 4),
            ),
          ],
          border: Border.all(color: cs.secondary.withOpacity(0.28), width: 1.1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.secondary.withOpacity(0.19),
              child: Icon(Icons.person, color: cs.primary, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.empNm,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.5,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      widget.dptNm,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "사번: ${widget.empNo}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                      fontSize: 13.0,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
