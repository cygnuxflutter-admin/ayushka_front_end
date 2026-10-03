import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayushka/models/permission_model.dart';
import 'package:ayushka/app/core/values/permission_constants.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/permission_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:ayushka/widgets/permission_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RBAC Permission Models Test', () {
    test('PermissionItemModel serialization and deserialization', () {
      final json = {
        'moduleId': 'mod-1',
        'moduleCode': 'COW',
        'moduleName': 'Cow Management',
        'subModuleCode': 'COW_LIST',
        'subModuleName': 'Cow Records',
        'canView': true,
        'canAdd': true,
        'canEdit': false,
        'canDelete': false,
      };

      final item = PermissionItemModel.fromJson(json);
      expect(item.moduleId, 'mod-1');
      expect(item.moduleCode, 'COW');
      expect(item.subModuleCode, 'COW_LIST');
      expect(item.canView, isTrue);
      expect(item.canAdd, isTrue);
      expect(item.canEdit, isFalse);
      expect(item.canDelete, isFalse);
      expect(item.hasAllPermissions, isFalse);
      expect(item.hasAnyPermission, isTrue);

      final encoded = item.toJson();
      expect(encoded['moduleCode'], 'COW');
      expect(encoded['canView'], isTrue);

      final updatePayload = item.toUpdatePayload();
      expect(updatePayload['subModuleCode'], 'COW_LIST');
      expect(updatePayload['canAdd'], isTrue);
    });

    test('UserPermissionsResponse parsing with admin flag', () {
      final json = {
        'success': true,
        'data': {
          'userId': 'usr-999',
          'role': 'Staff',
          'isAdmin': false,
          'permissions': [
            {
              'moduleId': 'm1',
              'moduleCode': 'COW',
              'subModuleCode': 'COW_LIST',
              'canView': true,
              'canAdd': false,
              'canEdit': false,
              'canDelete': false,
            }
          ]
        }
      };

      final res = UserPermissionsResponse.fromJson(json);
      expect(res.userId, 'usr-999');
      expect(res.role, 'Staff');
      expect(res.isAdmin, isFalse);
      expect(res.permissions.length, 1);
      expect(res.permissions.first.canView, isTrue);
    });
  });

  group('PermissionService Evaluation & State Management Test', () {
    late StorageService storageService;
    late PermissionService permissionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await Get.putAsync(() => StorageService().init());
      await storageService.saveToken('mock-access-token');
      Get.put(ApiService());
      permissionService = Get.put(PermissionService());
    });

    tearDown(() {
      Get.reset();
    });

    test('Admin user has unrestricted access', () async {
      // Simulate Admin permissions
      final perms = [
        const PermissionItemModel(
          moduleId: '1',
          moduleCode: PermissionModules.cow,
          moduleName: 'Cow Management',
          subModuleCode: PermissionSubModules.cowList,
          subModuleName: 'Cow Records',
          canView: false, // Even if false, Admin has bypass
          canAdd: false,
          canEdit: false,
          canDelete: false,
        ),
      ];

      await storageService.saveUserPermissions(perms, true);
      permissionService.loadFromCache();

      expect(permissionService.isAdmin, isTrue);
      expect(permissionService.canView(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.canAdd(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.canEdit(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.canDelete(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.isModuleVisible(PermissionModules.cow), isTrue);
    });

    test('Non-admin user has granular access correctly evaluated', () async {
      final perms = [
        const PermissionItemModel(
          moduleId: '1',
          moduleCode: PermissionModules.cow,
          moduleName: 'Cow Management',
          subModuleCode: PermissionSubModules.cowList,
          subModuleName: 'Cow Records',
          canView: true,
          canAdd: true,
          canEdit: false,
          canDelete: false,
        ),
        const PermissionItemModel(
          moduleId: '2',
          moduleCode: PermissionModules.user,
          moduleName: 'User Management',
          subModuleCode: PermissionSubModules.userList,
          subModuleName: 'User Records',
          canView: false,
          canAdd: false,
          canEdit: false,
          canDelete: false,
        ),
      ];

      await storageService.saveUserPermissions(perms, false);
      permissionService.loadFromCache();

      expect(permissionService.isAdmin, isFalse);

      // Cow Module
      expect(permissionService.canView(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.canAdd(PermissionModules.cow, PermissionSubModules.cowList), isTrue);
      expect(permissionService.canEdit(PermissionModules.cow, PermissionSubModules.cowList), isFalse);
      expect(permissionService.canDelete(PermissionModules.cow, PermissionSubModules.cowList), isFalse);
      expect(permissionService.isModuleVisible(PermissionModules.cow), isTrue);

      // User Module
      expect(permissionService.canView(PermissionModules.user, PermissionSubModules.userList), isFalse);
      expect(permissionService.isModuleVisible(PermissionModules.user), isFalse);
    });
  });

  group('PermissionGuard UI Widget Tests', () {
    late StorageService storageService;
    late PermissionService permissionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await Get.putAsync(() => StorageService().init());
      await storageService.saveToken('mock-access-token');
      Get.put(ApiService());
      permissionService = Get.put(PermissionService());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Renders child when permission is granted and hides when denied', (tester) async {
      final perms = [
        const PermissionItemModel(
          moduleId: '1',
          moduleCode: PermissionModules.cow,
          moduleName: 'Cow Management',
          subModuleCode: PermissionSubModules.cowList,
          subModuleName: 'Cow Records',
          canView: true,
          canAdd: true,
          canEdit: false,
          canDelete: false,
        ),
      ];

      await storageService.saveUserPermissions(perms, false);
      permissionService.loadFromCache();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PermissionGuard(
                  moduleCode: PermissionModules.cow,
                  subModuleCode: PermissionSubModules.cowList,
                  action: PermissionAction.add,
                  child: const Text('Add Cow Button'),
                ),
                PermissionGuard(
                  moduleCode: PermissionModules.cow,
                  subModuleCode: PermissionSubModules.cowList,
                  action: PermissionAction.delete,
                  fallback: const Text('No Delete Permission Fallback'),
                  child: const Text('Delete Cow Button'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Add is granted -> 'Add Cow Button' should be present
      expect(find.text('Add Cow Button'), findsOneWidget);

      // Delete is denied -> 'Delete Cow Button' should not be present, fallback should be shown
      expect(find.text('Delete Cow Button'), findsNothing);
      expect(find.text('No Delete Permission Fallback'), findsOneWidget);
    });
  });
}
