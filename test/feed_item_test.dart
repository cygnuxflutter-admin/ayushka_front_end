import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/feed_item_model.dart';

void main() {
  group('FeedItemModel Tests', () {
    test('Parses feed item json with populated gaushalaId object', () {
      final json = {
        '_id': '6abe19adf47731b8bb6fc186',
        'gaushalaId': {
          '_id': '6abcaee5d7556202004414b0',
          'gaushalaName': 'ayushka_navsari',
        },
        'itemName': 'Green Fodder (Maize/Jowar)',
        'itemCode': 'GF-001',
        'category': 'GREEN_FODDER',
        'unit': 'KG',
        'currentStock': 250,
        'minStockAlert': 100,
        'unitPrice': 5.5,
        'description': 'Fresh green maize fodder for cattle',
        'isActive': true,
        'isDeleted': false,
        'createdBy': {
          '_id': '6abb81dec91ddf959f54022a',
          'name': 'Ayushka Admin',
        },
        'createdAt': '2026-10-01T08:28:29.692Z',
        'updatedAt': '2026-10-01T08:28:29.692Z',
      };

      final item = FeedItemModel.fromJson(json);

      expect(item.id, '6abe19adf47731b8bb6fc186');
      expect(item.gaushalaId, '6abcaee5d7556202004414b0');
      expect(item.gaushalaName, 'ayushka_navsari');
      expect(item.itemName, 'Green Fodder (Maize/Jowar)');
      expect(item.itemCode, 'GF-001');
      expect(item.category, 'GREEN_FODDER');
      expect(item.categoryEnum, FeedItemCategory.greenFodder);
      expect(item.unit, 'KG');
      expect(item.unitEnum, FeedItemUnit.kg);
      expect(item.currentStock, 250.0);
      expect(item.minStockAlert, 100.0);
      expect(item.unitPrice, 5.5);
      expect(item.description, 'Fresh green maize fodder for cattle');
      expect(item.isActive, true);
      expect(item.isDeleted, false);
      expect(item.createdBy, 'Ayushka Admin');
      expect(item.isLowStock, false);
    });

    test('Parses feed item json with string gaushalaId and initialStock fallback', () {
      final json = {
        'id': 'item_123',
        'gaushalaId': 'g_456',
        'gaushalaName': 'Main Farm',
        'itemName': 'Dry Grass',
        'itemCode': 'DF-02',
        'category': 'DRY_FODDER',
        'unit': 'TON',
        'initialStock': 10.0,
        'minStockAlert': 20.0,
        'unitPrice': 1500.0,
        'isActive': true,
      };

      final item = FeedItemModel.fromJson(json);

      expect(item.id, 'item_123');
      expect(item.gaushalaId, 'g_456');
      expect(item.gaushalaName, 'Main Farm');
      expect(item.itemName, 'Dry Grass');
      expect(item.itemCode, 'DF-02');
      expect(item.category, 'DRY_FODDER');
      expect(item.categoryEnum, FeedItemCategory.dryFodder);
      expect(item.unit, 'TON');
      expect(item.unitEnum, FeedItemUnit.ton);
      expect(item.currentStock, 10.0);
      expect(item.minStockAlert, 20.0);
      expect(item.isLowStock, true); // 10 <= 20
    });

    test('Serializes to JSON correctly for create and update payloads', () {
      const item = FeedItemModel(
        id: 'item_999',
        gaushalaId: 'g_456',
        itemName: 'Mineral Mix',
        itemCode: 'SUP-01',
        category: 'SUPPLEMENT',
        unit: 'BAG',
        currentStock: 50.0,
        minStockAlert: 10.0,
        unitPrice: 850.0,
        description: 'Vitamins & Calcium',
        isActive: true,
      );

      final json = item.toJson(includeInitialStock: true);

      expect(json['_id'], 'item_999');
      expect(json['gaushalaId'], 'g_456');
      expect(json['itemName'], 'Mineral Mix');
      expect(json['itemCode'], 'SUP-01');
      expect(json['category'], 'SUPPLEMENT');
      expect(json['unit'], 'BAG');
      expect(json['initialStock'], 50.0);
      expect(json['minStockAlert'], 10.0);
      expect(json['unitPrice'], 850.0);
      expect(json['description'], 'Vitamins & Calcium');
      expect(json['isActive'], true);
    });

    test('copyWith updates fields as expected', () {
      const original = FeedItemModel(
        id: '1',
        itemName: 'Fodder',
        category: 'GREEN_FODDER',
        unit: 'KG',
        currentStock: 100,
      );

      final updated = original.copyWith(
        itemName: 'Fresh Green Fodder',
        currentStock: 150,
        unitPrice: 6.0,
      );

      expect(updated.id, '1');
      expect(updated.itemName, 'Fresh Green Fodder');
      expect(updated.currentStock, 150);
      expect(updated.unitPrice, 6.0);
      expect(updated.category, 'GREEN_FODDER');
      expect(updated.unit, 'KG');
    });

    test('Category and Unit enum fromCode handling', () {
      expect(FeedItemCategory.fromCode('green_fodder'), FeedItemCategory.greenFodder);
      expect(FeedItemCategory.fromCode('DRY_FODDER'), FeedItemCategory.dryFodder);
      expect(FeedItemCategory.fromCode('concentrate_feed'), FeedItemCategory.concentrateFeed);
      expect(FeedItemCategory.fromCode('supplement'), FeedItemCategory.supplement);
      expect(FeedItemCategory.fromCode('unknown'), FeedItemCategory.other);

      expect(FeedItemUnit.fromCode('kg'), FeedItemUnit.kg);
      expect(FeedItemUnit.fromCode('TON'), FeedItemUnit.ton);
      expect(FeedItemUnit.fromCode('quintal'), FeedItemUnit.quintal);
      expect(FeedItemUnit.fromCode('bag'), FeedItemUnit.bag);
      expect(FeedItemUnit.fromCode('bundle'), FeedItemUnit.bundle);
      expect(FeedItemUnit.fromCode('liter'), FeedItemUnit.liter);
      expect(FeedItemUnit.fromCode('invalid'), FeedItemUnit.other);
    });
  });
}
