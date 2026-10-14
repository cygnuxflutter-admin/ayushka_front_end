import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/cow_model.dart';

void main() {
  group('CowModel Status Hierarchy Tests', () {
    test('Hierarchy 1: Deleted cow returns "Deleted" and cannot be edited', () {
      final cow1 = CowModel.fromJson({
        'id': '1',
        'tag_id': 'TAG-01',
        'isDelete': true,
        'isDied': true,
        'isActive': true,
      });
      expect(cow1.statusDisplay, 'Deleted');
      expect(cow1.canEdit, false);

      final cow2 = CowModel.fromJson({
        'id': '2',
        'tag_id': 'TAG-02',
        'isDeleted': true,
        'send_died_date': '2026-09-30',
        'isActive': false,
      });
      expect(cow2.statusDisplay, 'Deleted');
      expect(cow2.canEdit, false);
    });

    test('Hierarchy 2: Died cow (not deleted) returns "Died" and cannot be edited', () {
      final cow1 = CowModel.fromJson({
        'id': '3',
        'tag_id': 'TAG-03',
        'isDelete': false,
        'isDied': true,
        'isActive': true,
      });
      expect(cow1.statusDisplay, 'Died');
      expect(cow1.canEdit, false);

      final cow2 = CowModel.fromJson({
        'id': '4',
        'tag_id': 'TAG-04',
        'isDelete': false,
        'send_died_date': '2026-09-30',
        'isActive': true,
      });
      expect(cow2.statusDisplay, 'Died');
      expect(cow2.canEdit, false);
    });

    test('Hierarchy 3: InActive cow (not deleted, not died) returns "InActive" and can be edited', () {
      final cow = CowModel.fromJson({
        'id': '5',
        'tag_id': 'TAG-05',
        'isDelete': false,
        'isDied': false,
        'isActive': false,
      });
      expect(cow.statusDisplay, 'InActive');
      expect(cow.canEdit, true);
    });

    test('Hierarchy 4: Active cow (not deleted, not died, isActive true) returns "Active" and can be edited', () {
      final cow = CowModel.fromJson({
        'id': '6',
        'tag_id': 'TAG-06',
        'isDelete': false,
        'isDied': false,
        'isActive': true,
      });
      expect(cow.statusDisplay, 'Active');
      expect(cow.canEdit, true);
    });

    test('AddCowRequestModel supports male cattle with specific cow type', () {
      const request = AddCowRequestModel(
        breed: 'breed-1',
        gaushalaId: 'gaushala-1',
        type: 'type-bull-1',
        tagId: 'BULL-001',
        isFemale: false,
        addedBy: 'user-1',
      );

      final json = request.toJson();
      expect(json['tag_id'], 'BULL-001');
      expect(json['isFemale'], false);
      expect(json['type'], 'type-bull-1');
    });

    test('CowModel with male gender properly parses and preserves cowType', () {
      final cow = CowModel.fromJson({
        'id': '7',
        'tag_id': 'BULL-002',
        'isFemale': false,
        'type': {
          'id': 'type-10',
          'typeName': 'Breeding Bull',
        },
      });

      expect(cow.isFemale, false);
      expect(cow.cowType, isNotNull);
      expect(cow.cowType?.typeName, 'Breeding Bull');
    });
  });
}
