import 'dart:math';
import '../models/character.dart';
import '../models/tile_grid.dart';

class OpponentData {
  final String name;
  final int wins;
  final int losses;
  final TileGrid grid;

  OpponentData({
    required this.name,
    required this.wins,
    required this.losses,
    required this.grid,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wins': wins,
      'losses': losses,
      'grid': grid.toJson(),
    };
  }

  factory OpponentData.fromJson(Map<String, dynamic> json) {
    return OpponentData(
      name: json['name'] as String,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      grid: TileGrid.fromJson(json['grid'] as Map<String, dynamic>),
    );
  }
}

class MatchmakerService {
  static final MatchmakerService _instance = MatchmakerService._internal();
  factory MatchmakerService() => _instance;
  MatchmakerService._internal() {
    _initializeBotPresets();
  }

  // 플레이어들의 배치 세이브 풀 (Key: '승-패')
  final Map<String, List<OpponentData>> _playerPool = {};

  // 기본 봇 데이터베이스
  final List<OpponentData> _botPresets = [];

  // 매칭 검색
  OpponentData getOpponent(int wins, int losses) {
    final key = '$wins-$losses';
    final random = Random();

    // 1. 플레이어 풀에서 동일한 승-패 기록 검색
    if (_playerPool.containsKey(key) && _playerPool[key]!.isNotEmpty) {
      final list = _playerPool[key]!;
      // 80% 확률로 다른 플레이어의 실제 데이터 매칭, 20%는 봇
      if (random.nextDouble() < 0.8) {
        return list[random.nextInt(list.length)];
      }
    }

    // 2. 적합한 난이도의 봇 찾기
    // 봇들의 '승-패' 기록 중 플레이어의 '승' 수와 가장 가깝거나 난이도가 비슷한 봇 매칭
    final matchedBots = _botPresets.where((bot) {
      // 대략 승수 차이가 +-1 이내인 봇 매칭
      return (bot.wins - wins).abs() <= 1;
    }).toList();

    if (matchedBots.isNotEmpty) {
      return matchedBots[random.nextInt(matchedBots.length)];
    }

    // 예외 상황: 가장 가까운 봇 아무나 매칭
    return _botPresets[random.nextInt(_botPresets.length)];
  }

  // 플레이어 배치 데이터 풀에 저장
  void savePlayerLayout(
      String playerName, int wins, int losses, TileGrid grid) {
    final key = '$wins-$losses';
    final cloneGrid = grid.clone();

    // 혹시라도 전투 중 피해를 입은 상태가 아닌, 최대 HP 상태로 백업해야 하므로 HP 복구
    for (final tile in cloneGrid.tiles.values) {
      if (tile.character != null) {
        tile.character!.currentHp = tile.character!.currentMaxHp;
        tile.character!.shield = 0;
        tile.character!.poisonDuration = 0;
        tile.character!.poisonDamage = 0;
        tile.character!.deathHandled = false;
      }
    }

    final opponent = OpponentData(
      name: playerName,
      wins: wins,
      losses: losses,
      grid: cloneGrid,
    );

    _playerPool.putIfAbsent(key, () => []).add(opponent);
  }

  // 봇 프리셋 목록 초기화 (총 15개 이상, 난이도별 세분화)
  void _initializeBotPresets() {
    _botPresets.clear();

    // --- 0승 구간 봇 (매우 약함) ---
    _botPresets.add(OpponentData(
      name: '매점 앞 1학년 민수',
      wins: 0,
      losses: 0,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
      ], {
        const Point(0, 0): CharacterType.normalStudent,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '빵 들고 뛰는 철이',
      wins: 0,
      losses: 1,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
      ], {
        const Point(0, 0): CharacterType.shuttle,
        const Point(1, 0): CharacterType.normalStudent,
      }),
    ));

    // --- 1승 구간 봇 (약함) ---
    _botPresets.add(OpponentData(
      name: '2학년 축구대기방 지훈',
      wins: 1,
      losses: 0,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
      ], {
        const Point(0, 0): CharacterType.normalStudent,
        const Point(1, 0): CharacterType.iljin,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '학원 째고 피시방 가는 준호',
      wins: 1,
      losses: 1,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, -1),
      ], {
        const Point(0, 0): CharacterType.shuttle,
        const Point(0, -1): CharacterType.prefect,
      }),
    ));

    // --- 2~3승 구간 봇 (보통) ---
    _botPresets.add(OpponentData(
      name: '축구화 새로 산 태민',
      wins: 2,
      losses: 1,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(1, 1),
      ], {
        const Point(0, 0): CharacterType.captain,
        const Point(1, 0): CharacterType.normalStudent,
        const Point(0, 1): CharacterType.shuttle,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '선도부 우등생 서윤',
      wins: 3,
      losses: 0,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(1, 1),
      ], {
        const Point(0, 0): CharacterType.prefect,
        const Point(1, 0): CharacterType.studious,
        const Point(0, 1): CharacterType.normalStudent,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '야간 자율학습 도망조',
      wins: 3,
      losses: 2,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(2, 0),
        const Point(1, 1),
      ], {
        const Point(0, 0): CharacterType.iljin,
        const Point(1, 0): CharacterType.normalStudent,
        const Point(2, 0): CharacterType.shuttle,
      }),
    ));

    // --- 4~5승 구간 봇 (중간고사급 난이도) ---
    _botPresets.add(OpponentData(
      name: '방과후 화학반 성민',
      wins: 4,
      losses: 1,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(1, 1),
        const Point(2, 0),
      ], {
        const Point(0, 0): CharacterType.chemTeacher,
        const Point(1, 0): CharacterType.prefect,
        const Point(2, 0): CharacterType.normalStudent,
        const Point(0, 1): CharacterType.shuttle,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '매점 단골 패밀리',
      wins: 5,
      losses: 2,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(2, 0),
        const Point(0, 1),
        const Point(1, 1),
      ], {
        const Point(0, 0): CharacterType.storeKeeper,
        const Point(1, 0): CharacterType.shuttle,
        const Point(2, 0): CharacterType.iljin,
        const Point(0, 1): CharacterType.normalStudent,
      }),
    ));

    // --- 6~7승 구간 봇 (강함) ---
    _botPresets.add(OpponentData(
      name: '체육실 열쇠 당번',
      wins: 6,
      losses: 0,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(0, 1),
        const Point(1, 1),
        const Point(2, 0),
        const Point(2, 1),
      ], {
        const Point(0, 0): CharacterType.peTeacher,
        const Point(1, 0): CharacterType.captain,
        const Point(0, 1): CharacterType.prefect,
        const Point(2, 0): CharacterType.normalStudent,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '시험기간 독서실 정예반',
      wins: 7,
      losses: 2,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(2, 0),
        const Point(1, 1),
        const Point(2, 1),
        const Point(0, 2),
      ], {
        const Point(0, 0): CharacterType.studious,
        const Point(1, 0): CharacterType.prefect,
        const Point(2, 0): CharacterType.chemTeacher,
        const Point(1, 1): CharacterType.normalStudent,
        const Point(0, 2): CharacterType.shuttle,
      }),
    ));

    // --- 8~9승 구간 봇 (최상위권 보스급) ---
    _botPresets.add(OpponentData(
      name: '급식 순서 1순위 일진회',
      wins: 8,
      losses: 1,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(2, 0),
        const Point(0, 1),
        const Point(1, 1),
        const Point(2, 1),
        const Point(1, 2),
      ], {
        const Point(0, 0): CharacterType.iljin,
        const Point(1, 0): CharacterType.peTeacher,
        const Point(2, 0): CharacterType.iljin,
        const Point(0, 1): CharacterType.captain,
        const Point(1, 1): CharacterType.prefect,
        const Point(2, 1): CharacterType.shuttle,
      }),
    ));

    _botPresets.add(OpponentData(
      name: '교무실 어벤져스',
      wins: 9,
      losses: 2,
      grid: _createBotGrid([
        const Point(0, 0),
        const Point(1, 0),
        const Point(2, 0),
        const Point(0, 1),
        const Point(1, 1),
        const Point(2, 1),
        const Point(0, -1),
        const Point(1, -1),
      ], {
        const Point(0, 0): CharacterType.lunchLady,
        const Point(1, 0): CharacterType.peTeacher,
        const Point(2, 0): CharacterType.chemTeacher,
        const Point(0, 1): CharacterType.prefect,
        const Point(1, 1): CharacterType.studious,
        const Point(0, -1): CharacterType.captain,
        const Point(1, -1): CharacterType.storeKeeper,
      }),
    ));
  }

  // 봇 전장 생성 헬퍼
  TileGrid _createBotGrid(List<Point<int>> tilePositions,
      Map<Point<int>, CharacterType> placements) {
    final grid = TileGrid();
    grid.tiles.clear();
    for (final pos in tilePositions) {
      grid.addTile(pos);
    }
    placements.forEach((pos, type) {
      final template = CharacterTemplate.getByType(type);
      grid.setCharacter(
        pos,
        CharacterInstance(
          id: 'bot_${type.name}_${Random().nextInt(10000)}',
          template: template,
        ),
      );
    });
    grid.recalculateOrder();
    return grid;
  }
}
