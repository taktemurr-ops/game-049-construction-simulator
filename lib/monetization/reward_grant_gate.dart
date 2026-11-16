/// SDK-independent reward eligibility guard. This does not display ads or
/// verify ad-network callbacks: callers must supply a server-verified completion.
/// No reward is granted for loading, closing, failing or skipping an ad.
class RewardGrantGate {
  final Set<String> _granted = <String>{};
  final Set<String> _pending = <String>{};

  /// A unique opportunity ID must be created by the game for each offer.
  /// Returns false for duplicate or invalid offers.
  bool offer(String opportunityId) {
    if (opportunityId.trim().isEmpty ||
        _granted.contains(opportunityId) ||
        _pending.contains(opportunityId)) {
      return false;
    }
    _pending.add(opportunityId);
    return true;
  }

  /// Invoke only after trusted verification of the completed rewarded ad.
  /// The caller must persist grants for durable exactly-once semantics.
  bool confirmVerified(String opportunityId, {required bool verified}) {
    if (!verified || !_pending.remove(opportunityId)) return false;
    return _granted.add(opportunityId);
  }

  /// A failed, skipped or unavailable ad never blocks normal gameplay.
  void cancel(String opportunityId) => _pending.remove(opportunityId);

  bool wasGranted(String opportunityId) => _granted.contains(opportunityId);
}

/// Natural-break-only interstitial pacing; no SDK or consent implementation.
/// Callers must separately check age, consent and ad availability.
class InterstitialPacing {
  final int minimumCompletedRounds;
  int _roundsSinceLastAd = 0;

  InterstitialPacing({this.minimumCompletedRounds = 3})
      : assert(minimumCompletedRounds > 0);

  void onRoundCompleted() => _roundsSinceLastAd++;

  bool get eligibleAtNaturalBreak =>
      _roundsSinceLastAd >= minimumCompletedRounds;

  /// Only record a successfully displayed ad; failed loads don't count.
  void onAdDisplayed() => _roundsSinceLastAd = 0;
}
