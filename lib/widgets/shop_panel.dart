import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/character.dart';
import '../models/game_state.dart';

class ShopPanel extends StatelessWidget {
  const ShopPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final shopGap = isWide ? 12.0 : 8.0;
        final shopCardWidth = isWide
            ? (constraints.maxWidth - shopGap * 4) / 5
            : 116.0;
        final shopCardHeight = isWide
            ? min(240.0, max(196.0, shopCardWidth * 0.92))
            : 190.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 상태 표시줄 (골드, 라이프, 승수) ---
            Row(
              children: [
                // 골드 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.neonGold.withValues(alpha: 0.15),
                        AppColors.neonGold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonGold.withValues(alpha: 0.6),
                    ),
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
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          // 승 수 표시
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.winGreen.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.winGreen.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: AppColors.winGreen,
                                  size: 14,
                                ),
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
                            children: List.generate(gameState.maxLosses, (
                              index,
                            ) {
                              final isLost = index < gameState.losses;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                child: Icon(
                                  isLost
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  color: isLost
                                      ? AppColors.textMuted.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.damageRed,
                                  size: 18,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                const Icon(
                  Icons.weekend_outlined,
                  color: AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  '대기석',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => gameState.tapBenchSlot(index),
                    child: _BenchSlot(
                      index: index,
                      character: char,
                      isSelected: isSelected,
                      onSell: () => gameState.sellCharacterFromBench(index),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // --- 3. 상점 (Shop) ---
            Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  '상점',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '같은 유닛 3개 → 합성',
                  style: TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ShopShelf(
              cardWidth: shopCardWidth,
              cardHeight: shopCardHeight,
              gap: shopGap,
              scrollable: !isWide,
              itemBuilder: (index) {
                final template = gameState.shopCards[index];
                if (template == null) return const _SoldOutShopCard();

                final gradeColor = AppColors.getGradeColor(template.grade);
                return Material(
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
                    child: _ShopCard(
                      template: template,
                      gradeColor: gradeColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // --- 4. 조작 버튼 ---
            LayoutBuilder(
              builder: (context, buttonConstraints) {
                final rerollButton = _buildRerollButton(gameState);
                final battleButton = _buildBattleButton(context, gameState);

                if (buttonConstraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      rerollButton,
                      const SizedBox(height: 8),
                      battleButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 1, child: rerollButton),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: battleButton),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRerollButton(GameState gameState) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.neonCyan, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      onPressed: () => gameState.rerollShop(),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.refresh_rounded,
              color: AppColors.neonCyan,
              size: 16,
            ),
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
    );
  }

  Widget _buildBattleButton(BuildContext context, GameState gameState) {
    return Container(
      decoration: gameState.canStartBattle
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPink.withValues(alpha: 0.2),
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
            borderRadius: BorderRadius.circular(12),
          ),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
                gameState.canStartBattle ? '전투 시작' : '배치 필요',
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

class _ShopShelf extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final double gap;
  final bool scrollable;
  final Widget Function(int index) itemBuilder;

  const _ShopShelf({
    required this.cardWidth,
    required this.cardHeight,
    required this.gap,
    required this.scrollable,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final children = List.generate(5, (index) {
      return Padding(
        padding: EdgeInsets.only(right: index == 4 ? 0 : gap),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: itemBuilder(index),
        ),
      );
    });

    if (scrollable) {
      return SizedBox(
        height: cardHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: children),
        ),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: Row(children: children),
    );
  }
}

class _BenchSlot extends StatelessWidget {
  final int index;
  final CharacterInstance? character;
  final bool isSelected;
  final VoidCallback onSell;

  const _BenchSlot({
    required this.index,
    required this.character,
    required this.isSelected,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final char = character;
    Widget slot = Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 80,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.neonCyan.withValues(alpha: 0.14)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.neonGold
              : AppColors.outline.withValues(alpha: 0.6),
          width: isSelected ? 3.0 : 2.0,
        ),
      ),
      child: char == null ? _buildEmptySlot() : _buildCharacterSlot(char),
    );

    if (char == null) return slot;

    final gradeColor = AppColors.getGradeColor(char.grade);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gradeColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: gradeColor.withValues(alpha: 0.1), blurRadius: 6),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(9), child: slot),
    );
  }

  Widget _buildEmptySlot() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.outline.withValues(alpha: 0.18),
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: AppColors.textDim.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSlot(CharacterInstance char) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(char.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(
              char.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8,
              ),
            ),
          ],
        ),
        Positioned(
          top: 4,
          left: 4,
          child: Row(
            children: List.generate(
              char.starLevel,
              (_) => const Icon(
                Icons.star_rounded,
                color: AppColors.neonGold,
                size: 8,
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onSell,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: 1),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}

class _ShopCard extends StatelessWidget {
  final CharacterTemplate template;
  final Color gradeColor;

  const _ShopCard({required this.template, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final headerHeight = min(34.0, max(28.0, height * 0.15));
        final emojiSize = min(58.0, max(34.0, min(width, height) * 0.30));
        final nameFontSize = min(15.0, max(11.0, width * 0.055));
        final contentPadding = min(10.0, max(7.0, width * 0.035));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline, width: 2.5),
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
              Positioned.fill(
                top: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: headerHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gradeColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.outline, width: 2),
                    ),
                  ),
                  child: Text(
                    AppColors.getGradeText(template.grade),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  headerHeight + contentPadding,
                  contentPadding,
                  contentPadding,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            template.emoji,
                            style: TextStyle(fontSize: emojiSize),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: min(9.0, max(5.0, height * 0.035))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 104,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatBubble(
                              icon: Icons.flash_on_rounded,
                              value: template.attack,
                              color: AppColors.neonGold,
                            ),
                            _CostBubble(cost: template.cost),
                            _StatBubble(
                              icon: Icons.favorite_rounded,
                              value: template.maxHp,
                              color: AppColors.damageRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoldOutShopCard extends StatelessWidget {
  const _SoldOutShopCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.45),
          width: 2.5,
        ),
      ),
      child: const Text(
        '품절',
        style: TextStyle(
          color: AppColors.textDim,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _StatBubble({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 27,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline, width: 1.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 10),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostBubble extends StatelessWidget {
  final int cost;

  const _CostBubble({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 1.6),
      ),
      child: Text(
        '${cost}G',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
