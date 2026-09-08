import 'package:flutter_test/flutter_test.dart';
import 'package:backloggd_clone/main.dart';

void main() {
  testWidgets('Catalog screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BackloggdCloneApp());

    // Verify that our search catalog title or hint text is present.
    expect(find.text('Catálogo de Juegos'), findsOneWidget);
  });
}
