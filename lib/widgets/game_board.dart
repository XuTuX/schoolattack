import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../models/tile_grid.dart';

class GameBoard extends StatefulWidget {
  final bool isInteractive;

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
    _expandPulse = Tween<double>(begin: 0.25, end: 0.7).animate(
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

    final expandables = widget.isInteractive
        ? grid.getExpandablePositions()
        : <Point<int>>[];
    final points = [...tiles.keys, ...expandables];
    final minX = points.map((p) => p.x).reduce(min);
    final maxX = points.map((p) => p.x).reduce(max);
    final minY = points.map((p) => p.y).reduce(min);
    final maxY = points.map((p) => p.y).reduce(max);

    final colCount = maxX - minX + 1;
    final rowCount = maxY - minY + 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7CC466),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.20),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _BoardPainter())),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 9.0;
                const inset = 18.0;
                final availableWidth =
                    constraints.maxWidth - inset * 2 - gap * (colCount - 1);
                final availableHeight =
                    constraints.maxHeight - inset * 2 - gap * (rowCount - 1);
                final cellSize = min(
                  76.0,
                  min(availableWidth / colCount, availableHeight / rowCount),
                );
                final step = cellSize + gap;
                final gridWidth = colCount * cellSize + (colCount - 1) * gap;
                final gridHeight = rowCount * cellSize + (rowCount - 1) * gap;
                final startX = (constraints.maxWidth - gridWidth) / 2;
                final startY = (constraints.maxHeight - gridHeight) / 2;

                return Stack(
                  children: [
                    if (widget.isInteractive)
                      for (final pos in expandables)
                        Positioned(
                          left: startX + (pos.x - minX) * step,
                          top: startY + (pos.y - minY) * step,
                          width: cellSize,
                          height: cellSize,
                          child: _buildExpansionTile(context, gameState, pos),
                        ),
                    for (final tile in tiles.values)
                      Positioned(
                        left: startX + (tile.position.x - minX) * step,
                        top: startY + (tile.position.y - minY) * step,
                        width: cellSize,
                        height: cellSize,
                        child: _buildTile(context, gameState, tile),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, GameState gameState, Tile tile) {
    return DragTarget<Point<int>>(
      onWillAcceptWithDetails: (_) => widget.isInteractive,
      onAcceptWithDetails: (details) =>
          gameState.reorderTile(details.data, tile.position),
      builder: (context, candidateData, rejectedData) {
        final char = tile.character;
        final isOver = candidateData.isNotEmpty;
        final isSelected = gameState.selectedGridPos == tile.position;
        final hasSelection = gameState.selectedCharacter != null;

        final tileContent = _TileCard(
          tile: tile,
          character: char,
          isOver: isOver,
          isSelected: isSelected,
          hasSelection: hasSelection,
          canReorder: widget.isInteractive,
        );

        if (!widget.isInteractive) return tileContent;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => gameState.tapGridTile(tile.position),
          child: tileContent,
        );
      },
    );
  }

  Widget _buildExpansionTile(
    BuildContext context,
    GameState gameState,
    Point<int> pos,
  ) {
    return AnimatedBuilder(
      animation: _expandPulse,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (gameState.gold >= gameState.tileCost) {
                final purchased = gameState.purchaseTile(pos);
                if (purchased && gameState.selectedCharacter != null) {
                  gameState.tapGridTile(pos);
                }
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('골드가 부족합니다! (타일 확장: 4골드)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: _expandPulse.value),
                  width: 1.6,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white.withValues(alpha: 0.86),
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gameState.tileCost}G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TileCard extends StatelessWidget {
  final Tile tile;
  final CharacterInstance? character;
  final bool isOver;
  final bool isSelected;
  final bool hasSelection;
  final bool canReorder;

  const _TileCard({
    required this.tile,
    required this.character,
    required this.isOver,
    required this.isSelected,
    required this.hasSelection,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    final char = character;
    final gradeColor = AppColors.getGradeColor(char?.grade);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFD86B)
            : isOver
            ? AppColors.neonCyanLight
            : char == null
            ? const Color(0xFFE7F2D5)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.neonGold
              : isOver || hasSelection
              ? AppColors.neonCyan
              : char == null
              ? AppColors.outline.withValues(alpha: 0.35)
              : gradeColor,
          width: isSelected || isOver || char != null ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.18),
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 5,
            left: 5,
            child: _OrderHandle(
              position: tile.position,
              orderNumber: tile.orderNumber,
              canReorder: canReorder,
            ),
          ),
          if (char == null)
            Icon(
              Icons.add_rounded,
              color: AppColors.outline.withValues(alpha: 0.16),
              size: 24,
            )
          else
            _CharacterTileContent(character: char),
          if (isSelected)
            Positioned(
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonGold,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outline, width: 1),
                ),
                child: const Text(
                  '선택',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CharacterTileContent extends StatelessWidget {
  final CharacterInstance character;

  const _CharacterTileContent({required this.character});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final emojiSize = min(34.0, max(22.0, size * 0.42));
        final nameFontSize = min(9.0, max(7.0, size * 0.12));
        final statHeight = min(22.0, max(17.0, size * 0.26));
        final statMinWidth = min(28.0, max(22.0, size * 0.36));
        final starSize = min(10.0, max(7.0, size * 0.13));
        final edge = min(5.0, max(3.0, size * 0.07));

        return Stack(
          children: [
            Positioned(
              top: edge,
              right: edge,
              child: Row(
                children: List.generate(
                  character.starLevel,
                  (_) => Icon(
                    Icons.star_rounded,
                    color: AppColors.neonGold,
                    size: starSize,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, size * 0.16, 4, statHeight + 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          character.emoji,
                          style: TextStyle(fontSize: emojiSize),
                        ),
                      ),
                    ),
                    Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: edge,
              left: edge,
              child: _BoardStatBadge(
                icon: Icons.flash_on_rounded,
                value: character.currentAttack,
                color: AppColors.neonGold,
                height: statHeight,
                minWidth: statMinWidth,
              ),
            ),
            Positioned(
              bottom: edge,
              right: edge,
              child: _BoardStatBadge(
                icon: Icons.favorite_rounded,
                value: character.currentHp,
                color: AppColors.damageRed,
                height: statHeight,
                minWidth: statMinWidth,
              ),
            ),
            if (character.shield > 0)
              Positioned(
                top: size * 0.30,
                right: edge,
                child: _StatusPill(
                  text: 'S${character.shield}',
                  color: AppColors.shieldBlue,
                  fontSize: min(8.0, max(6.0, size * 0.10)),
                ),
              ),
            if (character.poisonDuration > 0)
              Positioned(
                top: size * 0.30,
                left: edge,
                child: _StatusPill(
                  text: 'P${character.poisonDuration}',
                  color: AppColors.poisonPurple,
                  fontSize: min(8.0, max(6.0, size * 0.10)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OrderHandle extends StatelessWidget {
  final Point<int> position;
  final int orderNumber;
  final bool canReorder;

  const _OrderHandle({
    required this.position,
    required this.orderNumber,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _OrderBadge(orderNumber: orderNumber);
    if (!canReorder) return badge;

    return Draggable<Point<int>>(
      data: position,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: _OrderBadge(orderNumber: orderNumber),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: badge),
      child: badge,
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int orderNumber;

  const _OrderBadge({required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    final isStart = orderNumber == 1;
    return Container(
      width: isStart ? 24 : 20,
      height: isStart ? 24 : 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isStart ? AppColors.neonPink : AppColors.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 1.4),
      ),
      child: Text(
        '$orderNumber',
        style: TextStyle(
          color: isStart ? Colors.white : AppColors.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BoardStatBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final double height;
  final double minWidth;

  const _BoardStatBadge({
    required this.icon,
    required this.value,
    required this.color,
    this.height = 22,
    this.minWidth = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 8),
          Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: min(8.0, max(6.0, height * 0.38)),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _StatusPill({
    required this.text,
    required this.color,
    this.fontSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF7CC466);
    canvas.drawRect(Offset.zero & size, base);

    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (double x = -size.height; x < size.width; x += 44) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 18, 0)
        ..lineTo(x + size.height + 18, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 16, size.width - 32, size.height - 32),
        const Radius.circular(18),
      ),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 22),
      Offset(size.width / 2, size.height - 22),
      linePaint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 36, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
