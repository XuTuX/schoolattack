import 'dart:math';
import 'character.dart';

class Tile {
  final Point<int> position;
  CharacterInstance? character;
  int orderNumber; // 1-indexed

  Tile({required this.position, this.character, this.orderNumber = 0});

  Tile clone() {
    return Tile(
      position: position,
      character: character?.clone(),
      orderNumber: orderNumber,
    );
  }
}

class TileGrid {
  final Map<Point<int>, Tile> _tiles = {};
  bool _hasCustomOrder = false;

  TileGrid();

  Map<Point<int>, Tile> get tiles => _tiles;

  List<Tile> get sortedTiles {
    final list = _tiles.values.toList();
    list.sort((a, b) {
      if (a.position.y != b.position.y) {
        return a.position.y.compareTo(b.position.y); // 위에서 아래로 (Y 오름차순)
      }
      return a.position.x.compareTo(b.position.x); // 왼쪽에서 오른쪽으로 (X 오름차순)
    });
    return list;
  }

  // 타일 개수
  int get count => _tiles.length;

  // 초기 2칸 세팅
  void initializeDefault() {
    _tiles.clear();
    _hasCustomOrder = false;
    addTile(const Point(0, 0));
    addTile(const Point(1, 0));
    recalculateOrder();
  }

  // 타일 추가
  bool addTile(Point<int> pos) {
    if (_tiles.containsKey(pos)) return false;
    _tiles[pos] = Tile(position: pos);
    if (_hasCustomOrder) {
      _tiles[pos]!.orderNumber = _nextOrderNumber;
    } else {
      recalculateOrder();
    }
    return true;
  }

  // 캐릭터 배치
  void setCharacter(Point<int> pos, CharacterInstance? char) {
    if (_tiles.containsKey(pos)) {
      _tiles[pos]!.character = char;
    }
  }

  // 캐릭터 제거
  CharacterInstance? removeCharacter(Point<int> pos) {
    if (_tiles.containsKey(pos)) {
      final char = _tiles[pos]!.character;
      _tiles[pos]!.character = null;
      return char;
    }
    return null;
  }

  // 턴 순서 재계산 [왼쪽 위 ➡️ 오른쪽 아래]
  void recalculateOrder() {
    final sorted = sortedTiles;
    for (int i = 0; i < sorted.length; i++) {
      sorted[i].orderNumber = i + 1;
    }
    _hasCustomOrder = false;
  }

  int get _nextOrderNumber {
    if (_tiles.isEmpty) return 1;
    return _tiles.values.map((tile) => tile.orderNumber).reduce(max) + 1;
  }

  List<Tile> get orderedTiles {
    final list = _tiles.values.toList();
    list.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
    return list;
  }

  // 순번 배지를 드래그했을 때 기존 순서 목록에서 이동한다.
  bool moveTileOrder(Point<int> from, Point<int> to) {
    if (from == to || !_tiles.containsKey(from) || !_tiles.containsKey(to)) {
      return false;
    }

    final ordered = orderedTiles;
    final fromIndex = ordered.indexWhere((tile) => tile.position == from);
    final toIndex = ordered.indexWhere((tile) => tile.position == to);
    if (fromIndex == -1 || toIndex == -1) return false;

    final moved = ordered.removeAt(fromIndex);
    ordered.insert(toIndex, moved);

    for (int i = 0; i < ordered.length; i++) {
      ordered[i].orderNumber = i + 1;
    }
    _hasCustomOrder = true;
    return true;
  }

  // 확장 가능한 빈 타일 후보 목록 (현재 가지고 있는 타일들의 상하좌우 중 빈 곳)
  List<Point<int>> getExpandablePositions() {
    final Set<Point<int>> candidates = {};
    const List<Point<int>> directions = [
      Point(0, -1), // 상
      Point(0, 1), // 하
      Point(-1, 0), // 좌
      Point(1, 0), // 우
    ];

    for (final pos in _tiles.keys) {
      for (final dir in directions) {
        final neighbor = Point(pos.x + dir.x, pos.y + dir.y);
        if (!_tiles.containsKey(neighbor)) {
          candidates.add(neighbor);
        }
      }
    }
    return candidates.toList();
  }

  TileGrid clone() {
    final grid = TileGrid();
    for (final entry in _tiles.entries) {
      grid._tiles[entry.key] = entry.value.clone();
    }
    grid._hasCustomOrder = _hasCustomOrder;
    return grid;
  }

  Map<String, dynamic> toJson() {
    final tileList = _tiles.values.map((tile) {
      return {
        'x': tile.position.x,
        'y': tile.position.y,
        'orderNumber': tile.orderNumber,
        'character': tile.character?.toJson(),
      };
    }).toList();
    return {'tiles': tileList};
  }

  factory TileGrid.fromJson(Map<String, dynamic> json) {
    final grid = TileGrid();
    final list = json['tiles'] as List;
    for (final item in list) {
      final x = item['x'] as int;
      final y = item['y'] as int;
      final pos = Point(x, y);
      grid._tiles[pos] = Tile(
        position: pos,
        orderNumber: item['orderNumber'] as int? ?? 0,
      );

      final charJson = item['character'] as Map<String, dynamic>?;
      if (charJson != null) {
        grid.setCharacter(pos, CharacterInstance.fromJson(charJson));
      }
    }
    final hasStoredOrder = grid.tiles.values.every(
      (tile) => tile.orderNumber > 0,
    );
    if (hasStoredOrder) {
      grid._hasCustomOrder = true;
    } else {
      grid.recalculateOrder();
    }
    return grid;
  }
}
