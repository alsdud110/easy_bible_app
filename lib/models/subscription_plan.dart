/// 구독(정기결제) 플랜 정의
///
/// ⚠️ 아래 productId 값은 플레이스홀더입니다.
/// Google Play Console / App Store Connect에 실제 "정기 결제(구독)" 상품을 등록한 뒤,
/// 여기 있는 productId 문자열을 실제 상품 ID로 교체하면 바로 동작합니다.
/// (Android/iOS 모두 같은 productId를 쓰는 걸 권장 - 각 콘솔에서 동일하게 등록)
library subscription_plan;

enum SubscriptionPeriod { monthly, yearly }

class SubscriptionPlan {
  final SubscriptionPeriod period;
  final String productId;
  final String title;
  final String description;

  const SubscriptionPlan({
    required this.period,
    required this.productId,
    required this.title,
    required this.description,
  });

  static const monthly = SubscriptionPlan(
    period: SubscriptionPeriod.monthly,
    productId: 'premium_monthly', // TODO: 실제 스토어 상품 ID로 교체
    title: '월간 프리미엄',
    description: '매달 자동 갱신 · 언제든 해지 가능',
  );

  static const yearly = SubscriptionPlan(
    period: SubscriptionPeriod.yearly,
    productId: 'premium_yearly', // TODO: 실제 스토어 상품 ID로 교체
    title: '연간 프리미엄',
    description: '1년 단위 자동 갱신 · 월간 대비 할인 프로모션에 활용',
  );

  static const List<SubscriptionPlan> all = [monthly, yearly];

  static SubscriptionPlan? byProductId(String id) {
    for (final plan in all) {
      if (plan.productId == id) return plan;
    }
    return null;
  }
}

/// 프리미엄(구독)으로만 제공할 성경 번역본의 언어 코드 목록.
/// LanguageProvider의 BibleLanguage.code 값과 매칭됩니다 (ko/snb/en).
///
/// 지금은 예시로 영어(KJV)만 잠가두었습니다. 다른 정책을 원하면 이 Set만 수정하세요.
/// 예) 기존 사용자에게 이미 노출된 번역본은 계속 무료로 두고,
///     "새로 추가하는" 번역본만 이 목록에 넣는 방식을 권장합니다.
const Set<String> premiumBibleLanguageCodes = {'en', 'snb'};
