import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymply/services/donation_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationModal extends SignalWidget {
  const DonationModal({super.key});

  static const String _privacyPolicyUrl =
      'https://github.com/plotsklapps/gymply/blob/master/PRIVACY_POLICY.md';
  static const String _appleEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIOS = !kIsWeb && Platform.isIOS;

    // Watch Signals.
    final bool isLoading = donationService.sIsLoading.value;
    final List<ProductDetails> products = donationService.sProducts.value;
    final bool isAvailable = donationService.sIsAvailable.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // --- FIXED HEADER ---
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SUPPORT GYMPLY.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(IconUtils.close),
            ),
          ],
        ),
        const Divider(),

        // --- SCROLLABLE BODY ---
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 8),
                Icon(
                  IconUtils.heart,
                  size: 48,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  isIOS
                      ? 'GYMPLY. is 100% free, private, and open-source.\n\n'
                            'Your supporter subscription helps cover '
                            'development costs and keeps the project alive '
                            'without ever adding ads or selling your data.'
                      : 'GYMPLY. is 100% free, private, and open-source.\n\n'
                            'Your donations help cover development costs and '
                            'keep the project alive without ever adding ads '
                            'or selling your data.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // --- SUPPORTER PERK HIGHLIGHT ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        IconUtils.sparkles,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'You get: 50+ Themes and 50+ Fonts!',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isAvailable)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isIOS
                          ? 'Subscriptions are currently unavailable. '
                                'Please ensure you have an active App Store '
                                'connection.'
                          : 'Donations are currently unavailable. '
                                'Please ensure you have a working Google Play '
                                'connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  )
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (products.isEmpty)
                  Column(
                    children: <Widget>[
                      const Text('No products found in the store.'),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () async {
                          await donationService.fetchProducts();
                        },
                        child: const Text('RETRY'),
                      ),
                    ],
                  )
                else ...<Widget>[
                  ...products.map(
                    (ProductDetails p) => _ProductTile(product: p),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await donationService.restorePurchases();
                  },
                  icon: const Icon(IconUtils.sync),
                  label: const Text('RESTORE PURCHASES'),
                ),
                if (isIOS) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Payment will be charged to your Apple ID account at '
                    'confirmation of purchase. Subscription automatically '
                    'renews unless cancelled at least 24 hours before the '
                    'end of the current period. Manage or cancel anytime in '
                    'your Apple ID Account Settings.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: <Widget>[
                      TextButton(
                        onPressed: () async {
                          await launchUrl(
                            Uri.parse(_privacyPolicyUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: const Text('Privacy Policy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await launchUrl(
                            Uri.parse(_appleEulaUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: const Text('Terms of Use (EULA)'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductDetails product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIOS = !kIsWeb && Platform.isIOS;

    String subtitle = '';
    String priceLabel = product.price;
    IconData icon = IconUtils.heart;

    if (product.id.contains('support_monthly')) {
      subtitle = isIOS ? '1 Month • Auto-renews monthly' : 'Support monthly';
      if (isIOS) priceLabel = '${product.price} / mo';
      icon = IconUtils.calendarDay;
    } else if (product.id.contains('support_yearly')) {
      subtitle = isIOS
          ? '1 Year • Auto-renews yearly (Best value!)'
          : 'Support yearly (Best value!)';
      if (isIOS) priceLabel = '${product.price} / yr';
      icon = IconUtils.calendarMonth;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: ListTile(
        onTap: () async {
          await donationService.buyProduct(product);
        },
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          product.title
              .split('(')
              .first
              .trim(), // Remove the "(GYMPLY.)" suffix if present.
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          priceLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
