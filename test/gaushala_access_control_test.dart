import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayushka/app/core/widgets/global_gaushala_selector.dart';
import 'package:ayushka/app/data/models/gaushala_model.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/gaushala_session_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:ayushka/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:ayushka/app/modules/dashboard/widgets/mobile_drawer.dart';

class _MockApiService extends GetxService implements ApiService {
  final List<GaushalaModel> mockGaushalas;

  _MockApiService(this.mockGaushalas);

  @override
  Future<List<GaushalaModel>> getGaushalas() async {
    return mockGaushalas;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late GaushalaSessionService gaushalaService;

  final testGaushalas = [
    const GaushalaModel(id: '674f9a0c1234567890abcdef', gaushalaName: 'ayushka_navsari'),
    const GaushalaModel(id: '674f9a0c1234567890abcdeg', gaushalaName: 'surat_farm'),
    const GaushalaModel(id: '674f9a0c1234567890abcdeh', gaushalaName: 'ahmedabad_center'),
  ];

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    storageService = await Get.putAsync(() => StorageService().init());
    Get.put<ApiService>(_MockApiService(testGaushalas));
    gaushalaService = Get.put(GaushalaSessionService());
  });

  group('Role and Super Admin Evaluation Tests', () {
    test('Only Super Admin roles are identified as isSuperAdmin', () {
      const superAdminUser1 = UserModel(
        id: 'u1',
        name: 'Super Admin User',
        email: 'super@ayushka.com',
        role: 'Superadmin',
        username: 'super_admin_ayushka',
      );
      expect(superAdminUser1.isSuperAdmin, isTrue);

      const superAdminUser2 = UserModel(
        id: 'u2',
        name: 'Platform Head',
        email: 'head@ayushka.com',
        role: 'Super Admin',
      );
      expect(superAdminUser2.isSuperAdmin, isTrue);

      const superAdminUser3 = UserModel(
        id: 'u3',
        name: 'Admin Boss',
        email: 'boss@ayushka.com',
        role: 'super_admin',
      );
      expect(superAdminUser3.isSuperAdmin, isTrue);

      // Regular Admin (Farm Admin, Admin) must NOT be Super Admin
      const regularAdmin = UserModel(
        id: 'u4',
        name: 'Branch Admin',
        email: 'admin@surat.com',
        role: 'Admin',
      );
      expect(regularAdmin.isSuperAdmin, isFalse);
      expect(regularAdmin.isAdmin, isTrue);

      const farmAdmin = UserModel(
        id: 'u5',
        name: 'Farm Admin',
        email: 'farmadmin@ayushka.com',
        role: 'Farm Admin',
      );
      expect(farmAdmin.isSuperAdmin, isFalse);

      // Staff must NOT be Super Admin
      const staffUser = UserModel(
        id: 'u6',
        name: 'Staff Member',
        email: 'staff@ayushka.com',
        role: 'Staff',
      );
      expect(staffUser.isSuperAdmin, isFalse);
      expect(staffUser.isAdmin, isFalse);
    });
  });

  group('Gaushala Access Control and Isolation Tests', () {
    test('Non-SuperAdmin (Admin, Staff) is strictly locked to their login gaushala and cannot change', () async {
      // Create user assigned to 'surat_farm'
      const adminSurat = UserModel(
        id: 'u-admin-1',
        name: 'Surat Admin',
        email: 'admin@surat.com',
        role: 'Admin',
        gaushalaId: '674f9a0c1234567890abcdeg',
        gaushalaName: 'surat_farm',
      );

      await storageService.saveUser(adminSurat);
      await gaushalaService.initSession(user: adminSurat, isLogin: true);

      // 1. canChangeGaushala must be false
      expect(gaushalaService.canChangeGaushala, isFalse);

      // 2. Selected gaushala must strictly be surat_farm
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeg');
      expect(gaushalaService.selectedGaushalaName, 'surat_farm');

      // 3. Only their assigned gaushala must be visible in gaushalas list ("biju kai pan show nahee thay")
      expect(gaushalaService.gaushalas.length, 1);
      expect(gaushalaService.gaushalas.first.gaushalaName, 'surat_farm');

      // 4. Attempting to switch gaushala must be blocked
      final otherGaushala = testGaushalas.first; // ayushka_navsari
      gaushalaService.setGaushala(otherGaushala);

      // Must remain locked to surat_farm
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeg');
      expect(gaushalaService.selectedGaushalaName, 'surat_farm');

      // 5. Attempting to switch by ID/name must be blocked
      gaushalaService.setGaushalaById('ayushka_navsari');
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeg');
      expect(gaushalaService.selectedGaushalaName, 'surat_farm');
    });

    test('Staff user is strictly locked to their login gaushala and cannot see other gaushalas', () async {
      const staffMember = UserModel(
        id: 'u-staff-1',
        name: 'Ahmedabad Worker',
        email: 'worker@ahmedabad.com',
        role: 'Staff',
        gaushalaId: '674f9a0c1234567890abcdeh',
        gaushalaName: 'ahmedabad_center',
      );

      await storageService.saveUser(staffMember);
      await gaushalaService.initSession(user: staffMember, isLogin: true);

      expect(gaushalaService.canChangeGaushala, isFalse);
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeh');
      expect(gaushalaService.selectedGaushalaName, 'ahmedabad_center');
      expect(gaushalaService.gaushalas.length, 1);
      expect(gaushalaService.gaushalas.first.id, '674f9a0c1234567890abcdeh');

      // Attempting to switch must do nothing
      gaushalaService.setGaushalaById('surat_farm');
      expect(gaushalaService.selectedGaushalaName, 'ahmedabad_center');
    });

    test('Super Admin can view all gaushalas and switch between any gaushala', () async {
      const superAdmin = UserModel(
        id: 'u-super-1',
        name: 'Super Administrator',
        email: 'super@ayushka.com',
        role: 'Superadmin',
        username: 'super_admin_ayushka',
        gaushalaId: '674f9a0c1234567890abcdef',
        gaushalaName: 'ayushka_navsari',
      );

      await storageService.saveUser(superAdmin);
      await gaushalaService.initSession(user: superAdmin, isLogin: true);

      // 1. canChangeGaushala is true
      expect(gaushalaService.canChangeGaushala, isTrue);

      // 2. All gaushalas are present in gaushalas list
      expect(gaushalaService.gaushalas.length, 3);

      // 3. Super Admin can switch to surat_farm
      gaushalaService.setGaushalaById('surat_farm');
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeg');
      expect(gaushalaService.selectedGaushalaName, 'surat_farm');

      // 4. Super Admin can switch to ahmedabad_center
      gaushalaService.setGaushalaById('ahmedabad_center');
      expect(gaushalaService.selectedGaushalaId, '674f9a0c1234567890abcdeh');
      expect(gaushalaService.selectedGaushalaName, 'ahmedabad_center');
    });
  });

  group('GlobalGaushalaSelector UI Tests', () {
    testWidgets('GlobalGaushalaSelector renders fixed locked badge for Admin/Staff user', (tester) async {
      const regularAdmin = UserModel(
        id: 'u-admin-1',
        name: 'Admin Branch',
        email: 'admin@surat.com',
        role: 'Admin',
        gaushalaId: '674f9a0c1234567890abcdeg',
        gaushalaName: 'surat_farm',
      );
      await storageService.saveUser(regularAdmin);
      await gaushalaService.initSession(user: regularAdmin, isLogin: true);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: GlobalGaushalaSelector(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays the assigned gaushala name
      expect(find.text('surat_farm'), findsOneWidget);

      // Displays the lock icon indicating non-changeable status
      expect(find.byIcon(PhosphorIconsRegular.lockSimple), findsOneWidget);

      // Does not show keyboard arrow down icon (which is only in dropdown mode)
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });

    testWidgets('GlobalGaushalaSelector renders interactive dropdown for Super Admin', (tester) async {
      const superAdmin = UserModel(
        id: 'u-super-1',
        name: 'Super Admin',
        email: 'super@ayushka.com',
        role: 'Superadmin',
        username: 'super_admin_ayushka',
        gaushalaId: '674f9a0c1234567890abcdef',
        gaushalaName: 'ayushka_navsari',
      );
      await storageService.saveUser(superAdmin);
      await gaushalaService.initSession(user: superAdmin, isLogin: true);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: GlobalGaushalaSelector(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays active gaushala name
      expect(find.text('ayushka_navsari'), findsOneWidget);

      // Displays dropdown arrow
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Lock icon is NOT displayed for Super Admin
      expect(find.byIcon(PhosphorIconsRegular.lockSimple), findsNothing);
    });
  });

  group('Gaushala Module Navigation Visibility Tests', () {
    testWidgets('WebSidebar shows Gaushalas module strictly for Super Admin', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const superAdmin = UserModel(
        id: 'u-super-1',
        name: 'Super Admin',
        email: 'super@ayushka.com',
        role: 'Superadmin',
        username: 'super_admin_ayushka',
        gaushalaId: '674f9a0c1234567890abcdef',
        gaushalaName: 'ayushka_navsari',
      );
      await storageService.saveUser(superAdmin);
      await gaushalaService.initSession(user: superAdmin, isLogin: true);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: superAdmin,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Gaushalas should be visible in WebSidebar
      expect(find.text('Gaushalas'), findsOneWidget);
    });

    testWidgets('WebSidebar strictly HIDES Gaushalas module for non-SuperAdmin (Admin/Staff)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const regularAdmin = UserModel(
        id: 'u-admin-1',
        name: 'Regular Admin',
        email: 'admin@surat.com',
        role: 'Admin',
        gaushalaId: '674f9a0c1234567890abcdeg',
        gaushalaName: 'surat_farm',
      );
      await storageService.saveUser(regularAdmin);
      await gaushalaService.initSession(user: regularAdmin, isLogin: true);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: regularAdmin,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Gaushalas must NOT be shown to Regular Admin
      expect(find.text('Gaushalas'), findsNothing);
    });

    testWidgets('MobileDrawer shows Gaushalas strictly for Super Admin and hides for non-SuperAdmin', (tester) async {
      const superAdmin = UserModel(
        id: 'u-super-1',
        name: 'Super Admin',
        email: 'super@ayushka.com',
        role: 'Superadmin',
      );
      const regularAdmin = UserModel(
        id: 'u-admin-1',
        name: 'Regular Admin',
        email: 'admin@surat.com',
        role: 'Admin',
      );

      // 1. Super Admin
      await storageService.saveUser(superAdmin);
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            drawer: MobileDrawer(
              currentUser: superAdmin,
              onLogout: () {},
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('Gaushalas'), findsOneWidget);

      // 2. Regular Admin
      await storageService.saveUser(regularAdmin);
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            drawer: MobileDrawer(
              currentUser: regularAdmin,
              onLogout: () {},
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );
      final scaffoldState2 = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState2.openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('Gaushalas'), findsNothing);
    });

    testWidgets('WebSidebar and MobileDrawer show Roles strictly for Super Admin and hide for regular Admin', (tester) async {
      const superAdmin = UserModel(
        id: 'u-super-1',
        name: 'Super Admin',
        email: 'super@ayushka.com',
        role: 'Superadmin',
      );
      const regularAdmin = UserModel(
        id: 'u-admin-1',
        name: 'admin_ayushka',
        email: 'admin@ayushka.com',
        role: 'Admin',
      );

      // Super Admin: Roles must be visible in WebSidebar
      await storageService.saveUser(superAdmin);
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: superAdmin,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Roles'), findsOneWidget);

      // Regular Admin: Roles must NOT be visible in WebSidebar
      await storageService.saveUser(regularAdmin);
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: regularAdmin,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Roles'), findsNothing);

      // Regular Admin: Roles must NOT be visible in MobileDrawer
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            drawer: MobileDrawer(
              currentUser: regularAdmin,
              onLogout: () {},
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('Roles'), findsNothing);
    });
  });
}

