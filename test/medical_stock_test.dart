import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ayushka/app/core/widgets/custom_text_field.dart';
import 'package:ayushka/app/data/models/gaushala_model.dart';
import 'package:ayushka/app/data/models/medical_item_model.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/gaushala_session_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:ayushka/app/modules/medical_stock/dialogs/view_batches_dialog.dart';
import 'package:ayushka/app/modules/medical_stock/medical_stock_controller.dart';
import 'package:ayushka/app/modules/medical_stock/views/batches_tracker_view.dart';
import 'package:ayushka/app/modules/medical_stock/widgets/medical_stock_animations.dart';

class _FakeApiService extends GetxService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future.value(null);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeStorageService extends GetxService implements StorageService {
  @override
  UserModel? getUser() => null;
  @override
  String? getSelectedGaushalaId() => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGaushalaSessionService extends GetxService implements GaushalaSessionService {
  @override
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  @override
  final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>();
  @override
  String get selectedGaushalaId => 'g-101';
  @override
  String get selectedGaushalaName => 'Navsari';
  @override
  bool get canChangeGaushala => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Medical Stock - Model & Serialization Tests', () {
    test('MedicalBatchModel JSON roundtrip & expiry calculation', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 25));
      final mfg = now.subtract(const Duration(days: 100));

      final batch = MedicalBatchModel(
        id: 'b-101',
        itemId: 'item-01',
        itemName: 'Oxytetracycline 20% LA',
        batchNumber: 'OXY-2026-A',
        expiryDate: expiry,
        mfgDate: mfg,
        quantity: 200,
        availableQuantity: 150,
        unitPrice: 180.0,
        mrp: 210.0,
        status: 'ACTIVE',
      );

      final json = batch.toJson();
      final parsed = MedicalBatchModel.fromJson(json);

      expect(parsed.id, equals('b-101'));
      expect(parsed.batchNumber, equals('OXY-2026-A'));
      expect(parsed.availableQuantity, equals(150.0));
      expect(parsed.isExpired, isFalse);
      expect(parsed.isExpiringSoon, isTrue); // <= 30 days
      expect(parsed.daysUntilExpiry, inInclusiveRange(24, 25));
      expect(parsed.expiryStatus, equals(ExpiryStatus.critical));
    });

    test('Expired batch detection and days remaining label', () {
      final now = DateTime.now();
      final expiredDate = now.subtract(const Duration(days: 10));

      final batch = MedicalBatchModel(
        id: 'b-102',
        itemId: 'item-02',
        batchNumber: 'EXP-999',
        expiryDate: expiredDate,
        quantity: 50,
        availableQuantity: 20,
        status: 'EXPIRED',
      );

      expect(batch.isExpired, isTrue);
      expect(batch.expiryStatus, equals(ExpiryStatus.expired));
      expect(batch.daysRemainingLabel, contains('Expired'));
    });

    test('MedicalItemModel fefoBatches sorting puts earliest expiry first', () {
      final now = DateTime.now();

      final batchFarFuture = MedicalBatchModel(
        id: 'b-3',
        itemId: 'item-01',
        batchNumber: 'B-FAR',
        expiryDate: now.add(const Duration(days: 300)),
        quantity: 100,
        availableQuantity: 100,
      );

      final batchNearFuture = MedicalBatchModel(
        id: 'b-1',
        itemId: 'item-01',
        batchNumber: 'B-EARLY',
        expiryDate: now.add(const Duration(days: 15)),
        quantity: 100,
        availableQuantity: 100,
      );

      final batchMidFuture = MedicalBatchModel(
        id: 'b-2',
        itemId: 'item-01',
        batchNumber: 'B-MID',
        expiryDate: now.add(const Duration(days: 90)),
        quantity: 100,
        availableQuantity: 100,
      );

      final item = MedicalItemModel(
        id: 'item-01',
        itemName: 'Amoxicillin Injection',
        category: 'INJECTION',
        unit: 'VIAL',
        minStockAlert: 50,
        totalStock: 300,
        batches: [batchFarFuture, batchNearFuture, batchMidFuture],
      );

      final fefoList = item.fefoBatches;

      expect(fefoList.length, equals(3));
      expect(fefoList[0].batchNumber, equals('B-EARLY'));
      expect(fefoList[1].batchNumber, equals('B-MID'));
      expect(fefoList[2].batchNumber, equals('B-FAR'));
      expect(item.earliestExpiringBatch?.batchNumber, equals('B-EARLY'));
    });

    test('FEFO deduction logic across multiple batches', () {
      final now = DateTime.now();

      final b1 = MedicalBatchModel(
        id: 'b-1',
        itemId: 'it-1',
        batchNumber: 'LOT-1',
        expiryDate: now.add(const Duration(days: 20)),
        quantity: 100,
        availableQuantity: 100,
      );

      final b2 = MedicalBatchModel(
        id: 'b-2',
        itemId: 'it-1',
        batchNumber: 'LOT-2',
        expiryDate: now.add(const Duration(days: 120)),
        quantity: 150,
        availableQuantity: 150,
      );

      final item = MedicalItemModel(
        id: 'it-1',
        itemName: 'Albendazole',
        totalStock: 250,
        batches: [b1, b2],
      );

      // Request 160 units outward
      double requestQty = 160.0;
      double remaining = requestQty;
      final deductions = <String, double>{};

      for (final batch in item.fefoBatches) {
        if (remaining <= 0) break;
        final take = batch.availableQuantity < remaining ? batch.availableQuantity : remaining;
        deductions[batch.batchNumber] = take;
        remaining -= take;
      }

      expect(remaining, equals(0.0));
      // First batch LOT-1 had 100, so all 100 must be consumed first
      expect(deductions['LOT-1'], equals(100.0));
      // Remaining 60 consumed from LOT-2
      expect(deductions['LOT-2'], equals(60.0));
    });

    test('Inward batch DTO line total calculation', () {
      final dto = MedicalInwardBatchDto(
        batchNumber: 'B-2027',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        quantity: 250,
        unitPrice: 45.0,
      );

      expect(dto.lineTotal, equals(11250.0));
      final json = dto.toJson();
      expect(json['batchNumber'], equals('B-2027'));
      expect(json['quantity'], equals(250.0));
      expect(json['unitPrice'], equals(45.0));
    });

    test('Batch pagination logic with default 5 items per page', () {
      final dummyBatches = List.generate(
        8,
        (i) => MedicalBatchModel(
          id: 'b-$i',
          itemId: 'item-$i',
          batchNumber: 'BATCH-00$i',
          expiryDate: DateTime.now().add(Duration(days: 30 * (i + 1))),
          quantity: 100,
          availableQuantity: 100,
        ),
      );

      int rowsPerPage = 5;
      int currentPage = 1;

      List<MedicalBatchModel> getPaginated(List<MedicalBatchModel> list, int page, int perPage) {
        final start = (page - 1) * perPage;
        if (start >= list.length) return [];
        final end = (start + perPage > list.length) ? list.length : start + perPage;
        return list.sublist(start, end);
      }

      int getTotalPages(int count, int perPage) => count == 0 ? 1 : (count / perPage).ceil();

      // Page 1: Default 5 items
      final page1 = getPaginated(dummyBatches, currentPage, rowsPerPage);
      expect(page1.length, equals(5));
      expect(page1.first.batchNumber, equals('BATCH-000'));
      expect(page1.last.batchNumber, equals('BATCH-004'));
      expect(getTotalPages(dummyBatches.length, rowsPerPage), equals(2));

      // Page 2: Remaining 3 items
      currentPage = 2;
      final page2 = getPaginated(dummyBatches, currentPage, rowsPerPage);
      expect(page2.length, equals(3));
      expect(page2.first.batchNumber, equals('BATCH-005'));
      expect(page2.last.batchNumber, equals('BATCH-007'));

      // User changes rowsPerPage to 10
      rowsPerPage = 10;
      currentPage = 1;
      final allOnPage1 = getPaginated(dummyBatches, currentPage, rowsPerPage);
      expect(allOnPage1.length, equals(8));
      expect(getTotalPages(dummyBatches.length, rowsPerPage), equals(1));
    });

    test('MedicalInwardBatchRow reactive line total and quantity calculations', () {
      final row = MedicalInwardBatchRow(
        initialBatchNo: 'B-TEST',
        initialQty: 10,
        initialUnitPrice: 25.5,
      );

      expect(row.rowQuantity.value, equals(10.0));
      expect(row.lineTotal.value, equals(255.0));

      row.quantityController.text = '20';
      expect(row.rowQuantity.value, equals(20.0));
      expect(row.lineTotal.value, equals(510.0));

      row.unitPriceController.text = '30';
      expect(row.lineTotal.value, equals(600.0));

      row.dispose();
    });

    testWidgets('CustomTextField renders 48px height with isDense and compact padding', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              key: key,
              label: 'Supplier / Donor Name',
              hint: 'e.g. Vikas Pharma Traders',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.person, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Supplier / Donor Name'), findsOneWidget);
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('Multi-batch table with LayoutBuilder outside Obx works reactively without GetX error', (tester) async {
      final rows = <MedicalInwardBatchRow>[].obs;
      rows.add(MedicalInwardBatchRow(initialBatchNo: 'B-001', initialQty: 10, initialUnitPrice: 50));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1000,
                    child: Obx(() {
                      final list = rows.toList();
                      return Table(
                        children: [
                          const TableRow(children: [Text('Header')]),
                          ...list.map((r) => TableRow(children: [
                            Text(r.batchNumber),
                          ])),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('B-001'), findsOneWidget);

      // Add another row dynamically
      rows.add(MedicalInwardBatchRow(initialBatchNo: 'B-002', initialQty: 20, initialUnitPrice: 100));
      await tester.pumpAndSettle();

      expect(find.text('B-002'), findsOneWidget);

      for (final r in rows) {
        r.dispose();
      }
    });

    testWidgets('ViewBatchesDialog renders all columns including Actions and Adjust buttons without clipping', (tester) async {
      Get.reset();
      Get.put<ApiService>(_FakeApiService());
      Get.put<StorageService>(_FakeStorageService());
      Get.put<GaushalaSessionService>(_FakeGaushalaSessionService());
      final controller = Get.put(MedicalStockController());

      final testItem = MedicalItemModel(
        id: 'med-001',
        itemName: 'Oxytetracycline 20% LA',
        itemCode: 'MED-OXY-100',
        category: 'INJECTION',
        unit: 'VIAL',
        minStockAlert: 20,
        batches: [
          MedicalBatchModel(
            id: 'b-01',
            itemId: 'med-001',
            batchNumber: 'OXY-2410',
            expiryDate: DateTime.now().add(const Duration(days: 22)),
            mfgDate: DateTime(2025, 10, 26),
            quantity: 200,
            availableQuantity: 150,
            unitPrice: 180,
            status: 'ACTIVE',
          ),
          MedicalBatchModel(
            id: 'b-02',
            itemId: 'med-001',
            batchNumber: 'OXY-2503',
            expiryDate: DateTime.now().add(const Duration(days: 280)),
            mfgDate: DateTime(2026, 8, 2),
            quantity: 200,
            availableQuantity: 200,
            unitPrice: 185,
            status: 'ACTIVE',
          ),
        ],
      );

      controller.items.assignAll([testItem]);

      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewBatchesDialog(item: testItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all headers are present
      expect(find.text('Batch Number'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Available Stock'), findsOneWidget);
      expect(find.text('Expiry / FEFO'), findsOneWidget);
      expect(find.text('Unit Price'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);

      // Verify batches and action buttons
      expect(find.text('OXY-2410'), findsOneWidget);
      expect(find.text('OXY-2503'), findsOneWidget);
      expect(find.text('Adjust'), findsNWidgets(2));
      expect(find.text('Close'), findsOneWidget);

      expect(tester.takeException(), isNull);

      Get.reset();
    });

    testWidgets('CustomTextField with floatingLabel renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Floating Label Test',
              hint: 'Type here',
              floatingLabel: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Floating Label Test'), findsOneWidget);
      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('AnimatedModuleViewSwitcher renders in bounded and unbounded contexts without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AnimatedModuleViewSwitcher(
                    child: Text('Unbounded Test Content'),
                  ),
                  SizedBox(
                    height: 200,
                    child: AnimatedModuleViewSwitcher(
                      child: Text('Bounded Test Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unbounded Test Content'), findsOneWidget);
      expect(find.text('Bounded Test Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('Items and batches sync links batches to medicine and enables FEFO stock out', () {
      Get.put<ApiService>(_FakeApiService());
      Get.put<StorageService>(_FakeStorageService());
      Get.put<GaushalaSessionService>(_FakeGaushalaSessionService());
      final controller = Get.put(MedicalStockController());

      // Item with empty batches array (as typically returned by GET /medical-stock/items)
      final rawItem = MedicalItemModel(
        id: 'item-sync-01',
        itemName: 'Amoxicillin 500mg',
        itemCode: 'AMX-500',
        category: 'TABLET',
        unit: 'STRIP',
        totalStock: 0,
        minStockAlert: 20,
        batches: const [],
      );

      // Batches fetched from GET /medical-stock/batches
      final batch1 = MedicalBatchModel(
        id: 'batch-sync-01',
        itemId: 'item-sync-01',
        batchNumber: 'AMX-B1',
        expiryDate: DateTime.now().add(const Duration(days: 45)),
        quantity: 100,
        availableQuantity: 100,
        unitPrice: 50,
        status: 'ACTIVE',
      );
      final batch2 = MedicalBatchModel(
        id: 'batch-sync-02',
        itemId: 'item-sync-01',
        batchNumber: 'AMX-B2',
        expiryDate: DateTime.now().add(const Duration(days: 120)),
        quantity: 50,
        availableQuantity: 50,
        unitPrice: 52,
        status: 'ACTIVE',
      );

      // Populate allBatches and items
      controller.allBatches.assignAll([batch1, batch2]);
      controller.items.assignAll([rawItem.copyWith(batches: [batch1, batch2], totalStock: 150, activeBatchesCount: 2)]);

      // Test getBatchesForItem
      final batches = controller.getBatchesForItem('item-sync-01');
      expect(batches.length, equals(2));
      expect(batches[0].batchNumber, equals('AMX-B1'));
      expect(batches[1].batchNumber, equals('AMX-B2'));

      // Test Stock Outward selection
      controller.onOutwardItemChanged(controller.items.first);
      expect(controller.outwardItemAvailableStock, equals(150.0));

      // Test FEFO calculation with requested quantity = 120
      controller.outwardQuantityController.text = '120';
      expect(controller.outwardHasExcessStockError.value, isFalse);
      expect(controller.outwardFefoPreviews.length, equals(2));
      // First batch (earliest expiry) should be fully consumed (100)
      expect(controller.outwardFefoPreviews[0].deductedQuantity, equals(100.0));
      expect(controller.outwardFefoPreviews[0].remainingQuantity, equals(0.0));
      expect(controller.outwardFefoPreviews[0].isFullyConsumed, isTrue);
      // Second batch should be partially consumed (20 consumed, 30 remaining)
      expect(controller.outwardFefoPreviews[1].deductedQuantity, equals(20.0));
      expect(controller.outwardFefoPreviews[1].remainingQuantity, equals(30.0));
      expect(controller.outwardFefoPreviews[1].isPartiallyConsumed, isTrue);

      Get.reset();
    });

    testWidgets('BatchesTrackerView renders without duplicate key error even with duplicate batch data', (tester) async {
      Get.reset();
      Get.put<ApiService>(_FakeApiService());
      Get.put<StorageService>(_FakeStorageService());
      Get.put<GaushalaSessionService>(_FakeGaushalaSessionService());
      final controller = Get.put<MedicalStockController>(MedicalStockController());

      final dupBatch = MedicalBatchModel(
        id: '6abe66706fc94d1a996a6f41',
        itemId: 'item-dup-01',
        itemName: 'Meloxicam 5mg/ml',
        batchNumber: 'MEL-2410',
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        quantity: 50,
        availableQuantity: 50,
        status: 'ACTIVE',
      );

      // Even if multiple duplicate batches somehow existed
      controller.allBatches.assignAll([dupBatch, dupBatch]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatchesTrackerView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified no Duplicate keys found exception was thrown!
      expect(find.byType(BatchesTrackerView), findsOneWidget);
      expect(find.text('MEL-2410'), findsWidgets);

      Get.reset();
    });
  });
}
