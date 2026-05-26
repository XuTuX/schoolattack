import 'dart:math';
import 'package:flutter/material.dart';
import 'character.dart';
import 'tile_grid.dart';
import '../services/matchmaker.dart';
import '../widgets/game_board.dart'; // DragData 참조

enum GamePhase { lobby, prepare, battle, victoryCutscene, gameover }

class GameState extends ChangeNotifier {
  String playerName = '전학생';
  int gold = 0;
  int wins = 0;
  int losses = 0;
  final int maxWins = 10;
  final int maxLosses = 5; // 5개 하트

  GamePhase phase = GamePhase.lobby;

  final TileGrid playerGrid = TileGrid();
  final List<CharacterInstance?> bench = List.generate(5, (_) => null);
  final List<CharacterTemplate?> shopCards = List.generate(5, (_) => null);

  OpponentData? currentOpponent;

  // 전투용 일시적 상태 (원래 그리드 복사)
  TileGrid? battlePlayerGrid;
  TileGrid? battleOpponentGrid;

  // 전투 중 로그 기록
  final List<String> battleLog = [];

  // 매치메이커 서비스
  final MatchmakerService _matchmaker = MatchmakerService();

  // --- 드래그 판매 전용 HUD 상태 ---
  bool isDragging = false;
  int? draggingCharacterGold;
  int? selectedBenchIndex;
  Point<int>? selectedGridPos;

  GameState() {
    startNewGame();
  }

  // 매점 아주머니 패시브 적용 여부 (전장 또는 대기석에 존재)
  bool get hasStoreKeeper {
    // 전장 검사
    for (final tile in playerGrid.tiles.values) {
      if (tile.character?.type == CharacterType.storeKeeper) {
        return true;
      }
    }
    // 대기석 검사
    for (final char in bench) {
      if (char?.type == CharacterType.storeKeeper) {
        return true;
      }
    }
    return false;
  }

  int get rerollCost => hasStoreKeeper ? 1 : 2;
  int get tileCost => 4;
  int get roundIncome => hasStoreKeeper ? 12 : 10;
  int get activeBoardUnitCount {
    return playerGrid.tiles.values
        .where((tile) => tile.character != null)
        .length;
  }

  bool get canStartBattle => activeBoardUnitCount > 0;

  // 새 게임 시작
  void startNewGame() {
    wins = 0;
    losses = 0;
    gold = 0;
    phase = GamePhase.lobby;
    playerGrid.initializeDefault();
    for (int i = 0; i < bench.length; i++) {
      bench[i] = null;
    }
    battleLog.clear();
    currentOpponent = null;
    isDragging = false;
    draggingCharacterGold = null;
    clearSelection(notify: false);
    notifyListeners();
  }

  CharacterInstance? get selectedCharacter {
    final benchIndex = selectedBenchIndex;
    if (benchIndex != null && benchIndex >= 0 && benchIndex < bench.length) {
      return bench[benchIndex];
    }
    final gridPos = selectedGridPos;
    if (gridPos != null) {
      return playerGrid.tiles[gridPos]?.character;
    }
    return null;
  }

  String get selectionHint {
    final char = selectedCharacter;
    if (char == null) return '유닛을 탭해서 선택한 뒤 원하는 칸을 탭하세요.';
    return '${char.name} 선택됨 · 전장이나 대기석을 탭해 이동/교체';
  }

  void clearSelection({bool notify = true}) {
    selectedBenchIndex = null;
    selectedGridPos = null;
    if (notify) notifyListeners();
  }

  void selectBench(int index) {
    if (index < 0 || index >= bench.length || bench[index] == null) return;
    if (selectedBenchIndex == index) {
      clearSelection();
      return;
    }
    selectedBenchIndex = index;
    selectedGridPos = null;
    notifyListeners();
  }

  void selectGrid(Point<int> pos) {
    final char = playerGrid.tiles[pos]?.character;
    if (char == null) return;
    if (selectedGridPos == pos) {
      clearSelection();
      return;
    }
    selectedGridPos = pos;
    selectedBenchIndex = null;
    notifyListeners();
  }

  bool tapBenchSlot(int index) {
    if (index < 0 || index >= bench.length) return false;

    final gridPos = selectedGridPos;
    if (gridPos != null) {
      return returnToBench(gridPos, index);
    }

    final benchIndex = selectedBenchIndex;
    if (benchIndex != null) {
      if (benchIndex == index) {
        clearSelection();
        return true;
      }
      swapBench(benchIndex, index);
      return true;
    }

    if (bench[index] != null) {
      selectBench(index);
      return true;
    }
    return false;
  }

  bool tapGridTile(Point<int> pos) {
    final benchIndex = selectedBenchIndex;
    if (benchIndex != null) {
      return placeCharacter(benchIndex, pos);
    }

    final gridPos = selectedGridPos;
    if (gridPos != null) {
      if (gridPos == pos) {
        clearSelection();
        return true;
      }
      return moveGridCharacter(gridPos, pos);
    }

    if (playerGrid.tiles[pos]?.character != null) {
      selectGrid(pos);
      return true;
    }
    return false;
  }

  bool sellSelectedCharacter() {
    final benchIndex = selectedBenchIndex;
    if (benchIndex != null) {
      sellCharacterFromBench(benchIndex);
      return true;
    }

    final gridPos = selectedGridPos;
    if (gridPos != null) {
      sellCharacterFromGrid(gridPos);
      return true;
    }
    return false;
  }

  // 준비 단계 진입
  void enterPreparePhase() {
    phase = GamePhase.prepare;
    final reward = roundIncome;
    if (hasStoreKeeper) {
      battleLog.add('🏪 매점 아주머니의 세일 효과로 추가 골드 +2를 획득했습니다!');
    }
    gold += reward;

    // 상점 초기화
    rerollShop(free: true);
    notifyListeners();
  }

  // 상점 갱신 (리롤)
  void rerollShop({bool free = false}) {
    if (!free) {
      final cost = rerollCost;
      if (gold < cost) return;
      gold -= cost;
    }

    final random = Random();
    for (int i = 0; i < shopCards.length; i++) {
      final randVal = random.nextDouble();
      CharacterGrade selectedGrade;
      if (randVal < 0.45) {
        selectedGrade = CharacterGrade.normal;
      } else if (randVal < 0.75) {
        selectedGrade = CharacterGrade.rare;
      } else if (randVal < 0.93) {
        selectedGrade = CharacterGrade.epic;
      } else {
        selectedGrade = CharacterGrade.legendary;
      }

      final candidates = CharacterTemplate.templates
          .where((t) => t.grade == selectedGrade)
          .toList();

      if (candidates.isNotEmpty) {
        shopCards[i] = candidates[random.nextInt(candidates.length)];
      } else {
        shopCards[i] = CharacterTemplate
            .templates[random.nextInt(CharacterTemplate.templates.length)];
      }
    }
    notifyListeners();
  }

  // 상점에서 캐릭터 구매
  bool buyCharacter(int shopIndex) {
    if (shopIndex < 0 || shopIndex >= shopCards.length) return false;
    final template = shopCards[shopIndex];
    if (template == null) return false;

    if (gold < template.cost) return false;

    int emptyBenchIdx = bench.indexWhere((c) => c == null);
    if (emptyBenchIdx == -1) return false; // 대기석 꽉 참

    gold -= template.cost;
    bench[emptyBenchIdx] = CharacterInstance(
      id: 'char_${template.type.name}_${DateTime.now().microsecondsSinceEpoch}',
      template: template,
    );
    shopCards[shopIndex] = null;

    // 구매 후 동일 유닛 3개 합성 진급 자동 검사
    checkForUpgrades();
    selectedBenchIndex = bench[emptyBenchIdx] == null ? null : emptyBenchIdx;
    selectedGridPos = null;

    notifyListeners();
    return true;
  }

  // 캐릭터 판매 (대기석)
  void sellCharacterFromBench(int benchIndex) {
    if (benchIndex < 0 || benchIndex >= bench.length) return;
    final char = bench[benchIndex];
    if (char == null) return;

    // 성급에 비례해서 판매 환불 골드 지급
    final refund = char.cost * char.starLevel;
    gold += refund;
    bench[benchIndex] = null;
    clearSelection(notify: false);
    notifyListeners();
  }

  // 캐릭터 판매 (전장 타일)
  void sellCharacterFromGrid(Point<int> pos) {
    final char = playerGrid.removeCharacter(pos);
    if (char != null) {
      final refund = char.cost * char.starLevel;
      gold += refund;
      clearSelection(notify: false);
      notifyListeners();
    }
  }

  // 타일 확장 구매
  bool purchaseTile(Point<int> pos) {
    if (gold < tileCost) return false;
    final expandables = playerGrid.getExpandablePositions();
    if (!expandables.contains(pos)) return false;

    gold -= tileCost;
    playerGrid.addTile(pos);
    notifyListeners();
    return true;
  }

  // 대기석 -> 전장 타일 배치
  bool placeCharacter(int benchIndex, Point<int> pos) {
    if (benchIndex < 0 || benchIndex >= bench.length) return false;
    final charToPlace = bench[benchIndex];
    if (charToPlace == null) return false;

    final targetTile = playerGrid.tiles[pos];
    if (targetTile == null) return false;

    final existingChar = targetTile.character;

    playerGrid.setCharacter(pos, charToPlace);
    bench[benchIndex] = existingChar;
    clearSelection(notify: false);

    checkForUpgrades(); // 스왑/배치 중 합성이 일어날 가능성 대비 검사
    notifyListeners();
    return true;
  }

  // 전장 타일 -> 대기석 회수
  bool returnToBench(Point<int> pos, int targetBenchIndex) {
    final targetTile = playerGrid.tiles[pos];
    if (targetTile == null) return false;

    final charToReturn = targetTile.character;
    if (charToReturn == null) return false;

    final benchChar = bench[targetBenchIndex];
    bench[targetBenchIndex] = charToReturn;
    playerGrid.setCharacter(pos, benchChar);
    clearSelection(notify: false);

    checkForUpgrades();
    notifyListeners();
    return true;
  }

  // 전장 타일 -> 전장 타일 이동
  bool moveGridCharacter(Point<int> from, Point<int> to) {
    final fromTile = playerGrid.tiles[from];
    final toTile = playerGrid.tiles[to];
    if (fromTile == null || toTile == null) return false;

    final char = fromTile.character;
    fromTile.character = toTile.character;
    toTile.character = char;
    clearSelection(notify: false);

    notifyListeners();
    return true;
  }

  // 대기석 내부 교환
  void swapBench(int idxA, int idxB) {
    if (idxA < 0 || idxA >= bench.length || idxB < 0 || idxB >= bench.length) {
      return;
    }
    final temp = bench[idxA];
    bench[idxA] = bench[idxB];
    bench[idxB] = temp;
    clearSelection(notify: false);
    notifyListeners();
  }

  // --- 🌟 성급 합성 기능 (3성 Consolidation) ---
  bool checkForUpgrades() {
    bool didUpgrade = false;

    for (int targetStar = 1; targetStar <= 2; targetStar++) {
      // 캐릭터타입별로 소유한 캐릭터들의 위치(벤치/그리드) 정보 목록 수집
      final Map<CharacterType, List<Map<String, dynamic>>> placements = {};

      // 1. 대기석 스캔
      for (int i = 0; i < bench.length; i++) {
        final char = bench[i];
        if (char != null && char.starLevel == targetStar) {
          placements.putIfAbsent(char.type, () => []).add({
            'type': 'bench',
            'index': i,
            'char': char,
          });
        }
      }

      // 2. 전장 스캔
      for (final entry in playerGrid.tiles.entries) {
        final tile = entry.value;
        final char = tile.character;
        if (char != null && char.starLevel == targetStar) {
          placements.putIfAbsent(char.type, () => []).add({
            'type': 'grid',
            'pos': entry.key,
            'char': char,
          });
        }
      }

      // 3. 동일 등급 동일 캐릭터가 3개 이상 모였는지 탐색
      for (final entry in placements.entries) {
        final list = entry.value;
        if (list.length >= 3) {
          final target = list[0];
          final charToUpgrade = target['char'] as CharacterInstance;

          // 진급 수행!
          charToUpgrade.upgradeStar();
          battleLog.add(
              '🌟 [합성 성공] ${charToUpgrade.name}이(가) ★${charToUpgrade.starLevel}로 진급했습니다!');

          // 나머지 2마리 제거
          final deleteA = list[1];
          final deleteB = list[2];

          _deleteChar(deleteA);
          _deleteChar(deleteB);

          didUpgrade = true;
          break; // 다시 1성부터 순차 재검사
        }
      }

      if (didUpgrade) break;
    }

    if (didUpgrade) {
      checkForUpgrades(); // 연속 합성 처리 (재귀)
      return true;
    }

    return false;
  }

  void _deleteChar(Map<String, dynamic> loc) {
    if (loc['type'] == 'bench') {
      bench[loc['index'] as int] = null;
    } else if (loc['type'] == 'grid') {
      playerGrid.setCharacter(loc['pos'] as Point<int>, null);
    }
  }

  // --- 🪙 드래그 판매 관련 컨트롤러 ---
  void startDragging(int goldAmount) {
    isDragging = true;
    draggingCharacterGold = goldAmount;
    notifyListeners();
  }

  void stopDragging() {
    isDragging = false;
    draggingCharacterGold = null;
    notifyListeners();
  }

  void sellDraggedCharacter(DragData data) {
    if (data.source == 'bench') {
      final char = bench[data.benchIndex!];
      if (char != null) {
        final refund = char.cost * char.starLevel;
        gold += refund;
        bench[data.benchIndex!] = null;
        clearSelection(notify: false);
        battleLog.add(
            '🪙 [드래그 판매] ${char.name} ★${char.starLevel}를 판매하여 $refund골드를 회수했습니다.');
      }
    } else if (data.source == 'grid') {
      final char = playerGrid.tiles[data.gridPos!]?.character;
      if (char != null) {
        final refund = char.cost * char.starLevel;
        gold += refund;
        playerGrid.setCharacter(data.gridPos!, null);
        clearSelection(notify: false);
        battleLog.add(
            '🪙 [드래그 판매] ${char.name} ★${char.starLevel}를 판매하여 $refund골드를 회수했습니다.');
      }
    }
    stopDragging();
  }

  // 전투 시작
  void startBattle() {
    if (!canStartBattle) {
      battleLog.add('전투를 시작하려면 전장에 유닛을 최소 1명 배치해야 합니다.');
      notifyListeners();
      return;
    }

    battleLog.clear();
    clearSelection(notify: false);
    battleLog.add('⚔️ 전투 개시! 매칭 상대를 검색하는 중...');

    currentOpponent = _matchmaker.getOpponent(wins, losses);
    battleLog.add(
        '🏫 대전 상대: [${currentOpponent!.name}] (기록: ${currentOpponent!.wins}승 ${currentOpponent!.losses}패)');

    _matchmaker.savePlayerLayout(playerName, wins, losses, playerGrid);

    battlePlayerGrid = playerGrid.clone();
    battleOpponentGrid = currentOpponent!.grid.clone();

    // 마나 초기화
    _resetManaForBattle(battlePlayerGrid!);
    _resetManaForBattle(battleOpponentGrid!);

    _applyPreBattleEffects();

    phase = GamePhase.battle;
    notifyListeners();
  }

  void _resetManaForBattle(TileGrid grid) {
    for (final tile in grid.tiles.values) {
      if (tile.character != null) {
        tile.character!.mana = 0; // 매 전투 때마다 마나는 0부터 시작
        tile.character!.deathHandled = false;
      }
    }
  }

  // 전투 전 버프 적용
  void _applyPreBattleEffects() {
    if (battlePlayerGrid == null || battleOpponentGrid == null) return;

    _applyGridPreBattle(battlePlayerGrid!, isPlayer: true);
    _applyGridPreBattle(battleOpponentGrid!, isPlayer: false);
  }

  void _applyGridPreBattle(TileGrid grid, {required bool isPlayer}) {
    final prefix = isPlayer ? '[아군]' : '[적군]';

    bool hasPrefect = false;
    for (final tile in grid.tiles.values) {
      if (tile.character?.type == CharacterType.prefect) {
        hasPrefect = true;
        break;
      }
    }
    if (hasPrefect) {
      battleLog.add('$prefix 👮 선도부장의 통제로 아군 전체가 실드(+40)를 얻고 규율을 지킵니다!');
      for (final tile in grid.tiles.values) {
        if (tile.character != null) {
          tile.character!.shield += 40;
        }
      }
    }

    final pePositions = <Point<int>>[];
    for (final tile in grid.tiles.values) {
      if (tile.character?.type == CharacterType.peTeacher) {
        pePositions.add(tile.position);
      }
    }

    for (final pePos in pePositions) {
      final adjacentOffsets = [
        const Point(0, -1),
        const Point(0, 1),
        const Point(-1, 0),
        const Point(1, 0)
      ];

      battleLog.add('$prefix 🏋️ 체육 선생님 주변 캐릭터들이 하드 트레이닝으로 최대 체력(+50)을 늘립니다!');
      for (final offset in adjacentOffsets) {
        final adjPos = Point(pePos.x + offset.x, pePos.y + offset.y);
        final neighborTile = grid.tiles[adjPos];
        if (neighborTile != null && neighborTile.character != null) {
          final char = neighborTile.character!;
          char.currentMaxHp += 50;
          char.currentHp += 50;
        }
      }
    }
  }

  // 전투 완료 처리
  void finishBattle(bool playerWon) {
    isDragging = false;
    draggingCharacterGold = null;
    if (playerWon) {
      wins++;
      battleLog.add('🎉 승리했습니다! 현재 기록: $wins승 $losses패');
      if (wins >= maxWins) {
        phase = GamePhase.victoryCutscene;
      } else {
        phase = GamePhase.prepare;
        enterPreparePhase();
      }
    } else {
      losses++;
      battleLog.add('💀 패배했습니다... 현재 기록: $wins승 $losses패');
      if (losses >= maxLosses) {
        phase = GamePhase.gameover;
      } else {
        phase = GamePhase.prepare;
        enterPreparePhase();
      }
    }
    notifyListeners();
  }
}
