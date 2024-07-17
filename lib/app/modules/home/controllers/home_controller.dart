import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../model/login_model.dart';

class HomeController extends GetxController {
  final _service = FlutterBackgroundService();
  RxBool isRunning = false.obs;
  @override
  void onInit() {
    checkServicRuning();
    super.onInit();
  }

  @override
  void onClose() {
    closeService();
    super.onClose();
  }

  Future closeService() async {
    var ret = await _service.isRunning();
    if (ret) {
      _service.invoke("stopService");
      isRunning.value = false;
    }
  }

  Future startService() async {
    var ret = await _service.isRunning();
    if (!ret) {
      _service.startService();
      isRunning.value = true;
    }
  }

  Future<void> checkServicRuning() async {
    isRunning.value = await _service.isRunning();
  }

  UserData? getLoginInfo() {
    final GetStorage box = GetStorage();
    var loginUserJson = box.read("loginInfo");
    UserData? loginUser =
        loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }
}
