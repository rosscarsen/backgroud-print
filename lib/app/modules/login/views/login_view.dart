import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    final ctl = Get.put(LoginController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('登錄'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Form(
            key: ctl.formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                //公司
                TextInput(
                  prefixIcon: Icons.apartment,
                  inputController: ctl.companyController,
                  lableText: "公司",
                ),
                const SizedBox(height: 15),
                //用戶
                TextInput(
                    prefixIcon: Icons.person,
                    inputController: ctl.userController,
                    lableText: "用戶"),
                const SizedBox(height: 15),
                //密碼
                TextInput(
                  prefixIcon: Icons.verified_user,
                  inputController: ctl.pwdController,
                  lableText: "密碼",
                ),
                const SizedBox(height: 15),
                Obx(() {
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "記住密碼",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    value: ctl.isCheck.value,
                    onChanged: ((value) {
                      ctl.isCheck.value = value!;
                    }),
                  );
                }),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color.fromARGB(66, 30, 29, 29);
                      }
                      return const Color.fromARGB(255, 59, 137, 62);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white54;
                      }
                      return Colors.white;
                    }),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                    ),
                  ),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ctl.login();
                  },
                  child: const Text(
                    "登錄",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextInput extends StatelessWidget {
  final TextEditingController inputController;
  final String lableText;
  final IconData prefixIcon;

  const TextInput({
    super.key,
    required this.inputController,
    required this.lableText,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: UniqueKey(),
      controller: inputController,
      style: TextStyle(color: Colors.grey[900], fontSize: 18),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.only(left: 0, right: 0, top: 16, bottom: 20),
        hintText: lableText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          onPressed: () {
            inputController.clear();
          },
          icon: const Icon(
            Icons.cancel,
            size: 18,
          ),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return "必填項，不能為空";
        }
        return null;
      },
    );
  }
}
