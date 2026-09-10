import 'package:flutter_test/flutter_test.dart';
import 'package:backloggd_clone/main.dart';

void main() {
  testWidgets('Catalog screen smoke test', (WidgetTester tester) async {
    // Pasamos el parámetro requerido para que coincida con el nuevo constructor de main.dart
    await tester.pumpWidget(
      const BackloggdCloneApp(initialRouteIsLoggedIn: true),
    );

    // Verify that our search catalog title or hint text is present.
    expect(find.text('Catálogo de Juegos'), findsOneWidget);
  });
}
