import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_attack/main.dart';
import 'package:school_attack/models/game_state.dart';

void main() {
  testWidgets('Lobby screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameState(),
        child: const SchoolAttackApp(),
      ),
    );

    expect(find.text('급식실 대소동'), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1400, 1000),
  ]) {
    testWidgets(
      'Prepare screen has no overflow at ${size.width}x${size.height}',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final gameState = GameState()..enterPreparePhase();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: gameState,
            child: const SchoolAttackApp(),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  }
}
