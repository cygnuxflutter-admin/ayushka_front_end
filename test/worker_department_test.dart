import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/department_model.dart';
import 'package:ayushka/app/data/models/worker_model.dart';
import 'package:ayushka/app/data/models/department_summary_model.dart';

void main() {
  group('DepartmentModel Tests', () {
    test('DepartmentModel parses JSON with nested workerStats correctly', () {
      final json = {
        '_id': 'dept123',
        'gaushalaId': 'gau456',
        'gaushalaName': 'Ayushka Main Farm',
        'departmentName': 'Milking Operations',
        'departmentCode': 'MILK',
        'description': 'Daily milking and milk storage',
        'isActive': true,
        'workerStats': {
          'totalWorkers': 10,
          'activeWorkers': 8,
          'inactiveWorkers': 2,
        },
      };

      final dept = DepartmentModel.fromJson(json);

      expect(dept.id, 'dept123');
      expect(dept.gaushalaId, 'gau456');
      expect(dept.gaushalaName, 'Ayushka Main Farm');
      expect(dept.departmentName, 'Milking Operations');
      expect(dept.departmentCode, 'MILK');
      expect(dept.description, 'Daily milking and milk storage');
      expect(dept.isActive, true);
      expect(dept.workerStats.totalWorkers, 10);
      expect(dept.workerStats.activeWorkers, 8);
      expect(dept.workerStats.inactiveWorkers, 2);
    });

    test('DepartmentModel parses populated gaushalaId object', () {
      final json = {
        'id': 'dept999',
        'gaushalaId': {
          '_id': 'gau888',
          'gaushalaName': 'Navsari Farm',
        },
        'departmentName': 'Feed Preparation',
        'departmentCode': 'FEED',
      };

      final dept = DepartmentModel.fromJson(json);

      expect(dept.id, 'dept999');
      expect(dept.gaushalaId, 'gau888');
      expect(dept.gaushalaName, 'Navsari Farm');
      expect(dept.departmentName, 'Feed Preparation');
      expect(dept.departmentCode, 'FEED');
    });

    test('DepartmentModel toJson produces valid payload', () {
      final dept = DepartmentModel(
        id: 'dept1',
        gaushalaId: 'gau1',
        departmentName: 'Medical',
        departmentCode: 'MED',
        description: 'Healthcare & veterinary',
        isActive: true,
      );

      final json = dept.toJson();

      expect(json['_id'], 'dept1');
      expect(json['gaushalaId'], 'gau1');
      expect(json['departmentName'], 'Medical');
      expect(json['departmentCode'], 'MED');
      expect(json['isActive'], true);
    });
  });

  group('WorkerModel Tests', () {
    test('WorkerModel parses JSON and populated fields correctly', () {
      final json = {
        '_id': 'w101',
        'gaushalaId': 'gau1',
        'departmentId': {
          '_id': 'dept1',
          'departmentName': 'Milking Operations',
          'departmentCode': 'MILK',
        },
        'name': 'Ramesh Patel',
        'joiningDate': '2024-01-15T00:00:00.000Z',
        'isActive': true,
        'isDelete': false,
      };

      final worker = WorkerModel.fromJson(json);

      expect(worker.id, 'w101');
      expect(worker.gaushalaId, 'gau1');
      expect(worker.departmentId, 'dept1');
      expect(worker.departmentName, 'Milking Operations');
      expect(worker.departmentCode, 'MILK');
      expect(worker.name, 'Ramesh Patel');
      expect(worker.joiningDate, isNotNull);
      expect(worker.joiningDate!.year, 2024);
      expect(worker.joiningDate!.month, 1);
      expect(worker.joiningDate!.day, 15);
      expect(worker.isActive, true);
      expect(worker.isDelete, false);
      expect(worker.leavingDate, isNull);
    });

    test('Worker leaving gaushala updates isActive to false and records leavingDate', () {
      final worker = WorkerModel(
        id: 'w101',
        gaushalaId: 'gau1',
        departmentId: 'dept1',
        name: 'Ramesh Patel',
        joiningDate: DateTime.utc(2024, 1, 15),
        isActive: true,
        isDelete: false,
      );

      final departureDate = DateTime.utc(2024, 6, 30);
      final leftWorker = worker.copyWith(
        isActive: false,
        isDelete: false,
        leavingDate: departureDate,
      );

      expect(leftWorker.isActive, false);
      expect(leftWorker.isDelete, false);
      expect(leftWorker.leavingDate, departureDate);
    });

    test('Soft-delete updates isDelete to true', () {
      final worker = WorkerModel(
        id: 'w101',
        gaushalaId: 'gau1',
        departmentId: 'dept1',
        name: 'Ramesh Patel',
        isActive: true,
        isDelete: false,
      );

      final deletedWorker = worker.copyWith(
        isDelete: true,
        isActive: false,
      );

      expect(deletedWorker.isDelete, true);
      expect(deletedWorker.isActive, false);
    });

    test('Worker toJson outputs correct fields', () {
      final worker = WorkerModel(
        id: 'w101',
        gaushalaId: 'gau1',
        departmentId: 'dept1',
        name: 'Ramesh Patel',
        joiningDate: DateTime.utc(2024, 1, 15),
        isActive: true,
        isDelete: false,
      );

      final json = worker.toJson();

      expect(json['_id'], 'w101');
      expect(json['gaushalaId'], 'gau1');
      expect(json['departmentId'], 'dept1');
      expect(json['name'], 'Ramesh Patel');
      expect(json['isActive'], true);
      expect(json['isDelete'], false);
      expect(json['joiningDate'], contains('2024-01-15'));
    });
  });

  group('DepartmentSummaryModel Tests', () {
    test('DepartmentSummaryModel parses overall stats and department breakdown', () {
      final json = {
        'totalDepartments': 3,
        'totalWorkers': 15,
        'activeWorkers': 12,
        'inactiveWorkers': 3,
        'departmentBreakdown': [
          {
            'departmentId': 'd1',
            'departmentName': 'Milking Operations',
            'departmentCode': 'MILK',
            'totalWorkers': 8,
            'activeWorkers': 7,
            'inactiveWorkers': 1,
          },
          {
            'departmentId': 'd2',
            'departmentName': 'Feed & Nutrition',
            'departmentCode': 'FEED',
            'totalWorkers': 5,
            'activeWorkers': 4,
            'inactiveWorkers': 1,
          },
          {
            'departmentId': 'd3',
            'departmentName': 'Medical Care',
            'departmentCode': 'MED',
            'totalWorkers': 2,
            'activeWorkers': 1,
            'inactiveWorkers': 1,
          },
        ],
      };

      final summary = DepartmentSummaryModel.fromJson(json);

      expect(summary.totalDepartments, 3);
      expect(summary.totalWorkers, 15);
      expect(summary.activeWorkers, 12);
      expect(summary.inactiveWorkers, 3);
      expect(summary.departmentBreakdown.length, 3);
      expect(summary.departmentBreakdown.first.departmentCode, 'MILK');
      expect(summary.departmentBreakdown.first.activeWorkers, 7);
    });

    test('DepartmentSummaryModel handles nested data key gracefully', () {
      final json = {
        'success': true,
        'data': {
          'totalDepartments': 2,
          'overallWorkers': 10,
          'activeWorkers': 9,
          'inactiveWorkers': 1,
          'breakdown': [
            {
              'departmentId': 'd1',
              'departmentName': 'Milking',
              'departmentCode': 'MILK',
              'totalWorkers': 6,
              'activeWorkers': 5,
              'inactiveWorkers': 1,
            },
          ],
        },
      };

      final summary = DepartmentSummaryModel.fromJson(json);

      expect(summary.totalDepartments, 2);
      expect(summary.totalWorkers, 10);
      expect(summary.activeWorkers, 9);
      expect(summary.inactiveWorkers, 1);
      expect(summary.departmentBreakdown.length, 1);
    });
  });
}
