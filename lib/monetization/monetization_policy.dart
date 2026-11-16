/// Pure policy checks; does not show ads or validate purchases.
/// A production SDK adapter must obtain consent and verify rewards server-side.
enum RewardPurpose { hint, extraMove, secondChance, cosmetic }
enum Audience { unknown, general, childDirected }

class MonetizationPolicy {
  MonetizationPolicy({this.minimumCompletedRounds = 3, this.roundCooldown = 3});
  final int minimumCompletedRounds;
  final int roundCooldown;
  int _completedRounds = 0;
  int? _lastInterstitialRound;
  bool _adsRemoved = false;
  bool _consentGranted = false;
  Audience _audience = Audience.unknown;
  final Set<String> _claimedRewardIds = {};

  void setAudience(Audience value) => _audience = value;
  void setConsent(bool granted) => _consentGranted = granted;
  /// Only call after a verified store entitlement or restore.
  void setVerifiedAdsRemoved(bool value) => _adsRemoved = value;
  void recordCompletedRound() => _completedRounds++;

  bool get mayRequestAds =>
      !_adsRemoved && _consentGranted && _audience == Audience.general;

  bool get mayShowInterstitial =>
      mayRequestAds &&
      _completedRounds >= minimumCompletedRounds &&
      (_lastInterstitialRound == null ||
       _completedRounds - _lastInterstitialRound! >= roundCooldown);

  bool markInterstitialShown() {
    if (!mayShowInterstitial) return false;
    _lastInterstitialRound = _completedRounds;
    return true;
  }

  /// Reward IDs must be unique server-issued IDs, not client-generated IDs.
  /// This in-memory replay guard is insufficient without persistent backend dedupe.
  bool claimVerifiedReward({
    required String rewardId,
    required RewardPurpose purpose,
    required bool serverVerified,
    required bool userInitiated,
  }) {
    if (!mayRequestAds || !serverVerified || !userInitiated ||
        rewardId.trim().isEmpty || _claimedRewardIds.contains(rewardId)) {
      return false;
    }
    _claimedRewardIds.add(rewardId);
    return true;
  }
}
