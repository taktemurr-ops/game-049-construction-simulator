import 'dart:math' as math;

import '../core/arcade.dart';
import '../core/level_plan.dart';

/// Shared deterministic management / tycoon simulation used by the
/// strategy games (civilization, empire, factory, city, farm, restaurant,
/// airport, hotel, colony). A game is described by a [TycoonSpec]; the
/// simulation runs on the fixed 60 Hz [ArcadeSim] so that levels can be
/// validated by a bot, resumed by input replay and played on every platform.

/// A resource (stock). Index 0 is always money.
class Res {
  final String id, tr, en;
  final int color;

  /// Auto-sell price per unit (0 = not sold, kept for needs/inputs).
  final double sell;

  /// Units kept in stock before auto-selling.
  final double keep;

  /// Approximate worth per unit, used by the autopilot's planning.
  final double value;
  const Res(this.id, this.tr, this.en, this.color, {this.sell = 0, this.keep = 0, this.value = 0});
}

/// A building / upgrade that can be bought repeatedly.
class Bld {
  final String id, tr, en;
  final double cost;

  /// Currency resource index (0 = money).
  final int costRes;
  final double growth;

  /// Output per second per unit.
  final Map<int, double> make;

  /// Input per second per unit.
  final Map<int, double> use;

  /// Population capacity per unit.
  final double housing;

  /// Service slots (rooms, gates, tables) per unit.
  final int slots;

  /// Customers served per second per unit.
  final double staff;

  /// Extra customer attraction per unit (0.1 = +10 %).
  final double attract;

  /// Income multiplier per unit (markets, banks, territories): +x.
  final double boost;

  /// Unlocked when the total produced amount of [unlockRes] reaches [unlockAt].
  final int unlockRes;
  final double unlockAt;

  /// Money upkeep per second per unit.
  final double upkeep;

  /// Output waits in the building until the player harvests (tap scene).
  final bool manual;
  final int start;

  /// Painter shape: 0 house, 1 factory, 2 field, 3 tower, 4 dome, 5 shop, 6 tank.
  final int shape;
  final int color;

  const Bld(this.id, this.tr, this.en, this.cost,
      {this.costRes = 0,
      this.growth = 1.15,
      this.make = const {},
      this.use = const {},
      this.housing = 0,
      this.slots = 0,
      this.staff = 0,
      this.attract = 0,
      this.boost = 0,
      this.unlockRes = -1,
      this.unlockAt = 0,
      this.upkeep = 0,
      this.manual = false,
      this.start = 0,
      this.shape = 0,
      this.color = 0xFF90A4AE});
}

enum TGoal { earn, population, produce, served, count }

class TycoonSpec {
  final List<Res> res;
  final List<Bld> blds;
  final double startMoney;

  // Population model (civilization, city, colony).
  final bool population;
  final double basePop;
  final double baseHousing;
  final Map<int, double> needs; // per person per second
  final int critical; // need whose shortage costs a life (-1 = none)
  final double tax; // money per person per second
  final double growRate;

  // Customer model (restaurant, hotel, airport, shop).
  final bool customers;
  final List<int> wants; // item resources (-1 = only a slot)
  final double arrival; // customers per second
  final double patience; // seconds
  final double pay;
  final double serviceSec; // >0: occupies a slot for this long
  final double baseStaff;

  /// Money per manual tap on the scene ("work").
  final double clickMoney;

  final TGoal goal;
  final int goalIndex; // resource (produce) or building (count)
  final String goalTr, goalEn;
  final String unitTr, unitEn;

  /// Level length (seconds) of a campaign round.
  final int baseSeconds;

  const TycoonSpec({
    required this.res,
    required this.blds,
    this.startMoney = 50,
    this.population = false,
    this.basePop = 0,
    this.baseHousing = 0,
    this.needs = const {},
    this.critical = -1,
    this.tax = 0,
    this.growRate = 0.4,
    this.customers = false,
    this.wants = const [],
    this.arrival = 0.3,
    this.patience = 20,
    this.pay = 5,
    this.serviceSec = 0,
    this.baseStaff = 0.3,
    this.clickMoney = 1,
    required this.goal,
    this.goalIndex = 0,
    required this.goalTr,
    required this.goalEn,
    this.unitTr = 'müşteri',
    this.unitEn = 'customers',
    this.baseSeconds = 210,
  });
}

class TycoonLevel {
  final ArcadeMeta meta;
  final TycoonSpec spec;
  final double target; // 0 = no goal (endless / zen / time attack)
  final int limitSec; // 0 = unlimited
  final bool events;
  final bool disasters;
  final double rush; // customer multiplier
  final double startMoney;
  final double upkeepMul;
  final double priceMul;

  const TycoonLevel({
    required this.meta,
    required this.spec,
    required this.target,
    required this.limitSec,
    required this.events,
    required this.disasters,
    required this.rush,
    required this.startMoney,
    required this.upkeepMul,
    required this.priceMul,
  });

  TycoonLevel withTarget(double t) => TycoonLevel(
      meta: meta,
      spec: spec,
      target: t,
      limitSec: limitSec,
      events: events,
      disasters: disasters,
      rush: rush,
      startMoney: startMoney,
      upkeepMul: upkeepMul,
      priceMul: priceMul);
}

/// Mechanics every tycoon game offers to the level planner.
const tycoonMechanics = ['events', 'disasters', 'rush', 'frugal', 'upkeep', 'bargain'];

/// Builds a level and calibrates its goal by letting the autopilot play it:
/// the target is a fraction of what the bot reaches in the time limit, so
/// every campaign level is provably finishable (doc 5.3).
TycoonLevel generateTycoonLevel(TycoonSpec spec, LevelSpec s) {
  final m = ArcadeMeta.of(s);
  final d = s.difficulty;
  final frugal = s.has('frugal');
  final base = TycoonLevel(
    meta: m,
    spec: spec,
    target: 0,
    limitSec: m.goal ? spec.baseSeconds + 30 - d * 6 : 0,
    events: s.has('events') || d >= 4,
    disasters: s.has('disasters'),
    rush: s.has('rush') ? 1.6 : 1.0,
    startMoney: spec.startMoney * (frugal ? 0.6 : 1.0),
    upkeepMul: s.has('upkeep') ? 1.6 : 1.0,
    priceMul: s.has('bargain') ? 0.85 : 1.0,
  );
  if (!m.goal) return base;
  final probe = TycoonSim(base);
  runBot(probe, tycoonBot, base.limitSec * kTicksPerSecond);
  final reached = probe.metric;
  final frac = 0.5 + 0.04 * d; // d10 => 90 % of the autopilot result
  final target = math.max(1.0, (reached * frac).floorToDouble());
  return base.withTarget(target);
}

class Customer {
  final int want; // resource index or -1
  double patience;
  final double maxPatience;
  final bool vip;
  Customer(this.want, this.patience, this.vip) : maxPatience = patience;
}

// Screen layout (world units) shared by painter, input and bot.
const double kSceneTop = 170;
const double kSceneBottom = 800;
const double kCardTop = 820;
const double kCardW = 310;
const double kCardH = 180;

math.Rectangle<double> cardRect(int i) =>
    math.Rectangle<double>(20 + (i % 3) * 330, kCardTop + (i ~/ 3) * 190, kCardW, kCardH);

int? cardAt(double x, double y) {
  if (y < kCardTop) return null;
  final col = ((x - 20) / 330).floor(), row = ((y - kCardTop) / 190).floor();
  if (col < 0 || col > 2 || row < 0 || row > 3) return null;
  return row * 3 + col;
}

class TycoonSim extends ArcadeSim {
  final TycoonLevel level;
  TycoonSpec get spec => level.spec;
  late final List<double> stock;
  late final List<double> made;
  late final List<int> count;
  late final List<double> manualStore;
  double earned = 0;
  double pop = 0;
  double rep = 50;
  double happiness = 1;
  final List<Customer> queue = [];
  final List<double> busy = []; // remaining service seconds per occupied slot
  final List<int> busyPay = [];
  int served = 0, lost = 0, bought = 0, clicks = 0, harvests = 0;
  double _arrAcc = 0, _serveAcc = 0, _shortT = 0;
  int eventKind = 0; // 0 none, 1 boom, 2 storm, 3 rush, 4 festival (+rep)
  int eventLeft = 0;
  int _nextEvent = 0;
  int boostLeft = 0;
  int extraTicks = 0;
  bool _timeOver = false;

  /// Sound hint: 1 buy, 2 served/harvest, 3 lost/short, 4 event, 5 coin.
  int lastEvent = 0;

  /// Index of a card that was tapped but could not be bought (UI shake).
  int denied = -1;

  TycoonSim(this.level) : super(level.meta, lives: 3) {
    final n = spec.res.length;
    stock = List.filled(n, 0);
    made = List.filled(n, 0);
    count = [for (final b in spec.blds) b.start];
    manualStore = List.filled(spec.blds.length, 0);
    stock[0] = level.startMoney;
    pop = spec.basePop;
    if (spec.population) {
      // Starting reserves so the first minute is playable.
      for (final e in spec.needs.entries) {
        stock[e.key] += e.value * math.max(4, spec.basePop) * 40;
      }
    }
    _nextEvent = 60 * (25 + rng.nextInt(15));
  }

  double get limitTicks => level.limitSec * kTicksPerSecond + extraTicks.toDouble();
  int get secondsLeft => level.limitSec == 0 ? 0 : ((limitTicks - ticks) / kTicksPerSecond).ceil().clamp(0, 99999);

  double get housing {
    var h = spec.baseHousing;
    for (var i = 0; i < count.length; i++) {
      h += spec.blds[i].housing * count[i];
    }
    return h;
  }

  int get slots {
    var s = 0;
    for (var i = 0; i < count.length; i++) {
      s += spec.blds[i].slots * count[i];
    }
    return s;
  }

  double get staffRate {
    var s = spec.baseStaff;
    for (var i = 0; i < count.length; i++) {
      s += spec.blds[i].staff * count[i];
    }
    return s;
  }

  double get incomeMul {
    var m = 1.0;
    for (var i = 0; i < count.length; i++) {
      m += spec.blds[i].boost * count[i];
    }
    if (eventKind == 1 || boostLeft > 0) m *= 1.5;
    return m;
  }

  double get prodMul {
    var m = 1.0;
    if (eventKind == 1) m += 0.5;
    if (eventKind == 2) m -= 0.5;
    if (boostLeft > 0) m += 1.0;
    return m;
  }

  bool unlocked(int i) {
    final b = spec.blds[i];
    return b.unlockRes < 0 || made[b.unlockRes] >= b.unlockAt;
  }

  double costOf(int i) => spec.blds[i].cost * level.priceMul * math.pow(spec.blds[i].growth, count[i]);

  bool canBuy(int i) => i < spec.blds.length && unlocked(i) && stock[spec.blds[i].costRes] >= costOf(i);

  bool buy(int i) {
    if (!canBuy(i)) {
      denied = i;
      return false;
    }
    stock[spec.blds[i].costRes] -= costOf(i);
    count[i]++;
    bought++;
    score += 10;
    lastEvent = 1;
    return true;
  }

  double get metric => switch (spec.goal) {
        TGoal.earn => earned,
        TGoal.population => pop,
        TGoal.produce => made[spec.goalIndex],
        TGoal.served => served.toDouble(),
        TGoal.count => count[spec.goalIndex].toDouble(),
      };

  void _earn(double v) {
    if (v <= 0) return;
    stock[0] += v;
    made[0] += v;
    earned += v;
  }

  double get manualTotal => manualStore.fold(0.0, (a, b) => a + b);

  /// Manual action on the scene: harvest, serve the first customer, or work.
  void work() {
    clicks++;
    if (manualTotal >= 1) {
      for (var i = 0; i < manualStore.length; i++) {
        final b = spec.blds[i];
        if (manualStore[i] <= 0) continue;
        for (final e in b.make.entries) {
          final amount = e.value / _makeSum(b) * manualStore[i];
          stock[e.key] += amount;
          made[e.key] += amount;
          if (e.key == 0) earned += amount;
        }
        manualStore[i] = 0;
      }
      harvests++;
      score += 3;
      lastEvent = 2;
      return;
    }
    if (queue.isNotEmpty && _tryServe(queue.first, tip: 1.3)) {
      queue.removeAt(0);
      lastEvent = 2;
      return;
    }
    _earn(spec.clickMoney * incomeMul);
    lastEvent = 5;
  }

  double _makeSum(Bld b) => b.make.values.fold(0.0, (a, v) => a + v);

  bool _tryServe(Customer c, {double tip = 1}) {
    if (c.want >= 0 && stock[c.want] < 1) return false;
    if (spec.serviceSec > 0 && busy.length >= slots) return false;
    if (c.want >= 0) stock[c.want] -= 1;
    final value = spec.pay * (0.8 + rep / 250) * (c.vip ? 2.5 : 1) * tip * (c.want >= 0 ? 1 : 1);
    if (spec.serviceSec > 0) {
      busy.add(spec.serviceSec);
      busyPay.add((value * incomeMul).round());
    } else {
      _earn(value * incomeMul);
      _done();
    }
    return true;
  }

  void _done() {
    served++;
    score += 5;
    rep = math.min(100, rep + 0.6);
    lastEvent = 2;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    denied = -1;
    const dt = kDt;
    if (input.tap && input.hasPointer) {
      final c = cardAt(input.x, input.y);
      if (c != null) {
        buy(c);
      } else if (input.y >= kSceneTop && input.y < kSceneBottom) {
        work();
      }
    }
    if (boostLeft > 0) boostLeft--;
    _events();
    final pm = prodMul;
    // Production with inputs.
    for (var i = 0; i < count.length; i++) {
      final n = count[i];
      if (n == 0) continue;
      final b = spec.blds[i];
      var ratio = 1.0;
      for (final e in b.use.entries) {
        final need = e.value * n * dt;
        if (need > 0) ratio = math.min(ratio, stock[e.key] / need);
      }
      if (ratio <= 0) continue;
      for (final e in b.use.entries) {
        stock[e.key] -= e.value * n * dt * ratio;
      }
      if (b.manual) {
        final cap = _makeSum(b) * n * 30;
        manualStore[i] = math.min(cap, manualStore[i] + _makeSum(b) * n * dt * ratio * pm);
      } else {
        for (final e in b.make.entries) {
          final v = e.value * n * dt * ratio * pm;
          if (e.key == 0) {
            _earn(v * incomeMul);
          } else {
            stock[e.key] += v;
            made[e.key] += v;
          }
        }
      }
      if (b.upkeep > 0) stock[0] = math.max(0, stock[0] - b.upkeep * n * dt * level.upkeepMul);
    }
    if (spec.population) _population(dt);
    if (spec.customers) _customers(dt);
    // Auto-sell surplus.
    for (var r = 1; r < spec.res.length; r++) {
      final rs = spec.res[r];
      if (rs.sell <= 0) continue;
      final surplus = stock[r] - rs.keep;
      if (surplus >= 1) {
        stock[r] -= surplus;
        _earn(surplus * rs.sell * incomeMul);
      }
    }
    if (ticks % 60 == 0) score += 1;
    if (level.target > 0 && metric >= level.target) {
      win();
      return;
    }
    if (level.limitSec > 0 && ticks >= limitTicks && !_timeOver) {
      _timeOver = true;
      lives = 1;
      shield = 0;
      hit();
    }
  }

  void _population(double dt) {
    final cap = housing;
    var short = false, criticalShort = false;
    for (final e in spec.needs.entries) {
      final need = pop * e.value * dt;
      if (stock[e.key] >= need) {
        stock[e.key] -= need;
      } else {
        stock[e.key] = 0;
        short = true;
        if (e.key == spec.critical) criticalShort = true;
      }
    }
    happiness += ((short ? 0.25 : 1.0) - happiness) * dt * 0.5;
    if (pop < cap && happiness > 0.55) {
      pop = math.min(cap, pop + spec.growRate * (1 + cap * 0.03) * happiness * dt);
    } else if (pop > cap) {
      pop = math.max(cap, pop - spec.growRate * dt * 2);
    } else if (short) {
      pop = math.max(0, pop - spec.growRate * 0.3 * dt);
    }
    _earn(pop * spec.tax * (0.4 + 0.6 * happiness) * dt * incomeMul);
    if (criticalShort && !meta.zen) {
      _shortT += dt;
      if (_shortT > 8) {
        _shortT = 0;
        lastEvent = 3;
        hit();
      }
    } else {
      _shortT = math.max(0, _shortT - dt);
    }
  }

  void _customers(double dt) {
    var attract = 0.0;
    for (var i = 0; i < count.length; i++) {
      attract += spec.blds[i].attract * count[i];
    }
    final rate = spec.arrival * (0.55 + rep / 110) * (1 + attract) * level.rush * (eventKind == 3 ? 1.8 : 1);
    _arrAcc += rate * dt;
    while (_arrAcc >= 1) {
      _arrAcc -= 1;
      if (queue.length >= 8) {
        lost++;
        rep = math.max(0, rep - 1);
        continue;
      }
      final want = spec.wants.isEmpty ? -1 : spec.wants[rng.nextInt(spec.wants.length)];
      queue.add(Customer(want, spec.patience * (0.8 + rng.nextDouble() * 0.4), rng.chance(0.08)));
    }
    for (final c in [...queue]) {
      c.patience -= dt;
      if (c.patience <= 0) {
        queue.remove(c);
        lost++;
        rep = math.max(0, rep - 3);
        lastEvent = 3;
      }
    }
    _serveAcc = math.min(3, _serveAcc + staffRate * dt);
    while (_serveAcc >= 1 && queue.isNotEmpty) {
      final i = queue.indexWhere((c) => (c.want < 0 || stock[c.want] >= 1));
      if (i < 0) break;
      if (!_tryServe(queue[i])) break;
      queue.removeAt(i);
      _serveAcc -= 1;
    }
    for (var i = busy.length - 1; i >= 0; i--) {
      busy[i] -= dt;
      if (busy[i] <= 0) {
        _earn(busyPay[i].toDouble());
        busy.removeAt(i);
        busyPay.removeAt(i);
        _done();
      }
    }
  }

  void _events() {
    if (eventLeft > 0) {
      eventLeft--;
      if (eventLeft == 0) eventKind = 0;
      return;
    }
    if (!level.events || ticks < _nextEvent) return;
    _nextEvent = ticks + 60 * (30 + rng.nextInt(25));
    final roll = rng.nextInt(level.disasters ? 4 : 3);
    eventKind = switch (roll) { 0 => 1, 1 => 3, 2 => 4, _ => 2 };
    eventLeft = 60 * 12;
    if (eventKind == 4) rep = math.min(100, rep + 8);
    lastEvent = 4;
  }

  @override
  void onLifeLost() {
    if (_timeOver) {
      _timeOver = false;
      extraTicks += 60 * 60; // a continue grants one more minute
    }
    if (spec.critical >= 0) {
      stock[spec.critical] += math.max(5, pop) * (spec.needs[spec.critical] ?? 0.1) * 40;
    }
  }

  /// Booster: production frenzy (double output, +50 % income) for 20 s.
  @override
  bool useBooster() {
    if (over) return false;
    boostLeft = 60 * 20;
    return true;
  }

  @override
  double get progress => level.target == 0 ? 0 : (metric / level.target).clamp(0, 1);

  @override
  String get goalText => level.target == 0 ? fmtNum(metric) : '${fmtNum(metric)}/${fmtNum(level.target)}';

  @override
  Map<String, int> get stats => {
        'buildings_bought': bought,
        'money_earned': earned.floor(),
        'customers_served': served,
        'population_peak': pop.floor(),
        'harvests': harvests,
      };

  @override
  int get stars {
    if (!won) return 0;
    if (level.limitSec == 0) return 3;
    final used = ticks / (level.limitSec * kTicksPerSecond);
    final s = used <= 0.7 ? 3 : (used <= 0.9 ? 2 : 1);
    return (s - revives).clamp(1, 3);
  }
}

String fmtNum(double v) {
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e4) return '${(v / 1e3).toStringAsFixed(1)}K';
  return v.floor().toString();
}

/// Greedy planner used for validation, calibration and the demo.
ArcadeInput tycoonBot(ArcadeSim sim) {
  final s = sim as TycoonSim;
  if (s.ticks % 12 != 0) return ArcadeInput.idle;
  final a = tycoonBotAction(s);
  if (a == null) return ArcadeInput.idle;
  if (a < 0) return const ArcadeInput(tap: true, down: true, x: 500, y: 500);
  final r = cardRect(a);
  return ArcadeInput(tap: true, down: true, x: (r.left + r.width / 2).roundToDouble(), y: (r.top + r.height / 2).roundToDouble());
}

/// Returns a card index to buy, -1 for a scene tap, null to wait.
int? tycoonBotAction(TycoonSim s) {
  final spec = s.spec;
  // Harvest every ~1.2 s when crops wait (leaves time to invest).
  if (s.manualTotal >= 3 && (s.ticks ~/ 12) % 6 == 0) return -1;
  // Spend non-money currencies (army, research) as soon as possible.
  for (var i = 0; i < spec.blds.length; i++) {
    if (spec.blds[i].costRes != 0 && s.canBuy(i) && _value(s, i) > 0) return i;
  }
  // 1. Fix shortages of needs / starving inputs first.
  if (spec.population) {
    for (final e in spec.needs.entries) {
      final perSec = s.pop * e.value;
      if (s.stock[e.key] < perSec * 25 && _netRate(s, e.key) < perSec * 1.1) {
        final b = _cheapestMaker(s, e.key);
        if (b != null) return s.canBuy(b) ? b : _fallback(s);
      }
    }
  }
  if (spec.customers && s.queue.length >= 4) {
    // Service capacity or stock of the most wanted item.
    for (final c in s.queue) {
      if (c.want >= 0 && s.stock[c.want] < 1) {
        final b = _cheapestMaker(s, c.want);
        if (b != null) return s.canBuy(b) ? b : _fallback(s);
      }
    }
    int? best;
    for (var i = 0; i < spec.blds.length; i++) {
      final b = spec.blds[i];
      if ((b.staff > 0 || (spec.serviceSec > 0 && b.slots > 0)) && s.unlocked(i)) {
        if (best == null || s.costOf(i) < s.costOf(best)) best = i;
      }
    }
    if (best != null && s.canBuy(best)) return best;
  }
  // 2. Best return on investment.
  int? best;
  var bestScore = 0.0;
  for (var i = 0; i < spec.blds.length; i++) {
    if (!s.unlocked(i) || spec.blds[i].costRes != 0) continue;
    final v = _value(s, i);
    if (v <= 0) continue;
    final sc = v / s.costOf(i);
    if (sc > bestScore) {
      bestScore = sc;
      best = i;
    }
  }
  if (best != null) {
    // Feed the chain first: an input that is not supplied => buy its maker.
    for (final e in spec.blds[best].use.entries) {
      if (_netRate(s, e.key) < e.value && s.stock[e.key] < 30) {
        final m = _cheapestMaker(s, e.key);
        if (m != null && m != best) {
          best = m;
          break;
        }
      }
    }
    if (s.canBuy(best!)) return best;
  }
  return _fallback(s);
}

int? _fallback(TycoonSim s) => s.spec.clickMoney > 0 || s.queue.isNotEmpty ? -1 : null;

double _netRate(TycoonSim s, int r) {
  var v = 0.0;
  for (var i = 0; i < s.count.length; i++) {
    final b = s.spec.blds[i];
    v += (b.make[r] ?? 0) * s.count[i] - (b.use[r] ?? 0) * s.count[i];
  }
  return v;
}

int? _cheapestMaker(TycoonSim s, int r) {
  int? best;
  for (var i = 0; i < s.spec.blds.length; i++) {
    final b = s.spec.blds[i];
    if (!s.unlocked(i) || (b.make[r] ?? 0) <= 0) continue;
    // Its own inputs must be available.
    if (b.use.keys.any((k) => _netRate(s, k) <= 0 && s.stock[k] < 5)) continue;
    if (best == null || s.costOf(i) < s.costOf(best)) best = i;
  }
  return best;
}

double _resValue(TycoonSim s, int r) {
  final rs = s.spec.res[r];
  if (r == 0) return 1;
  if (rs.sell > 0) return rs.sell;
  return rs.value;
}

double _value(TycoonSim s, int i) {
  final spec = s.spec;
  final b = spec.blds[i];
  var v = 0.0;
  for (final e in b.make.entries) {
    v += e.value * _resValue(s, e.key);
  }
  for (final e in b.use.entries) {
    // Inputs nobody produces make the building useless.
    if (_netRate(s, e.key) <= e.value * 0.5 && s.stock[e.key] < 10 && (_cheapestMaker(s, e.key) == null)) return 0;
    v -= e.value * _resValue(s, e.key) * 0.5;
  }
  v -= b.upkeep;
  if (spec.population && b.housing > 0) {
    final room = s.housing - s.pop;
    v += b.housing * spec.tax * (room < 3 ? 1.2 : 0.2);
  }
  if (spec.customers) {
    final pressure = (s.queue.length + 1) / 4;
    v += b.staff * spec.pay * 0.6 * pressure;
    if (spec.serviceSec > 0) v += b.slots * spec.pay / spec.serviceSec * (s.busy.length >= s.slots ? 1.4 : 0.3);
    v += b.attract * spec.arrival * spec.pay * 2;
  }
  if (b.boost > 0) v += b.boost * math.max(1, s.earned / math.max(1, s.seconds)) * 0.8;
  if (spec.goal == TGoal.count && spec.goalIndex == i) v += s.costOf(i) * 0.02 + 1;
  if (spec.goal == TGoal.produce) v += (b.make[spec.goalIndex] ?? 0) * 3;
  if (spec.goal == TGoal.count) {
    final cur = spec.blds[spec.goalIndex].costRes;
    if (cur != 0) v += (b.make[cur] ?? 0) * spec.res[cur].value * 2;
  }
  return v;
}
