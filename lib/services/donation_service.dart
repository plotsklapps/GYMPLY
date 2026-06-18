import 'dart:async';

import 'package:gymply/services/settings_service.dart';
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

  // Subscription IDs.
  static const Set<String> _kIds = <String>{
    idMonthly,
    idYearly,
  };

  // Signals for state management.
  final Signal<bool> sIsAvailable = Signal<bool>(
    false,
    options: const SignalOptions<bool>(
      name: 'sIsAvailable',
    ),
  );
  final Signal<bool> sIsLoading = Signal<bool>(
    false,
    options: const SignalOptions<bool>(
      name: 'sIsLoading',
    ),
  );
  final Signal<List<ProductDetails>> sProducts = Signal<List<ProductDetails>>(
    <ProductDetails>[],
    options: const SignalOptions<List<ProductDetails>>(
      name: 'sProducts',
    ),
  );
  final Signal<bool> sIsSupporter = Signal<bool>(
    false,
    options: const SignalOptions<bool>(
      name: 'sIsSupporter',
    ),
  );

  // Initialize the service.
  Future<void> initialize() async {
    sIsSupporter.value = settingsService.isSupporter;

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

    // Restore past purchases silently.
    if (sIsAvailable.value) {
      await _iap.restorePurchases();
    }
  }

  Future<void> _checkAvailability() async {
    sIsAvailable.value = await _iap.isAvailable();

    // Log success.
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

      // Sort products by price (cheapest first).
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

  // Start a purchase. All remaining products are subscriptions.
  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Handle purchase updates.
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    // Check if there's any active (purchased or restored) subscription in the stream.
    final bool hasValidPurchase = purchaseDetailsList.any(
      (PurchaseDetails p) =>
          p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored,
    );

    for (final PurchaseDetails purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.error) {
        _logger.e('DonationService: Purchase error: ${purchase.error}');
        ToastService.showError(
          title: 'Purchase Failed',
          subtitle: purchase.error?.message ?? 'Unknown error',
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }

    // Sync the signal and Hive if the status has changed.
    if (hasValidPurchase != sIsSupporter.value) {
      sIsSupporter.value = hasValidPurchase;
      await settingsService.updateIsSupporter(value: hasValidPurchase);

      if (hasValidPurchase) {
        ToastService.showSuccess(
          title: 'Thank You!',
          subtitle: 'Your support keeps GYMPLY. alive and free.',
        );
      } else {
        // Reset themes/fonts if the subscription expired.
        settingsService.verifySupporterPerks();
        _logger.i('DonationService: Supporter status revoked (expired).');
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

final DonationService donationService = DonationService();
