import 'package:get/get.dart';

import '../controllers/pond_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PondController>()) {
      Get.put<PondController>(PondController(), permanent: true);
    }
  }
}
