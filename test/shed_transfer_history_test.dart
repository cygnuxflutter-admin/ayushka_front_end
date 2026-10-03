import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ayushka/app/data/models/shed_transfer_history_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/modules/cow/widgets/shed_transfer_history_dialog.dart';

class _FakeApiService extends GetxService implements ApiService {
  @override
  Future<ShedTransferHistoryResponse> getShedTransferHistory({
    String? gaushalaId,
    String? cowId,
    int? page,
    int? limit,
  }) async {
    return ShedTransferHistoryResponse(
      success: true,
      message: 'OK',
      data: ShedTransferHistoryData(
        records: [
          ShedTransferRecord(
            id: 'rec_101',
            reason: 'Moved to milking shed',
            transferDate: DateTime(2026, 9, 30, 10, 0),
            cow: const TransferCowSummary(
              id: 'c1',
              tagId: 'TAG-101',
              calfName: 'Gauri',
              isFemale: true,
            ),
            fromShed: const TransferShedSummary(
              id: 's1',
              shedName: 'Shed 1',
              shedNumber: 'S-01',
            ),
            toShed: const TransferShedSummary(
              id: 's2',
              shedName: 'Shed 2',
              shedNumber: 'S-02',
            ),
            transferredBy: const TransferUserSummary(
              id: 'u1',
              name: 'Admin User',
              emailId: 'admin@ayushka.com',
            ),
          ),
        ],
        total: 1,
        page: 1,
        limit: 10,
        totalPages: 1,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ShedTransferHistoryModel Serialization Tests', () {
    test('Parses Gaushala-wide shed transfer history response correctly', () {
      final json = {
        "success": true,
        "message": "Shed transfer history fetched successfully",
        "data": {
          "gaushala": {
            "_id": "6abcaebfd7556202004414a8",
            "gaushalaName": "ayushka_surat"
          },
          "records": [
            {
              "_id": "6abcfec057d4e60bbca282ca",
              "cow_id": {
                "_id": "6abce2dbfd6c01f90cab81cc",
                "breed": {
                  "_id": "6abbae15faa1ef7a8f6090a6",
                  "breedName": "Gir"
                },
                "type": {
                  "_id": "6abc973b6be6842e3db6c29f",
                  "typeName": "Milking"
                },
                "tag_id": "Tag-320",
                "calf_name": "Gomti",
                "isFemale": true,
                "avatarUrl": "",
                "isDied": false
              },
              "from_shed_id": {
                "_id": "6abcaf13d7556202004414c8",
                "shedName": "Shed01",
                "shedNumber": "SH-01"
              },
              "to_shed_id": {
                "_id": "6abcaf13d7556202004414c8",
                "shedName": "Shed01",
                "shedNumber": "SH-01"
              },
              "gaushala_id": {
                "_id": "6abcaebfd7556202004414a8",
                "gaushalaName": "ayushka_surat"
              },
              "transferredBy": {
                "_id": "6abb81dec91ddf959f54022a",
                "name": "Ayushka Admin",
                "emailId": "ayushka@yopmail.com",
                "username": "admin_ayushka"
              },
              "transferDate": "2026-09-30T12:21:20.829Z",
              "reason": "Testing gaushala check transfer",
              "createdAt": "2026-09-30T12:21:20.852Z",
              "updatedAt": "2026-09-30T12:21:20.852Z",
              "__v": 0
            }
          ],
          "total": 7,
          "page": 1,
          "limit": 7,
          "totalPages": 1
        }
      };

      final response = ShedTransferHistoryResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Shed transfer history fetched successfully');
      expect(response.data, isNotNull);

      final data = response.data!;
      expect(data.total, 7);
      expect(data.page, 1);
      expect(data.limit, 7);
      expect(data.totalPages, 1);
      expect(data.gaushala?.gaushalaName, 'ayushka_surat');
      expect(data.cow, isNull);

      expect(data.records.length, 1);
      final record = data.records.first;
      expect(record.id, '6abcfec057d4e60bbca282ca');
      expect(record.cow?.tagId, 'Tag-320');
      expect(record.cow?.calfName, 'Gomti');
      expect(record.cow?.breedName, 'Gir');
      expect(record.cow?.typeName, 'Milking');
      expect(record.cow?.isFemale, true);
      expect(record.fromShed?.shedName, 'Shed01');
      expect(record.fromShed?.shedNumber, 'SH-01');
      expect(record.fromShed?.display, 'Shed01 (SH-01)');
      expect(record.toShed?.display, 'Shed01 (SH-01)');
      expect(record.gaushala?.gaushalaName, 'ayushka_surat');
      expect(record.transferredBy?.name, 'Ayushka Admin');
      expect(record.transferredBy?.emailId, 'ayushka@yopmail.com');
      expect(record.reason, 'Testing gaushala check transfer');
      expect(record.transferDate, isNotNull);
    });

    test('Parses Cow-specific shed transfer history response correctly', () {
      final json = {
        "success": true,
        "message": "Shed transfer history fetched successfully",
        "data": {
          "cow": {
            "_id": "6abce2dbfd6c01f90cab81cc",
            "tag_id": "Tag-320",
            "calf_name": "Gomti"
          },
          "gaushala": {
            "_id": "6abcaebfd7556202004414a8",
            "gaushalaName": "ayushka_surat"
          },
          "records": [
            {
              "_id": "6abcfec057d4e60bbca282ca",
              "cow_id": {
                "_id": "6abce2dbfd6c01f90cab81cc",
                "tag_id": "Tag-320",
                "calf_name": "Gomti",
                "isFemale": true,
              },
              "from_shed_id": {
                "_id": "6abcaf01d7556202004414be",
                "shedName": "Shed01",
                "shedNumber": "SH-01"
              },
              "to_shed_id": {
                "_id": "6abcaf13d7556202004414c8",
                "shedName": "Shed02",
                "shedNumber": "SH-02"
              },
              "transferredBy": {
                "_id": "6abb81dec91ddf959f54022a",
                "name": "Ayushka Admin",
              },
              "transferDate": "2026-09-30T10:30:00.000Z",
              "reason": "Moved to milking shed",
            }
          ],
          "total": 1,
          "page": 1,
          "limit": 10,
          "totalPages": 1
        }
      };

      final response = ShedTransferHistoryResponse.fromJson(json);

      expect(response.success, true);
      expect(response.data, isNotNull);
      final data = response.data!;
      expect(data.cow?.tagId, 'Tag-320');
      expect(data.cow?.calfName, 'Gomti');
      expect(data.cow?.displayName, 'Tag-320 (Gomti)');
      expect(data.records.length, 1);
      expect(data.records.first.fromShed?.display, 'Shed01 (SH-01)');
      expect(data.records.first.toShed?.display, 'Shed02 (SH-02)');
      expect(data.records.first.reason, 'Moved to milking shed');
    });
  });

  group('Shed Transfer Advance Filter & CSV Export Tests', () {
    final records = [
      ShedTransferRecord(
        id: '1',
        cow: const TransferCowSummary(id: 'c1', tagId: 'Tag-301', calfName: 'Gomti', isFemale: true),
        fromShed: const TransferShedSummary(id: 's1', shedName: 'Shed01', shedNumber: 'SH-01'),
        toShed: const TransferShedSummary(id: 's2', shedName: 'Shed02', shedNumber: 'SH-02'),
        reason: 'Moved to milking shed',
        transferredBy: const TransferUserSummary(id: 'u1', name: 'Ayushka Admin', emailId: 'admin@test.com'),
        transferDate: DateTime(2026, 9, 30, 10, 0),
      ),
      ShedTransferRecord(
        id: '2',
        cow: const TransferCowSummary(id: 'c2', tagId: 'Tag-302', calfName: 'Radha', isFemale: true),
        fromShed: const TransferShedSummary(id: 's2', shedName: 'Shed02', shedNumber: 'SH-02'),
        toShed: const TransferShedSummary(id: 's3', shedName: 'Shed03', shedNumber: 'SH-03'),
        reason: 'Medical quarantine',
        transferredBy: const TransferUserSummary(id: 'u2', name: 'Dr. Patel', emailId: 'doctor@test.com'),
        transferDate: DateTime(2026, 9, 28, 14, 30),
      ),
      ShedTransferRecord(
        id: '3',
        cow: const TransferCowSummary(id: 'c3', tagId: 'Tag-303', calfName: 'Nandi', isFemale: false),
        fromShed: const TransferShedSummary(id: 's1', shedName: 'Shed01', shedNumber: 'SH-01'),
        toShed: const TransferShedSummary(id: 's3', shedName: 'Shed03', shedNumber: 'SH-03'),
        reason: 'Routine relocation',
        transferredBy: const TransferUserSummary(id: 'u1', name: 'Ayushka Admin', emailId: 'admin@test.com'),
        transferDate: DateTime(2026, 9, 25, 9, 15),
      ),
    ];

    test('Filters records correctly by Origin Shed (From Shed)', () {
      final fromShed1 = records.where((r) => r.fromShed?.id == 's1').toList();
      expect(fromShed1.length, 2);
      expect(fromShed1.map((r) => r.cow?.tagId), containsAll(['Tag-301', 'Tag-303']));
    });

    test('Filters records correctly by Destination Shed (To Shed)', () {
      final toShed3 = records.where((r) => r.toShed?.id == 's3').toList();
      expect(toShed3.length, 2);
      expect(toShed3.map((r) => r.cow?.tagId), containsAll(['Tag-302', 'Tag-303']));
    });

    test('Filters records correctly by Reason', () {
      final quarantine = records.where((r) => r.reason.toLowerCase().contains('quarantine')).toList();
      expect(quarantine.length, 1);
      expect(quarantine.first.cow?.tagId, 'Tag-302');
    });

    test('Filters records correctly by Staff Member', () {
      final patelTransfers = records.where((r) => r.transferredBy?.id == 'u2').toList();
      expect(patelTransfers.length, 1);
      expect(patelTransfers.first.transferredBy?.name, 'Dr. Patel');
    });

    test('Filters records correctly by Date Range', () {
      final start = DateTime(2026, 9, 27, 0, 0);
      final end = DateTime(2026, 9, 30, 23, 59);

      final dateFiltered = records.where((r) {
        if (r.transferDate == null) return false;
        return !r.transferDate!.isBefore(start) && !r.transferDate!.isAfter(end);
      }).toList();

      expect(dateFiltered.length, 2);
      expect(dateFiltered.map((r) => r.cow?.tagId), containsAll(['Tag-301', 'Tag-302']));
    });

    test('Generates valid CSV formatted content with escaped values', () {
      String escapeCsv(String val) {
        if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
          return '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }

      final buffer = StringBuffer();
      buffer.writeln('#,Date & Time,Tag ID,Calf Name,Gender,Breed,From Shed,To Shed,Reason,Transferred By');

      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        buffer.writeln([
          '${i + 1}',
          escapeCsv(r.transferDate.toString()),
          escapeCsv(r.cow?.tagId ?? ''),
          escapeCsv(r.cow?.calfName ?? ''),
          escapeCsv(r.cow?.isFemale == true ? 'Female' : 'Male'),
          escapeCsv(r.cow?.breedName ?? ''),
          escapeCsv(r.fromShed?.display ?? ''),
          escapeCsv(r.toShed?.display ?? ''),
          escapeCsv(r.reason),
          escapeCsv(r.transferredBy?.name ?? ''),
        ].join(','));
      }

      final csvContent = buffer.toString();
      expect(csvContent, contains('#,Date & Time,Tag ID,Calf Name,Gender,Breed,From Shed,To Shed,Reason,Transferred By'));
      expect(csvContent, contains('Tag-301'));
      expect(csvContent, contains('Moved to milking shed'));
      expect(csvContent, contains('Medical quarantine'));
    });
  });

  group('ShedTransferHistoryDialog Widget Tests', () {
    setUp(() {
      Get.reset();
      Get.put<ApiService>(_FakeApiService());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Renders ShedTransferHistoryDialog with table scrollbars without ScrollPosition assertion error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: ShedTransferHistoryDialog(
              gaushalaId: 'gaushala_1',
              gaushalaName: 'Ayushka Gaushala',
            ),
          ),
        ),
      );

      // Pump to allow API response and setState to rebuild
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header and table contents rendered
      expect(find.text('Shed Transfer History'), findsOneWidget);
      expect(find.text('GAUSHALA AUDIT'), findsOneWidget);
      expect(find.text('TAG-101'), findsOneWidget);
      expect(find.text('Moved to milking shed'), findsOneWidget);

      // Verify no Scrollbar / ScrollPosition exceptions during frame draw
      expect(tester.takeException(), isNull);
    });
  });
}
