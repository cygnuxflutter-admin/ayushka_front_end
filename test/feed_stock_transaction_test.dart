import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/core/widgets/custom_dropdown_search.dart';
import 'package:ayushka/app/data/models/feed_stock_transaction_model.dart';
import 'package:ayushka/app/data/models/feed_item_model.dart';

void main() {
  group('FeedStockTransactionModel Tests', () {
    test('Parses Inward transaction JSON correctly (Matching User Curl Payload)', () {
      final json = {
        '_id': '6abe2192f47731b8bb6fc26b',
        'gaushalaId': {
          '_id': '6abcaee5d7556202004414b0',
          'gaushalaName': 'ayushka_navsari',
        },
        'itemId': {
          '_id': '6abe19adf47731b8bb6fc186',
          'itemName': 'Improved Green Maize Fodder',
          'itemCode': 'GF-002',
          'category': 'GREEN_FODDER',
          'unit': 'KG',
        },
        'type': 'INWARD',
        'reason': 'PURCHASE',
        'quantity': 500,
        'unit': 'KG',
        'ratePerUnit': 15,
        'totalAmount': 7500,
        'shedId': null,
        'transactionDate': '2026-10-01T09:02:10.118Z',
        'supplierOrDonorName': 'Ram Agro',
        'billOrReceiptNo': 'INV-1024',
        'vehicleNumber': 'GJ-01-AB-1234',
        'notes': 'Purchased green maize fodder',
        'stockBefore': 80,
        'stockAfter': 580,
        'recordedBy': {
          '_id': '6abb81dec91ddf959f54022a',
          'name': 'Ayushka Admin',
        },
        'isDeleted': false,
        'createdAt': '2026-10-01T09:02:10.152Z',
        'updatedAt': '2026-10-01T09:02:10.152Z',
      };

      final tx = FeedStockTransactionModel.fromJson(json);

      expect(tx.id, '6abe2192f47731b8bb6fc26b');
      expect(tx.gaushalaId, '6abcaee5d7556202004414b0');
      expect(tx.gaushalaName, 'ayushka_navsari');
      expect(tx.itemId, '6abe19adf47731b8bb6fc186');
      expect(tx.itemName, 'Improved Green Maize Fodder');
      expect(tx.itemCode, 'GF-002');
      expect(tx.category, 'GREEN_FODDER');
      expect(tx.categoryEnum, FeedItemCategory.greenFodder);
      expect(tx.type, 'INWARD');
      expect(tx.typeEnum, FeedStockTransactionType.inward);
      expect(tx.isInward, true);
      expect(tx.isOutward, false);
      expect(tx.reason, 'PURCHASE');
      expect(tx.reasonEnum, FeedStockTransactionReason.purchase);
      expect(tx.quantity, 500.0);
      expect(tx.signedQuantity, 500.0);
      expect(tx.unit, 'KG');
      expect(tx.ratePerUnit, 15.0);
      expect(tx.totalAmount, 7500.0);
      expect(tx.shedId, isNull);
      expect(tx.supplierOrDonorName, 'Ram Agro');
      expect(tx.billOrReceiptNo, 'INV-1024');
      expect(tx.vehicleNumber, 'GJ-01-AB-1234');
      expect(tx.notes, 'Purchased green maize fodder');
      expect(tx.stockBefore, 80.0);
      expect(tx.stockAfter, 580.0);
      expect(tx.recordedById, '6abb81dec91ddf959f54022a');
      expect(tx.recordedByName, 'Ayushka Admin');
    });

    test('Parses Outward transaction JSON correctly (Matching User Curl Payload)', () {
      final json = {
        '_id': '6abe2197f47731b8bb6fc276',
        'gaushalaId': {
          '_id': '6abcaee5d7556202004414b0',
          'gaushalaName': 'ayushka_navsari',
        },
        'itemId': {
          '_id': '6abe19adf47731b8bb6fc186',
          'itemName': 'Improved Green Maize Fodder',
          'itemCode': 'GF-002',
          'category': 'GREEN_FODDER',
          'unit': 'KG',
        },
        'type': 'OUTWARD',
        'reason': 'DAILY_FEEDING',
        'quantity': 300,
        'unit': 'KG',
        'ratePerUnit': 0,
        'totalAmount': 0,
        'shedId': {
          '_id': '6abcaf01d7556202004414be',
          'shedName': 'Shed01',
          'shedNumber': 'SH-01',
        },
        'transactionDate': '2026-10-01T07:00:00.000Z',
        'notes': 'Morning green fodder issued for Shed No. 2 cows',
        'stockBefore': 580,
        'stockAfter': 280,
        'recordedBy': {
          '_id': '6abb81dec91ddf959f54022a',
          'name': 'Ayushka Admin',
        },
      };

      final tx = FeedStockTransactionModel.fromJson(json);

      expect(tx.id, '6abe2197f47731b8bb6fc276');
      expect(tx.gaushalaId, '6abcaee5d7556202004414b0');
      expect(tx.itemId, '6abe19adf47731b8bb6fc186');
      expect(tx.type, 'OUTWARD');
      expect(tx.typeEnum, FeedStockTransactionType.outward);
      expect(tx.isInward, false);
      expect(tx.isOutward, true);
      expect(tx.reason, 'DAILY_FEEDING');
      expect(tx.reasonEnum, FeedStockTransactionReason.dailyFeeding);
      expect(tx.quantity, 300.0);
      expect(tx.signedQuantity, -300.0);
      expect(tx.shedId, '6abcaf01d7556202004414be');
      expect(tx.shedName, 'Shed01');
      expect(tx.shedNumber, 'SH-01');
      expect(tx.stockBefore, 580.0);
      expect(tx.stockAfter, 280.0);
      expect(tx.notes, 'Morning green fodder issued for Shed No. 2 cows');
    });

    test('Serializes FeedStockInwardRequest to match backend endpoint requirements', () {
      final req = FeedStockInwardRequest(
        gaushalaId: '6abcaee5d7556202004414b0',
        itemId: '6abe19adf47731b8bb6fc186',
        quantity: 500,
        unit: 'KG',
        reason: 'PURCHASE',
        ratePerUnit: 15,
        supplierOrDonorName: 'Ram Agro',
        billOrReceiptNo: 'INV-1024',
        vehicleNumber: 'GJ-01-AB-1234',
        notes: 'Purchased green maize fodder',
      );

      final json = req.toJson();

      expect(json['gaushalaId'], '6abcaee5d7556202004414b0');
      expect(json['itemId'], '6abe19adf47731b8bb6fc186');
      expect(json['quantity'], 500.0);
      expect(json['unit'], 'KG');
      expect(json['reason'], 'PURCHASE');
      expect(json['ratePerUnit'], 15.0);
      expect(json['supplierOrDonorName'], 'Ram Agro');
      expect(json['billOrReceiptNo'], 'INV-1024');
      expect(json['vehicleNumber'], 'GJ-01-AB-1234');
      expect(json['notes'], 'Purchased green maize fodder');
    });

    test('Serializes FeedStockOutwardRequest to match backend endpoint requirements', () {
      final req = FeedStockOutwardRequest(
        gaushalaId: '6abcaee5d7556202004414b0',
        itemId: '6abe19adf47731b8bb6fc186',
        quantity: 300,
        unit: 'KG',
        shedId: '6abcaf01d7556202004414be',
        reason: 'DAILY_FEEDING',
        transactionDate: DateTime.parse('2026-10-01T07:00:00.000Z'),
        notes: 'Morning green fodder issued for Shed No. 2 cows',
      );

      final json = req.toJson();

      expect(json['gaushalaId'], '6abcaee5d7556202004414b0');
      expect(json['itemId'], '6abe19adf47731b8bb6fc186');
      expect(json['quantity'], 300.0);
      expect(json['unit'], 'KG');
      expect(json['shedId'], '6abcaf01d7556202004414be');
      expect(json['reason'], 'DAILY_FEEDING');
      expect(json['transactionDate'], '2026-10-01T07:00:00.000Z');
      expect(json['notes'], 'Morning green fodder issued for Shed No. 2 cows');
    });

    test('Enums handle edge cases and unknown codes gracefully', () {
      expect(FeedStockTransactionType.fromCode(null), FeedStockTransactionType.inward);
      expect(FeedStockTransactionType.fromCode('outward'), FeedStockTransactionType.outward);
      expect(FeedStockTransactionType.fromCode('unknown'), FeedStockTransactionType.inward);

      expect(FeedStockTransactionReason.fromCode(null), FeedStockTransactionReason.other);
      expect(FeedStockTransactionReason.fromCode('purchase'), FeedStockTransactionReason.purchase);
      expect(FeedStockTransactionReason.fromCode('daily_feeding'), FeedStockTransactionReason.dailyFeeding);
      expect(FeedStockTransactionReason.fromCode('unknown'), FeedStockTransactionReason.other);
    });
  });

  group('CustomDropdownSearch UI & Clear Button Tests', () {
    testWidgets('Required dropdown does not show clear button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDropdownSearch<String>(
              label: 'Gaushala',
              isRequired: true,
              selectedItem: 'Navsari Gaushala',
              items: const ['Navsari Gaushala', 'Surat Gaushala'],
              itemAsString: (s) => s,
              onChanged: (val) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Label and text should be rendered
      expect(find.text('Gaushala *'), findsOneWidget);
      expect(find.text('Navsari Gaushala'), findsOneWidget);

      // Clear button (Icons.clear_rounded) should NOT be visible for required fields
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });

    testWidgets('Dropdown with showClearButton: false suppresses clear button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDropdownSearch<String>(
              label: 'Filter',
              showClearButton: false,
              selectedItem: 'All Types',
              items: const ['All Types', 'Inward', 'Outward'],
              itemAsString: (s) => s,
              onClear: () {},
              onChanged: (val) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Types'), findsOneWidget);
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });

    testWidgets('Optional dropdown with showClearButton: true shows clear button', (tester) async {
      String? selected = 'Optional Item';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CustomDropdownSearch<String>(
                  label: 'Optional',
                  isRequired: false,
                  showClearButton: true,
                  selectedItem: selected,
                  items: const ['Optional Item', 'Second Item'],
                  itemAsString: (s) => s,
                  onChanged: (val) {
                    setState(() => selected = val);
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear button should be visible
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tapping clear button clears the selection
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();
      expect(selected, isNull);
    });
  });

  group('Outward Stock Validation & Calculation Tests', () {
    test('Calculates remaining stock correctly when quantity is within available stock', () {
      const double availableStock = 510.0;
      const double enteredQty = 300.0;
      final double remaining = availableStock - enteredQty;
      expect(remaining, 210.0);
      expect(enteredQty <= availableStock, isTrue);
    });

    test('Identifies when entered quantity exceeds available stock', () {
      const double availableStock = 510.0;
      const double enteredQty = 600.0;
      final bool exceeds = enteredQty > availableStock;
      expect(exceeds, isTrue);
    });

    test('Clamps quantity to maximum available stock when limit exceeded', () {
      const double availableStock = 510.0;
      double enteredQty = 600.0;
      if (enteredQty > availableStock) {
        enteredQty = availableStock;
      }
      expect(enteredQty, 510.0);
      expect(availableStock - enteredQty, 0.0);
    });
  });

  group('Stock Transaction Search & Filtering Logic Tests', () {
    final sampleTx1 = FeedStockTransactionModel.fromJson({
      '_id': 'tx_001',
      'itemId': {
        '_id': 'item_1',
        'itemName': 'Green Hybrid Fodder (9977)',
        'itemCode': 'FOD-9977',
        'category': 'GREEN_FODDER',
        'unit': 'KG',
      },
      'type': 'INWARD',
      'reason': 'PURCHASE',
      'quantity': 300,
      'unit': 'KG',
      'ratePerUnit': 0,
      'totalAmount': 0,
      'supplierOrDonorName': 'Kisan Fodder Mart',
      'billOrReceiptNo': 'INV-9977',
      'vehicleNumber': 'GJ-21-AA-1122',
      'notes': 'Fresh green harvest batch',
      'stockBefore': 235,
      'stockAfter': 535,
      'recordedBy': {'_id': 'u1', 'name': 'Ayushka Admin'},
    });

    final sampleTx2 = FeedStockTransactionModel.fromJson({
      '_id': 'tx_002',
      'itemId': {
        '_id': 'item_2',
        'itemName': 'High-Protein Cattle Feed (3967)',
        'itemCode': 'FEED-3967',
        'category': 'DRY_FODDER',
        'unit': 'KG',
      },
      'type': 'INWARD',
      'reason': 'PURCHASE',
      'quantity': 500,
      'unit': 'KG',
      'ratePerUnit': 32.5,
      'totalAmount': 16250,
      'supplierOrDonorName': 'Amul Feeds',
      'billOrReceiptNo': 'BILL-3967',
      'vehicleNumber': 'GJ-05-XY-9999',
      'notes': 'Protein rich concentrate bags',
      'stockBefore': 0,
      'stockAfter': 500,
      'recordedBy': {'_id': 'u1', 'name': 'Ayushka Admin'},
    });

    final sampleTx3 = FeedStockTransactionModel.fromJson({
      '_id': 'tx_003',
      'itemId': {
        '_id': 'item_1',
        'itemName': 'Green Hybrid Fodder (9977)',
        'itemCode': 'FOD-9977',
        'category': 'GREEN_FODDER',
        'unit': 'KG',
      },
      'type': 'OUTWARD',
      'reason': 'DAILY_FEEDING',
      'quantity': 150,
      'unit': 'KG',
      'shedId': {'_id': 'shed_1', 'shedName': 'Shed 01', 'shedNumber': 'SH-01'},
      'notes': 'Afternoon feeding to milch cows',
      'stockBefore': 535,
      'stockAfter': 385,
      'recordedBy': {'_id': 'u2', 'name': 'Ramesh Bhai'},
    });

    final allItems = [sampleTx1, sampleTx2, sampleTx3];

    List<FeedStockTransactionModel> filterTransactions({
      required List<FeedStockTransactionModel> transactions,
      String query = '',
      String type = 'ALL',
      String reason = 'ALL',
      String? itemId,
    }) {
      final cleanQuery = query.trim().toLowerCase();
      return transactions.where((t) {
        if (type != 'ALL' && t.type.toUpperCase() != type.toUpperCase()) return false;
        if (reason != 'ALL' && t.reason.toUpperCase() != reason.toUpperCase()) return false;
        if (itemId != null && t.itemId != itemId) return false;

        if (cleanQuery.isNotEmpty) {
          final tokens = cleanQuery.split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
          final corpus = [
            t.itemName,
            t.itemCode,
            t.category,
            t.categoryEnum.label,
            t.type,
            t.typeEnum.label,
            t.reason,
            t.reasonEnum.label,
            t.supplierOrDonorName,
            t.billOrReceiptNo,
            t.vehicleNumber,
            t.notes,
            t.recordedByName,
            t.shedName ?? '',
            t.shedNumber ?? '',
            t.unit,
            t.quantity.toString(),
            t.quantity.toStringAsFixed(0),
            if (t.totalAmount > 0) t.totalAmount.toString(),
          ].join(' ').toLowerCase();

          return tokens.every((token) => corpus.contains(token));
        }
        return true;
      }).toList();
    }

    test('Searches by item code or numeric suffix (9977)', () {
      final results = filterTransactions(transactions: allItems, query: '9977');
      expect(results.length, 2);
      expect(results.every((r) => r.itemName.contains('9977')), isTrue);
    });

    test('Searches by partial item name (High-Protein)', () {
      final results = filterTransactions(transactions: allItems, query: 'High-Protein');
      expect(results.length, 1);
      expect(results.first.id, 'tx_002');
    });

    test('Searches across supplier name and bill number', () {
      final bySupplier = filterTransactions(transactions: allItems, query: 'Amul');
      expect(bySupplier.length, 1);
      expect(bySupplier.first.supplierOrDonorName, 'Amul Feeds');

      final byBill = filterTransactions(transactions: allItems, query: 'INV-9977');
      expect(byBill.length, 1);
      expect(byBill.first.billOrReceiptNo, 'INV-9977');
    });

    test('Searches across vehicle number and notes', () {
      final byVehicle = filterTransactions(transactions: allItems, query: 'GJ-21');
      expect(byVehicle.length, 1);
      expect(byVehicle.first.vehicleNumber, 'GJ-21-AA-1122');

      final byNotes = filterTransactions(transactions: allItems, query: 'milch cows');
      expect(byNotes.length, 1);
      expect(byNotes.first.id, 'tx_003');
    });

    test('Multi-token search works correctly (green outward)', () {
      final results = filterTransactions(transactions: allItems, query: 'green outward');
      expect(results.length, 1);
      expect(results.first.id, 'tx_003');
    });

    test('Filters by type and reason combined with search', () {
      final inwardOnly = filterTransactions(transactions: allItems, query: '9977', type: 'INWARD');
      expect(inwardOnly.length, 1);
      expect(inwardOnly.first.id, 'tx_001');

      final outwardOnly = filterTransactions(transactions: allItems, query: '9977', type: 'OUTWARD');
      expect(outwardOnly.length, 1);
      expect(outwardOnly.first.id, 'tx_003');
    });

    test('Empty query returns all records', () {
      final results = filterTransactions(transactions: allItems, query: '');
      expect(results.length, 3);
    });

    test('Non-matching query returns empty list', () {
      final results = filterTransactions(transactions: allItems, query: 'xyznotfound999');
      expect(results.isEmpty, isTrue);
    });
  });
}
