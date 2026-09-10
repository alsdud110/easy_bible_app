import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

/// 앱 전체에서 "프리미엄(구독) 여부"를 참조하는 단일 진실 공급원(source of truth).
///
/// ⚠️ 지금은 스토어에 실제 구독 상품이 등록되기 전 단계라, 코드 구조
/// (상태관리 + 페이월 UI + 게이팅 로직)만 먼저 만들어둔 버전입니다.
/// - Play Console / App Store Connect에 구독 상품을 등록한 뒤
///   lib/models/subscription_plan.dart 의 productId만 실제 값으로 바꾸면
///   나머지 코드는 그대로 동작합니다.
/// - 프로덕션에서는 서버에서 영수증을 검증하는 걸 권장하지만, 지금은
///   클라이언트에서 PurchaseDetails 상태만으로 판단하는 간이 버전입니다.
class SubscriptionProvider extends ChangeNotifier {
  static const String _cacheKey = 'is_premium_cached';

  final SubscriptionService _service = SubscriptionService();

  bool _isPremium = false;
  bool _isLoading = true;
  bool _storeAvailable = false;
  String? _errorMessage;
  List<ProductDetails> _products = [];

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get storeAvailable => _storeAvailable;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  ProductDetails? productFor(SubscriptionPlan plan) {
    for (final p in _products) {
      if (p.id == plan.productId) return p;
    }
    return null;
  }

  /// 앱 시작 시 1회 호출 (main.dart에서 실행)
  Future<void> initialize() async {
    // 1) 로컬 캐시로 우선 즉시 표시 (스토어 왕복 없이 UI 깜빡임 방지)
    await _loadCachedStatus();

    // 2) 구매 스트림 리스닝 시작
    _service.onPurchaseUpdate = _handlePurchaseUpdates;
    _service.startListening();

    // 3) 스토어 사용 가능 여부 확인 + 상품 목록 로드
    try {
      _storeAvailable = await _service.isAvailable();
      if (_storeAvailable) {
        await _loadProducts();
        // 4) 기존 구매 내역으로 구독 상태 재확인
        await restorePurchases();
      } else {
        debugPrint('⚠️ 인앱결제 스토어 사용 불가 (에뮬레이터이거나 스토어 상품 미등록일 수 있음)');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('구독 초기화 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_cacheKey) ?? false;
    } catch (e) {
      debugPrint('구독 캐시 로드 실패: $e');
    }
  }

  Future<void> _saveCachedStatus(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, value);
    } catch (e) {
      debugPrint('구독 캐시 저장 실패: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _service.queryProducts();
      if (response.error != null) {
        _errorMessage = response.error!.message;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '⚠️ 스토어에서 찾을 수 없는 상품 ID: ${response.notFoundIDs} '
            '(Play Console/App Store Connect에 상품을 등록했는지 확인하세요)');
      }
      _products = response.productDetails;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('상품 목록 로드 실패: $e');
    }
  }

  /// 특정 플랜 구독 시작. 결과는 구매 스트림(_handlePurchaseUpdates)으로 비동기 전달됨.
  Future<void> purchasePlan(SubscriptionPlan plan) async {
    final product = productFor(plan);
    if (product == null) {
      _errorMessage =
          '상품 정보를 찾을 수 없습니다 (${plan.productId}). 스토어 상품 등록 상태를 확인하세요.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    try {
      await _service.purchase(product);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 구매 복원 (기기 변경, 재설치 시 / iOS 심사 필수 항목)
  Future<void> restorePurchases() async {
    try {
      await _service.restorePurchases();
    } catch (e) {
      debugPrint('구매 복원 실패: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setPremium(true);
          _service.completePurchase(purchase);
          break;
        case PurchaseStatus.error:
          _errorMessage = purchase.error?.message;
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  void _setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    _saveCachedStatus(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
