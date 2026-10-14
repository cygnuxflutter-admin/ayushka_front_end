import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayushka/app/core/values/permission_constants.dart';
import 'package:ayushka/app/data/models/breed_model.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/permission_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:ayushka/app/data/models/gaushala_model.dart';
import 'package:ayushka/app/data/services/gaushala_session_service.dart';
import 'package:ayushka/app/modules/breed/breed_controller.dart';
import 'package:ayushka/app/modules/breed/breed_screen.dart';
import 'package:ayushka/models/permission_model.dart';

class _MockBreedApiService extends GetxService implements ApiService {
  final List<BreedModel> mockBreeds = [
    BreedModel(
      id: 'b1',
      breedName: 'Gir',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    BreedModel(
      id: 'b2',
      breedName: 'Kankrej',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<BreedModel>> getBreedTypes() async {
    return List.from(mockBreeds);
  }

  @override
  Future<BreedModel> createBreedType(String breedName) async {
    final newBreed = BreedModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      breedName: breedName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockBreeds.insert(0, newBreed);
    return newBreed;
  }

  @override
  Future<List<GaushalaModel>> getGaushalas() async {
    return [
      const GaushalaModel(id: 'g1', gaushalaName: 'ayushka_navsari'),
    ];
  }

  @override
  Future<UserPermissionsResponse> getMyPermissions() async {
    return UserPermissionsResponse(
      userId: 'admin_1',
      role: 'Admin',
      isAdmin: true,
      permissions: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late _MockBreedApiService apiService;
  late PermissionService permissionService;
  late GaushalaSessionService gaushalaSessionService;

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    storageService = await Get.putAsync(() => StorageService().init());
    apiService = Get.put<_MockBreedApiService>(_MockBreedApiService());
    Get.put<ApiService>(apiService);
    permissionService = Get.put(PermissionService());
    gaushalaSessionService = Get.put(GaushalaSessionService());
  });

  tearDown(() {
    Get.delete<BreedController>(force: true);
  });

  group('Breed Admin Access & Creation Tests', () {
    test('Admin user (non-SuperAdmin) has canAddBreed = true and can access Breeds', () async {
      const adminUser = UserModel(
        id: 'usr_admin',
        name: 'Navsari Admin',
        email: 'navsari_admin@ayushka.com',
        role: 'Admin',
        username: 'admin_ayushka',
      );

      await storageService.saveUser(adminUser);
      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isSuperAdmin, isFalse);

      final controller = Get.put(BreedController());
      expect(controller.canAddBreed, isTrue);

      await controller.fetchBreeds();
      expect(controller.breeds.length, 2);
      expect(controller.breeds.first.breedName, 'Gir');

      // Test adding a new breed as admin
      final created = await controller.createBreed('Sahiwal');
      expect(created, isTrue);
      expect(controller.breeds.length, 3);
      expect(controller.breeds.first.breedName, 'Sahiwal');
    });

    test('Super Admin user has canAddBreed = true and can create breeds', () async {
      const superAdminUser = UserModel(
        id: 'usr_super',
        name: 'Main Head',
        email: 'head@ayushka.com',
        role: 'Superadmin',
        username: 'superadmin',
      );

      await storageService.saveUser(superAdminUser);
      expect(superAdminUser.isSuperAdmin, isTrue);

      final controller = Get.put(BreedController());
      expect(controller.canAddBreed, isTrue);

      final created = await controller.createBreed('Tharparkar');
      expect(created, isTrue);
      expect(controller.breeds.first.breedName, 'Tharparkar');
    });

    test('Staff user without breed permissions cannot add breed', () async {
      const staffUser = UserModel(
        id: 'usr_staff',
        name: 'Regular Staff',
        email: 'staff@ayushka.com',
        role: 'Staff',
      );

      await storageService.saveUser(staffUser);
      await storageService.saveUserPermissions([
        const PermissionItemModel(
          moduleId: 'm1',
          moduleCode: PermissionModules.cow,
          moduleName: 'Cow Management',
          subModuleCode: PermissionSubModules.cowList,
          subModuleName: 'Cow Records',
          canView: true,
          canAdd: false,
        ),
      ], false);
      permissionService.loadFromCache();

      expect(staffUser.isAdmin, isFalse);
      expect(staffUser.isSuperAdmin, isFalse);

      final controller = Get.put(BreedController());
      expect(controller.canAddBreed, isFalse);
    });

    test('Staff user with BREED_TYPE add permission CAN add breed', () async {
      const staffUser = UserModel(
        id: 'usr_staff_breed',
        name: 'Breed Manager Staff',
        email: 'breedstaff@ayushka.com',
        role: 'Staff',
      );

      await storageService.saveUser(staffUser);
      await storageService.saveUserPermissions([
        const PermissionItemModel(
          moduleId: 'm_breed',
          moduleCode: PermissionModules.breedType,
          moduleName: 'Breed Types',
          subModuleCode: PermissionSubModules.breedTypeList,
          subModuleName: 'Breed Master',
          canView: true,
          canAdd: true,
        ),
      ], false);
      permissionService.loadFromCache();

      final controller = Get.put(BreedController());
      expect(controller.canAddBreed, isTrue);
    });

    testWidgets('BreedScreen renders "Add Breed" button for Admin user on Desktop', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      const adminUser = UserModel(
        id: 'usr_admin',
        name: 'admin_ayushka',
        email: 'admin@ayushka.com',
        role: 'Admin',
        username: 'admin_ayushka',
      );

      await storageService.saveUser(adminUser);
      Get.put(BreedController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: BreedScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Breeds Master'), findsOneWidget);
      expect(find.text('Add Breed'), findsOneWidget);
    });
  });
}
