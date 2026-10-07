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
import '../modules/feed_item/feed_item_binding.dart';
import '../modules/feed_item/feed_item_screen.dart';
import '../modules/feed_stock_transaction/feed_stock_transaction_binding.dart';
import '../modules/feed_stock_transaction/feed_stock_transaction_screen.dart';
import '../modules/medical_stock/medical_stock_binding.dart';
import '../modules/medical_stock/medical_stock_screen.dart';
import '../modules/module_management/module_binding.dart';
import '../modules/module_management/module_screen.dart';
import '../modules/role/role_binding.dart';
import '../modules/role/role_screen.dart';
import '../modules/shed/shed_binding.dart';
import '../modules/shed/shed_screen.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/treatment/treatment_binding.dart';
import '../modules/treatment/treatment_details_binding.dart';
import '../modules/treatment/treatment_details_screen.dart';
import '../modules/treatment/treatment_list_screen.dart';
import '../modules/type/type_binding.dart';
import '../modules/type/type_screen.dart';
import '../modules/user/user_binding.dart';
import '../modules/user/user_screen.dart';
import '../modules/worker/worker_binding.dart';
import '../modules/worker/worker_screen.dart';
import '../modules/milk/milk_binding.dart';
import '../modules/milk/milk_main_view.dart';
import '../modules/forbidden/forbidden_screen.dart';
import '../../screens/user_permissions_screen.dart';
import 'app_routes.dart';
import 'permission_middleware.dart';

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
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.roles)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UserScreen(),
      binding: UserBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.users)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.userPermissions,
      page: () => const UserPermissionsScreen(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.userPermissions)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.moduleManagement,
      page: () => const ModuleScreen(),
      binding: ModuleBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.moduleManagement)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.gaushalas,
      page: () => const GaushalaScreen(),
      binding: GaushalaBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.gaushalas)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.sheds,
      page: () => const ShedScreen(),
      binding: ShedBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.sheds)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.breeds,
      page: () => const BreedScreen(),
      binding: BreedBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.breeds)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.types,
      page: () => const TypeScreen(),
      binding: TypeBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.types)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.feedItems,
      page: () => const FeedItemScreen(),
      binding: FeedItemBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.feedItems)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.feedTransactions,
      page: () => const FeedStockTransactionScreen(),
      binding: FeedStockTransactionBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.feedTransactions)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.cows,
      page: () => const CowScreen(),
      binding: CowBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.cows)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.addCow,
      page: () => const AddCowScreen(),
      binding: AddCowBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.addCow)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.editCow,
      page: () => const AddCowScreen(),
      binding: AddCowBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.editCow)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.medicalStock,
      page: () => const MedicalStockScreen(),
      binding: MedicalStockBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.medicalStock)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.treatments,
      page: () => const TreatmentListScreen(),
      binding: TreatmentBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.treatments)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.treatmentDetails,
      page: () => const TreatmentDetailsScreen(),
      binding: TreatmentDetailsBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.treatmentDetails)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.workers,
      page: () => const WorkerScreen(),
      binding: WorkerBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.workers)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.departments,
      page: () => const WorkerScreen(),
      binding: WorkerBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.departments)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.milk,
      page: () => const MilkMainView(),
      binding: MilkBinding(),
      middlewares: [RoutePermissionRegistry.forRoute(AppRoutes.milk)],
      transition: kIsWeb ? Transition.noTransition : Transition.cupertino,
      transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.forbidden,
      page: () => const ForbiddenScreen(),
      transition: kIsWeb ? Transition.fadeIn : Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];
}

