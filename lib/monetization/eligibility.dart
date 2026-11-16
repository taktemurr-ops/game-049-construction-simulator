/// Local monetization eligibility rules; not an ad SDK or payment integration.
/// Server-side ad verification and store purchase validation are still required.
enum ConsentStatus { unknown, granted, denied }
enum AudienceClass { general, childDirected, unknown }

class MonetizationEligibility {
  const MonetizationEligibility({
    required this.consent,
    required this.audience,
    required this.adsRemoved,
    required this.completedRounds,
    required this.roundsSinceInterstitial,
  });

  final ConsentStatus consent;
  final AudienceClass audience;
  final bool adsRemoved;
  final int completedRounds;
  final int roundsSinceInterstitial;

  /// Unknown age or consent means no personalized or interstitial ads.
  bool get canRequestInterstitial =>
      consent == ConsentStatus.granted &&
      audience == AudienceClass.general &&
      !adsRemoved &&
      completedRounds >= 3 &&
      roundsSinceInterstitial >= 3;

  /// Rewarded ads must always be optional and explicitly requested.
  bool canRequestRewarded({required bool userInitiated}) =>
      userInitiated &&
      consent == ConsentStatus.granted &&
      audience == AudienceClass.general &&
      !adsRemoved;
}

/// In-memory duplicate protection only. A durable backend ledger is needed
/// before issuing valuable rewards or allowing cross-device restoration.
class RewardReceiptLedger {
  final Set<String> _consumedReceipts = <String>{};

  bool acceptVerifiedReceipt({
    required String receiptId,
    required bool sdkCompleted,
    required bool serverVerified,
  }) {
    if (receiptId.trim().isEmpty || !sdkCompleted || !serverVerified) {
      return false;
    }
    return _consumedReceipts.add(receiptId);
  }
}
