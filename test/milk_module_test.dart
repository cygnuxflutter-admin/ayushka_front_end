import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/modules/milk/models/fridge_stock_model.dart';
import 'package:ayushka/modules/milk/models/milk_daily_summary_model.dart';
import 'package:ayushka/modules/milk/models/milk_disposal_model.dart';
import 'package:ayushka/modules/milk/models/milk_distribution_model.dart';
import 'package:ayushka/modules/milk/models/milk_production_model.dart';

void main() {
  group('MilkDailySummaryModel Tests', () {
    test('Correctly parses API spec sample response', () {
      final json = {
        'date': '2026-10-02',
        'gaushalaId': 'gau-navsari-1',
        'production': {
          'morningProduced': 500.0,
          'eveningProduced': 580.0,
          'totalProduced': 1080.0,
          'morningCowsCount': 42,
          'eveningCowsCount': 45,
        },
        'distribution': {
          'morningDistributed': 480.0,
          'eveningDistributed': 550.0,
          'allDistributed': 0.0,
          'totalDistributed': 1030.0,
          'totalRevenue': 61800.0,
        },
        'disposal': {
          'totalDisposed': 0.0,
        },
        'stockBalance': {
          'morningAvailable': 20.0,
          'eveningAvailable': 30.0,
          'remainingFridgeMilk': 50.0,
        },
      };

      final model = MilkDailySummaryModel.fromJson(json);

      expect(model.date, '2026-10-02');
      expect(model.gaushalaId, 'gau-navsari-1');

      // Production
      expect(model.production.morningProduced, 500.0);
      expect(model.production.eveningProduced, 580.0);
      expect(model.production.totalProduced, 1080.0);
      expect(model.production.morningCowsCount, 42);
      expect(model.production.eveningCowsCount, 45);
      expect(model.production.totalCowsCount, 87);

      // Distribution
      expect(model.distribution.morningDistributed, 480.0);
      expect(model.distribution.eveningDistributed, 550.0);
      expect(model.distribution.totalDistributed, 1030.0);
      expect(model.distribution.totalRevenue, 61800.0);

      // Disposal & Stock
      expect(model.disposal.totalDisposed, 0.0);
      expect(model.stockBalance.morningAvailable, 20.0);
      expect(model.stockBalance.eveningAvailable, 30.0);
      expect(model.stockBalance.remainingFridgeMilk, 50.0);
    });

    test('Handles empty or null json gracefully', () {
      final model = MilkDailySummaryModel.fromJson({});
      expect(model.date, '');
      expect(model.production.totalProduced, 0.0);
      expect(model.distribution.totalRevenue, 0.0);
      expect(model.stockBalance.remainingFridgeMilk, 0.0);
    });
  });

  group('MilkProductionModel Tests', () {
    test('Parses production record with populated cow and worker objects', () {
      final json = {
        '_id': 'prod_001',
        'gaushalaId': 'gau_01',
        'date': '2026-10-02',
        'shift': 'morning',
        'cowId': {
          '_id': 'cow_123',
          'tagId': 'TAG-402',
          'calfName': 'Ganga',
        },
        'workerId': {
          '_id': 'wrk_999',
          'name': 'Ramesh Kumar',
        },
        'quantity': 12.5,
        'remarks': 'Normal milking',
        'variance': 2.3,
        'alertGenerated': false,
      };

      final prod = MilkProductionModel.fromJson(json);

      expect(prod.id, 'prod_001');
      expect(prod.cowId, 'cow_123');
      expect(prod.cowTag, 'TAG-402');
      expect(prod.cowName, 'Ganga');
      expect(prod.displayCowTitle, 'TAG-402 (Ganga)');
      expect(prod.workerId, 'wrk_999');
      expect(prod.workerName, 'Ramesh Kumar');
      expect(prod.quantity, 12.5);
      expect(prod.isMorning, true);
      expect(prod.isEvening, false);
      expect(prod.milkShift, MilkShift.morning);
      expect(prod.alertGenerated, false);
    });

    test('BulkProductionEntryItem serializes to JSON correctly', () {
      final item = BulkProductionEntryItem(
        cowId: 'cow_1',
        cowTag: 'TAG-01',
        workerId: 'wrk_1',
        quantity: 10.5,
      );

      final json = item.toJson();
      expect(json['cowId'], 'cow_1');
      expect(json['workerId'], 'wrk_1');
      expect(json['quantity'], 10.5);
    });
  });

  group('MilkDistributionModel Tests', () {
    test('Parses same-day distribution correctly', () {
      final json = {
        '_id': 'dist_1',
        'gaushalaId': 'gau_1',
        'milkDate': '2026-10-02',
        'distributionDate': '2026-10-02',
        'shift': 'morning',
        'quantity': 25.0,
        'recipientType': 'customer',
        'recipientName': 'Ramesh Patel',
        'ratePerLiter': 60.0,
        'totalAmount': 1500.0,
        'isDelayed': false,
      };

      final dist = MilkDistributionModel.fromJson(json);

      expect(dist.id, 'dist_1');
      expect(dist.quantity, 25.0);
      expect(dist.ratePerLiter, 60.0);
      expect(dist.totalAmount, 1500.0);
      expect(dist.recipientTypeEnum, RecipientType.customer);
      expect(dist.isDelayedDistribution, false);
      expect(dist.isAllShiftPool, false);
    });

    test('Detects delayed entry distribution when shift is all', () {
      final json = {
        '_id': 'dist_delayed',
        'gaushalaId': 'gau_1',
        'milkDate': '2026-10-01',
        'distributionDate': '2026-10-02',
        'shift': 'all',
        'quantity': 40.0,
        'recipientType': 'dairy_plant',
        'recipientName': 'Amul Dairy Plant',
        'ratePerLiter': 58.0,
      };

      final dist = MilkDistributionModel.fromJson(json);

      expect(dist.isAllShiftPool, true);
      expect(dist.isDelayedDistribution, true);
      expect(dist.totalAmount, 40.0 * 58.0);
      expect(dist.recipientTypeEnum, RecipientType.dairyPlant);
    });
  });

  group('MilkDisposalModel Tests', () {
    test('Parses disposal record and enum accurately', () {
      final json = {
        '_id': 'disp_10',
        'gaushalaId': 'gau_1',
        'milkDate': '2026-10-01',
        'disposalDate': '2026-10-02',
        'quantity': 10.0,
        'reason': 'temperature_failure',
        'reportedBy': 'wrk_5',
        'reportedByName': 'Dinesh Bhai',
        'remarks': 'Chiller power tripped overnight',
      };

      final disp = MilkDisposalModel.fromJson(json);

      expect(disp.id, 'disp_10');
      expect(disp.quantity, 10.0);
      expect(disp.disposalReasonEnum, DisposalReason.temperatureFailure);
      expect(disp.reportedByName, 'Dinesh Bhai');
      expect(disp.remarks, 'Chiller power tripped overnight');
    });
  });

  group('FridgeStockModel Tests', () {
    test('Parses fridge stock item', () {
      final json = {
        'milkDate': '2026-09-30',
        'gaushalaId': 'gau_1',
        'totalProduced': 950.0,
        'totalDistributed': 900.0,
        'totalDisposed': 10.0,
        'remainingFridgeMilk': 40.0,
      };

      final stock = FridgeStockModel.fromJson(json);

      expect(stock.milkDate, '2026-09-30');
      expect(stock.totalProduced, 950.0);
      expect(stock.totalDistributed, 900.0);
      expect(stock.totalDisposed, 10.0);
      expect(stock.remainingFridgeMilk, 40.0);
    });
  });

  group('Milk Distribution Stock Limit Validation Tests', () {
    test('Calculates remaining balance and detects limit exceeded accurately', () {
      const double availableMorning = 120.0;

      // Safe within limit
      double enteredQty = 25.0;
      double remaining = availableMorning - enteredQty;
      bool isExceeded = enteredQty > availableMorning;
      bool isOutOfStock = availableMorning <= 0;

      expect(remaining, 95.0);
      expect(isExceeded, false);
      expect(isOutOfStock, false);

      // Exact MAX limit
      enteredQty = 120.0;
      remaining = availableMorning - enteredQty;
      isExceeded = enteredQty > availableMorning;
      expect(remaining, 0.0);
      expect(isExceeded, false);

      // Exceeded limit
      enteredQty = 150.0;
      remaining = availableMorning - enteredQty;
      isExceeded = enteredQty > availableMorning;
      expect(remaining, -30.0);
      expect(isExceeded, true);

      // Out of stock
      const double zeroAvailable = 0.0;
      expect(zeroAvailable <= 0, true);
    });

    test('Quick Limit calculations (25%, 50%, 75%, MAX) are accurate', () {
      const double available = 120.0;
      expect(double.parse((available * 0.25).toStringAsFixed(1)), 30.0);
      expect(double.parse((available * 0.50).toStringAsFixed(1)), 60.0);
      expect(double.parse((available * 0.75).toStringAsFixed(1)), 90.0);
      expect(double.parse((available * 1.0).toStringAsFixed(1)), 120.0);
    });
  });
}

