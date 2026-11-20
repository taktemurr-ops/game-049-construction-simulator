import 'package:flutter/material.dart';

import '../app/arcade_stage.dart';
import '../app/game_api.dart';
import '../core/game_rules.dart';
import 'tycoon_engine.dart';
import 'rules.dart';
import 'tycoon_view.dart';

const _theme = TycoonTheme(Color(0xFFFFE8A3), Color(0xFFB08968), Color(0xFFF77F00));



final gameConfig = GameConfig(
  gameId: 'game-049-construction-simulator',
  title: const ['İnşaat Simülatörü', 'Construction Simulator', 'Construction Simulator', 'Construction Simulator', 'Construction Simulator'],
  tagline: const ['Kaz, beton dök, gökdelenleri kat kat yükselt!', 'Dig, pour and raise skyscrapers floor by floor!', 'Dig, pour and raise skyscrapers floor by floor!', 'Dig, pour and raise skyscrapers floor by floor!', 'Dig, pour and raise skyscrapers floor by floor!'],
  seedColor: const Color(0xFFFFB703),
  icon: Icons.construction,
  rules: BuildRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => TycoonSim((ctx.generated as GeneratedLevel<TycoonLevel>).puzzle),
    paint: (c, s, p, t) => paintTycoon(c, s, p, t, ctx.lang == 'tr', _theme),
    sound: tycoonSound,
    boosterIcon: Icons.bolt,
    boosterLabel: (l) => l == 'tr' ? 'Çılgın üretim' : 'Production frenzy',
    howTo: const [
      'Hammadde zinciri kur, ara ürünleri birleştir ve hedef sayıda son ürünü üret.',
      'Build the supply chain, combine parts and produce the target amount.',
      'Baue die Lieferkette und produziere das Ziel.',
      'Construye la cadena y produce el objetivo.',
      'Construisez la chaîne et produisez l\'objectif.',
    ],
  ),
  tutorial: const [
    TutorialStep(Icons.touch_app, [
      'Kartlara dokun: bina al. Sarı fiyat = alınabilir.',
      'Tap cards to buy. Yellow price = affordable.',
      'Karten antippen zum Kaufen.',
      'Toca las cartas para comprar.',
      'Touchez les cartes pour acheter.',
    ]),
    TutorialStep(Icons.pan_tool, [
      'Sahneye dokun: çalış, hasat et veya ilk müşteriye hemen servis yap.',
      'Tap the scene: work, harvest or serve the first customer.',
      'Szene antippen: arbeiten oder ernten.',
      'Toca la escena: trabajar o cosechar.',
      'Touchez la scène : travailler ou récolter.',
    ]),
    TutorialStep(Icons.bolt, [
      'Çılgın üretim güçlendirmesi 20 sn boyunca üretimi ikiye katlar.',
      'Production frenzy doubles output for 20 s.',
      'Produktionsrausch verdoppelt 20 s.',
      'Frenesí duplica la producción 20 s.',
      'Frénésie : production ×2 pendant 20 s.',
    ]),
  ],
);
