import '../core/arcade.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'build_spec.dart';
import 'tycoon_rules.dart';

class BuildRules extends TycoonRules {
  BuildRules()
      : super(buildSpec, 'game-049-construction-simulator', const [
          GameStat('money_earned', 'İnşaat geliri', 'Construction revenue', scale: 10000),
          GameStat('buildings_bought', 'Makine', 'Machines', scale: 40),
          GameStat('customers_served', 'Teslim', 'Deliveries', scale: 20),
        ], const [
          MissionTemplate('money_earned', 'money_earned', [3333, 6666, 10000]),
          MissionTemplate('buildings_bought', 'buildings_bought', [13, 26, 40]),
        ]);
}

ArcadeRules createRules() => BuildRules();
