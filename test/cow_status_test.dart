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
  });
}
