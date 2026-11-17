/// Store-independent entitlement reconciliation. Never trusts client purchase events.
class PurchaseEntitlement {
  final String productId;
  final String transactionId;
  final String accountId;
  final bool serverVerified;
  const PurchaseEntitlement({required this.productId, required this.transactionId, required this.accountId, required this.serverVerified});
}
class EntitlementLedger {
  final Set<String> _processed = <String>{};
  final Set<String> _ownedProducts = <String>{};
  final String accountId;
  EntitlementLedger(this.accountId);
  /// Returns true only for a newly verified transaction. Persist transaction
  /// IDs and entitlements server-side in production; this is in-memory only.
  bool reconcile(PurchaseEntitlement purchase) {
    if (!purchase.serverVerified ||
        purchase.accountId != accountId ||
        purchase.productId.trim().isEmpty ||
        purchase.transactionId.trim().isEmpty ||
        !_processed.add(purchase.transactionId)) return false;
    _ownedProducts.add(purchase.productId);
    return true;
  }
  bool owns(String productId) => _ownedProducts.contains(productId);
  bool get adsRemoved => owns('remove_ads');
}
