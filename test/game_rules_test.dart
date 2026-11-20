import 'package:flutter_test/flutter_test.dart';
import 'package:game_049_construction_simulator/core/arcade.dart';
import 'package:game_049_construction_simulator/core/level_plan.dart';
import 'package:game_049_construction_simulator/game/rules.dart';
import 'package:game_049_construction_simulator/game/tycoon_engine.dart';

void main() {
  final rules = BuildRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('buying a card costs its price and raises the next price', () {
    final s = TycoonSim(rules.build(planner.spec(1)).puzzle);
    final i = List.generate(s.spec.blds.length, (i) => i).firstWhere((i) => s.unlocked(i) && s.spec.blds[i].costRes == 0);
    s.stock[0] = 100000;
    final c0 = s.costOf(i);
    final n0 = s.count[i];
    expect(s.buy(i), isTrue);
    expect(s.count[i], n0 + 1);
    expect(s.stock[0], closeTo(100000 - c0, 0.001));
    expect(s.costOf(i), greaterThan(c0));
  });

  test('tapping a card through input buys it', () {
    final s = TycoonSim(rules.build(planner.spec(1)).puzzle);
    s.stock[0] = 100000;
    final total = s.count.fold<int>(0, (a, b) => a + b);
    final r = cardRect(0);
    s.tick(ArcadeInput(tap: true, down: true, x: r.left + 20, y: r.top + 20));
    expect(s.count.fold<int>(0, (a, b) => a + b), total + (s.unlocked(0) && s.spec.blds[0].costRes == 0 ? 1 : 0));
  });

  test('locked buildings cannot be bought', () {
    final s = TycoonSim(rules.build(planner.spec(1)).puzzle);
    s.stock.fillRange(0, s.stock.length, 1e9);
    for (var i = 0; i < s.spec.blds.length; i++) {
      if (!s.unlocked(i)) expect(s.buy(i), isFalse);
    }
  });

  test('the economy grows: after two minutes of autopilot more money was earned', () {
    final s = TycoonSim(rules.build(planner.run(GameModeId.endless, 2)).puzzle);
    runBot(s, rules.bot, 60 * 120);
    expect(s.earned, greaterThan(50));
    expect(s.bought, greaterThan(3));
    expect(s.stats['buildings_bought'], s.bought);
  });

  test('campaign goal is calibrated below what the autopilot reaches', () {
    for (final n in [1, 25, 99]) {
      final l = rules.build(planner.spec(n)).puzzle;
      expect(l.target, greaterThan(0));
      expect(l.limitSec, greaterThan(60));
      final s = TycoonSim(l);
      final r = runBot(s, rules.bot, l.limitSec * kTicksPerSecond);
      expect(r.won, isTrue, reason: 'level $n');
      expect(s.stars, inInclusiveRange(1, 3));
    }
  });

  test('running out of time ends the round, a continue grants a minute', () {
    final l = rules.build(planner.spec(3)).puzzle;
    final s = TycoonSim(l);
    for (var t = 0; t < l.limitSec * kTicksPerSecond + 5 && !s.over; t++) {
      s.tick(ArcadeInput.idle);
    }
    if (!s.won) {
      expect(s.dead, isTrue);
      s.revive();
      expect(s.over, isFalse);
      expect(s.secondsLeft, greaterThan(50));
    }
  });

  test('frenzy booster increases output', () {
    final l = rules.build(planner.run(GameModeId.zen, 1)).puzzle;
    final a = TycoonSim(l), b = TycoonSim(l);
    b.useBooster();
    for (var t = 0; t < 600; t++) {
      a.tick(ArcadeInput.idle);
      b.tick(ArcadeInput.idle);
    }
    double total(TycoonSim s) => s.made.fold(0.0, (x, y) => x + y) + s.manualTotal;
    expect(total(b), greaterThan(total(a)));
  });
}
