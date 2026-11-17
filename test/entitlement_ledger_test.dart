import 'package:flutter_test/flutter_test.dart';
import '../lib/monetization/entitlement_ledger.dart';
void main() {
  test('unverified and mismatched purchases never unlock', () {
    final ledger = EntitlementLedger('user-a');
    expect(ledger.reconcile(const PurchaseEntitlement(productId:'remove_ads', transactionId:'tx1', accountId:'user-a', serverVerified:false)), false);
    expect(ledger.reconcile(const PurchaseEntitlement(productId:'remove_ads', transactionId:'tx2', accountId:'user-b', serverVerified:true)), false);
    expect(ledger.adsRemoved, false);
  });
  test('verified transaction is idempotent', () {
    final ledger = EntitlementLedger('user-a');
    const purchase = PurchaseEntitlement(productId:'remove_ads', transactionId:'tx3', accountId:'user-a', serverVerified:true);
    expect(ledger.reconcile(purchase), true);
    expect(ledger.reconcile(purchase), false);
    expect(ledger.adsRemoved, true);
  });
  test('empty transaction id is rejected', () {
    final ledger = EntitlementLedger('user-a');
    expect(ledger.reconcile(const PurchaseEntitlement(productId:'remove_ads', transactionId:'', accountId:'user-a', serverVerified:true)), false);
  });
}
