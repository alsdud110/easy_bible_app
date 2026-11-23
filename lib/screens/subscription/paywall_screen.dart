import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/subscription_plan.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/colors.dart';

/// 프리미엄 구독 화면 (페이월)
///
/// 앱 전반의 디자인 언어(퀴즈 홈/홈 화면과 동일한 섹션 타이틀, 카드 보더,
/// 버튼 스타일 등)를 그대로 따르도록 맞췄습니다.
///
/// ⚠️ 스토어(Google Play Console / App Store Connect)에 구독 상품이 아직
/// 등록되지 않은 상태에서도 화면 자체는 정상적으로 뜨도록 만들어져 있습니다.
/// 상품이 등록되기 전까지는 가격 대신 "가격 정보 없음" 문구가 보이고,
/// 실제 상품을 등록한 뒤 lib/models/subscription_plan.dart의 productId를
/// 교체하면 이 화면은 그대로 동작합니다.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  bool _purchasing = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  static const List<_Benefit> _benefits = [
    _Benefit(
      icon: Icons.block_rounded,
      title: '광고 없이 쾌적하게',
      description: '배너/전면 광고 없이 앱을 이용할 수 있어요',
    ),
    _Benefit(
      icon: Icons.translate_rounded,
      title: '추가 성경 번역본',
      description: '표준새번역, KJV(영어) 등 프리미엄 전용 번역본을 자유롭게',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(SubscriptionProvider provider) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      await provider.purchasePlan(_selectedPlan);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.isPremium) {
            return _AlreadyPremiumView(onRestore: provider.restorePurchases);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroBanner(cs: cs, isDark: theme.brightness == Brightness.dark),
                  const SizedBox(height: 20),

                  _SectionTitle(
                    title: '프리미엄 혜택',
                    icon: Icons.auto_awesome_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),
                  ..._benefits.map((b) => _BenefitTile(benefit: b, cs: cs)),

                  const SizedBox(height: 8),
                  _SectionTitle(
                    title: '플랜 선택',
                    icon: Icons.workspace_premium_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),

                  if (!provider.storeAvailable) _StoreUnavailableNotice(cs: cs),
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        provider.errorMessage!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: CommonColors.error),
                      ),
                    ),

                  Row(
                    children: SubscriptionPlan.all
                        .map((plan) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: _PlanCard(
                                  plan: plan,
                                  product: provider.productFor(plan),
                                  selected: _selectedPlan == plan,
                                  onTap: () =>
                                      setState(() => _selectedPlan = plan),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _purchasing ? null : () => _handlePurchase(provider),
                      child: _purchasing
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Text('구독하기'),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: provider.restorePurchases,
                      child: const Text('이전 구매 복원하기'),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '구독은 언제든 스토어(Play 스토어/App Store)에서 해지할 수 있어요.',
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 상단 히어로 배너 - 홈 화면 Bento 카드와 동일한 톤(그라데이션, radius 24)
class _HeroBanner extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  const _HeroBanner({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.primary : LightColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded,
              color: Theme.of(context).colorScheme.onPrimary, size: 40),
          const SizedBox(height: 12),
          Text(
            'All in Bible 프리미엄',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '더 깊이 있는 말씀 생활을 위한 구독',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

// 섹션 타이틀 - quiz_home_screen._buildSectionTitle과 동일한 패턴(컬러바 + 아이콘 + 텍스트)
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  const _SectionTitle(
      {required this.title, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String description;
  const _Benefit(
      {required this.icon, required this.title, required this.description});
}

class _BenefitTile extends StatelessWidget {
  final _Benefit benefit;
  final ColorScheme cs;
  const _BenefitTile({required this.benefit, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(benefit.icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    benefit.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
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

class _StoreUnavailableNotice extends StatelessWidget {
  final ColorScheme cs;
  const _StoreUnavailableNotice({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CommonColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: CommonColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '지금 이 기기/환경에서는 인앱결제 스토어를 사용할 수 없어요.\n'
              '실제 기기 + 스토어 상품 등록 후 정상 동작합니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// 플랜 카드 - quiz_home_screen._DifficultyCard와 동일한 보더/선택 표현 방식
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ProductDetails? product;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceText = product?.price ?? '가격 정보 없음';
    final isRecommended = plan.period == SubscriptionPeriod.yearly;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '추천',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                plan.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: selected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? QuizColors.correct
                    : cs.outline.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlreadyPremiumView extends StatelessWidget {
  final Future<void> Function() onRestore;
  const _AlreadyPremiumView({required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: cs.primary, size: 64),
            const SizedBox(height: 16),
            Text(
              '이미 프리미엄을 이용 중이에요',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '광고 없이, 추가 번역본과 함께 즐겨보세요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRestore,
              child: const Text('구매 내역 다시 확인하기'),
            ),
          ],
        ),
      ),
    );
  }
}
