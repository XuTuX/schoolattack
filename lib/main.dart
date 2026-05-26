import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'models/game_state.dart';
import 'widgets/game_board.dart';
import 'widgets/shop_panel.dart';
import 'widgets/battle_view.dart';
import 'widgets/glass_panel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const SchoolAttackApp(),
    ),
  );
}

class SchoolAttackApp extends StatelessWidget {
  const SchoolAttackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '급식실 대소동',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonCyan,
          brightness: Brightness.light,
          primary: AppColors.neonCyan,
          secondary: AppColors.neonGold,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      home: const MainGameController(),
    );
  }
}

class MainGameController extends StatelessWidget {
  const MainGameController({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    // 밝은 장난감 보드 느낌의 공통 배경
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: NeonBackground()),
          SafeArea(
            child: _buildPhaseScreen(context, gameState.phase),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseScreen(BuildContext context, GamePhase phase) {
    switch (phase) {
      case GamePhase.lobby:
        return const LobbyScreen();
      case GamePhase.prepare:
        return const PrepareScreen();
      case GamePhase.battle:
        return const BattleView();
      case GamePhase.victoryCutscene:
        return const VictoryCutsceneScreen();
      case GamePhase.gameover:
        return const GameoverScreen();
    }
  }
}

// ════════════════════════════════════════
// 파스텔 배경 (하늘 + 운동장)
// ════════════════════════════════════════
class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyTop,
            AppColors.skyBottom,
            AppColors.scaffoldBg,
          ],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: CustomPaint(painter: _BackdropGridPainter()),
    );
  }
}

class _BackdropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint = Paint()..color = AppColors.grass;
    final darkGrassPaint = Paint()
      ..color = AppColors.grassDark.withValues(alpha: 0.4);
    final pathPaint = Paint()..color = const Color(0xFFFFD98F);
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);

    final groundTop = size.height * 0.74;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            -40, groundTop, size.width + 80, size.height - groundTop + 50),
        const Radius.elliptical(120, 46),
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.48, groundTop + 36, size.width * 0.72, 64),
      darkGrassPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.18, groundTop + 10, size.width * 0.34, 260),
      pathPaint,
    );

    void drawCloud(double x, double y, double scale) {
      canvas.drawCircle(Offset(x, y), 20 * scale, cloudPaint);
      canvas.drawCircle(
          Offset(x + 24 * scale, y - 8 * scale), 26 * scale, cloudPaint);
      canvas.drawCircle(Offset(x + 54 * scale, y), 20 * scale, cloudPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 8 * scale, y, 76 * scale, 20 * scale),
          Radius.circular(12 * scale),
        ),
        cloudPaint,
      );
    }

    drawCloud(size.width * 0.10, size.height * 0.12, 0.8);
    drawCloud(size.width * 0.68, size.height * 0.17, 1.0);

    final speckPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.08);
    for (double x = 16; x < size.width; x += 54) {
      for (double y = 22; y < size.height; y += 58) {
        canvas.drawCircle(Offset(x, y), 2.0, speckPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════
// 🏠 1. 로비 화면 (Lobby)
// ════════════════════════════════════════
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController =
      TextEditingController(text: '신입생');

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = constraints.maxWidth < 520 ? 280.0 : 360.0;
        final contentWidth = min(constraints.maxWidth - 48, maxContentWidth);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── 떠다니는 이모지 캐릭터들 ───
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: const _FloatingEmojis(),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '급식실 대소동',
                    style: TextStyle(
                      color: AppColors.neonGold,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: AppColors.outline,
                          blurRadius: 0,
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: Colors.white,
                          blurRadius: 0,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'SCHOOL LUNCH AUTO BATTLE',
                    style: TextStyle(
                      color: AppColors.neonPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.outline,
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      '타일을 넓히고, 배치를 다듬고, 자동 전투로 10승까지',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── 이름 입력 & 게임 시작 패널 ───
                  SizedBox(
                    width: min(320, contentWidth),
                    child: GlassPanel(
                      borderNeonColor: AppColors.neonCyan,
                      child: Column(
                        children: [
                          const Text(
                            '플레이어 이름',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            maxLength: 8,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.surfaceCard,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.outline, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.neonCyan, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ─── 펄스 글로우 시작 버튼 ───
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final glowOpacity =
                                  0.15 + _pulseAnimation.value * 0.2;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.outline.withValues(
                                          alpha: glowOpacity + 0.10),
                                      blurRadius: 0,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonCyan,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.outline,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 16),
                                ),
                                onPressed: () {
                                  if (_nameController.text.trim().isNotEmpty) {
                                    gameState.playerName =
                                        _nameController.text.trim();
                                  }
                                  gameState.enterPreparePhase();
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      '게임 시작',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
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
        );
      },
    );
  }
}

/// 로비 위에 떠다니는 이모지 캐릭터 행
class _FloatingEmojis extends StatelessWidget {
  const _FloatingEmojis();

  @override
  Widget build(BuildContext context) {
    const emojis = ['🧑‍🍳', '⚽', '👮', '📝', '🏪', '😈', '🍞'];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emojis.map((emoji) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════
// 🛠️ 2. 준비 및 배치 화면 (Prepare)
// ════════════════════════════════════════
class PrepareScreen extends StatelessWidget {
  const PrepareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 상단 정보 바 ───
          GlassPanel(
            borderNeonColor: AppColors.neonCyan.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 라운드 표시
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonCyan.withValues(alpha: 0.2),
                            AppColors.neonCyan.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'ROUND ${gameState.wins + gameState.losses + 1}',
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    // 도움말
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.help_outline,
                          color: AppColors.neonCyan, size: 20),
                      onPressed: () => _showGuideDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ─── 승/패 진행 바 ───
                Row(
                  children: [
                    // 승리 진행 바
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: AppColors.winGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${gameState.wins}/${gameState.maxWins}승',
                                style: const TextStyle(
                                  color: AppColors.winGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: gameState.wins / gameState.maxWins,
                              minHeight: 5,
                              backgroundColor:
                                  AppColors.winGreen.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.winGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 라이프 하트 표시
                    Row(
                      children: List.generate(gameState.maxLosses, (index) {
                        final isLost = index < gameState.losses;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            isLost ? Icons.favorite_border : Icons.favorite,
                            color: isLost
                                ? AppColors.textMuted.withValues(alpha: 0.35)
                                : AppColors.damageRed,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '배치 ${gameState.activeBoardUnitCount}명',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      '다음 기본 보상 ${gameState.roundIncome}G',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2D 전장 그리드
          const Expanded(
            child: GameBoard(isInteractive: true),
          ),
          const SizedBox(height: 12),

          // 상점 및 컨트롤 패널
          const GlassPanel(
            borderNeonColor: AppColors.neonGold,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: ShopPanel(),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: SizedBox(
            width: 340,
            child: GlassPanel(
              borderNeonColor: AppColors.neonCyan,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: AppColors.neonCyan, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '게임 규칙',
                          style: TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem('1', '준비 단계마다 10골드를 받습니다.'),
                  _buildRuleItem('2', '인접한 빈 칸을 4골드로 확장합니다.'),
                  _buildRuleItem('3', '같은 유닛 3개는 자동으로 합성됩니다.'),
                  _buildRuleItem('4', '전투는 같은 번호 칸끼리 동시에 행동합니다.'),
                  _buildRuleItem('5', '10승이면 승리, 5패면 게임오버입니다.'),
                  const SizedBox(height: 8),
                  const Text(
                    '상세 규칙은 docs/GAME_RULES.md에 정리되어 있습니다.',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 10, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  static Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.neonCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// 🏆 4. 최종 승리 스크린 (Victory Cutscene)
// ════════════════════════════════════════
class VictoryCutsceneScreen extends StatefulWidget {
  const VictoryCutsceneScreen({super.key});

  @override
  State<VictoryCutsceneScreen> createState() => _VictoryCutsceneScreenState();
}

class _VictoryCutsceneScreenState extends State<VictoryCutsceneScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _confettiController.addListener(() => setState(() {}));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 이모지 파티클 생성
    final rng = Random();
    const emojis = ['🎉', '👑', '⭐', '🏆', '✨', '🎊', '🥇'];
    for (int i = 0; i < 30; i++) {
      _particles.add(_ConfettiParticle(
        emoji: emojis[rng.nextInt(emojis.length)],
        x: rng.nextDouble(),
        startY: -0.1 - rng.nextDouble() * 0.5,
        speed: 0.3 + rng.nextDouble() * 0.6,
        drift: (rng.nextDouble() - 0.5) * 0.2,
        size: 14.0 + rng.nextDouble() * 14,
        delay: rng.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 컨펫티 이모지 파티클
        for (final p in _particles)
          Builder(builder: (context) {
            double progress = (_confettiController.value + p.delay) % 1.0;
            double y = p.startY + progress * 1.5;
            double x = p.x + sin(progress * pi * 3) * p.drift;
            double opacity = y > 0.8 ? max(0, 1.0 - (y - 0.8) * 5) : 1.0;
            if (y < 0) opacity = 0;

            return Positioned(
              left: x * size.width,
              top: y * size.height,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  p.emoji,
                  style: TextStyle(fontSize: p.size),
                ),
              ),
            );
          }),

        // 메인 콘텐츠
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber
                            .withValues(alpha: _glowAnimation.value * 0.15),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: GlassPanel(
                borderNeonColor: AppColors.victoryGold,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFFD166),
                            Colors.amberAccent,
                            Color(0xFFF4B860),
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        '👑 전설의 급식러 탄생 👑',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '🎉 축하합니다! 🎉\n\n'
                      '치열한 급식실 결투 끝에 10승을 달성하였습니다!\n'
                      '학교 모든 구역의 오토배틀 강자들을 꺾고\n'
                      '급식 배식권 1순위를 공식 쟁취하셨습니다!',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // 전적 통계
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statBadge(
                              '승', '${gameState.wins}', AppColors.winGreen),
                          const SizedBox(width: 16),
                          _statBadge(
                              '패', '${gameState.losses}', AppColors.damageRed),
                          const SizedBox(width: 16),
                          _statBadge(
                              '총 라운드',
                              '${gameState.wins + gameState.losses}',
                              AppColors.neonCyan),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGold,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                              color: AppColors.outline, width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => gameState.startNewGame(),
                        child: const Text(
                          '새 게임 시작하기',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final String emoji;
  final double x;
  final double startY;
  final double speed;
  final double drift;
  final double size;
  final double delay;

  _ConfettiParticle({
    required this.emoji,
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.size,
    required this.delay,
  });
}

// ════════════════════════════════════════
// 💀 5. 게임오버 스크린 (Game Over)
// ════════════════════════════════════════
class GameoverScreen extends StatefulWidget {
  const GameoverScreen({super.key});

  @override
  State<GameoverScreen> createState() => _GameoverScreenState();
}

class _GameoverScreenState extends State<GameoverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    // 초기 셰이크 연출
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shake = sin(_shakeAnimation.value * pi * 6) * 6;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: child,
            );
          },
          child: GlassPanel(
            borderNeonColor: AppColors.defeatRed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Colors.redAccent,
                        Color(0xFFFF6B6B),
                        Colors.red,
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    '💀 매점 빵 셔틀 엔딩 💀',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '결투에서 5회 패배하여 라이프가 소진되었습니다.\n\n'
                  '결국 급식실 대열 합류에 밀려나,\n'
                  '선배들의 빵을 사러 가는 매점 셔틀 신세가 되었습니다...\n'
                  '다음엔 더 기발한 2D 배치 조합으로 도전하세요!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 전적 통계
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statBadge('승', '${gameState.wins}', AppColors.winGreen),
                      const SizedBox(width: 16),
                      _statBadge(
                          '패', '${gameState.losses}', AppColors.damageRed),
                      const SizedBox(width: 16),
                      _statBadge(
                          '총 라운드',
                          '${gameState.wins + gameState.losses}',
                          AppColors.neonCyan),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '🍞 😭 🎒 🏪',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.defeatRed,
                      foregroundColor: Colors.white,
                      side:
                          const BorderSide(color: AppColors.outline, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => gameState.startNewGame(),
                    child: const Text(
                      '다시 도전하기',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
