import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('PetMatch app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PetMatchApp());

    // Verify that the title PetMatch is present
    expect(find.text('PetMatch'), findsWidgets);
  });
}
