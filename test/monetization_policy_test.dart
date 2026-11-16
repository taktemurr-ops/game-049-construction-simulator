import 'package:flutter_test/flutter_test.dart';
import '../lib/monetization/monetization_policy.dart';

void main() {
  test('unknown audience and missing consent prevent advertising', () {
    final policy = MonetizationPolicy();
    policy.recordCompletedRound();
    policy.recordCompletedRound();
    policy.recordCompletedRound();
    expect(policy.mayShowInterstitial, false);
    policy.setConsent(true);
    expect(policy.mayShowInterstitial, false);
    policy.setAudience(Audience.childDirected);
    expect(policy.mayShowInterstitial, false);
  });

  test('interstitial respects rounds, cooldown and verified removal', () {
    final policy = MonetizationPolicy();
    policy.setConsent(true);
    policy.setAudience(Audience.general);
    for (var i = 0; i < 3; i++) policy.recordCompletedRound();
    expect(policy.markInterstitialShown(), true);
    expect(policy.markInterstitialShown(), false);
    for (var i = 0; i < 3; i++) policy.recordCompletedRound();
    expect(policy.mayShowInterstitial, true);
    policy.setVerifiedAdsRemoved(true);
    expect(policy.mayShowInterstitial, false);
  });

  test('reward requires verified voluntary completion and cannot replay', () {
    final policy = MonetizationPolicy();
    policy.setConsent(true);
    policy.setAudience(Audience.general);
    expect(policy.claimVerifiedReward(rewardId: 'r1',
      purpose: RewardPurpose.hint, serverVerified: false,
      userInitiated: true), false);
    expect(policy.claimVerifiedReward(rewardId: 'r1',
      purpose: RewardPurpose.hint, serverVerified: true,
      userInitiated: false), false);
    expect(policy.claimVerifiedReward(rewardId: 'r1',
      purpose: RewardPurpose.hint, serverVerified: true,
      userInitiated: true), true);
    expect(policy.claimVerifiedReward(rewardId: 'r1',
      purpose: RewardPurpose.hint, serverVerified: true,
      userInitiated: true), false);
  });
}
