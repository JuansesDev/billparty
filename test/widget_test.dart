import 'package:flutter_test/flutter_test.dart';

import 'package:billparty/main.dart';

void main() {
  testWidgets('renders the blank home screen', (WidgetTester tester) async {
    // Build the app and render the first frame.
    await tester.pumpWidget(const BillPartyApp());

    // The app bar title and the placeholder body are on screen.
    expect(find.text('BillParty'), findsOneWidget);
    expect(find.text('Blank screen — ready to build.'), findsOneWidget);
  });
}
