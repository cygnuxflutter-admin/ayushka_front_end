import 'package:ayushka/app/core/utils/responsive_layout.dart';
import 'package:ayushka/app/core/widgets/custom_button.dart';
import 'package:ayushka/app/core/widgets/custom_loader.dart';
import 'package:ayushka/app/core/widgets/custom_shimmer.dart';
import 'package:ayushka/app/data/models/auth_tokens_model.dart';
import 'package:ayushka/app/data/models/breed_model.dart';
import 'package:ayushka/app/data/models/cow_model.dart';
import 'package:ayushka/app/data/models/gaushala_model.dart';
import 'package:ayushka/app/data/models/role_model.dart';
import 'package:ayushka/app/data/models/shed_model.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/core/widgets/custom_text_field.dart';
import 'package:ayushka/app/core/widgets/logout_confirmation_dialog.dart';
import 'package:ayushka/app/modules/auth/widgets/cow_photo_slider.dart';
import 'package:ayushka/app/modules/dashboard/widgets/mobile_drawer.dart';
import 'package:ayushka/app/modules/dashboard/widgets/web_sidebar.dart';
import 'dart:math';
import 'dart:ui';
import 'package:ayushka/app/core/utils/file_download_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  group('Cattle Management Unit Tests', () {
    test('UserModel JSON serialization & deserialization with refreshToken', () {
      final user = UserModel(
        id: 'USR-101',
        name: 'Aayush Farm Manager',
        email: 'admin@ayushka.com',
        role: 'Farm Manager',
        token: 'sample_token_xyz',
        refreshToken: 'sample_refresh_token_abc',
      );

      final json = user.toJson();
      expect(json['id'], 'USR-101');
      expect(json['email'], 'admin@ayushka.com');
      expect(json['refreshToken'], 'sample_refresh_token_abc');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.id, user.id);
      expect(deserialized.name, user.name);
      expect(deserialized.email, user.email);
      expect(deserialized.role, user.role);
      expect(deserialized.token, user.token);
      expect(deserialized.refreshToken, user.refreshToken);
    });

    test('AuthTokensModel JSON serialization & deserialization', () {
      final tokenJson = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testAccess',
        'refreshToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testRefresh',
        'tokenType': 'Bearer',
        'expiresIn': '1h',
        'refreshTokenExpiresIn': '7d',
      };

      final tokens = AuthTokensModel.fromJson(tokenJson);
      expect(tokens.accessToken, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testAccess');
      expect(tokens.refreshToken, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testRefresh');
      expect(tokens.tokenType, 'Bearer');
      expect(tokens.expiresIn, '1h');
      expect(tokens.refreshTokenExpiresIn, '7d');

      final serialized = tokens.toJson();
      expect(serialized['accessToken'], tokens.accessToken);
      expect(serialized['refreshToken'], tokens.refreshToken);
      expect(serialized['tokenType'], 'Bearer');
      expect(serialized['expiresIn'], '1h');
      expect(serialized['refreshTokenExpiresIn'], '7d');
    });

    test('RoleModel JSON serialization & deserialization', () {
      final roleJson = {
        '_id': '6abb81def57748110edefe5b',
        'roleName': 'Admin',
        'createdAt': '2026-09-29T09:16:14.270Z',
        'updatedAt': '2026-09-29T10:04:55.829Z',
      };

      final role = RoleModel.fromJson(roleJson);
      expect(role.id, '6abb81def57748110edefe5b');
      expect(role.roleName, 'Admin');
      expect(role.createdAt, isNotNull);
      expect(role.updatedAt, isNotNull);

      final serialized = role.toJson();
      expect(serialized['roleName'], 'Admin');
      expect(serialized['_id'], '6abb81def57748110edefe5b');
    });

    test('ShedModel JSON serialization & deserialization', () {
      final shedJson = {
        '_id': '6abb9f91c763f94b2875c1af',
        'shedName': 'North Shed A',
        'shedNumber': 'SHED-001',
        'createdAt': '2026-09-29T11:22:57.079Z',
        'updatedAt': '2026-09-29T11:23:07.118Z',
      };

      final shed = ShedModel.fromJson(shedJson);
      expect(shed.id, '6abb9f91c763f94b2875c1af');
      expect(shed.shedName, 'North Shed A');
      expect(shed.shedNumber, 'SHED-001');
      expect(shed.createdAt, isNotNull);
      expect(shed.updatedAt, isNotNull);

      final serialized = shed.toJson();
      expect(serialized['shedName'], 'North Shed A');
      expect(serialized['shedNumber'], 'SHED-001');
      expect(serialized['_id'], '6abb9f91c763f94b2875c1af');
    });

    test('BreedModel JSON serialization & deserialization', () {
      final breedJson = {
        '_id': '6abbae15faa1ef7a8f6090a6',
        'breedName': 'Gir',
        'createdAt': '2026-09-29T12:24:53.336Z',
        'updatedAt': '2026-09-29T12:24:53.336Z',
      };

      final breed = BreedModel.fromJson(breedJson);
      expect(breed.id, '6abbae15faa1ef7a8f6090a6');
      expect(breed.breedName, 'Gir');
      expect(breed.createdAt, isNotNull);
      expect(breed.updatedAt, isNotNull);

      final serialized = breed.toJson();
      expect(serialized['breedName'], 'Gir');
      expect(serialized['_id'], '6abbae15faa1ef7a8f6090a6');
    });

    test('AddCowRequestModel converts tag_id to uppercase in toJson', () {
      const request = AddCowRequestModel(
        breed: 'breed-1',
        gaushalaId: 'gaushala-1',
        type: 'type-1',
        tagId: 'gir-001',
        isFemale: true,
        addedBy: 'user-1',
      );

      final json = request.toJson();
      expect(json['tag_id'], 'GIR-001');
    });

    test('CowModel.fromJson and CowParentRef.fromJson convert tag_id to uppercase', () {
      final cowJson = {
        '_id': 'cow-123',
        'tag_id': 'gir-002',
        'isFemale': true,
      };

      final cow = CowModel.fromJson(cowJson);
      expect(cow.tagId, 'GIR-002');

      final parent = CowParentRef.fromJson(cowJson);
      expect(parent.tagId, 'GIR-002');
    });

    test('UpperCaseTextFormatter converts lowercase input to uppercase', () {
      const formatter = UpperCaseTextFormatter();
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: 'gir-001',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'GIR-001');
      expect(result.selection.baseOffset, 7);
    });

    test('AddCowRequestModel includes dam_id and sair_id in toJson', () {
      const request = AddCowRequestModel(
        breed: 'breed-1',
        gaushalaId: 'gaushala-1',
        type: 'type-1',
        tagId: 'gir-005',
        isFemale: true,
        addedBy: 'user-1',
        damId: 'cow-dam-001',
        sairId: 'cow-sire-002',
      );

      final json = request.toJson();
      expect(json['tag_id'], 'GIR-005');
      expect(json['dam_id'], 'cow-dam-001');
      expect(json['sair_id'], 'cow-sire-002');
    });

    test('CowModel equality and hashCode comparison by id', () {
      const cow1 = CowModel(id: 'cow-100', tagId: 'TAG-1');
      const cow2 = CowModel(id: 'cow-100', tagId: 'TAG-1-DIFF');
      const cow3 = CowModel(id: 'cow-200', tagId: 'TAG-1');

      expect(cow1 == cow2, isTrue);
      expect(cow1 == cow3, isFalse);
      expect(cow1.hashCode, cow2.hashCode);
    });

    test('UserModel parses populated gaushala Map, gaushalaName and checks isAdmin', () {
      // 1. Populated gaushala Map
      final userJson = {
        '_id': 'USR-999',
        'name': 'Ayushka Admin',
        'email': 'admin@ayushka.com',
        'role': 'Admin',
        'gaushalaId': {
          '_id': '674f9a0c1234567890abcdef',
          'gaushalaName': 'ayushka_navsari',
        },
      };

      final user = UserModel.fromJson(userJson);
      expect(user.id, 'USR-999');
      expect(user.gaushalaId, '674f9a0c1234567890abcdef');
      expect(user.gaushalaName, 'ayushka_navsari');
      expect(user.isAdmin, isTrue);

      // 2. Regular user with string gaushala_id and non-admin role
      final staffJson = {
        '_id': 'USR-123',
        'name': 'Staff User',
        'email': 'staff@ayushka.com',
        'role': 'Farm Staff',
        'gaushala_id': '674f9a0c1234567890abcdef',
        'gaushala_name': 'ayushka_navsari',
      };

      final staff = UserModel.fromJson(staffJson);
      expect(staff.gaushalaId, '674f9a0c1234567890abcdef');
      expect(staff.gaushalaName, 'ayushka_navsari');
      expect(staff.isAdmin, isFalse);
    });

    test('StorageService persists and retrieves active selected gaushala ID', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      expect(storage.getSelectedGaushalaId(), isNull);

      await storage.saveSelectedGaushalaId('gaushala-navsari-101');
      expect(storage.getSelectedGaushalaId(), 'gaushala-navsari-101');

      await storage.removeSelectedGaushalaId();
      expect(storage.getSelectedGaushalaId(), isNull);
    });

    test('GaushalaModel JSON parsing and normalized slug matching', () {
      final gaushalas = [
        const GaushalaModel(id: '674f9a0c1234567890abcdef', gaushalaName: 'ayushka_navsari'),
        const GaushalaModel(id: '674f9a0c1234567890abcdeg', gaushalaName: 'surat_farm'),
      ];

      // Exact ID match
      final matchById = gaushalas.firstWhere((g) => g.id == '674f9a0c1234567890abcdef');
      expect(matchById.gaushalaName, 'ayushka_navsari');

      // Normalized slug match (slug with spaces/hyphens matching underscore name)
      const inputQuery = 'ayushka navsari';
      final cleanQuery = inputQuery.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '').toLowerCase();
      final matchByName = gaushalas.firstWhere((g) =>
          g.gaushalaName.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '').toLowerCase() == cleanQuery);
      expect(matchByName.id, '674f9a0c1234567890abcdef');
    });

    test('User default gaushala selection prioritizes user assigned gaushala over test gaushalas', () {
      final gaushalas = [
        const GaushalaModel(id: 'test-999', gaushalaName: 'Delete Died Test Gaushala'),
        const GaushalaModel(id: '674f9a0c1234567890abcdef', gaushalaName: 'ayushka_navsari'),
        const GaushalaModel(id: '674f9a0c1234567890abcdeg', gaushalaName: 'surat_farm'),
      ];

      // 1. User with assigned gaushala
      final user = UserModel.fromJson({
        '_id': 'usr-1',
        'name': 'Test User',
        'email': 'user@ayushka.com',
        'role': 'Admin',
        'gaushalaId': '674f9a0c1234567890abcdef',
        'gaushalaName': 'ayushka_navsari',
      });

      final matched = gaushalas.firstWhere(
        (g) => g.id == user.gaushalaId || g.gaushalaName.toLowerCase() == user.gaushalaName?.toLowerCase(),
      );
      expect(matched.gaushalaName, 'ayushka_navsari');
      expect(matched.gaushalaName, isNot('Delete Died Test Gaushala'));

      // 2. User with no assigned gaushala defaults to ayushka_navsari
      final adminNoGaushala = UserModel.fromJson({
        '_id': 'usr-admin',
        'name': 'Super Admin',
        'email': 'admin@ayushka.com',
        'role': 'Admin',
      });
      expect(adminNoGaushala.gaushalaId, isNull);

      final platformDefault = gaushalas.firstWhere(
        (g) => g.gaushalaName.toLowerCase().contains('ayushka'),
      );
      expect(platformDefault.gaushalaName, 'ayushka_navsari');
      expect(platformDefault.gaushalaName, isNot('Delete Died Test Gaushala'));
    });
  });

  group('Widget & Responsive UI Tests', () {
    testWidgets('CustomButton renders text and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Save Cattle',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Cattle'), findsOneWidget);
      await tester.tap(find.text('Save Cattle'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('ResponsiveLayout adapts to mobile and desktop constraints', (tester) async {
      // Test Desktop
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile View'),
            desktop: Text('Desktop View'),
          ),
        ),
      );

      expect(find.text('Desktop View'), findsOneWidget);
      expect(find.text('Mobile View'), findsNothing);

      // Test Mobile
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile View'),
            desktop: Text('Desktop View'),
          ),
        ),
      );

      expect(find.text('Mobile View'), findsOneWidget);
      expect(find.text('Desktop View'), findsNothing);

      // Reset
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('ResponsiveLayout invokes only active builder on demand', (tester) async {
      int mobileBuildCount = 0;
      int desktopBuildCount = 0;

      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobileBuilder: (context) {
              mobileBuildCount++;
              return const Text('Mobile Builder');
            },
            desktopBuilder: (context) {
              desktopBuildCount++;
              return const Text('Desktop Builder');
            },
          ),
        ),
      );

      expect(find.text('Desktop Builder'), findsOneWidget);
      expect(find.text('Mobile Builder'), findsNothing);
      expect(desktopBuildCount, 1);
      expect(mobileBuildCount, 0); // Mobile builder was never invoked!

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('CowPhotoSlider renders and contains breed information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CowPhotoSlider(height: 240),
          ),
        ),
      );

      // Verify Gir herd information is visible on the first slide
      expect(find.text('GIR HERD'), findsOneWidget);

      // Advance timer by 4.5 seconds to verify auto-play transition without error
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('WebSidebar renders collapsed and expanded without overflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 515);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: null,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test collapsed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: true,
                  onToggle: () {},
                  currentUser: null,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Test animation frames from collapsed to expanded
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Farm Overview'), findsNothing);

      // Re-expand with animation frames
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: null,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Farm Overview'), findsOneWidget);
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('WebSidebar collapsed hover reveals flyout submenu', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: true,
                  onToggle: () {},
                  currentUser: null,
                  onLogout: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final mastersIcon = find.byIcon(PhosphorIconsRegular.stack);
      expect(mastersIcon, findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(mastersIcon));
      await tester.pumpAndSettle();

      expect(find.text('MASTERS'), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Gaushalas'), findsOneWidget);
      expect(find.text('Sheds'), findsOneWidget);
      expect(find.text('Breeds'), findsOneWidget);
      expect(find.text('Types'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Pressing Enter key on password field triggers onSubmitted', (tester) async {
      bool submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                submitted = true;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextFormField);
      await tester.tap(textField);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('Enter key and Numpad Enter triggers callback via CallbackShortcuts', (tester) async {
      int enterCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.enter): () => enterCount++,
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () => enterCount++,
              },
              child: const Focus(
                autofocus: true,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(enterCount, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      expect(enterCount, 2);
    });

    testWidgets('CustomTableShimmer renders headers and shimmering rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTableShimmer(
              rowCount: 4,
              columnFlexes: [6, 6, 5],
              headers: ['#', 'BREED NAME', 'SYSTEM ID', 'CREATED AT'],
            ),
          ),
        ),
      );

      expect(find.text('#'), findsOneWidget);
      expect(find.text('BREED NAME'), findsOneWidget);
      expect(find.text('SYSTEM ID'), findsOneWidget);
      expect(find.text('CREATED AT'), findsOneWidget);
      expect(find.byType(CustomShimmer), findsOneWidget);
    });

    testWidgets('CustomListShimmer renders expected number of cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomListShimmer(itemCount: 5),
          ),
        ),
      );

      expect(find.byType(CustomShimmer), findsOneWidget);
      expect(find.byType(ShimmerPlaceholder), findsWidgets);
    });

    testWidgets('CustomBrandedSpinner renders loading message and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomBrandedSpinner(
              message: 'Loading cattle breeds...',
              size: LoaderSize.medium,
            ),
          ),
        ),
      );

      expect(find.text('Loading cattle breeds...'), findsOneWidget);
      expect(find.byType(CustomBrandedSpinner), findsOneWidget);
    });

    testWidgets('CustomInlineLoader renders with circular progress animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomInlineLoader(size: 16),
          ),
        ),
      );

      expect(find.byType(CustomInlineLoader), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CustomListLoader adapts properly to table and list mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomListLoader.table(
              itemCount: 3,
              headers: ['#', 'ITEM', 'CODE'],
              columnFlexes: [6, 4],
            ),
          ),
        ),
      );

      expect(find.byType(CustomTableShimmer), findsOneWidget);
      expect(find.text('ITEM'), findsOneWidget);
    });

    testWidgets('CustomTextField with isUpperCase converts entered text to uppercase in UI', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Tag ID *',
              hint: 'e.g. GIR-001',
              isUpperCase: true,
            ),
          ),
        ),
      );

      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'gir-001');
      await tester.pump();

      expect(controller.text, 'GIR-001');
      expect(find.text('GIR-001'), findsOneWidget);
    });

    test('FileDownloadHelper executes safely without throwing on non-web/test platforms', () async {
      expect(
        () => FileDownloadHelper.download(
          bytes: [1, 2, 3, 4],
          fileName: 'cow_import_template.xlsx',
        ),
        returnsNormally,
      );
    });

    test('formatBytes helper formats bytes accurately across units', () {
      String formatBytes(int bytes, [int decimals = 1]) {
        if (bytes <= 0) return '0 B';
        const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
        final i = (log(bytes) / log(1024)).floor();
        final clampedIndex = i.clamp(0, suffixes.length - 1);
        return '${(bytes / pow(1024, clampedIndex)).toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
      }

      expect(formatBytes(0), '0 B');
      expect(formatBytes(500), '500.0 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(13912), '13.6 KB');
      expect(formatBytes(1048576), '1.0 MB');
    });

    testWidgets('LogoutConfirmationDialog renders user details, warning note, cancel and sign out buttons', (WidgetTester tester) async {
      final user = UserModel(
        id: 'USR-201',
        name: 'Ayushka Admin',
        email: 'admin@ayushka.com',
        role: 'Super Admin',
      );

      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(
              currentUser: user,
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );

      expect(find.text('Sign Out Confirmation'), findsOneWidget);
      expect(find.text('Ayushka Admin'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Make sure all pending changes are saved before proceeding.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('WebSidebar clicking sign out icon button opens confirmation dialog', (WidgetTester tester) async {
      bool logoutCalled = false;
      final user = UserModel(
        id: 'USR-202',
        name: 'Farm Manager',
        email: 'manager@ayushka.com',
        role: 'Manager',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  isCollapsed: false,
                  onToggle: () {},
                  currentUser: user,
                  onLogout: () => logoutCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify sign out tooltip exists
      final signOutFinder = find.byTooltip('Sign Out');
      expect(signOutFinder, findsOneWidget);

      // Tap Sign Out icon button
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Dialog should now be open
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      expect(find.text('Sign Out Confirmation'), findsOneWidget);
      expect(find.text('Farm Manager'), findsWidgets);
      expect(logoutCalled, isFalse);

      // Tapping Sign Out in dialog should trigger logout
      await tester.tap(find.widgetWithText(CustomButton, 'Sign Out'));
      await tester.pumpAndSettle();
      expect(logoutCalled, isTrue);
    });

    testWidgets('MobileDrawer renders user profile and master navigation', (WidgetTester tester) async {
      final user = UserModel(
        id: 'USR-200',
        name: 'Aayush Farm Head',
        email: 'aayush@ayushka.com',
        role: 'Farm Admin',
        token: 'token_abc',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: MobileDrawer(
              currentUser: user,
              onLogout: () {},
            ),
            body: const Center(child: Text('Home')),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(MobileDrawer), findsOneWidget);
      expect(find.text('Aayush Farm Head'), findsOneWidget);
      expect(find.text('aayush@ayushka.com'), findsOneWidget);
      expect(find.text('Farm Overview'), findsOneWidget);
      expect(find.text('Herd & Cattle'), findsOneWidget);
      expect(find.text('MASTER CATALOGS'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
