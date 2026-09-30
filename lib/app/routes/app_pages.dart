import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_screen.dart';
import '../modules/breed/breed_binding.dart';
import '../modules/breed/breed_screen.dart';
import '../modules/cow/add_cow_binding.dart';
import '../modules/cow/add_cow_screen.dart';
import '../modules/cow/cow_binding.dart';
import '../modules/cow/cow_screen.dart';
import '../modules/dashboard/dashboard_binding.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/gaushala/gaushala_binding.dart';
import '../modules/gaushala/gaushala_screen.dart';
import '../modules/role/role_binding.dart';
import '../modules/role/role_screen.dart';
import '../modules/shed/shed_binding.dart';
import '../modules/shed/shed_screen.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/type/type_binding.dart';
import '../modules/type/type_screen.dart';
import '../modules/user/user_binding.dart';
import '../modules/user/user_screen.dart';
import 'app_routes.dart';

/// Centralized route registry configuring pages, bindings, and transitions.
class AppPages {
  AppPages._();

  static const initial = AppRoutes.initial;

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: kIsWeb ? Transition.fadeIn : Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthScreen(),
      binding: AuthBinding(),
      transition: kIsWeb ? Transition.fadeIn : Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.roles,
      page: () => const RoleScreen(),
      binding: RoleBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UserScreen(),
      binding: UserBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.gaushalas,
      page: () => const GaushalaScreen(),
      binding: GaushalaBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.sheds,
      page: () => const ShedScreen(),
      binding: ShedBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.breeds,
      page: () => const BreedScreen(),
      binding: BreedBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.types,
      page: () => const TypeScreen(),
      binding: TypeBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.cows,
      page: () => const CowScreen(),
      binding: CowBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.addCow,
      page: () => const AddCowScreen(),
      binding: AddCowBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.editCow,
      page: () => const AddCowScreen(),
      binding: AddCowBinding(),
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
  ];
}

