import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistance/core/locale/app_locale.dart';

void main() {
  group('AppLocale', () {
    test('fromCode reconnait toutes les valeurs', () {
      expect(AppLocale.fromCode('fr'), AppLocale.french);
      expect(AppLocale.fromCode('dioula'), AppLocale.dioula);
      expect(AppLocale.fromCode('nouchi'), AppLocale.nouchi);
      expect(AppLocale.fromCode('baoule'), AppLocale.baoule);
    });

    test('fromCode inconnue revient au français', () {
      expect(AppLocale.fromCode('klingon'), AppLocale.french);
      expect(AppLocale.fromCode(null), AppLocale.french);
      expect(AppLocale.fromCode(''), AppLocale.french);
    });

    test('isExperimental est vrai sauf pour le français', () {
      expect(AppLocale.french.isExperimental, isFalse);
      expect(AppLocale.dioula.isExperimental, isTrue);
      expect(AppLocale.nouchi.isExperimental, isTrue);
      expect(AppLocale.baoule.isExperimental, isTrue);
    });

    test('codes round-trip', () {
      for (final locale in AppLocale.values) {
        expect(AppLocale.fromCode(locale.code), locale);
      }
    });
  });
}
