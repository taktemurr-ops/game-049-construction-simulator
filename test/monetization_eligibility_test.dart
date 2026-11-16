import 'package:flutter_test/flutter_test.dart';
import '../lib/monetization/eligibility.dart';

void main() {
  test('interstitial requires adult audience, consent and natural break', () {
    const policy = MonetizationEligibility(
      consent: ConsentStatus.granted,
      audience: AudienceClass.general,
      adsRemoved: false,
      completedRounds: 3,
      roundsSinceInterstitial: 3,
    );
    expect(policy.canRequestInterstitial, isTrue);
    expect(policy.canRequestRewarded(userInitiated: false), isFalse);
    expect(policy.canRequestRewarded(userInitiated: true), isTrue);
  });

  test('unknown age, denied consent or ad removal blocks ads', () {
    for (final audience in [AudienceClass.unknown, AudienceClass.childDirected]) {
      final policy = MonetizationEligibility(
        consent: ConsentStatus.granted,
        audience: audience,
        adsRemoved: false,
        completedRounds: 20,
        roundsSinceInterstitial: 20,
      );
      expect(policy.canRequestInterstitial, isFalse);
      expect(policy.canRequestRewarded(userInitiated: true), isFalse);
    }
    const removed = MonetizationEligibility(
      consent: ConsentStatus.granted,
      audience: AudienceClass.general,
      adsRemoved: true,
      completedRounds: 20,
      roundsSinceInterstitial: 20,
    );
    expect(removed.canRequestInterstitial, isFalse);
  });

  test('only verified receipts are accepted once', () {
    final ledger = RewardReceiptLedger();
    expect(ledger.acceptVerifiedReceipt(receiptId: 'r1', sdkCompleted: true, serverVerified: false), isFalse);
    expect(ledger.acceptVerifiedReceipt(receiptId: 'r1', sdkCompleted: true, serverVerified: true), isTrue);
    expect(ledger.acceptVerifiedReceipt(receiptId: 'r1', sdkCompleted: true, serverVerified: true), isFalse);
  });
}
