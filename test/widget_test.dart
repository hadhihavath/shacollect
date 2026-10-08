import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sha_collects/main.dart';

void main() {
  testWidgets('ShaCollectsApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShaCollectsApp(),
      ),
    );

    expect(find.byType(ShaCollectsApp), findsOneWidget);
  });
}
