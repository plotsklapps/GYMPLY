import 'package:flutter/material.dart';
import 'package:gymply/services/donation_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class DonationModal extends StatelessWidget {
  const DonationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch signals.
    final bool isLoading = donationService.sIsLoading.watch(context);
    final List<ProductDetails> products = donationService.sProducts.watch(
      context,
    );
    final bool isAvailable = donationService.sIsAvailable.watch(context);

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
              icon: const Icon(LucideIcons.circleX),
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
                  LucideIcons.heart,
                  size: 48,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'GYMPLY. is 100% free, private, and open-source. '
                  'Your donations help cover development costs and keep '
                  'the project alive without ever adding ads or selling '
                  'your data.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

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
                        LucideIcons.sparkles,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Supporters get custom app icons!',
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
                      'Donations are currently unavailable. '
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
                  // --- SUBSCRIPTIONS ---
                  const _SectionTitle(title: 'SUBSCRIPTIONS'),
                  const SizedBox(height: 8),
                  ...products
                      .where(
                        (ProductDetails p) {
                          return p.id.contains('support_monthly') ||
                              p.id.contains('support_yearly');
                        },
                      )
                      .map(
                        (ProductDetails p) {
                          return _ProductTile(
                            product: p,
                            isSubscription: true,
                          );
                        },
                      ),

                  const SizedBox(height: 16),

                  // --- ONE-TIME DONATIONS ---
                  const _SectionTitle(title: 'ONE-TIME DONATIONS'),
                  const SizedBox(height: 8),
                  ...products
                      .where((ProductDetails p) {
                        return p.id.startsWith('donate_');
                      })
                      .map(
                        (ProductDetails p) {
                          return _ProductTile(
                            product: p,
                            isSubscription: false,
                          );
                        },
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.isSubscription});

  final ProductDetails product;
  final bool isSubscription;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    String subtitle = '';
    IconData icon = LucideIcons.heart;

    if (product.id.contains('support_monthly')) {
      subtitle = 'Support monthly';
      icon = LucideIcons.calendarClock;
    } else if (product.id.contains('support_yearly')) {
      subtitle = 'Support yearly (Best value!)';
      icon = LucideIcons.star;
    } else {
      subtitle = 'One-time support';
      icon = LucideIcons.gift;
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
              .trim(), // Remove the "(GYMPLY.)" suffix from Google Play.
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          product.price,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
