import 'package:get/get.dart';

import '../models/usage.dart';
import '../screens/add_product_screen.dart';
import '../screens/add_usage_screen.dart';
import '../screens/home_screen.dart';
import '../screens/pond_details_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(
      name: AppRoutes.pondDetails,
      page: () {
        final args = Get.arguments;
        if (args is int) {
          return PondDetailsScreen(pondId: args);
        }
        if (args is Map) {
          final pondId = args['pondId'] as int? ?? 1;
          return PondDetailsScreen(pondId: pondId);
        }
        return const PondDetailsScreen(pondId: 1);
      },
    ),
    GetPage(
      name: AppRoutes.addUsage,
      page: () {
        final args = Get.arguments;
        if (args is Map) {
          return AddUsageScreen(
            pondId: args['pondId'] as int?,
            productType: args['productType'] as String?,
            initialUsage: args['initialUsage'] as Usage?,
            usageId: args['usageId'] as String?,
          );
        }
        return const AddUsageScreen();
      },
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () {
        final args = Get.arguments;
        if (args is Map) {
          return AddProductScreen(productType: args['productType'] as String?);
        }
        if (args is String) {
          return AddProductScreen(productType: args);
        }
        return const AddProductScreen();
      },
    ),
  ];
}
