import 'dart:async';

import 'package:gymply/services/toast_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class DonationService {
  // Singleton pattern.
  factory DonationService() {
    return _instance;
  }
  DonationService._internal();
  static final DonationService _instance = DonationService._internal();

  final Logger _logger = Logger();
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // IDs for Google Play Console.
  static const String idMonthly = 'support_monthly';
  static const String idYearly = 'support_yearly';
  static const String idOneTime5 = 'donate_5';
  static const String idOneTime15 = 'donate_15';
  static const String idOneTime50 = 'donate_50';

  // For the query, we use the base IDs for subscriptions on Android.
  static const Set<String> _kIds = <String>{
    idMonthly,
    idYearly,
    idOneTime5,
    idOneTime15,
    idOneTime50,
  };

  // Signals for state management.
  final Signal<bool> sIsAvailable = Signal<bool>(false);
  final Signal<bool> sIsLoading = Signal<bool>(false);
  final Signal<List<ProductDetails>> sProducts = Signal<List<ProductDetails>>(
    <ProductDetails>[],
  );
  final Signal<bool> sIsSupporter = Signal<bool>(false);

  // Initialize the service.
  Future<void> initialize() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () async {
        await _subscription?.cancel();
      },
      onError: (Object error) {
        // Log error.
        _logger.e('DonationService: Purchase stream error: $error');

        // Show toast to user.
        ToastService.showError(
          title: 'Error',
          subtitle: 'Failed to process purchase: $error',
        );
      },
    );
    await _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    sIsAvailable.value = await _iap.isAvailable();
    _logger.i('DonationService: IAP Available: ${sIsAvailable.value}');

    if (sIsAvailable.value) {
      await fetchProducts();
    }
  }

  // Fetch product details from Google Play.
  Future<void> fetchProducts() async {
    sIsLoading.value = true;
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        _kIds,
      );

      if (response.notFoundIDs.isNotEmpty) {
        _logger.w(
          'DonationService: IDs not found: ${response.notFoundIDs.join(', ')}',
        );
      }

      // Sort products by price (roughly).
      final List<ProductDetails> sortedProducts =
          response.productDetails.toList()
            ..sort((ProductDetails a, ProductDetails b) {
              return a.rawPrice.compareTo(b.rawPrice);
            });

      sProducts.value = sortedProducts;
      _logger.i('DonationService: Fetched ${sProducts.value.length} products');
    } on Exception catch (e) {
      // Log error.
      _logger.e('DonationService: Error fetching products: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Error',
        subtitle: 'Failed to load products: $e',
      );
    } finally {
      sIsLoading.value = false;
    }
  }

  // Start a purchase.
  Future<void> buyProduct(ProductDetails product) async {
    late PurchaseParam purchaseParam;

    if (product.id == idMonthly || product.id == idYearly) {
      purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  // Handle purchase updates.
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show loading or wait.
      } else if (purchase.status == PurchaseStatus.error) {
        _logger.e('DonationService: Purchase error: ${purchase.error}');
        ToastService.showError(
          title: 'Purchase Failed',
          subtitle: purchase.error?.message ?? 'Unknown error',
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _logger.i(
          'DonationService: Product purchased/restored: ${purchase.productID}',
        );

        // In a real app, you would validate the receipt here.
        // For a donation-based free app, we just thank the user.

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        sIsSupporter.value = true;

        ToastService.showSuccess(
          title: 'Thank You!',
          subtitle: 'Your support keeps GYMPLY. alive and free.',
        );
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

final DonationService donationService = DonationService();
