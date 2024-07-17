import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../config.dart';
import '../../../model/ip_ping.dart';
import '../../../model/login_model.dart';
import '../../../service/api_client.dart';
import '../../../utils/easy_loding.dart';

class IpPingController extends GetxController {
  final apiCli = ApiClient();
  GetStorage box = GetStorage();
  RxList<IpData> allIp = <IpData>[].obs;
  RxBool loadding = false.obs;
  Future<void> getAllIP() async {
    UserData? loginUser = getLoginInfo();
    if (loginUser != null) {
      try {
        loadding(true);
        Map<String, dynamic> queryData = {
          "dsn": loginUser.dsn!.toJson(),
          "company": loginUser.company
        };
        var response = await apiCli.post(Config.getAllLocalIP, data: queryData);
        if (response.statusCode == 200) {
          final ipPing = ipPingFromJson(json.encode(response.data));
          if (ipPing.state == 200) {
            allIp.value = ipPing.data;
          }
        }
      } catch (e) {
        print(e);
      } finally {
        loadding(false);
      }
    }
  }

  UserData? getLoginInfo() {
    var loginUserJson = box.read("loginInfo");
    UserData? loginUser =
        loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }

  Future<void> testConnection(String host, {int port = 80}) async {
    showLoding("$host正在連接中，請稍候...");
    try {
      final socket =
          await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      successLoding("$host連接成功");
    } catch (e) {
      successLoding("$host連接失敗");
    }
  }
}
