// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chargly/main.dart';

void main() {
  testWidgets('shows phone selection and a battery estimate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CharglyApp());

    expect(find.text('Chargly'), findsOneWidget);
    expect(find.text('Telefon modelinizi seçin'), findsOneWidget);
    expect(find.text('45%'), findsWidgets);
    expect(find.text('5 sa 39 dk'), findsOneWidget);
    expect(find.text('3279 mAh'), findsOneWidget);
    expect(find.text('Sosyal medya'), findsOneWidget);
    expect(find.text('Oyun'), findsOneWidget);
    expect(find.text('Müzik'), findsOneWidget);
  });

  testWidgets('phone and usage selections update the estimate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CharglyApp());

    await tester.tap(find.byKey(const ValueKey('phone-model-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Samsung Galaxy S24 · 4000 mAh').last);
    await tester.pumpAndSettle();

    expect(find.text('4000 mAh'), findsOneWidget);
    expect(find.text('6 sa 54 dk'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scenario-oyun')));
    await tester.pumpAndSettle();
    expect(find.text('1 sa 12 dk'), findsOneWidget);
  });

  testWidgets('charge level, estimate and reset actions work', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CharglyApp());

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('battery-slider')),
    );
    slider.onChanged!(50);
    await tester.pump();
    expect(find.text('6 sa 17 dk'), findsOneWidget);

    await tester.ensureVisible(find.text('Tahmini süreyi hesapla'));
    await tester.tap(find.text('Tahmini süreyi hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('Tahmini süre: 6 sa 17 dk'), findsOneWidget);

    await tester.ensureVisible(find.text('Demoyu sıfırla'));
    await tester.tap(find.text('Demoyu sıfırla'));
    await tester.pumpAndSettle();
    expect(find.text('5 sa 39 dk'), findsOneWidget);
    expect(find.text('45%'), findsWidgets);
  });

  testWidgets('brightness and GPS affect the estimated duration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CharglyApp());

    await tester.ensureVisible(find.text('Konum / GPS açık'));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('5 sa 19 dk'), findsOneWidget);

    await tester.ensureVisible(find.text('Düşük'));
    await tester.tap(find.text('Düşük'));
    await tester.pumpAndSettle();
    expect(find.text('5 sa 24 dk'), findsOneWidget);
  });

  testWidgets('drawer opens an AI chat and returns to the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CharglyApp());

    await tester.tap(find.byKey(const ValueKey('main-menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI ile sohbet'));
    await tester.pumpAndSettle();

    expect(find.text('Geri dön'), findsOneWidget);
    expect(
      find.textContaining('Pil, batarya ve şarj tüketimi hakkında bana soru'),
      findsOneWidget,
    );

    await tester.tap(find.text('Geri dön'));
    await tester.pumpAndSettle();
    expect(find.text('Telefon modelinizi seçin'), findsOneWidget);
  });

  testWidgets('dashboard fits a mobile browser viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CharglyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Telefon modelinizi seçin'), findsOneWidget);
    expect(find.text('Tahmini kalan süre'), findsNothing);
    expect(find.text('TAHMİNİ KALAN SÜRE'), findsOneWidget);
  });
}
