import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/user_model.dart';

void main() {
  group('UserModel Super Admin Identification Tests', () {
    test('Identifies Superadmin by role string', () {
      const user = UserModel(
        id: 'user_1',
        name: 'Super Admin',
        email: 'superadmin@gmail.com',
        role: 'Superadmin',
        username: 'super_admin',
      );
      expect(user.isSuperAdmin, isTrue);
    });

    test('Identifies Superadmin with spaces or hyphens in role', () {
      const user = UserModel(
        id: 'user_2',
        name: 'Main Admin',
        email: 'admin2@gmail.com',
        role: 'Super Admin',
      );
      expect(user.isSuperAdmin, isTrue);
    });

    test('Identifies Superadmin by username', () {
      const user = UserModel(
        id: 'user_3',
        name: 'Some User',
        email: 'user@gmail.com',
        role: 'Admin',
        username: 'superadmin',
      );
      expect(user.isSuperAdmin, isTrue);
    });

    test('Identifies Superadmin by email', () {
      const user = UserModel(
        id: 'user_4',
        name: 'Admin Name',
        email: 'superadmin@example.org',
        role: 'CustomRole',
      );
      expect(user.isSuperAdmin, isTrue);
    });

    test('Regular admin is NOT Super Admin', () {
      const user = UserModel(
        id: 'user_5',
        name: 'Navsari Admin',
        email: 'admin@gmail.com',
        role: 'Admin',
        username: 'Navsari_admin',
      );
      expect(user.isSuperAdmin, isFalse);
    });
  });
}
