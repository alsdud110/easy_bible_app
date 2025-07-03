import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final double height;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.title,
    required this.iconData,
    this.height = 98,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.background.withOpacity(0.15),
            cs.surface.withOpacity(0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cs.surface.withOpacity(0.10),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: cs.surface.withOpacity(0.13),
                child: Icon(iconData, color: cs.primary, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.32)),
            ],
          ),
        ),
      ),
    );
  }
}
