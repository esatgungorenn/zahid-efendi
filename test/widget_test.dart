import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zahit_efendi/main.dart';
import 'package:zahit_efendi/models.dart';
import 'package:zahit_efendi/store.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  late AppStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ze_widget');
    store = AppStore(
      File('${dir.path}/data.json'),
      const SchoolTable(2026, 2025, [
        School(
            name: 'Test Anadolu Lisesi',
            province: 'Konya',
            district: 'Meram',
            type: SchoolType.anadolu,
            score: 450,
            percentile: 20),
      ]),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ZahitEfendiApp(store: store));
    await tester.pumpAndSettle();
  }

  testWidgets('empty app invites the first exam', (tester) async {
    await pumpApp(tester);
    expect(find.text('İlk denemeyi ekleyin'), findsOneWidget);
  });

  testWidgets('add exam flow: steppers enforce limits, save shows on home',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Yeni deneme ekle'));
    await tester.pumpAndSettle();

    // Türkçe: 20 questions. Push correct to 18, wrong to 2, then wrong is capped.
    final plusCorrect = find.byTooltip('Türkçe doğru artır');
    final plusWrong = find.byTooltip('Türkçe yanlış artır');
    Future<void> tap(Finder f, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(f);
        await tester.pump();
      }
    }

    await tap(plusCorrect, 18);
    await tap(plusWrong, 3); // third tap ignored: 18 + 2 = 20
    expect(tester.widget<Text>(find.byKey(const Key('tr-blank'))).data, '0');
    expect(find.text('net 17,33'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Sınav adı'), 'AGİS-1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Katılan kişi'), '355');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Sıralaması'), '400');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'LGS puanı'), '460,821');
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(find.text('Katılan kişiden büyük olamaz'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Sıralaması'), '55');
    await tester.pump();
    expect(find.text('Yüzdelik dilim: %15,49 (otomatik)'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Son deneme'), findsOneWidget);
    expect(find.textContaining('AGİS-1'), findsWidgets);
    expect(store.exams.single.answer('tr').correct, 18);
  });

  testWidgets('schools screen lists matches for selected province',
      (tester) async {
    await tester.runAsync(() async {
      await store.upsert(exam('a', rank: 53, participants: 348, score: 467));
      await store.updateSettings(const Settings(provinces: ['Konya']));
    });
    await pumpApp(tester);
    await tester.tap(find.text('Liseler'));
    await tester.pumpAndSettle();
    expect(find.text('Test Anadolu Lisesi'), findsOneWidget);
    expect(find.text('Girebildiği liseler (1)'), findsOneWidget);
  });
}
