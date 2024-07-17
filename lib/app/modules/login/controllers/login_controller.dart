import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../routes/app_pages.dart';
import '../../../service/api_client.dart';
import '../../../utils/easy_loding.dart';

class LoginController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  final box = GetStorage();
  final ApiClient apiClient = ApiClient();
  RxBool isCheck = true.obs;

  final count = 0.obs;
  @override
  void onInit() {
    getLoginInfo();
    super.onInit();
  }

  @override
  void onClose() {
    companyController.dispose();
    userController.dispose();
    pwdController.dispose();
    super.onClose();
  }

  void login() async {
    if (formKey.currentState!.validate()) {
      showLoding('登錄中...');
      var loginForm = formKey.currentState;
      loginForm!.validate();
      Map<String, dynamic> loginData = {
        "company": companyController.text,
        'user': userController.text,
        'pwd': pwdController.text,
      };

      try {
        Response response = await apiClient.post(Config.login, data: loginData);

        if (response.statusCode == 200) {
          LoginModel ret = LoginModel.fromJson(response.data);

          if (ret.status == 200) {
            box.remove("loginInfo");
            box.write("hasLogin", true);

            if (isCheck.value) {
              box.write("loginInfo", ret.data!.toJson());
            }

            Future.delayed(const Duration(milliseconds: 1000), () {
              Get.offAllNamed(Routes.HOME);
            });
            successLoding('登錄成功');
          } else {
            errorLoding('${ret.info}');
          }
        } else {
          errorLoding('登錄失敗');
        }
      } on DioException {
        errorLoding('请求错误');
      }
    }
  }

  void getLoginInfo() {
    var loginUserJson = box.read("loginInfo");
    UserData? loginUser =
        loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      companyController.text = loginUser.company ?? '';
      userController.text = loginUser.userCode ?? '';
      pwdController.text = loginUser.pwd ?? '';
    }
  }
}
