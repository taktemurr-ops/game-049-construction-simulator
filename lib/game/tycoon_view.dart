import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/arcade_stage.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/arcade.dart';
import 'tycoon_engine.dart';

/// Visual theme of a management game.
class TycoonTheme {
  final Color sky, ground, accent;
  final bool night;
  const TycoonTheme(this.sky, this.ground, this.accent, {this.night = false});
}

/// Draws HUD, the living scene (buildings, customers, slots) and the
/// purchase cards. Shared by every strategy/management game.
void paintTycoon(Canvas c, ArcadeSim sim, ArcadePalette p, double t, bool tr, TycoonTheme th) {
  final s = sim as TycoonSim;
  final spec = s.spec;
  // ---- scene ----
  final scene = Rect.fromLTWH(0, kSceneTop, kWorldW, kSceneBottom - kSceneTop);
  c.drawRect(
      scene,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [th.sky, Color.lerp(th.sky, th.ground, 0.6)!],
        ).createShader(scene));
  if (th.night) {
    final star = Paint()..color = Colors.white70;
    for (var i = 0; i < 40; i++) {
      final x = (i * 137.0) % kWorldW, y = kSceneTop + (i * 71.0) % 260;
      c.drawCircle(Offset(x, y), (i % 3 == 0 && !p.reducedMotion) ? 2 + math.sin(t * 3 + i) : 1.6, star);
    }
  }
  c.drawRect(Rect.fromLTWH(0, 620, kWorldW, kSceneBottom - 620), Paint()..color = th.ground);
  // Buildings: one icon per owned type, size grows with the count.
  var slot = 0;
  for (var i = 0; i < spec.blds.length; i++) {
    final n = s.count[i];
    if (n == 0) continue;
    final b = spec.blds[i];
    final col = slot % 6, row = slot ~/ 6;
    final cx = 90.0 + col * 164, base = 600.0 + row * 90 - (row > 0 ? 210 : 0);
    final size = 46 + math.min(40, n * 4).toDouble();
    _building(c, b.shape, Offset(cx, base), size, Color(b.color), p.reducedMotion ? 0 : t, n);
    if (s.manualStore[i] >= 1) {
      final pulse = p.reducedMotion ? 1.0 : 1 + 0.15 * math.sin(t * 6);
      c.drawCircle(Offset(cx + size * 0.5, base - size - 6), 16 * pulse, Paint()..color = const Color(0xFFFFD60A));
      paintText(c, '!', Offset(cx + size * 0.5, base - size - 6), 22, Colors.black);
    }
    paintText(c, '×$n', Offset(cx, base + 22), 24, Colors.white);
    slot++;
    if (slot >= 12) break;
  }
  if (slot == 0) {
    paintText(c, tr ? 'Aşağıdan ilk binanı kur' : 'Build your first building below', const Offset(500, 520), 32,
        Colors.white70);
  }
  // Customers queue.
  if (spec.customers) {
    for (var i = 0; i < s.queue.length; i++) {
      final q = s.queue[i];
      final x = 70.0 + i * 64, y = 770.0;
      final col = q.want >= 0 ? Color(spec.res[q.want].color) : th.accent;
      c.drawCircle(Offset(x, y - 34), 14, Paint()..color = const Color(0xFFFFE0BD));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 34, height: 42), const Radius.circular(10)),
          Paint()..color = q.vip ? const Color(0xFFFFD60A) : col);
      final f = (q.patience / q.maxPatience).clamp(0.0, 1.0);
      c.drawRect(Rect.fromLTWH(x - 20, y + 26, 40 * f, 6),
          Paint()..color = f > 0.4 ? const Color(0xFF7BD389) : const Color(0xFFEF476F));
    }
    if (spec.serviceSec > 0) {
      final total = math.max(1, s.slots);
      for (var i = 0; i < math.min(total, 16); i++) {
        final x = 620.0 + (i % 8) * 46, y = 690.0 + (i ~/ 8) * 40;
        final busy = i < s.busy.length;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 38, 30), const Radius.circular(6)),
            Paint()..color = busy ? th.accent : Colors.white24);
        if (busy) {
          final f = 1 - (s.busy[i] / spec.serviceSec).clamp(0.0, 1.0);
          c.drawRect(Rect.fromLTWH(x + 2, y + 24, 34 * f, 4), Paint()..color = Colors.white);
        }
      }
    }
  }
  // Event banner.
  if (s.eventKind != 0 || s.boostLeft > 0) {
    final txt = s.boostLeft > 0
        ? (tr ? 'ÇILGIN ÜRETİM ×2' : 'PRODUCTION FRENZY ×2')
        : switch (s.eventKind) {
            1 => tr ? 'Bereket! Üretim +%50' : 'Boom! Output +50%',
            2 => tr ? 'Fırtına! Üretim -%50' : 'Storm! Output -50%',
            3 => tr ? 'Yoğunluk! Daha çok ${spec.unitTr}' : 'Rush! More ${spec.unitEn}',
            _ => tr ? 'Festival! İtibar arttı' : 'Festival! Reputation up',
          };
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(160, 190, 680, 56), const Radius.circular(28)),
        Paint()..color = Colors.black45);
    paintText(c, txt, const Offset(500, 218), 30, const Color(0xFFFFD60A));
  }
  // ---- HUD ----
  c.drawRect(const Rect.fromLTWH(0, 0, kWorldW, kSceneTop), Paint()..color = Colors.black.withValues(alpha: 0.35));
  _chip(c, 20, 18, const Color(0xFFFFD60A), '${tr ? 'Para' : 'Money'} ${fmtNum(s.stock[0])}');
  final goal = tr ? spec.goalTr : spec.goalEn;
  _chip(c, 360, 18, Colors.white, '$goal ${s.goalText}');
  if (s.level.limitSec > 0) {
    final left = s.secondsLeft;
    _chip(c, 820, 18, left < 30 ? const Color(0xFFEF476F) : Colors.white70,
        '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}');
  }
  var x = 20.0;
  if (spec.population) {
    x = _chip(c, x, 92, const Color(0xFF8ECAE6), '${tr ? 'Nüfus' : 'Pop'} ${s.pop.floor()}/${s.housing.floor()}') + 12;
    x = _chip(c, x, 92, s.happiness > 0.6 ? const Color(0xFF7BD389) : const Color(0xFFEF476F),
            '${tr ? 'Mutluluk' : 'Joy'} ${(s.happiness * 100).round()}%') +
        12;
  }
  if (spec.customers) {
    x = _chip(c, x, 92, const Color(0xFFFFB4A2), '${tr ? 'İtibar' : 'Rep'} ${s.rep.round()}') + 12;
  }
  for (var r = 1; r < spec.res.length && x < 900; r++) {
    final rs = spec.res[r];
    if (rs.sell > 0 && s.stock[r] < 1) continue;
    x = _chip(c, x, 92, Color(rs.color), '${tr ? rs.tr : rs.en} ${fmtNum(s.stock[r])}') + 12;
  }
  // ---- cards ----
  for (var i = 0; i < spec.blds.length && i < 12; i++) {
    final b = spec.blds[i];
    final r = cardRect(i);
    final rect = Rect.fromLTWH(r.left, r.top, r.width, r.height);
    final open = s.unlocked(i);
    final afford = s.canBuy(i);
    final shake = s.denied == i ? 6.0 : 0.0;
    final rr = RRect.fromRectAndRadius(rect.shift(Offset(shake, 0)), const Radius.circular(22));
    c.drawRRect(rr, Paint()..color = open ? (afford ? const Color(0xFF2B2D42) : const Color(0xFF1F2033)) : Colors.black54);
    c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = afford ? 4 : 2
          ..color = afford ? th.accent : Colors.white24);
    if (!open) {
      final u = spec.res[b.unlockRes];
      paintText(c, tr ? 'Kilitli' : 'Locked', Offset(rect.center.dx, rect.top + 50), 34, Colors.white54);
      paintText(c, '${tr ? u.tr : u.en} ${fmtNum(b.unlockAt)}', Offset(rect.center.dx, rect.top + 120), 26,
          Colors.white54);
      continue;
    }
    _building(c, b.shape, Offset(rect.left + 52, rect.top + 92), 50, Color(b.color), 0, 1);
    paintText(c, tr ? b.tr : b.en, Offset(rect.left + 195, rect.top + 36), 26, Colors.white);
    paintText(c, '×${s.count[i]}', Offset(rect.left + 195, rect.top + 78), 26, Colors.white70);
    final cur = spec.res[b.costRes];
    paintText(c, '${b.costRes == 0 ? '' : '${tr ? cur.tr : cur.en} '}${fmtNum(s.costOf(i))}',
        Offset(rect.left + 195, rect.top + 128), 30, afford ? const Color(0xFFFFD60A) : Colors.white38);
  }
}

double _chip(Canvas c, double x, double y, Color col, String text) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: 30, color: col, fontWeight: FontWeight.bold)),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = tp.width + 32;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 56), const Radius.circular(28)),
      Paint()..color = Colors.black38);
  tp.paint(c, Offset(x + 16, y + 28 - tp.height / 2));
  return x + w;
}

void _building(Canvas c, int shape, Offset base, double size, Color col, double t, int n) {
  final body = Paint()..color = col;
  final dark = Paint()..color = Color.lerp(col, Colors.black, 0.35)!;
  final w = size, h = size;
  switch (shape) {
    case 0: // house
      c.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - h * 0.6, w, h * 0.6), body);
      c.drawPath(
          Path()
            ..moveTo(base.dx - w * 0.62, base.dy - h * 0.58)
            ..lineTo(base.dx, base.dy - h * 1.05)
            ..lineTo(base.dx + w * 0.62, base.dy - h * 0.58)
            ..close(),
          dark);
      c.drawRect(Rect.fromLTWH(base.dx - w * 0.1, base.dy - h * 0.3, w * 0.2, h * 0.3), Paint()..color = Colors.white70);
    case 1: // factory
      c.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - h * 0.55, w, h * 0.55), body);
      c.drawRect(Rect.fromLTWH(base.dx + w * 0.2, base.dy - h * 1.0, w * 0.18, h * 0.45), dark);
      final puff = t == 0 ? 0.0 : (t * 0.8) % 1;
      c.drawCircle(Offset(base.dx + w * 0.29, base.dy - h * (1.05 + puff * 0.4)), w * 0.12 * (1 - puff * 0.5),
          Paint()..color = Colors.white.withValues(alpha: 0.6 * (1 - puff)));
    case 2: // field
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - w * 0.6, base.dy - h * 0.35, w * 1.2, h * 0.35), const Radius.circular(8)),
          dark);
      for (var i = 0; i < 4; i++) {
        final sway = t == 0 ? 0.0 : math.sin(t * 2 + i) * 3;
        c.drawCircle(Offset(base.dx - w * 0.45 + i * w * 0.3 + sway, base.dy - h * 0.45), w * 0.12, body);
      }
    case 3: // tower
      c.drawRect(Rect.fromLTWH(base.dx - w * 0.22, base.dy - h * 1.1, w * 0.44, h * 1.1), body);
      c.drawRect(Rect.fromLTWH(base.dx - w * 0.32, base.dy - h * 1.2, w * 0.64, h * 0.16), dark);
    case 4: // dome
      c.drawArc(Rect.fromCenter(center: base, width: w * 1.2, height: h * 1.2), math.pi, math.pi, true, body);
      c.drawArc(Rect.fromCenter(center: base, width: w * 0.7, height: h * 0.7), math.pi, math.pi, true,
          Paint()..color = Colors.white24);
    case 5: // shop with awning
      c.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - h * 0.7, w, h * 0.7), Paint()..color = Colors.white70);
      for (var i = 0; i < 4; i++) {
        c.drawRect(Rect.fromLTWH(base.dx - w / 2 + i * w / 4, base.dy - h * 0.8, w / 4, h * 0.2), i.isEven ? body : dark);
      }
    default: // tank / silo
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - w * 0.3, base.dy - h, w * 0.6, h), Radius.circular(w * 0.3)), body);
      c.drawRect(Rect.fromLTWH(base.dx - w * 0.3, base.dy - h * 0.5, w * 0.6, h * 0.08), dark);
  }
  if (n > 1) {
    c.drawCircle(Offset(base.dx + w * 0.5, base.dy - h * 0.15), 3, Paint()..color = Colors.white54);
  }
}

Sfx? tycoonSound(ArcadeSim sim) => switch ((sim as TycoonSim).lastEvent) {
      1 => Sfx.place,
      2 => Sfx.coin,
      3 => Sfx.error,
      4 => Sfx.unlock,
      5 => Sfx.tap,
      _ => null,
    };
