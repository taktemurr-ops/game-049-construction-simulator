import 'tycoon_engine.dart';

const buildSpec = TycoonSpec(
  res: [
    Res('cash', 'Bütçe', 'Budget', 0xFFFFD60A),
    Res('sand', 'Kum', 'Sand', 0xFFE9C46A, sell: 0.3, keep: 30, value: 0.3),
    Res('concrete', 'Beton', 'Concrete', 0xFFADB5BD, sell: 1.6, keep: 20, value: 1.6),
    Res('steel', 'Çelik', 'Steel', 0xFF6C757D, sell: 2.5, keep: 15, value: 2.5),
    Res('floor', 'Kat', 'Floor', 0xFFFFB703, sell: 70, value: 70),
  ],
  blds: [
    Bld('digger', 'Kepçe', 'Digger', 15, make: {1: 1.0}, start: 1, shape: 6, color: 0xFFFFB703),
    Bld('mixer', 'Beton mikseri', 'Cement mixer', 60, make: {2: 0.5}, use: {1: 1.0}, shape: 1, color: 0xFFADB5BD),
    Bld('foundry', 'Çelik atölyesi', 'Steel shop', 140, make: {3: 0.35}, shape: 1, color: 0xFF6C757D),
    Bld('crane', 'Vinç', 'Tower crane', 260, make: {4: 0.08}, use: {2: 1.2, 3: 0.6}, unlockRes: 2, unlockAt: 20, shape: 3, color: 0xFFF77F00),
    Bld('truck', 'Damperli kamyon', 'Dump truck', 200, make: {1: 3.5}, shape: 6, color: 0xFFE9C46A),
    Bld('foreman', 'Şantiye şefi', 'Site foreman', 220, boost: 0.08, shape: 0, color: 0xFFE63946),
    Bld('plant', 'Beton santrali', 'Concrete plant', 650, make: {2: 2.2}, use: {1: 4.4}, unlockRes: 2, unlockAt: 60, shape: 1, color: 0xFF8D99AE),
    Bld('mill', 'Haddehane', 'Rolling mill', 900, make: {3: 1.6}, unlockRes: 3, unlockAt: 40, shape: 1, color: 0xFF495057),
    Bld('bigcrane', 'Dev vinç', 'Mega crane', 1500, make: {4: 0.4}, use: {2: 6, 3: 3}, unlockRes: 4, unlockAt: 5, shape: 3, color: 0xFFDC2F02),
    Bld('engineer', 'Mühendis', 'Engineer', 1400, boost: 0.25, unlockRes: 4, unlockAt: 10, shape: 0, color: 0xFF219EBC),
    Bld('contract', 'Kamu ihalesi', 'Public tender', 3000, boost: 0.4, unlockRes: 4, unlockAt: 25, shape: 4, color: 0xFF5E60CE),
  ],
  startMoney: 40,
  clickMoney: 2,
  goal: TGoal.produce,
  goalIndex: 4,
  goalTr: 'Kat',
  goalEn: 'Floors',
  unitTr: 'kat',
  unitEn: 'floors',
);
