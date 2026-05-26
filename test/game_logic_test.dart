import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_attack/models/character.dart';
import 'package:school_attack/models/tile_grid.dart';
import 'package:school_attack/models/game_state.dart';

void main() {
  group('TileGrid 및 정렬 알고리즘 테스트', () {
    test('초기화 시 (0,0)과 (1,0)이 각각 1번, 2번 순서로 부여되어야 한다.', () {
      final grid = TileGrid();
      grid.initializeDefault();

      final sorted = grid.sortedTiles;
      expect(sorted.length, 2);
      expect(sorted[0].position, const Point(0, 0));
      expect(sorted[0].orderNumber, 1);
      expect(sorted[1].position, const Point(1, 0));
      expect(sorted[1].orderNumber, 2);
    });

    test('타일이 여러 행/열에 배치되었을 때 Y 오름차순, X 오름차순으로 턴 순서가 정렬되어야 한다.', () {
      final grid = TileGrid();
      grid.addTile(const Point(1, 1));
      grid.addTile(const Point(0, 0));
      grid.addTile(const Point(0, 1));
      grid.addTile(const Point(1, 0));

      final sorted = grid.sortedTiles;
      expect(sorted.length, 4);

      expect(sorted[0].position, const Point(0, 0));
      expect(sorted[0].orderNumber, 1);

      expect(sorted[1].position, const Point(1, 0));
      expect(sorted[1].orderNumber, 2);

      expect(sorted[2].position, const Point(0, 1));
      expect(sorted[2].orderNumber, 3);

      expect(sorted[3].position, const Point(1, 1));
      expect(sorted[3].orderNumber, 4);
    });

    test('인접한 타일 확장 가능 후보 위치를 올바르게 계산해야 한다.', () {
      final grid = TileGrid();
      grid.initializeDefault();

      final expandables = grid.getExpandablePositions();

      expect(expandables.length, 6);
      expect(expandables.contains(const Point(0, -1)), true);
      expect(expandables.contains(const Point(0, 1)), true);
      expect(expandables.contains(const Point(-1, 0)), true);
      expect(expandables.contains(const Point(1, -1)), true);
      expect(expandables.contains(const Point(1, 1)), true);
      expect(expandables.contains(const Point(2, 0)), true);
    });

    test('순번을 드래그 재배치하면 시작 칸과 전투 순서가 변경되어야 한다.', () {
      final grid = TileGrid();
      grid.addTile(const Point(0, 0));
      grid.addTile(const Point(1, 0));
      grid.addTile(const Point(0, 1));

      final moved = grid.moveTileOrder(const Point(0, 1), const Point(0, 0));

      expect(moved, true);
      expect(grid.tiles[const Point(0, 1)]?.orderNumber, 1);
      expect(grid.tiles[const Point(0, 0)]?.orderNumber, 2);
      expect(grid.tiles[const Point(1, 0)]?.orderNumber, 3);

      final clone = grid.clone();
      expect(clone.tiles[const Point(0, 1)]?.orderNumber, 1);
      expect(clone.tiles[const Point(0, 0)]?.orderNumber, 2);
      expect(clone.tiles[const Point(1, 0)]?.orderNumber, 3);
    });
  });

  group('CharacterInstance 전투 연산 및 스케일링 테스트', () {
    test('대미지를 받으면 체력이 깎이고, 실드가 있을 시 실드가 먼저 삭감된다.', () {
      final template = CharacterTemplate.getByType(CharacterType.normalStudent);
      final char = CharacterInstance(id: 'test_1', template: template);

      expect(char.currentHp, 100);
      char.takeDamage(30);
      expect(char.currentHp, 70);

      char.shield = 40;
      char.takeDamage(30);
      expect(char.shield, 10);
      expect(char.currentHp, 70);

      char.takeDamage(20);
      expect(char.shield, 0);
      expect(char.currentHp, 60);
    });

    test('치유 시 최대 체력을 넘을 수 없다.', () {
      final template = CharacterTemplate.getByType(CharacterType.normalStudent);
      final char = CharacterInstance(id: 'test_2', template: template);

      char.currentHp = 80;
      char.heal(50);
      expect(char.currentHp, 100);
    });

    test('성급에 따른 스탯 증폭 배율이 정상적으로 적용되어야 한다.', () {
      final template = CharacterTemplate.getByType(
        CharacterType.normalStudent,
      ); // Base: HP 100, ATK 15

      final star1 = CharacterInstance(
        id: 's1',
        template: template,
        starLevel: 1,
      );
      final star2 = CharacterInstance(
        id: 's2',
        template: template,
        starLevel: 2,
      );
      final star3 = CharacterInstance(
        id: 's3',
        template: template,
        starLevel: 3,
      );

      expect(star1.currentMaxHp, 100);
      expect(star1.currentAttack, 15);

      expect(star2.currentMaxHp, 180); // 100 * 1.8 = 180
      expect(star2.currentAttack, 24); // 15 * 1.6 = 24

      expect(star3.currentMaxHp, 320); // 100 * 3.2 = 320
      expect(star3.currentAttack, 42); // 15 * 2.8 = 42
    });
  });

  group('오토배틀러 성급 합성(★1 -> ★2) 통합 테스트', () {
    test('동일한 1성 캐릭터 3개를 보유하면 자동으로 1개의 2성 유닛으로 합성되어야 한다.', () {
      final gameState = GameState();
      gameState.startNewGame();

      // 대기석 비움
      for (int i = 0; i < gameState.bench.length; i++) {
        gameState.bench[i] = null;
      }

      final template = CharacterTemplate.getByType(CharacterType.iljin);

      // 1성 유닛 3개 생성하여 대기석에 강제 적재
      gameState.bench[0] = CharacterInstance(
        id: 'unit1',
        template: template,
        starLevel: 1,
      );
      gameState.bench[1] = CharacterInstance(
        id: 'unit2',
        template: template,
        starLevel: 1,
      );
      gameState.bench[2] = CharacterInstance(
        id: 'unit3',
        template: template,
        starLevel: 1,
      );

      // 합성 조건 수동 실행
      final didCombine = gameState.checkForUpgrades();

      expect(didCombine, true);
      // 첫 번째 유닛이 2성으로 진급
      expect(gameState.bench[0] != null, true);
      expect(gameState.bench[0]!.starLevel, 2);
      expect(gameState.bench[0]!.currentMaxHp, 270); // 150 * 1.8 = 270

      // 두 번째와 세 번째는 삭제되어야 함
      expect(gameState.bench[1], null);
      expect(gameState.bench[2], null);
    });
  });

  group('전투 시작 조건 테스트', () {
    test('전장에 배치된 유닛이 없으면 전투 단계로 넘어가지 않아야 한다.', () {
      final gameState = GameState();
      gameState.enterPreparePhase();

      gameState.startBattle();

      expect(gameState.phase, GamePhase.prepare);
      expect(gameState.battleLog.last, '전투를 시작하려면 전장에 유닛을 최소 1명 배치해야 합니다.');
    });
  });

  group('탭 기반 배치 조작 테스트', () {
    test('대기석 유닛을 탭으로 선택한 뒤 전장 칸에 배치할 수 있다.', () {
      final gameState = GameState();
      gameState.enterPreparePhase();

      final template = CharacterTemplate.getByType(CharacterType.normalStudent);
      gameState.bench[0] = CharacterInstance(
        id: 'tap_unit',
        template: template,
      );

      expect(gameState.tapBenchSlot(0), true);
      expect(gameState.selectedBenchIndex, 0);

      expect(gameState.tapGridTile(const Point(0, 0)), true);
      expect(gameState.bench[0], null);
      expect(
        gameState.playerGrid.tiles[const Point(0, 0)]?.character?.id,
        'tap_unit',
      );
      expect(gameState.selectedCharacter, null);
    });

    test('전장 유닛을 탭으로 선택한 뒤 빈 대기석으로 회수할 수 있다.', () {
      final gameState = GameState();
      gameState.enterPreparePhase();

      final template = CharacterTemplate.getByType(CharacterType.iljin);
      gameState.playerGrid.setCharacter(
        const Point(0, 0),
        CharacterInstance(id: 'grid_unit', template: template),
      );

      expect(gameState.tapGridTile(const Point(0, 0)), true);
      expect(gameState.selectedGridPos, const Point(0, 0));

      expect(gameState.tapBenchSlot(0), true);
      expect(gameState.bench[0]?.id, 'grid_unit');
      expect(gameState.playerGrid.tiles[const Point(0, 0)]?.character, null);
      expect(gameState.selectedCharacter, null);
    });
  });
}
