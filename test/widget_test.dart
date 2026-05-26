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
}
