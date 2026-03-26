import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_finance_system/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const KanbanFinanceApp());
    expect(find.text('Kanban Finance'), findsOneWidget);
  });
}
