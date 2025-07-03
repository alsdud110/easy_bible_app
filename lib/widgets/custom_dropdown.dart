import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String) onChanged;
  final double height;
  final EdgeInsetsGeometry? margin;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.height = 48,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cs.secondary.withOpacity(0.30), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () async {
            final maxSheetHeight = MediaQuery.of(context).size.height * 0.48;
            final initialIndex = items.indexOf(value);
            const itemHeight = 56.0;
            final controller = ScrollController(
              initialScrollOffset:
                  (initialIndex > 0 ? initialIndex : 0) * itemHeight,
            );

            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: maxSheetHeight,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: ListView.separated(
                    controller: controller,
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.dividerColor,
                    ),
                    itemBuilder: (context, idx) {
                      final e = items[idx];
                      final isSelected = e == value;
                      return ListTile(
                        title: Text(
                          e,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? cs.primary : cs.onSurface,
                            fontSize: 17,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, e),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        trailing: isSelected
                            ? Icon(Icons.check, color: cs.primary, size: 22)
                            : null,
                      );
                    },
                  ),
                );
              },
            );
            if (result != null && result != value) {
              onChanged(result);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.iconTheme.color ?? cs.primary.withOpacity(0.58),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
