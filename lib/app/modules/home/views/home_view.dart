import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final ctl = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Print Service'),
        centerTitle: true,
        leading: Tooltip(
          message: "登出",
          child: IconButton(
            tooltip: "退出登錄",
            onPressed: () {
              showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: const Text('系統提示'),
                      content: const Text('確認退出登錄嗎?'),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: const Text('取消'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          child: const Text('確認'),
                          onPressed: () async {
                            await ctl.closeService();
                            final box = GetStorage();
                            box.remove("hasLOgin");
                            Get.offAllNamed(Routes.LOGIN);
                          },
                        ),
                      ],
                    );
                  });
            },
            icon: const Icon(Icons.login_outlined),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              Get.toNamed(Routes.IP_PING);
            },
            icon: const Icon(Icons.cast_connected),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(() => Text(
                  ctl.isRunning.value
                      ? 'service is running'
                      : "service is not running",
                  style: const TextStyle(fontSize: 30),
                )),
            const SizedBox(height: 10),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: const Text('开始'),
                  onPressed: () async {
                    await ctl.startService();
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('关闭'),
                  onPressed: () async {
                    await ctl.closeService();
                  },
                ),
                /* ElevatedButton(
                  child: const Text('获取存储信息'),
                  onPressed: () async {
                    print(ctl.getLoginInfo());
                  },
                ) */
              ],
            ),
          ],
        ),
      ),
    );
  }
}





/*

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openhiit_background_service/openhiit_background_service.dart';
import 'package:openhiit_background_service_android/openhiit_background_service_android.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = OpenhiitBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // test using external plugin

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
      },
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final service = OpenhiitBackgroundService();
  bool isRunning = false;
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    checkServiceStatus();
    service.on('update').listen((event) {
      setState(() {
        currentDate = event!["current_date"];
      });
    });
  }

  void checkServiceStatus() async {
    bool? isRunning = await service.isRunning();
    setState(() {
      this.isRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Service App'),
        ),
        body: Container(
          color: Colors.red,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(currentDate.toString()),
              ElevatedButton(
                child: Text(isRunning ? "stop service" : "start service"),
                onPressed: () {
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }
                  setState(() {
                    isRunning = !isRunning;
                  });
                },
              ),
            ],
          ),
        ),
        /* body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(currentDate.toString()),
              ElevatedButton(
                child: Text(isRunning ? "stop service" : "start service"),
                onPressed: () {
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }
                  setState(() {
                    isRunning = !isRunning;
                  });
                },
              ),
            ],
          ),
        ), */
      ),
    );
  }
}

 */