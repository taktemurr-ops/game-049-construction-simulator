import 'package:flutter_test/flutter_test.dart';
import '../lib/monetization/verified_entitlement_store.dart';

void main() {
  test('purchase callbacks do not unlock without store verification', () {
    final store = VerifiedEntitlementStore();
    expect(store.beginPurchase('remove_ads', PurchaseKind.removeAds), isTrue);
    expect(store.adsRemoved, isFalse);
    expect(store.applyVerifiedTransaction(
      productId: 'remove_ads', transactionId: 'tx-1',
      storeVerified: false, productMatches: true, belongsToAccount: true,
    ), isFalse);
    expect(store.adsRemoved, isFalse);
    store.failPurchase('remove_ads');
    expect(store.stateOf('remove_ads'), PurchaseState.locked);
  });

  test('verified purchase unlocks once and rejects replay', () {
    final store = VerifiedEntitlementStore();
    store.beginPurchase('remove_ads', PurchaseKind.removeAds);
    expect(store.applyVerifiedTransaction(
      productId: 'remove_ads', transactionId: 'tx-2',
      storeVerified: true, productMatches: true, belongsToAccount: true,
    ), isTrue);
    expect(store.adsRemoved, isTrue);
    expect(store.applyVerifiedTransaction(
      productId: 'remove_ads', transactionId: 'tx-2',
      storeVerified: true, productMatches: true, belongsToAccount: true,
    ), isFalse);
  });

  test('wrong product or account cannot restore entitlement', () {
    final store = VerifiedEntitlementStore();
    expect(store.applyVerifiedTransaction(
      productId: 'premium', transactionId: 'tx-3',
      storeVerified: true, productMatches: false, belongsToAccount: true,
    ), isFalse);
    expect(store.applyVerifiedTransaction(
      productId: 'premium', transactionId: 'tx-4',
      storeVerified: true, productMatches: true, belongsToAccount: false,
    ), isFalse);
    expect(store.stateOf('premium'), PurchaseState.locked);
  });
}
