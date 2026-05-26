import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/game_state.dart';
import 'game_board.dart'; // DragData 사용

class ShopPanel extends StatelessWidget {
  const ShopPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. 상태 표시줄 (골드, 라이프, 승수) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 골드 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonGold.withValues(alpha: 0.15),
                    AppColors.neonGold.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.neonGold.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '${gameState.gold}',
                    style: const TextStyle(
                      color: AppColors.neonGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Gold',
                    style: TextStyle(
                      color: AppColors.neonGold,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                // 승 수 표시
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.winGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.winGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.winGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${gameState.wins}/${gameState.maxWins}',
                        style: const TextStyle(
                          color: AppColors.winGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 하트 라이프
                Row(
                  children: List.generate(gameState.maxLosses, (index) {
                    final isLost = index < gameState.losses;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Icon(
                        isLost ? Icons.favorite_border : Icons.favorite,
                        color: isLost
                            ? AppColors.textMuted.withValues(alpha: 0.4)
                            : AppColors.damageRed,
                        size: 18,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ─── 선택 힌트 바 ───
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: gameState.selectedCharacter == null
                ? AppColors.surfaceCard
                : AppColors.neonCyanLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: gameState.selectedCharacter == null
                  ? AppColors.outline.withValues(alpha: 0.55)
                  : AppColors.neonCyan,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  gameState.selectionHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: gameState.selectedCharacter == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (gameState.selectedCharacter != null) ...[
                const SizedBox(width: 8),
                _miniIconButton(
                  icon: Icons.sell_outlined,
                  color: AppColors.neonPinkLight,
                  tooltip: '판매',
                  onPressed: gameState.sellSelectedCharacter,
                ),
                _miniIconButton(
                  icon: Icons.close,
                  color: AppColors.textMuted,
                  tooltip: '선택 해제',
                  onPressed: gameState.clearSelection,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // --- 2. 대기석 (Bench) ---
        Row(
          children: [
            const Icon(Icons.weekend_outlined,
                color: AppColors.textMuted, size: 14),
            const SizedBox(width: 6),
            const Text(
              '대기석',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '탭하여 선택',
              style: TextStyle(color: AppColors.textDim, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final char = gameState.bench[index];
            final isSelected = gameState.selectedBenchIndex == index;

            return Expanded(
              child: DragTarget<DragData>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) {
                  final data = details.data;
                  if (data.source == 'grid') {
                    gameState.returnToBench(data.gridPos!, index);
                  } else if (data.source == 'bench') {
                    gameState.swapBench(data.benchIndex!, index);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final isOver = candidateData.isNotEmpty;

                  Widget benchSlot = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 80,
                    decoration: BoxDecoration(
                      color: isOver
                          ? AppColors.neonCyan.withValues(alpha: 0.14)
                          : isSelected
                              ? AppColors.neonCyan.withValues(alpha: 0.14)
                              : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.neonGold
                            : isOver
                                ? AppColors.neonCyan
                                : AppColors.outline.withValues(alpha: 0.6),
                        width: isSelected || isOver ? 3.0 : 2.0,
                      ),
                    ),
                    child: char == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color:
                                      AppColors.outline.withValues(alpha: 0.18),
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: AppColors.textDim
                                        .withValues(alpha: 0.55),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(char.emoji,
                                      style: const TextStyle(fontSize: 26)),
                                  const SizedBox(height: 2),
                                  Text(
                                    char.name,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 8),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              // 대기석 유닛 성급 표시
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Row(
                                  children: List.generate(
                                    char.starLevel,
                                    (_) => const Icon(Icons.star_rounded,
                                        color: AppColors.neonGold, size: 8),
                                  ),
                                ),
                              ),

                              // 대기석 유닛 삭제/판매 단추
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () =>
                                      gameState.sellCharacterFromBench(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.outline,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.damageRed,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonGold,
                                      borderRadius: BorderRadius.circular(4),
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
                    final gradeColor = AppColors.getGradeColor(char.grade);
                    benchSlot = Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gradeColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: gradeColor.withValues(alpha: 0.1),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: benchSlot,
                      ),
                    );

                    benchSlot = Draggable<DragData>(
                      data: DragData(source: 'bench', benchIndex: index),
                      onDragStarted: () {
                        gameState.startDragging(char.cost * char.starLevel);
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
                            width: 70,
                            height: 70,
                            child: benchSlot,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                AppColors.surfaceCard.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: benchSlot,
                    );
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => gameState.tapBenchSlot(index),
                    child: benchSlot,
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // --- 3. 상점 (Shop) ---
        Row(
          children: [
            const Icon(Icons.storefront_rounded,
                color: AppColors.textMuted, size: 14),
            const SizedBox(width: 6),
            const Text(
              '상점',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '같은 유닛 3개 → 합성',
              style: TextStyle(color: AppColors.textDim, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 155,
          child: Row(
            children: List.generate(5, (index) {
              final template = gameState.shopCards[index];

              if (template == null) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.45),
                          width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        '품절',
                        style: TextStyle(
                            color: AppColors.textDim,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ),
                );
              }

              final gradeColor = AppColors.getGradeColor(template.grade);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final success = gameState.buyCharacter(index);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              gameState.gold < template.cost
                                  ? '골드가 부족합니다!'
                                  : '대기석에 빈 자리가 없습니다!',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: gradeColor.withValues(alpha: 0.4),
                            width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.outline.withValues(alpha: 0.14),
                            blurRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ─── 등급 컬러 스트라이프 ───
                          Container(
                            width: double.infinity,
                            height: 3,
                            decoration: BoxDecoration(
                              color: gradeColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: gradeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppColors.getGradeText(template.grade),
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(template.emoji,
                                      style: const TextStyle(fontSize: 28)),
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    template.description,
                                    style: const TextStyle(
                                        color: AppColors.textDim, fontSize: 7),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.neonGold
                                              .withValues(alpha: 0.15),
                                          AppColors.neonGold
                                              .withValues(alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.neonGold
                                              .withValues(alpha: 0.5),
                                          width: 1),
                                    ),
                                    child: Text(
                                      '🪙 ${template.cost}G',
                                      style: const TextStyle(
                                        color: AppColors.neonGold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // --- 4. 조작 버튼 OR 드래그 판매 HUD 대체 영역 ---
        gameState.isDragging
            ? Container(
                height: 52,
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: DragTarget<DragData>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    gameState.sellDraggedCharacter(details.data);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isOver = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOver
                              ? [
                                  Colors.red.withValues(alpha: 0.35),
                                  Colors.red.withValues(alpha: 0.20),
                                ]
                              : [
                                  Colors.red.withValues(alpha: 0.12),
                                  Colors.red.withValues(alpha: 0.06),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOver
                              ? Colors.redAccent
                              : Colors.redAccent.withValues(alpha: 0.4),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent
                                .withValues(alpha: isOver ? 0.3 : 0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        isOver
                            ? '💥 놓아서 즉시 판매!'
                            : '🔥 여기에 드롭하여 즉시 판매 (🪙 +${gameState.draggingCharacterGold ?? 0}골드)',
                        style: TextStyle(
                          color: isOver ? Colors.white : AppColors.damageRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
              )
            : Row(
                children: [
                  // 리롤 버튼
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceCard,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.neonCyan, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => gameState.rerollShop(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              color: AppColors.neonCyan, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '리롤 ${gameState.rerollCost}G',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 전투 시작 버튼
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: gameState.canStartBattle
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.neonPink.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            )
                          : null,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gameState.canStartBattle
                              ? AppColors.neonPink
                              : AppColors.textMuted.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: gameState.canStartBattle
                                ? AppColors.outline
                                : AppColors.textMuted.withValues(alpha: 0.55),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (gameState.canStartBattle) {
                            gameState.startBattle();
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('전장에 유닛을 1명 이상 배치해야 합니다.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: gameState.canStartBattle
                                  ? Colors.white
                                  : AppColors.surfaceCard,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gameState.canStartBattle ? '⚔️ 전투 시작' : '배치 필요',
                              style: TextStyle(
                                color: gameState.canStartBattle
                                    ? Colors.white
                                    : AppColors.surfaceCard,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18),
      color: color,
      onPressed: onPressed,
    );
  }
}
