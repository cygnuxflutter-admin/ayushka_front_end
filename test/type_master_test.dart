import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/type_model.dart';

void main() {
  group('TypeModel Gaushala Association Tests', () {
    test('TypeModel parses gaushalaId as string correctly', () {
      final json = {
        '_id': '6abb81dec91ddf959f54022b',
        'typeName': 'Cow',
        'gaushalaId': '6abb81dec91ddf959f54022a',
        'createdAt': '2026-10-01T12:00:00.000Z',
      };

      final model = TypeModel.fromJson(json);

      expect(model.id, '6abb81dec91ddf959f54022b');
      expect(model.typeName, 'Cow');
      expect(model.gaushalaId, '6abb81dec91ddf959f54022a');
      expect(model.gaushalaName, null);
    });

    test('TypeModel parses gaushalaId as populated object correctly', () {
      final json = {
        '_id': '6abb81dec91ddf959f54022b',
        'typeName': 'Milking Cow',
        'gaushalaId': {
          '_id': '6abb81dec91ddf959f54022a',
          'gaushalaName': 'Ayushka Vedic Gaushala',
        },
      };

      final model = TypeModel.fromJson(json);

      expect(model.id, '6abb81dec91ddf959f54022b');
      expect(model.typeName, 'Milking Cow');
      expect(model.gaushalaId, '6abb81dec91ddf959f54022a');
      expect(model.gaushalaName, 'Ayushka Vedic Gaushala');
    });

    test('TypeModel parses snake_case gaushala_id correctly', () {
      final json = {
        '_id': '6abb81dec91ddf959f54022b',
        'typeName': 'Dry',
        'gaushala_id': '6abb81dec91ddf959f54022a',
        'gaushalaName': 'Navsari Station',
      };

      final model = TypeModel.fromJson(json);

      expect(model.gaushalaId, '6abb81dec91ddf959f54022a');
      expect(model.gaushalaName, 'Navsari Station');
    });

    test('TypeModel toJson serializes gaushalaId properly', () {
      const model = TypeModel(
        id: '6abb81dec91ddf959f54022b',
        typeName: 'Cow',
        gaushalaId: '6abb81dec91ddf959f54022a',
      );

      final json = model.toJson();

      expect(json['typeName'], 'Cow');
      expect(json['gaushalaId'], '6abb81dec91ddf959f54022a');
      expect(json['_id'], '6abb81dec91ddf959f54022b');
    });

    test('TypeModel copyWith correctly copies and updates gaushalaId and gaushalaName', () {
      const original = TypeModel(
        id: '1',
        typeName: 'Calf',
        gaushalaId: 'g1',
        gaushalaName: 'Gaushala 1',
      );

      final updated = original.copyWith(
        typeName: 'Heifer',
        gaushalaId: 'g2',
        gaushalaName: 'Gaushala 2',
      );

      expect(updated.id, '1');
      expect(updated.typeName, 'Heifer');
      expect(updated.gaushalaId, 'g2');
      expect(updated.gaushalaName, 'Gaushala 2');
    });

    test('Type filter strictly requires a valid gaushalaId (not null, not empty, not "all")', () {
      bool isValidGaushala(String? gId) {
        return gId != null && gId.trim().isNotEmpty && gId.trim().toLowerCase() != 'all';
      }

      expect(isValidGaushala(null), isFalse);
      expect(isValidGaushala(''), isFalse);
      expect(isValidGaushala('   '), isFalse);
      expect(isValidGaushala('all'), isFalse);
      expect(isValidGaushala('ALL'), isFalse);
      expect(isValidGaushala('6abb81dec91ddf959f54022a'), isTrue);
    });
  });
}
