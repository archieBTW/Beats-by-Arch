import 'package:flutter_test/flutter_test.dart';
import 'package:beats_by_arch/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BeatsByArchApp());
    await tester.pump();

    // Verify presets section exists
    expect(find.text('PRESETS'), findsOneWidget);
    expect(find.text('Custom Frequencies'), findsOneWidget);
  });
}
