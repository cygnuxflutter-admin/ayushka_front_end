import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ayushka/app/core/widgets/custom_text_field.dart';
import 'package:ayushka/app/core/widgets/custom_dropdown_search.dart';
import 'package:ayushka/app/modules/auth/auth_controller.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';

class MockApiService extends GetxService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStorageService extends GetxService implements StorageService {
  @override
  bool get isRememberMe => true;

  @override
  String? getSavedUserId() => 'testuser';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<ApiService>(MockApiService());
    Get.put<StorageService>(MockStorageService());
  });

  tearDown(() {
    Get.reset();
  });

  group('CustomTextField Resiliency Tests', () {
    testWidgets('CustomTextField renders safely even when passed a disposed TextEditingController', (tester) async {
      final disposedController = TextEditingController(text: 'secret');
      disposedController.dispose();

      // Passing a disposed controller would normally crash with
      // "A TextEditingController was used after being disposed."
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              controller: disposedController,
              isPassword: true,
            ),
          ),
        ),
      );

      // Verify no exception was thrown and widget rendered
      expect(find.text('Password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomTextField renders safely even when passed a disposed FocusNode', (tester) async {
      final disposedFocusNode = FocusNode();
      disposedFocusNode.dispose();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Username',
              focusNode: disposedFocusNode,
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomTextField uppercase feature works safely with effective controller', (tester) async {
      final controller = TextEditingController(text: 'lowercase');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Code',
              controller: controller,
              isUpperCase: true,
            ),
          ),
        ),
      );

      expect(controller.text, 'LOWERCASE');
      expect(tester.takeException(), isNull);
    });
  });

  group('AuthController Auto-Recovery Tests', () {
    test('AuthController automatically heals and recreates controllers if accessed after onClose', () {
      final authController = Get.put(AuthController());

      expect(authController.userIdController.text, 'testuser');
      authController.passwordController.text = '123456';

      // Simulate controller being closed
      authController.onClose();

      // Accessing getters should NOT return dead controllers or throw exceptions;
      // it should automatically re-create fresh, live controllers!
      expect(authController.userIdController, isNotNull);
      expect(authController.passwordController, isNotNull);

      // We should be able to read and write without any "used after being disposed" error
      authController.userIdController.text = 'recovered_user';
      authController.passwordController.text = 'new_password';

      expect(authController.userIdController.text, 'recovered_user');
      expect(authController.passwordController.text, 'new_password');
    });
  });

  group('CustomDropdownSearch Stability Tests', () {
    testWidgets('CustomDropdownSearch renders with stable key and selected item', (tester) async {
      final items = ['Option A', 'Option B', 'Option C'];
      String? selected = 'Option A';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDropdownSearch<String>(
              label: 'Test Dropdown',
              items: items,
              itemAsString: (item) => item,
              selectedItem: selected,
              onChanged: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('Test Dropdown'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
