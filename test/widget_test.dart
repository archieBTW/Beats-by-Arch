import 'package:flutter_test/flutter_test.dart';
import 'package:beats_by_arch/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BeatsByArchApp());
    
    // Verify the app title appears
    expect(find.text('Beats by Arch'), findsOneWidget);
    
    // Verify presets section exists
    expect(find.text('PRESETS'), findsOneWidget);
  });
}
