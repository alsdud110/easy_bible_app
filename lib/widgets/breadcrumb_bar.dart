import 'package:flutter/material.dart';

// Breadcrumb 위젯
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const BreadcrumbBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onTap: items.first.onTap, // ✅ 첫 번째 아이템의 onTap 사용 (변경 없음, 이미 올바름)
            child: Icon(
              Icons.home_rounded,
              color: items.first.isActive
                  ? cs.primary
                  : cs.primary.withOpacity(0.7), // ✅ 비활성화 시 투명도 적용
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                }),
              ),
            ),
          ),
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
