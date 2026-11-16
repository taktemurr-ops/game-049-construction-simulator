import 'package:flutter_test/flutter_test.dart';
import '../lib/monetization/reward_grant_gate.dart';

void main() {
  test('unverified, duplicate and cancelled rewards are never granted', () {
    final gate = RewardGrantGate();
    expect(gate.offer('hint-1'), isTrue);
    expect(gate.offer('hint-1'), isFalse);
    expect(gate.confirmVerified('hint-1', verified: false), isFalse);
    expect(gate.wasGranted('hint-1'), isFalse);
    expect(gate.confirmVerified('hint-1', verified: true), isTrue);
    expect(gate.confirmVerified('hint-1', verified: true), isFalse);
    expect(gate.offer('hint-1'), isFalse);
    expect(gate.offer('second-chance-2'), isTrue);
    gate.cancel('second-chance-2');
    expect(gate.confirmVerified('second-chance-2', verified: true), isFalse);
  });

  test('interstitials are eligible only after sufficient completed rounds', () {
    final pacing = InterstitialPacing(minimumCompletedRounds: 3);
    expect(pacing.eligibleAtNaturalBreak, isFalse);
    pacing.onRoundCompleted();
    pacing.onRoundCompleted();
    expect(pacing.eligibleAtNaturalBreak, isFalse);
    pacing.onRoundCompleted();
    expect(pacing.eligibleAtNaturalBreak, isTrue);
    pacing.onAdDisplayed();
    expect(pacing.eligibleAtNaturalBreak, isFalse);
  });
}
