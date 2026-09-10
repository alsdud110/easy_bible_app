import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_plan.dart';

/// in_app_purchase 패키지를 감싸는 서비스.
/// 스토어 상품 조회, 구매 시작, 복원, 구매 스트림 처리를 담당합니다.
///
/// ⚠️ 프로덕션에서는 구매 영수증(receipt)을 서버에서 검증하는 것을 권장합니다.
/// 지금은 백엔드가 없다는 전제 하에, 클라이언트 측 PurchaseDetails.status만으로
/// 구독 여부를 판단하는 간이 구조입니다. (SubscriptionProvider에서 사용)
class SubscriptionService {
  static final SubscriptionService _instance =
      SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _listening = false;

  /// 구매 상태가 바뀔 때마다 호출되는 콜백 (성공/실패/복원 등)
  void Function(List<PurchaseDetails> purchases)? onPurchaseUpdate;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// 구매 스트림 리스닝 시작 (앱 시작 시 1회만 호출하면 됨)
  void startListening() {
    if (_listening) return;
    _listening = true;
    _subscription = _iap.purchaseStream.listen(
      (purchases) => onPurchaseUpdate?.call(purchases),
      onDone: () {
        _subscription?.cancel();
        _listening = false;
      },
      onError: (error) {
        print('⚠️ 구매 스트림 오류: $error');
      },
    );
  }

  /// 스토어에 등록된 상품 정보 조회
  Future<ProductDetailsResponse> queryProducts() {
    final ids = SubscriptionPlan.all.map((p) => p.productId).toSet();
    return _iap.queryProductDetails(ids);
  }

  /// 구독 상품 구매 시작
  /// (자동 갱신 구독은 소모성이 아니므로 buyNonConsumable을 사용)
  Future<bool> purchase(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 기존 구매 복원 (기기 변경, 재설치, iOS 심사 필수 요건)
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// 구매 완료 처리 - 반드시 호출해야 스토어 구매 큐에서 제거됩니다.
  Future<void> completePurchase(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      return _iap.completePurchase(purchase);
    }
    return Future.value();
  }

  void dispose() {
    _subscription?.cancel();
    _listening = false;
  }
}
