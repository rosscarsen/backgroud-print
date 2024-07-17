import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/service/backgroun_print_sevices.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initializeService();

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Print",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: (context, child) {
        //加载框
        final easyLoading = EasyLoading.init();
        child = easyLoading(context, child);

        //设置文字大小不随系统设置改变
        child = MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child,
        );
        return child;
      },
    ),
  );
}
