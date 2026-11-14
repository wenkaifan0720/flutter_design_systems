// A password field shows one reveal button: its own, never a second from the text field it is built on.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

void main() {
  testWidgets('a password field shows one reveal button', (t) async {
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Fluent2Host(brightness: Brightness.light, child: child!),
        home: Center(
          child: SizedBox(
            width: 320,
            child: Fluent2PasswordField(label: 'Password', onChanged: (_) {}),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byIcon(Fluent2Icons.eye), findsOneWidget);
    await t.tap(find.byIcon(Fluent2Icons.eye));
    await t.pumpAndSettle();
    expect(find.byIcon(Fluent2Icons.eye), findsNothing);
    expect(find.byIcon(Fluent2Icons.eyeOff), findsOneWidget);
  });

  testWidgets('a hidden text field leaves the reveal to its own end control', (
    t,
  ) async {
    Future<void> pump(Widget? end) => t.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Fluent2Host(brightness: Brightness.light, child: child!),
        home: Center(
          child: SizedBox(
            width: 320,
            child: Fluent2TextField(
              label: 'PIN',
              obscureText: true,
              trailing: end,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    // obscureText alone is password by another name: its reveal button.
    await pump(null);
    await t.pumpAndSettle();
    expect(find.byIcon(Fluent2Icons.eye), findsOneWidget);
    // With the caller's own control at the end, no second button.
    await pump(const Icon(Fluent2Icons.lockClosed));
    await t.pumpAndSettle();
    expect(find.byIcon(Fluent2Icons.eye), findsNothing);
    expect(t.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
  });
}
