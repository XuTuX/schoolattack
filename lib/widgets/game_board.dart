import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/game_state.dart';

class DragData {
  final String source; // 'bench' or 'grid'
  final int? benchIndex;
  final Point<int>? gridPos;

  DragData({required this.source, this.benchIndex, this.gridPos});
}

class GameBoard extends StatefulWidget {
  final bool isInteractive; // 전투 뷰에서는 상호작용 불가

  const GameBoard({super.key, this.isInteractive = true});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandPulseController;
  late Animation<double> _expandPulse;

  @override
  void initState() {
    super.initState();
    _expandPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _expandPulse = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _expandPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _expandPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final grid = widget.isInteractive
        ? gameState.playerGrid
        : (gameState.battlePlayerGrid ?? gameState.playerGrid);

    final tiles = grid.tiles;
    if (tiles.isEmpty) {
      return const Center(
        child: Text(
          '전장이 비어 있습니다.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    final List<Point<int>> allPoints = tiles.keys.toList();
    final List<Point<int>> expandables =
        widget.isInteractive ? grid.getExpandablePositions() : [];

    final List<Point<int>> combined = [...allPoints, ...expandables];
    int minX = combined.map((p) => p.x).reduce(min);
    int maxX = combined.map((p) => p.x).reduce(max);
    int minY = combined.map((p) => p.y).reduce(min);
    int maxY = combined.map((p) => p.y).reduce(max);

    const double cellSize = 86.0;
    const double padding = 36.0;

    final double boardWidth = (maxX - minX + 1) * cellSize + padding * 2;
    final double boardHeight = (maxY - minY + 1) * cellSize + padding * 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: AppColors.grass.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.outline.withValues(alpha: 0.25),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2.0,
          child: Center(
            child: SizedBox(
              width: boardWidth,
              height: boardHeight,
              child: Stack(
                children: [
                  for (final tile in tiles.values) ...[
                    Positioned(
                      left: (tile.position.x - minX) * cellSize + padding,
                      top: (tile.position.y - minY) * cellSize + padding,
                      width: cellSize - 6,
                      height: cellSize - 6,
                      child: DragTarget<DragData>(
                        onWillAcceptWithDetails: (details) =>
                            widget.isInteractive,
                        onAcceptWithDetails: (details) {
                          final data = details.data;
                          if (data.source == 'bench') {
                            gameState.placeCharacter(
                                data.benchIndex!, tile.position);
                          } else if (data.source == 'grid') {
                            gameState.moveGridCharacter(
                                data.gridPos!, tile.position);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final char = tile.character;
                          final isOver = candidateData.isNotEmpty;
                          final isSelected =
                              gameState.selectedGridPos == tile.position;
                          final hasSelection =
                              gameState.selectedCharacter != null;

                          Widget tileContent = AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFE08A)
                                  : isOver
                                      ? const Color(0xFFDFF8FF)
                                      : char == null
                                          ? const Color(0xFFE7D7AC)
                                          : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.neonGold
                                    : isOver || hasSelection
                                        ? AppColors.neonCyan
                                        : AppColors.outline
                                            .withValues(alpha: 0.75),
                                width: isSelected || isOver ? 3.0 : 2.0,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 빈 타일 도트 패턴
                                if (char == null)
                                  Center(
                                    child: Icon(
                                      Icons.grid_4x4_rounded,
                                      color: AppColors.outline
                                          .withValues(alpha: 0.18),
                                      size: 28,
                                    ),
                                  ),

                                // 실행 순서 번호 (동그란 배지)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.outline,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${tile.orderNumber}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // 성급 별 표시 (우측 상단)
                                if (char != null)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Row(
                                      children: List.generate(
                                        char.starLevel,
                                        (_) => const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.neonGold,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ),

                                // 캐릭터 일러스트/이모지
                                if (char != null) ...[
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 14),
                                      Text(
                                        char.emoji,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        char.name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      // 체력바
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SizedBox(
                                          width: 60,
                                          height: 4,
                                          child: LinearProgressIndicator(
                                            value: char.currentMaxHp > 0
                                                ? char.currentHp /
                                                    char.currentMaxHp
                                                : 0.0,
                                            backgroundColor: AppColors.damageRed
                                                .withValues(alpha: 0.25),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              AppColors.hpGreen,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // 마나바
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SizedBox(
                                          width: 60,
                                          height: 3,
                                          child: LinearProgressIndicator(
                                            value: char.mana / 100.0,
                                            backgroundColor: AppColors.manaBlue
                                                .withValues(alpha: 0.25),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              AppColors.manaBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // 실드 표시
                                  if (char.shield > 0)
                                    Positioned(
                                      bottom: 12,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.shieldBlue,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'S${char.shield}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // 독 상태 표시
                                  if (char.poisonDuration > 0)
                                    Positioned(
                                      bottom: 12,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.poisonPurple,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'P${char.poisonDuration}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                if (isSelected)
                                  Positioned(
                                    bottom: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonGold,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.outline,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '선택',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );

                          if (char != null) {
                            final gradeColor =
                                AppColors.getGradeColor(char.grade);
                            tileContent = Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.outline
                                        .withValues(alpha: 0.18),
                                    blurRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: gradeColor,
                                  width: 2.0,
                                ),
                              ),
                              child: tileContent,
                            );

                            if (widget.isInteractive) {
                              tileContent = Draggable<DragData>(
                                data: DragData(
                                    source: 'grid', gridPos: tile.position),
                                onDragStarted: () {
                                  gameState.startDragging(
                                      char.cost * char.starLevel);
                                },
                                onDragEnd: (_) {
                                  gameState.stopDragging();
                                },
                                onDraggableCanceled: (_, _) {
                                  gameState.stopDragging();
                                },
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: SizedBox(
                                      width: cellSize - 10,
                                      height: cellSize - 10,
                                      child: tileContent,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard
                                          .withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                child: tileContent,
                              );
                            }
                          }

                          if (!widget.isInteractive) return tileContent;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => gameState.tapGridTile(tile.position),
                            child: tileContent,
                          );
                        },
                      ),
                    ),
                  ],
                  // ─── 확장 가능 타일 (펄스 애니메이션) ───
                  if (widget.isInteractive)
                    for (final pos in expandables) ...[
                      Positioned(
                        left: (pos.x - minX) * cellSize + padding,
                        top: (pos.y - minY) * cellSize + padding,
                        width: cellSize - 6,
                        height: cellSize - 6,
                        child: AnimatedBuilder(
                          animation: _expandPulse,
                          builder: (context, child) {
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (gameState.gold >= gameState.tileCost) {
                                    final purchased =
                                        gameState.purchaseTile(pos);
                                    if (purchased &&
                                        gameState.selectedCharacter != null) {
                                      gameState.tapGridTile(pos);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('골드가 부족합니다! (타일 확장: 4골드)'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard.withValues(
                                        alpha:
                                            0.45 + _expandPulse.value * 0.25),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.neonCyan.withValues(
                                          alpha: _expandPulse.value),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        color: AppColors.neonCyan.withValues(
                                            alpha: _expandPulse.value + 0.3),
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${gameState.tileCost}G',
                                        style: TextStyle(
                                          color: AppColors.neonCyan.withValues(
                                              alpha: _expandPulse.value + 0.3),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
