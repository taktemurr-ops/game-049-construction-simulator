/// Store-independent entitlement state machine. This is NOT a billing SDK.
/// Only a trusted backend may call applyVerifiedTransaction after validating
/// the store-signed purchase or restore against Apple/Google.
enum PurchaseKind { removeAds, cosmetic, premiumContent }
enum PurchaseState { locked, pendingVerification, entitled }

class VerifiedEntitlementStore {
  final Map<String, PurchaseState> _states = {};
  final Set<String> _processedTransactions = {};
  final Map<String, PurchaseKind> _kinds = {};

  PurchaseState stateOf(String productId) =>
      _states[productId] ?? PurchaseState.locked;

  bool beginPurchase(String productId, PurchaseKind kind) {
    if (productId.trim().isEmpty ||
        stateOf(productId) != PurchaseState.locked) return false;
    _kinds[productId] = kind;
    _states[productId] = PurchaseState.pendingVerification;
    return true;
  }

  /// Never call this from a client-side success callback alone.
  /// The verification result must be independently checked by a trusted server.
  bool applyVerifiedTransaction({
    required String productId,
    required String transactionId,
    required bool storeVerified,
    required bool productMatches,
    required bool belongsToAccount,
  }) {
    if (!storeVerified || !productMatches || !belongsToAccount ||
        productId.trim().isEmpty || transactionId.trim().isEmpty ||
        _processedTransactions.contains(transactionId)) return false;
    _processedTransactions.add(transactionId);
    _states[productId] = PurchaseState.entitled;
    return true;
  }

  /// A cancellation or failed verification must not unlock content.
  void failPurchase(String productId) {
    if (stateOf(productId) == PurchaseState.pendingVerification) {
      _states[productId] = PurchaseState.locked;
    }
  }

  bool get adsRemoved => _kinds.entries.any((entry) =>
      entry.value == PurchaseKind.removeAds &&
      stateOf(entry.key) == PurchaseState.entitled);
}
