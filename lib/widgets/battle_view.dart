import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/character.dart';
import '../models/tile_grid.dart';
import '../models/game_state.dart';
import 'glass_panel.dart';

class ProjectileEffect {
  final String id;
  final String emoji;
  final Offset start;
  final Offset end;
  final double progress; // 0.0 ~ 1.0
  final double scale; // 투사체 크기 스케일 (스킬인 경우 크게)

  ProjectileEffect({
    required this.id,
    required this.emoji,
    required this.start,
    required this.end,
    required this.progress,
    this.scale = 1.0,
  });

  ProjectileEffect copyWith({double? progress}) {
    return ProjectileEffect(
      id: id,
      emoji: emoji,
      start: start,
      end: end,
      progress: progress ?? this.progress,
      scale: scale,
    );
  }
}

class DamageTextEffect {
  final String id;
  final String text;
  final Offset position;
  final Color color;
  final double opacity;
  final double fontSize;

  DamageTextEffect({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    required this.opacity,
    this.fontSize = 20.0,
  });

  DamageTextEffect copyWith({Offset? position, double? opacity}) {
    return DamageTextEffect(
      id: id,
      text: text,
      position: position ?? this.position,
      color: color,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize,
    );
  }
}

class BattleView extends StatefulWidget {
  const BattleView({super.key});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  Timer? _battleTimer;
  int _currentTurnNumber = 1;
  int _roundCount = 1;
  bool _isAnimating = false;
  bool _resultShown = false;
  String _combatPhaseText = '전투 시작 대기 중...';

  List<ProjectileEffect> _projectiles = [];
  List<DamageTextEffect> _damageTexts = [];

  final Map<Point<int>, Offset> _playerTileOffsets = {};
  final Map<Point<int>, Offset> _opponentTileOffsets = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCombatSimulation();
    });
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    super.dispose();
  }

  // --- 전투 시뮬레이션 루프 개시 ---
  void _startCombatSimulation() {
    final gameState = Provider.of<GameState>(context, listen: false);

    setState(() {
      _combatPhaseText = '제 $_roundCount 라운드 시작!';
    });
    gameState.battleLog.add('🔔 [라운드 $_roundCount] 격돌이 시작됩니다!');
    _applyPoisonTick();

    _battleTimer = Timer.periodic(const Duration(milliseconds: 1700), (timer) {
      if (_isAnimating) return;
      _runNextCombatTurn();
    });
  }

  // 독 상태 틱 대미지 처리 (라운드 시작 시점)
  void _applyPoisonTick() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid;
    final oGrid = gameState.battleOpponentGrid;
    if (pGrid == null || oGrid == null) return;

    void tick(TileGrid grid, bool isPlayer) {
      final team = isPlayer ? '[아군]' : '[적군]';
      for (final tile in grid.tiles.values) {
        final char = tile.character;
        if (char != null && !char.isDead && char.poisonDuration > 0) {
          char.takeDamage(char.poisonDamage);
          char.poisonDuration--;
          gameState.battleLog.add(
              '$team ${char.emoji} ${char.name}이 화학 물질 중독으로 ${char.poisonDamage}의 피해를 입었습니다! (남은 턴: ${char.poisonDuration})');

          _spawnDamageText('🧪-${char.poisonDamage}', tile.position, isPlayer,
              Colors.purpleAccent);

          if (char.isDead) {
            gameState.battleLog
                .add('💀 $team ${char.emoji} ${char.name}이 독성 과다로 사망했습니다.');
            char.deathHandled = true;
            _handleDeathTrigger(char, isPlayer);
          }
        }
      }
    }

    tick(pGrid, true);
    tick(oGrid, false);
    _checkVictoryOrDefeat();
  }

  // --- 특정 순서(번호)의 턴 액션 실행 ---
  void _runNextCombatTurn() async {
    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid;
    final oGrid = gameState.battleOpponentGrid;
    if (pGrid == null || oGrid == null) return;

    final maxOrder = max(pGrid.count, oGrid.count);

    if (_currentTurnNumber > maxOrder) {
      _currentTurnNumber = 1;
      _roundCount++;
      gameState.battleLog.add('🔄 모든 구역 순회가 끝나고 제 $_roundCount 라운드로 순환합니다!');
      _applyPoisonTick();
      setState(() {
        _combatPhaseText = '제 $_roundCount 라운드 시작!';
      });
      return;
    }

    final tileA = pGrid.tiles.values.firstWhere(
        (t) => t.orderNumber == _currentTurnNumber,
        orElse: () => Tile(position: const Point(-999, -999)));
    final tileB = oGrid.tiles.values.firstWhere(
        (t) => t.orderNumber == _currentTurnNumber,
        orElse: () => Tile(position: const Point(-999, -999)));

    final charA = (tileA.position.x != -999 &&
            tileA.character != null &&
            !tileA.character!.isDead)
        ? tileA.character
        : null;
    final charB = (tileB.position.x != -999 &&
            tileB.character != null &&
            !tileB.character!.isDead)
        ? tileB.character
        : null;

    if (charA == null && charB == null) {
      _currentTurnNumber++;
      return;
    }

    setState(() {
      _isAnimating = true;
      _combatPhaseText = '동시 격돌: $_currentTurnNumber번 구역';
    });

    _executeCombatAction(tileA, charA, tileB, charB);
  }

  // --- 전투 행동 연산 및 애니메이션 연출 트리거 ---
  void _executeCombatAction(Tile? tileA, CharacterInstance? charA, Tile? tileB,
      CharacterInstance? charB) async {
    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid!;
    final oGrid = gameState.battleOpponentGrid!;

    final media = MediaQuery.of(context).size;
    final double screenWidth = media.width;
    final double screenHeight = media.height;

    const double S = 65.0;
    final double oGridCenterY = screenHeight * 0.22;
    final double pGridCenterY = screenHeight * 0.60;
    final double centerX = screenWidth / 2;

    double avgXPlayer =
        pGrid.tiles.keys.map((p) => p.x).reduce((a, b) => a + b) / pGrid.count;
    double avgYPlayer =
        pGrid.tiles.keys.map((p) => p.y).reduce((a, b) => a + b) / pGrid.count;
    double avgXOpp =
        oGrid.tiles.keys.map((p) => p.x).reduce((a, b) => a + b) / oGrid.count;
    double avgYOpp =
        oGrid.tiles.keys.map((p) => p.y).reduce((a, b) => a + b) / oGrid.count;

    Offset getTileOffset(Point<int> pos, {required bool isPlayer}) {
      if (isPlayer) {
        return Offset(
          centerX + (pos.x - avgXPlayer) * (S + 8) - (S / 2),
          pGridCenterY + (pos.y - avgYPlayer) * (S + 8) - (S / 2),
        );
      } else {
        return Offset(
          centerX - (pos.x - avgXOpp) * (S + 8) - (S / 2),
          oGridCenterY - (pos.y - avgYOpp) * (S + 8) - (S / 2),
        );
      }
    }

    final List<ProjectileEffect> newProjectiles = [];
    final List<DamageTextEffect> newDamageTexts = [];

    if (charA != null && tileA != null) {
      _playerTileOffsets[tileA.position] = const Offset(0, -15);
    }
    if (charB != null && tileB != null) {
      _opponentTileOffsets[tileB.position] = const Offset(0, 15);
    }
    setState(() {});

    final random = Random();

    // 15% 크리티컬 판정 헬퍼
    Map<String, dynamic> calculateDamage(int baseAtk, {required bool isSkill}) {
      final isCrit =
          !isSkill && (random.nextDouble() < 0.15); // 스킬은 고정 피해, 평타만 크리티컬 적용
      final finalDmg = isCrit ? (baseAtk * 1.5).toInt() : baseAtk;
      return {'damage': finalDmg, 'isCrit': isCrit};
    }

    // --- 아군 A 행동 연산 ---
    if (charA != null && tileA != null) {
      final startOffset = getTileOffset(tileA.position, isPlayer: true) +
          const Offset(S / 2, S / 2);

      // 마나가 100 이상이면 스킬 발동!
      if (charA.mana >= 100) {
        charA.mana = 0; // 마나 초기화

        if (charA.type == CharacterType.lunchLady) {
          // 스킬: 고기반찬 치유
          final targetTile = _getLowestHpTarget(pGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            targetChar.heal(80); // 스킬 힐은 더 강력함
            gameState.battleLog.add(
                '🧑‍🍳 [아군] 급식 이모가 따뜻한 스페셜 햄 반찬으로 ${targetChar.name}을 80 치유했습니다!');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: true) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_heal_${charA.id}',
              emoji: '💖',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_heal_${charA.id}',
              text: '💖+80',
              position: endOffset + const Offset(0, -20),
              color: Colors.greenAccent,
              opacity: 1.0,
              fontSize: 24,
            ));
          }
        } else if (charA.type == CharacterType.captain) {
          // 스킬: 관통 대포슛 (1.5배 피해)
          final targetTiles = _getRowTargets(oGrid, tileA.position.y);
          if (targetTiles.isNotEmpty) {
            gameState.battleLog
                .add('⚽ [아군] 축구부 주장이 불꽃 캐논 슛으로 동일 선상의 모든 적을 관통 공격합니다!');
            for (final t in targetTiles) {
              final targetChar = t.character!;
              final dmgInfo = calculateDamage(
                  (charA.currentAttack * 1.5).toInt(),
                  isSkill: true);
              final dmg = dmgInfo['damage'] as int;

              targetChar.takeDamage(dmg);
              gameState.battleLog
                  .add('  ↳ [적군] ${targetChar.name}에게 $dmg 스킬 대미지!');

              final endOffset = getTileOffset(t.position, isPlayer: false) +
                  const Offset(S / 2, S / 2);
              newProjectiles.add(ProjectileEffect(
                id: 'proj_capt_${charA.id}_${t.position.x}',
                emoji: '⚽🔥',
                start: startOffset,
                end: endOffset,
                progress: 0.0,
                scale: 1.6,
              ));
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_capt_${charA.id}_${t.position.x}',
                text: '🔥-$dmg',
                position: endOffset + const Offset(0, -20),
                color: Colors.orangeAccent,
                opacity: 1.0,
                fontSize: 22,
              ));
            }
          }
        } else if (charA.type == CharacterType.studious) {
          // 스킬: 정밀 저격 (2.0배 피해)
          final targetTile = _getLowestHpTarget(oGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            final dmgInfo =
                calculateDamage(charA.currentAttack * 2, isSkill: true);
            final dmg = dmgInfo['damage'] as int;

            targetChar.takeDamage(dmg);
            gameState.battleLog.add(
                '📝 [아군] 전교 1등이 정밀 약점 저격! ${targetChar.name}에게 $dmg 스킬 대미지!');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: false) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_stud_${charA.id}',
              emoji: '📝✨',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_stud_${charA.id}',
              text: '✨-$dmg',
              position: endOffset + const Offset(0, -20),
              color: Colors.amberAccent,
              opacity: 1.0,
              fontSize: 24,
            ));
          }
        } else if (charA.type == CharacterType.chemTeacher) {
          // 스킬: 화학식 독극물 투척
          final targetTiles = _getRandomTargets(oGrid, 3);
          if (targetTiles.isNotEmpty) {
            gameState.battleLog.add('🧪 [아군] 화학 선생님이 유독성 화합물을 던집니다!');
            for (final t in targetTiles) {
              final targetChar = t.character!;
              targetChar.poisonDuration = 3;
              targetChar.poisonDamage = 15;
              targetChar.takeDamage(charA.currentAttack);
              gameState.battleLog.add(
                  '  ↳ [적군] ${targetChar.name}에게 ${charA.currentAttack} 대미지 및 3턴 독 부여');

              final endOffset = getTileOffset(t.position, isPlayer: false) +
                  const Offset(S / 2, S / 2);
              newProjectiles.add(ProjectileEffect(
                id: 'proj_chem_${charA.id}_${t.position.x}_${t.position.y}',
                emoji: '🧪☠️',
                start: startOffset,
                end: endOffset,
                progress: 0.0,
                scale: 1.5,
              ));
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_chem_${charA.id}_${t.position.x}_${t.position.y}',
                text: '💥-${charA.currentAttack} 🧪독',
                position: endOffset + const Offset(0, -20),
                color: Colors.purpleAccent,
                opacity: 1.0,
                fontSize: 20,
              ));
            }
          }
        } else if (charA.type == CharacterType.prefect) {
          // 스킬: 단체 실드 추가 부여 (+30)
          gameState.battleLog
              .add('👮 [아군] 선도부장이 규율의 방패를 활성화하여 아군 전체에게 실드(+30)를 충전합니다!');
          for (final t in pGrid.tiles.values) {
            if (t.character != null && !t.character!.isDead) {
              t.character!.shield += 30;
              final endOffset = getTileOffset(t.position, isPlayer: true) +
                  const Offset(S / 2, S / 2);
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_prefect_${charA.id}_${t.position.x}',
                text: '🛡️+30',
                position: endOffset + const Offset(0, -20),
                color: Colors.lightBlueAccent,
                opacity: 1.0,
              ));
            }
          }
        } else {
          // 일반 유닛 스킬 (일반 학생 등): 그냥 공격력 1.5배 피해를 입히는 스킬
          final targetTile = _getHighestHpTarget(oGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            final dmg = (charA.currentAttack * 1.5).toInt();
            targetChar.takeDamage(dmg);
            gameState.battleLog.add(
                '🧑‍🎓 [아군] ${charA.name}이 칠판 지우개를 던져 ${targetChar.name}에게 $dmg 스킬 피해를 입혔습니다.');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: false) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_stud_skill_${charA.id}',
              emoji: '🧹',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_stud_skill_${charA.id}',
              text: '💥-$dmg',
              position: endOffset + const Offset(0, -20),
              color: Colors.cyanAccent,
              opacity: 1.0,
              fontSize: 22,
            ));
          }
        }
      } else {
        // 일반 공격: 마나 +30 획득
        final targetTile = _getHighestHpTarget(oGrid);
        if (targetTile != null && targetTile.character != null) {
          final targetChar = targetTile.character!;
          final dmgInfo = calculateDamage(charA.currentAttack, isSkill: false);
          final dmg = dmgInfo['damage'] as int;
          final isCrit = dmgInfo['isCrit'] as bool;

          targetChar.takeDamage(dmg);
          charA.mana = min(100, charA.mana + 30); // 마나 축적

          if (isCrit) {
            gameState.battleLog.add(
                '⚡ [크리티컬!] ${charA.emoji} [아군] ${charA.name}이 ${targetChar.name}에게 강타를 입혀 $dmg 피해를 줬습니다.');
          } else {
            gameState.battleLog.add(
                '${charA.emoji} [아군] ${charA.name}이 ${targetChar.name}을 공격해 $dmg 피해를 줬습니다. (마나 +30)');
          }

          if (charA.type == CharacterType.iljin) {
            charA.currentAttack += 5;
            gameState.battleLog.add(
                '  ↳ 😈 일진의 분노! 공격력이 +5 상승했습니다. (현재 ATK: ${charA.currentAttack})');
          }

          final endOffset =
              getTileOffset(targetTile.position, isPlayer: false) +
                  const Offset(S / 2, S / 2);
          newProjectiles.add(ProjectileEffect(
            id: 'proj_norm_${charA.id}',
            emoji: charA.type == CharacterType.normalStudent ? '🎒' : '👊',
            start: startOffset,
            end: endOffset,
            progress: 0.0,
          ));
          newDamageTexts.add(DamageTextEffect(
            id: 'txt_norm_${charA.id}',
            text: isCrit ? '⚡Crit -$dmg' : '💥-$dmg',
            position: endOffset + const Offset(0, -20),
            color: isCrit ? Colors.yellowAccent : Colors.redAccent,
            opacity: 1.0,
            fontSize: isCrit ? 25 : 20,
          ));
        }
      }
    }

    // --- 적군 B 행동 연산 ---
    if (charB != null && tileB != null) {
      final startOffset = getTileOffset(tileB.position, isPlayer: false) +
          const Offset(S / 2, S / 2);

      // 마나가 100 이상이면 스킬 발동!
      if (charB.mana >= 100) {
        charB.mana = 0;

        if (charB.type == CharacterType.lunchLady) {
          final targetTile = _getLowestHpTarget(oGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            targetChar.heal(80);
            gameState.battleLog.add(
                '🧑‍🍳 [적군] 급식 이모가 스페셜 햄 반찬으로 ${targetChar.name}을 80 치유했습니다!');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: false) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_heal_${charB.id}',
              emoji: '💖',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_heal_${charB.id}',
              text: '💖+80',
              position: endOffset + const Offset(0, -20),
              color: Colors.greenAccent,
              opacity: 1.0,
              fontSize: 24,
            ));
          }
        } else if (charB.type == CharacterType.captain) {
          final targetTiles = _getRowTargets(pGrid, tileB.position.y);
          if (targetTiles.isNotEmpty) {
            gameState.battleLog
                .add('⚽ [적군] 축구부 주장이 불꽃 캐논 슛으로 동일 선상의 모든 아군을 관통 공격합니다!');
            for (final t in targetTiles) {
              final targetChar = t.character!;
              final dmgInfo = calculateDamage(
                  (charB.currentAttack * 1.5).toInt(),
                  isSkill: true);
              final dmg = dmgInfo['damage'] as int;

              targetChar.takeDamage(dmg);
              gameState.battleLog
                  .add('  ↳ [아군] ${targetChar.name}에게 $dmg 스킬 대미지!');

              final endOffset = getTileOffset(t.position, isPlayer: true) +
                  const Offset(S / 2, S / 2);
              newProjectiles.add(ProjectileEffect(
                id: 'proj_capt_${charB.id}_${t.position.x}',
                emoji: '⚽🔥',
                start: startOffset,
                end: endOffset,
                progress: 0.0,
                scale: 1.6,
              ));
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_capt_${charB.id}_${t.position.x}',
                text: '🔥-$dmg',
                position: endOffset + const Offset(0, -20),
                color: Colors.orangeAccent,
                opacity: 1.0,
                fontSize: 22,
              ));
            }
          }
        } else if (charB.type == CharacterType.studious) {
          final targetTile = _getLowestHpTarget(pGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            final dmgInfo =
                calculateDamage(charB.currentAttack * 2, isSkill: true);
            final dmg = dmgInfo['damage'] as int;

            targetChar.takeDamage(dmg);
            gameState.battleLog.add(
                '📝 [적군] 전교 1등이 정밀 약점 저격! ${targetChar.name}에게 $dmg 스킬 대미지!');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: true) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_stud_${charB.id}',
              emoji: '📝✨',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_stud_${charB.id}',
              text: '✨-$dmg',
              position: endOffset + const Offset(0, -20),
              color: Colors.amberAccent,
              opacity: 1.0,
              fontSize: 24,
            ));
          }
        } else if (charB.type == CharacterType.chemTeacher) {
          final targetTiles = _getRandomTargets(pGrid, 3);
          if (targetTiles.isNotEmpty) {
            gameState.battleLog.add('🧪 [적군] 화학 선생님이 유독성 화합물을 던집니다!');
            for (final t in targetTiles) {
              final targetChar = t.character!;
              targetChar.poisonDuration = 3;
              targetChar.poisonDamage = 15;
              targetChar.takeDamage(charB.currentAttack);
              gameState.battleLog.add(
                  '  ↳ [아군] ${targetChar.name}에게 ${charB.currentAttack} 대미지 및 3턴 독 부여');

              final endOffset = getTileOffset(t.position, isPlayer: true) +
                  const Offset(S / 2, S / 2);
              newProjectiles.add(ProjectileEffect(
                id: 'proj_chem_${charB.id}_${t.position.x}_${t.position.y}',
                emoji: '🧪☠️',
                start: startOffset,
                end: endOffset,
                progress: 0.0,
                scale: 1.5,
              ));
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_chem_${charB.id}_${t.position.x}_${t.position.y}',
                text: '💥-${charB.currentAttack} 🧪독',
                position: endOffset + const Offset(0, -20),
                color: Colors.purpleAccent,
                opacity: 1.0,
                fontSize: 20,
              ));
            }
          }
        } else if (charB.type == CharacterType.prefect) {
          gameState.battleLog
              .add('👮 [적군] 선도부장이 규율의 방패를 활성화하여 적군 전체에게 실드(+30)를 충전합니다!');
          for (final t in oGrid.tiles.values) {
            if (t.character != null && !t.character!.isDead) {
              t.character!.shield += 30;
              final endOffset = getTileOffset(t.position, isPlayer: false) +
                  const Offset(S / 2, S / 2);
              newDamageTexts.add(DamageTextEffect(
                id: 'txt_prefect_${charB.id}_${t.position.x}',
                text: '🛡️+30',
                position: endOffset + const Offset(0, -20),
                color: Colors.lightBlueAccent,
                opacity: 1.0,
              ));
            }
          }
        } else {
          final targetTile = _getHighestHpTarget(pGrid);
          if (targetTile != null && targetTile.character != null) {
            final targetChar = targetTile.character!;
            final dmg = (charB.currentAttack * 1.5).toInt();
            targetChar.takeDamage(dmg);
            gameState.battleLog.add(
                '🧑‍🎓 [적군] ${charB.name}이 칠판 지우개를 던져 ${targetChar.name}에게 $dmg 스킬 피해를 입혔습니다.');

            final endOffset =
                getTileOffset(targetTile.position, isPlayer: true) +
                    const Offset(S / 2, S / 2);
            newProjectiles.add(ProjectileEffect(
              id: 'proj_stud_skill_${charB.id}',
              emoji: '🧹',
              start: startOffset,
              end: endOffset,
              progress: 0.0,
              scale: 1.5,
            ));
            newDamageTexts.add(DamageTextEffect(
              id: 'txt_stud_skill_${charB.id}',
              text: '💥-$dmg',
              position: endOffset + const Offset(0, -20),
              color: Colors.cyanAccent,
              opacity: 1.0,
              fontSize: 22,
            ));
          }
        }
      } else {
        // 일반 공격: 마나 +30
        final targetTile = _getHighestHpTarget(pGrid);
        if (targetTile != null && targetTile.character != null) {
          final targetChar = targetTile.character!;
          final dmgInfo = calculateDamage(charB.currentAttack, isSkill: false);
          final dmg = dmgInfo['damage'] as int;
          final isCrit = dmgInfo['isCrit'] as bool;

          targetChar.takeDamage(dmg);
          charB.mana = min(100, charB.mana + 30);

          if (isCrit) {
            gameState.battleLog.add(
                '⚡ [크리티컬!] ${charB.emoji} [적군] ${charB.name}이 ${targetChar.name}에게 강타를 입혀 $dmg 피해를 줬습니다.');
          } else {
            gameState.battleLog.add(
                '${charB.emoji} [적군] ${charB.name}이 ${targetChar.name}을 공격해 $dmg 피해를 줬습니다. (마나 +30)');
          }

          if (charB.type == CharacterType.iljin) {
            charB.currentAttack += 5;
            gameState.battleLog.add(
                '  ↳ 😈 적군 일진의 분노! 공격력이 +5 상승했습니다. (현재 ATK: ${charB.currentAttack})');
          }

          final endOffset = getTileOffset(targetTile.position, isPlayer: true) +
              const Offset(S / 2, S / 2);
          newProjectiles.add(ProjectileEffect(
            id: 'proj_norm_${charB.id}',
            emoji: charB.type == CharacterType.normalStudent ? '🎒' : '👊',
            start: startOffset,
            end: endOffset,
            progress: 0.0,
          ));
          newDamageTexts.add(DamageTextEffect(
            id: 'txt_norm_${charB.id}',
            text: isCrit ? '⚡Crit -$dmg' : '💥-$dmg',
            position: endOffset + const Offset(0, -20),
            color: isCrit ? Colors.yellowAccent : Colors.redAccent,
            opacity: 1.0,
            fontSize: isCrit ? 25 : 20,
          ));
        }
      }
    }

    // --- 2. 투사체 이동 애니메이션 실행 (0.5초간 업데이트) ---
    _projectiles = newProjectiles;
    const int totalSteps = 15;
    for (int step = 1; step <= totalSteps; step++) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (!mounted) return;
      setState(() {
        _projectiles = _projectiles.map((p) {
          return p.copyWith(progress: step / totalSteps);
        }).toList();
      });
    }

    // --- 3. 피격 대미지 팝업 노출 및 사망 정산 (0.6초간 대기) ---
    _projectiles.clear();
    _damageTexts = newDamageTexts;
    _playerTileOffsets.clear();
    _opponentTileOffsets.clear();
    setState(() {});

    _processDeathsAndTriggers();

    for (int fade = 9; fade >= 0; fade--) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() {
        _damageTexts = _damageTexts.map((txt) {
          return txt.copyWith(
            position: txt.position + const Offset(0, -1.5),
            opacity: fade / 10,
          );
        }).toList();
      });
    }

    _damageTexts.clear();
    _isAnimating = false;
    _currentTurnNumber++;
    setState(() {});

    _checkVictoryOrDefeat();
  }

  // --- 사망 처리 및 시너지 트리거 발동 ---
  void _processDeathsAndTriggers() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid!;
    final oGrid = gameState.battleOpponentGrid!;

    void checkGrid(TileGrid grid, bool isPlayer) {
      for (final tile in grid.tiles.values) {
        final char = tile.character;
        if (char != null && char.isDead && !char.deathHandled) {
          char.deathHandled = true;
          final team = isPlayer ? '[아군]' : '[적군]';
          gameState.battleLog
              .add('💀 $team ${char.emoji} ${char.name}이 쓰러졌습니다!');
          _handleDeathTrigger(char, isPlayer);
        }
      }
    }

    checkGrid(pGrid, true);
    checkGrid(oGrid, false);
  }

  void _handleDeathTrigger(CharacterInstance deadChar, bool isPlayer) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final grid =
        isPlayer ? gameState.battlePlayerGrid! : gameState.battleOpponentGrid!;
    final team = isPlayer ? '[아군]' : '[적군]';

    if (deadChar.type == CharacterType.shuttle) {
      gameState.battleLog
          .add('🍞 $team 빵셔틀의 희생! 눈물의 매점 질주를 본 아군 전체 공격력(+5) 버프 획득!');
      for (final tile in grid.tiles.values) {
        final c = tile.character;
        if (c != null && !c.isDead) {
          c.currentAttack += 5;
        }
      }
    }
  }

  // --- 승리/패배 상태 검증 ---
  void _checkVictoryOrDefeat() {
    if (_resultShown) return;
    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid;
    final oGrid = gameState.battleOpponentGrid;
    if (pGrid == null || oGrid == null) return;

    bool playerAlive = pGrid.tiles.values
        .any((t) => t.character != null && !t.character!.isDead);
    bool opponentAlive = oGrid.tiles.values
        .any((t) => t.character != null && !t.character!.isDead);

    if (!playerAlive && !opponentAlive) {
      _battleTimer?.cancel();
      _resultShown = true;
      gameState.battleLog.add(
          '🤝 양쪽 전장의 영웅들이 동시 사투 끝에 무승부가 되었습니다! 라이프 변동 없이 다음 준비 단계로 넘어갑니다.');
      _showResultOverlay(isDraw: true);
    } else if (!playerAlive) {
      _battleTimer?.cancel();
      _resultShown = true;
      _showResultOverlay(playerWon: false);
    } else if (!opponentAlive) {
      _battleTimer?.cancel();
      _resultShown = true;
      _showResultOverlay(playerWon: true);
    }
  }

  void _showResultOverlay({bool playerWon = false, bool isDraw = false}) {
    final gameState = Provider.of<GameState>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String title = '';
        String desc = '';
        Color neonColor = AppColors.textPrimary;

        if (isDraw) {
          title = '무승부 (동시 사망)';
          desc = '동시 공격으로 양측 진영이 공멸했습니다!\n라이프 손실 없이 다음 준비 단계로 넘어갑니다.';
          neonColor = AppColors.drawGrey;
        } else if (playerWon) {
          title = '👑 승리! 👑';
          desc = '급식실 선점 성공!\n적의 방어선을 무너뜨리고 승점을 획득했습니다.';
          neonColor = AppColors.winGreen;
        } else {
          title = '💀 패배... 💀';
          desc = '매점 빵 뺏기 실패!\n더 탄탄한 타일 형태와 캐릭터 배치가 필요합니다.';
          neonColor = AppColors.defeatRed;
        }

        return Center(
          child: SizedBox(
            width: 320,
            child: GlassPanel(
              borderNeonColor: neonColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: neonColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceCard,
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: neonColor, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isDraw) {
                        gameState.enterPreparePhase();
                      } else {
                        gameState.finishBattle(playerWon);
                      }
                    },
                    child: const Text('확인',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Tile? _getHighestHpTarget(TileGrid grid) {
    Tile? bestTile;
    int maxHp = -999;
    for (final tile in grid.sortedTiles) {
      final char = tile.character;
      if (char != null && !char.isDead) {
        if (char.currentHp > maxHp) {
          maxHp = char.currentHp;
          bestTile = tile;
        }
      }
    }
    return bestTile;
  }

  Tile? _getLowestHpTarget(TileGrid grid) {
    Tile? bestTile;
    int minHp = 999999;
    for (final tile in grid.sortedTiles) {
      final char = tile.character;
      if (char != null && !char.isDead) {
        if (char.currentHp < minHp) {
          minHp = char.currentHp;
          bestTile = tile;
        }
      }
    }
    return bestTile;
  }

  List<Tile> _getRowTargets(TileGrid grid, int rowY) {
    final list = <Tile>[];
    for (final tile in grid.tiles.values) {
      if (tile.position.y == rowY &&
          tile.character != null &&
          !tile.character!.isDead) {
        list.add(tile);
      }
    }
    return list;
  }

  List<Tile> _getRandomTargets(TileGrid grid, int count) {
    final aliveTiles = grid.tiles.values
        .where((t) => t.character != null && !t.character!.isDead)
        .toList();
    if (aliveTiles.isEmpty) return [];
    aliveTiles.shuffle();
    return aliveTiles.take(count).toList();
  }

  void _spawnDamageText(
      String text, Point<int> tilePos, bool isPlayer, Color color) {
    final media = MediaQuery.of(context).size;
    final double screenWidth = media.width;
    final double screenHeight = media.height;

    const double S = 65.0;
    final double oGridCenterY = screenHeight * 0.22;
    final double pGridCenterY = screenHeight * 0.60;
    final double centerX = screenWidth / 2;

    final gameState = Provider.of<GameState>(context, listen: false);
    final pGrid = gameState.battlePlayerGrid!;
    final oGrid = gameState.battleOpponentGrid!;

    double avgXPlayer =
        pGrid.tiles.keys.map((p) => p.x).reduce((a, b) => a + b) / pGrid.count;
    double avgYPlayer =
        pGrid.tiles.keys.map((p) => p.y).reduce((a, b) => a + b) / pGrid.count;
    double avgXOpp =
        oGrid.tiles.keys.map((p) => p.x).reduce((a, b) => a + b) / oGrid.count;
    double avgYOpp =
        oGrid.tiles.keys.map((p) => p.y).reduce((a, b) => a + b) / oGrid.count;

    Offset pos;
    if (isPlayer) {
      pos = Offset(
        centerX + (tilePos.x - avgXPlayer) * (S + 8),
        pGridCenterY + (tilePos.y - avgYPlayer) * (S + 8) - 10,
      );
    } else {
      pos = Offset(
        centerX - (tilePos.x - avgXOpp) * (S + 8),
        oGridCenterY - (tilePos.y - avgYOpp) * (S + 8) - 10,
      );
    }

    final id = 'poison_text_${DateTime.now().microsecondsSinceEpoch}';
    final effect = DamageTextEffect(
      id: id,
      text: text,
      position: pos,
      color: color,
      opacity: 1.0,
    );

    setState(() {
      _damageTexts.add(effect);
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _damageTexts.removeWhere((t) => t.id == id);
        });
      }
    });
  }

  Widget _buildCombatGrid(TileGrid grid, {required bool isPlayer}) {
    const double S = 65.0;
    final tiles = grid.tiles.values.toList();

    tiles.sort((a, b) {
      if (a.position.y != b.position.y) {
        return a.position.y.compareTo(b.position.y);
      }
      return a.position.x.compareTo(b.position.x);
    });

    int minX = grid.tiles.keys.map((p) => p.x).reduce(min);
    int maxX = grid.tiles.keys.map((p) => p.x).reduce(max);
    int minY = grid.tiles.keys.map((p) => p.y).reduce(min);
    int maxY = grid.tiles.keys.map((p) => p.y).reduce(max);

    final double gridW = (maxX - minX + 1) * (S + 8) + 16;
    final double gridH = (maxY - minY + 1) * (S + 8) + 16;

    return Container(
      width: gridW,
      height: gridH,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isPlayer ? AppColors.neonCyan : AppColors.neonPink)
              .withValues(alpha: 0.95),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.22),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          for (final tile in tiles) ...[
            Builder(builder: (context) {
              final shakeOffset = isPlayer
                  ? (_playerTileOffsets[tile.position] ?? Offset.zero)
                  : (_opponentTileOffsets[tile.position] ?? Offset.zero);

              final char = tile.character;
              final gradeColor = AppColors.getGradeColor(char?.grade);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                left: (tile.position.x - minX) * (S + 8) + shakeOffset.dx,
                top: (tile.position.y - minY) * (S + 8) + shakeOffset.dy,
                width: S,
                height: S,
                child: Container(
                  decoration: BoxDecoration(
                    color: char != null && !char.isDead
                        ? AppColors.surfaceCard
                        : const Color(0xFFE6D5A5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: char != null && !char.isDead
                          ? gradeColor
                          : AppColors.outline.withValues(alpha: 0.4),
                      width: char != null && !char.isDead ? 1.8 : 1.0,
                    ),
                    boxShadow: char != null && !char.isDead
                        ? [
                            BoxShadow(
                              color: AppColors.outline.withValues(alpha: 0.18),
                              blurRadius: 0,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 순서 번호 (동그란 배지)
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outline,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${tile.orderNumber}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // 성급 표시 (우측 상단)
                      if (char != null && !char.isDead)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              char.starLevel,
                              (_) => const Icon(
                                Icons.star_rounded,
                                color: AppColors.neonGold,
                                size: 7,
                              ),
                            ),
                          ),
                        ),

                      if (char != null) ...[
                        Opacity(
                          opacity: char.isDead ? 0.2 : 1.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 6),
                              Text(char.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 2),
                              // HP 바
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  width: 44,
                                  height: 3,
                                  child: LinearProgressIndicator(
                                    value: char.currentMaxHp > 0
                                        ? char.currentHp / char.currentMaxHp
                                        : 0,
                                    backgroundColor: AppColors.damageRed
                                        .withValues(alpha: 0.25),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      char.isDead
                                          ? Colors.grey
                                          : AppColors.hpGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              // 마나 바 (살아있을 때만)
                              if (!char.isDead)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                    width: 44,
                                    height: 2,
                                    child: LinearProgressIndicator(
                                      value: char.mana / 100.0,
                                      backgroundColor: AppColors.manaBlue
                                          .withValues(alpha: 0.25),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.manaBlue,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (char.shield > 0 && !char.isDead)
                          Positioned(
                            bottom: 6,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: AppColors.shieldBlue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '🛡️${char.shield}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (char.poisonDuration > 0 && !char.isDead)
                          Positioned(
                            bottom: 6,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '🧪${char.poisonDuration}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  /// 로그 텍스트에서 이벤트 타입별 색상 결정
  Color _getLogColor(String logText) {
    if (logText.contains('💀') ||
        logText.contains('사망') ||
        logText.contains('쓰러')) {
      return const Color(0xFFFF6B6B);
    }
    if (logText.contains('💖') ||
        logText.contains('치유') ||
        logText.contains('heal')) {
      return AppColors.healGreen;
    }
    if (logText.contains('🧪') || logText.contains('독')) {
      return AppColors.skillPurple;
    }
    if (logText.contains('⚡') || logText.contains('크리티컬')) {
      return AppColors.critYellow;
    }
    if (logText.contains('🛡️') ||
        logText.contains('실드') ||
        logText.contains('배리어')) {
      return const Color(0xFF64B5F6);
    }
    if (logText.contains('🌟') || logText.contains('합성')) {
      return AppColors.neonGold;
    }
    if (logText.contains('🔔') ||
        logText.contains('라운드') ||
        logText.contains('🔄')) {
      return AppColors.neonCyan;
    }
    if (logText.contains('스킬') ||
        logText.contains('🔥') ||
        logText.contains('캐논')) {
      return Colors.orangeAccent;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final battleLogs = gameState.battleLog;

    return Stack(
      children: [
        // --- 전체 전투 배경 레이아웃 ---
        Column(
          children: [
            // ─── 적군 영역 ───
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.neonPinkLight.withValues(alpha: 0.72),
                      AppColors.skyBottom.withValues(alpha: 0.58),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: gameState.battleOpponentGrid != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dangerous_outlined,
                                  color: AppColors.neonPinkLight
                                      .withValues(alpha: 0.7),
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '상대 · ${gameState.currentOpponent?.name ?? '과거의 도전자'}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildCombatGrid(gameState.battleOpponentGrid!,
                              isPlayer: false),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),

            // ─── VS 분리선 + 전투 로그 ───
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.panelBg,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.45),
                        width: 3),
                  ),
                ),
                child: Column(
                  children: [
                    // VS 배너 + 전투 진행 정보
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonCyanLight,
                            AppColors.surfaceCard,
                            AppColors.neonPinkLight,
                          ],
                        ),
                      ),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neonGold,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.outline, width: 2),
                            ),
                            child: const Text(
                              '⚔️ VS',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _combatPhaseText,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 전투 로그 (색상 구분)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        reverse: true,
                        itemCount: battleLogs.length,
                        itemBuilder: (context, index) {
                          final logText =
                              battleLogs[battleLogs.length - 1 - index];
                          final logColor = _getLogColor(logText);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                            child: Text(
                              logText,
                              style: TextStyle(
                                color: logColor,
                                fontSize: 10.5,
                                height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 아군 영역 ───
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.skyBottom.withValues(alpha: 0.58),
                      AppColors.grass.withValues(alpha: 0.62),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: gameState.battlePlayerGrid != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCombatGrid(gameState.battlePlayerGrid!,
                              isPlayer: true),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color:
                                      AppColors.neonCyan.withValues(alpha: 0.7),
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '아군 · ${gameState.playerName}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ],
        ),

        // --- 투사체 오버레이 그리기 ---
        for (final proj in _projectiles)
          Positioned(
            left: proj.start.dx + (proj.end.dx - proj.start.dx) * proj.progress,
            top: proj.start.dy + (proj.end.dy - proj.start.dy) * proj.progress,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Transform.scale(
                scale: proj.scale,
                child: Text(
                  proj.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          ),

        // --- 대미지 팝업 텍스트 오버레이 그리기 ---
        for (final txt in _damageTexts)
          Positioned(
            left: txt.position.dx,
            top: txt.position.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Opacity(
                opacity: txt.opacity,
                child: Text(
                  txt.text,
                  style: TextStyle(
                    color: txt.color,
                    fontSize: txt.fontSize,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1.5, 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
