import 'package:flutter_test/flutter_test.dart';
import 'package:melody_hub/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MelodyHubApp());
    expect(find.text('Melody Hub'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
