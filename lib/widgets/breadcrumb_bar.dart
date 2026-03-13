import 'package:flutter/material.dart';

// Breadcrumb 위젯
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final String? versionLabel;
  final VoidCallback? onVersionTap;

  const BreadcrumbBar({
    super.key,
    required this.items,
    this.versionLabel,
    this.onVersionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 홈 아이콘
          GestureDetector(
            onTap: items.first.onTap,
            child: Icon(
              Icons.home_rounded,
              color: items.first.isActive
                  ? cs.primary
                  : cs.primary.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Breadcrumb 아이템들
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(items.length - 1, (index) {
                  final item = items[index + 1];
                  return Row(
                    children: [
                      Icon(
                        Icons.chevron_right,
                        color: cs.onSurface.withOpacity(0.4),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: item.isActive
                                ? cs.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: item.isActive
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.7),
                              fontWeight: item.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  );
                }),
              ),
            ),
          ),
          // 버전 선택 칩
          if (versionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onVersionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      versionLabel!,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  BreadcrumbItem({
    required this.label,
    this.onTap,
    this.isActive = false,
  });
}
