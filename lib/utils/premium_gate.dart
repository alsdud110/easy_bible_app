import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription/paywall_screen.dart';

/// 프리미엄 전용 성경 번역본으로 전환하기 전에 호출하는 공용 게이트.
///
/// - 잠긴 번역본이 아니거나, 이미 구독 중이면 true를 즉시 반환 → 그대로 전환 진행
/// - 잠긴 번역본인데 구독 중이 아니면, 구독 유도 바텀시트를 띄우고 false를 반환
///   (호출부는 false면 실제 언어 전환을 하지 않아야 함)
Future<bool> ensureBibleLanguageUnlocked(
  BuildContext context,
  BibleLanguage language,
) async {
  if (!language.isPremiumOnly) return true;

  final isPremium = context.read<SubscriptionProvider>().isPremium;
  if (isPremium) return true;

  if (!context.mounted) return false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PremiumLanguageSheet(language: language),
  );

  return false;
}

class _PremiumLanguageSheet extends StatelessWidget {
  final BibleLanguage language;
  const _PremiumLanguageSheet({required this.language});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        // 바텀시트 하단이 제스처 바/네비게이션 바에 가려지지 않도록
        // 시스템 인셋만큼 여백을 더 확보 (custom_drawer.dart의 처리 방식과 동일)
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.workspace_premium_rounded,
                  color: cs.primary, size: 40),
              const SizedBox(height: 12),
              Text(
                '${language.displayName}은(는) 프리미엄 전용이에요',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '프리미엄을 구독하면 추가 번역본을 자유롭게 읽을 수 있어요.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(),
                      ),
                    );
                  },
                  child: const Text('프리미엄 알아보기'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('나중에'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
