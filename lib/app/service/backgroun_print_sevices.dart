import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart';

import '../config.dart';
import '../model/login_model.dart';
import '../model/printer_model.dart';
import '../utils/esc_help.dart';

final box = GetStorage();

///打印状态
bool printStatus = true;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
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
  //DartPluginRegistrant.ensureInitialized();
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

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    print("任务执行中,当前打印状态:$printStatus");
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Printer Service running",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }
    UserData? loginUser = getLoginInfo();

    if (loginUser != null) {
      Map<String, dynamic> queryData = {
        "dsn": loginUser.dsn!.toJson(),
        "company": loginUser.company
      };

      if (printStatus) {
        getData(queryData: queryData);
      }
    }
  });
}

///获取本地存储信息
UserData? getLoginInfo() {
  var loginUserJson = box.read("loginInfo");
  UserData? loginUser =
      loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
  if (loginUser != null) {
    return loginUser;
  }
  return null;
}

///获取单数据
void getData({required Map<String, dynamic> queryData}) async {
  printStatus = false;
  try {
    Dio dio = Dio();
    dio.options.baseUrl = Config.baseurl;
    dio.options.contentType = "application/json; charset=utf-8";
    dio.options.validateStatus = (status) => status != null;
    var response = await dio.get(Config.getData, queryParameters: queryData);
    if (response.statusCode == 200) {
      if (response.data != null) {
        PrinterModel ret = PrinterModel.fromJson(response.data);
        const PaperSize paper = PaperSize.mm80;
        final profile = await CapabilityProfile.load();
        final printer = NetworkPrinter(paper, profile);
        print("===>$ret");
        bool anyExecuted = false;
        if (ret.upperMenu != null) {
          ///打印上菜单
          anyExecuted = true;
          await printUpper(printer, ret.upperMenu!);
          anyExecuted = false;
        }
        if (ret.receipt != null) {
          ///打印收据
          anyExecuted = true;
          await printReceipt(printer, ret.receipt!);
          anyExecuted = false;
        }
        if (ret.customerRecord != null) {
          ///打印客户记录
          anyExecuted = true;
          await printCustomerRecord(printer, ret.customerRecord!);
          anyExecuted = false;
        }
        if (ret.qrCodeData != null) {
          ///打印QR
          anyExecuted = true;
          await printQrCode(printer, ret.qrCodeData!);
          anyExecuted = false;
        }
        if (ret.kitchen != null) {
          ///打印厨房水吧和班地尼
          ///组装打印厨房数据
          anyExecuted = true;

          Map<String?, List<Kitchen>> ipGroup =
              groupBy(ret.kitchen!, (Kitchen rows) => rows.mLanIP);
          final Map<String, Map<int, List<Kitchen>>> printData = {};
          ipGroup.forEach(
            (ip, value) => printData.putIfAbsent(
              ip!,
              () => groupBy(value, (Kitchen rows) => rows.mContinue!),
            ),
          );
          printData.removeWhere((key, value) => key.isEmpty);

          //打印厨房单
          if (printData.isNotEmpty) {
            await printkichen(printer, printData, ret.isPrintPrice!);
          }

          ///组装打印班地尼数据
          Map<String?, List<Kitchen>> bDLGroup =
              groupBy(ret.kitchen!, (Kitchen rows) => rows.bDLLanIP);
          final Map<String, Map<int, List<Kitchen>>> bDLPrintData = {};
          bDLGroup.forEach(
            (ip, value) => bDLPrintData.putIfAbsent(
              ip!,
              () => groupBy(value, (Kitchen rows) => rows.mNonContinue!),
            ),
          );
          bDLPrintData.removeWhere((key, value) => key.isEmpty);
          // print("班地尼:$bDLPrintData");
          //打印类目班地尼
          if (bDLPrintData.isNotEmpty) {
            await printBDL(printer, bDLPrintData, ret.isPrintPrice!);
          }
          anyExecuted = false;
        }
        if (!anyExecuted) {
          printStatus = true;
        }
      } else {
        printStatus = true;
      }
    }
  } on DioException catch (e) {
    print('Dio數據请求错误:${e.message}');
    printStatus = true;
  } catch (e) {
    print('數據请求错误:${e.toString()}');
    printStatus = true;
  }
}

///开始打印厨房单
Future<void> printkichen(NetworkPrinter printer,
    Map<String, Map<int, List<Kitchen>>> printData, int isPrintPrice) async {
  printData.forEach((key, item) async {
    printStatus = false;
    if (key.isNotEmpty) {
      final PosPrintResult linkret = await printer.connect(key, port: 9100);
      late List mInvoiceDetailID = [];
      if (PosPrintResult.success == linkret) {
        item.forEach((iscontinue, value) async {
          printStatus = false;
          if (iscontinue == 0) {
            for (int i = 0; i < value.length; i++) {
              mInvoiceDetailID.add(value[i].mInvoiceDetailID);
              //台号
              if (value[i].mPrinterType == "EPSON") {
                printer.text(
                  EscHelper.alginCeterPrint(
                      width: 48, content: "檯:${value[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              } else {
                printer.text(
                  "檯:${value[i].mTableNo}",
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              }

              if (value[i].mPrinterType != "" &&
                  value[i].mPrinterType == "EPSON") {
                printer.feed(4);
              }
              //单号
              printer.row([
                PosColumn(
                    text: "${value[0].mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true,
                    )),
                PosColumn(
                    text: "單號：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true,
                    )),
                PosColumn(
                    text: "${value[0].mInvoiceNo}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ))
              ]);

              //日期人数
              printer.row([
                PosColumn(
                    text: "${value[0].invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${value[0].invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "人數：",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${value[0].mPnum}",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      align: PosAlign.left,
                    )),
              ]);
              if (value[i].mPrinterType != "" &&
                  value[i].mPrinterType == "EPSON") {
                printer.feed(2);
              } else {
                printer.feed(1);
              }
              //名称
              var printName = EscHelper.strToList(
                  str: value[i].mBarcodeName!, splitLenth: 20);

              if (printName.isNotEmpty) {
                for (int j = 0; j < printName.length; j++) {
                  if (j == 0) {
                    printer.text(
                        '${value[i].mQty}${EscHelper.fillSpace(4 - EscHelper.strWidth(value[i].mQty))}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  } else if (printName[j].isNotEmpty) {
                    printer.text(
                        '${EscHelper.fillSpace(4)}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }
              //备注
              if (value[i].mRemarks != '') {
                var printRemarks = EscHelper.strToList(
                    str: value[i].mRemarks ?? "", splitLenth: 20);
                if (printRemarks.isNotEmpty) {
                  for (int k = 0; k < printRemarks.length; k++) {
                    printer.text(
                        '${EscHelper.fillSpace(value[i].mPrinterType == "EPSON" ? 4 : 5)}${printRemarks[k]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printRemarks[k]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }

              //价格
              if (isPrintPrice == 0) {
                if (value[i].mPrinterType == "EPSON") {
                  printer.text(
                    "${EscHelper.fillSpace(24 - EscHelper.strWidth("\$${value[i].mPrice}"))}\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                } else {
                  printer.text(
                    "\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right,
                    ),
                  );
                }
              }
              if (value[i].mPrinterType != "" &&
                  value[i].mPrinterType == "EPSON") {
                printer.feed(5);
              } else {
                printer.feed(1);
              }
              //台号
              if (value[i].mPrinterType == "EPSON") {
                printer.text(
                  EscHelper.alginCeterPrint(
                      width: 48, content: "檯:${value[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              } else {
                printer.text(
                  "檯:${value[i].mTableNo}",
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              }
              if (value[i].mPrinterType != "" &&
                  value[i].mPrinterType == "EPSON") {
                printer.feed(18);
              } else {
                printer.feed(1);
              }
              printer.cut();
              printStatus = true;
            }
            editstatus(mInvoiceDetailID);
          } else {
            ///连续打印

            //台号
            if (value[0].mPrinterType == "EPSON") {
              printer.text(
                EscHelper.alginCeterPrint(
                    width: 48, content: "檯:${value[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  bold: true,
                ),
                containsChinese: true,
              );
            } else {
              printer.text(
                "檯:${value[0].mTableNo}",
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                  bold: true,
                ),
                containsChinese: true,
              );
            }

            if (value[0].mPrinterType != "" &&
                value[0].mPrinterType == "EPSON") {
              printer.feed(4);
            }
            //单号
            printer.row([
              PosColumn(
                  text: "${value[0].mStationCode}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "單號：",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].mInvoiceNo}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size2,
                    height: PosTextSize.size2,
                    bold: true,
                  ))
            ]);
            //日期人数
            printer.row([
              PosColumn(
                  text: "${value[0].invoiceDate}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].invoiceTime}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "人數：",
                  width: 2,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].mPnum}",
                  width: 2,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    align: PosAlign.left,
                    bold: true,
                  )),
            ]);
            if (value[0].mPrinterType != "" &&
                value[0].mPrinterType == "EPSON") {
              printer.feed(2);
            } else {
              printer.feed(1);
            }
            for (int i = 0; i < value.length; i++) {
              printStatus = false;
              mInvoiceDetailID.add(value[i].mInvoiceDetailID);

              //名称
              var printName = EscHelper.strToList(
                  str: value[i].mBarcodeName ?? "", splitLenth: 20);

              if (printName.isNotEmpty) {
                for (int j = 0; j < printName.length; j++) {
                  if (i == 0) {
                    printer.text(
                        '${value[i].mQty}${EscHelper.fillSpace(4 - EscHelper.strWidth(value[i].mQty))}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  } else if (printName[j].isNotEmpty) {
                    printer.text(
                        '${EscHelper.fillSpace(4)}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }
              //备注
              if (value[i].mRemarks != '') {
                var printRemarks = EscHelper.strToList(
                    str: value[i].mRemarks ?? "", splitLenth: 20);
                if (printRemarks.isNotEmpty) {
                  for (int k = 0; k < printRemarks.length; k++) {
                    printer.text(
                        '${EscHelper.fillSpace(value[i].mPrinterType == "EPSON" ? 4 : 5)}${printRemarks[k]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printRemarks[i]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }

              //价格
              if (isPrintPrice == 0) {
                if (value[i].mPrinterType == "EPSON") {
                  printer.text(
                    "${EscHelper.fillSpace(24 - EscHelper.strWidth("\$${value[i].mPrice}"))}\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                } else {
                  printer.text(
                    "\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right,
                    ),
                  );
                }
              }
              if (value[i].mPrinterType != "" &&
                  value[i].mPrinterType == "EPSON") {
                printer.feed(5);
              } else {
                printer.feed(1);
              }
            }
            //台号
            if (value[0].mPrinterType == "EPSON") {
              printer.text(
                EscHelper.alginCeterPrint(
                    width: 48, content: "檯:${value[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  bold: true,
                ),
                containsChinese: true,
              );
            } else {
              printer.text(
                "檯:${value[0].mTableNo}",
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                  bold: true,
                ),
                containsChinese: true,
              );
            }
            if (value[0].mPrinterType != "" &&
                value[0].mPrinterType == "EPSON") {
              printer.feed(18);
            }
            printer.cut();
            printStatus = true;
            //修改发票明细状态
            editstatus(mInvoiceDetailID);
          }
        });
        printer.disconnect();
        printStatus = true;
      } else {
        print("打印機$key連接失敗");
        printStatus = true;
      }
    } else {
      printStatus = true;
    }
  });
}

///开始打印班地尼
Future<void> printBDL(NetworkPrinter printer,
    Map<String, Map<int, List<Kitchen>>> printData, int isPrintPrice) async {
  printData.forEach((key, item) async {
    printStatus = false;
    if (key.isNotEmpty) {
      final PosPrintResult linkret = await printer.connect(key, port: 9100);
      late List mInvoiceDetailID = [];
      if (PosPrintResult.success == linkret) {
        item.forEach((iscontinue, value) async {
          printStatus = false;
          if (iscontinue == 1) {
            for (int i = 0; i < value.length; i++) {
              mInvoiceDetailID.add(value[i].mInvoiceDetailID);
              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.text(
                  EscHelper.alginCeterPrint(width: 48, content: "上菜单"),
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                  ),
                  containsChinese: true,
                );
              } else {
                printer.text(
                  "上菜单",
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              }
              printer.feed(value[i].bDLPrinterType == "EPSON" ? 3 : 1);
              //台号
              if (value[i].bDLPrinterType == "EPSON") {
                printer.text(
                  EscHelper.alginCeterPrint(
                      width: 48, content: "檯:${value[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              } else {
                printer.text(
                  "檯:${value[i].mTableNo}",
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              }

              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.feed(4);
              }
              //单号
              printer.row([
                PosColumn(
                    text: "${value[0].mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true,
                    )),
                PosColumn(
                    text: "單號：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true,
                    )),
                PosColumn(
                    text: "${value[0].mInvoiceNo}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ))
              ]);

              //日期人数
              printer.row([
                PosColumn(
                    text: "${value[0].invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${value[0].invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "人數：",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(
                        width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${value[0].mPnum}",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      align: PosAlign.left,
                    )),
              ]);
              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.feed(2);
              } else {
                printer.feed(1);
              }
              //名称
              var printName = EscHelper.strToList(
                  str: value[i].mBarcodeName!, splitLenth: 20);

              if (printName.isNotEmpty) {
                for (int i = 0; i < printName.length; i++) {
                  if (i == 0) {
                    printer.text(
                        '${value[i].mQty}${EscHelper.fillSpace(4 - EscHelper.strWidth(value[i].mQty))}${printName[i]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[i]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  } else {
                    printer.text(
                        '${EscHelper.fillSpace(4)}${printName[i]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[i]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }
              //备注
              if (value[i].mRemarks != '') {
                var printRemarks = EscHelper.strToList(
                    str: value[i].mRemarks ?? "", splitLenth: 20);
                if (printRemarks.isNotEmpty) {
                  for (int j = 0; j < printRemarks.length; j++) {
                    printer.text(
                        '${EscHelper.fillSpace(value[i].bDLPrinterType == "EPSON" ? 4 : 5)}${printRemarks[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printRemarks[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }

              //价格
              if (isPrintPrice == 0) {
                if (value[i].bDLPrinterType == "EPSON") {
                  printer.text(
                    "${EscHelper.fillSpace(24 - EscHelper.strWidth("\$${value[i].mPrice}"))}\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                } else {
                  printer.text(
                    "\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right,
                    ),
                  );
                }
              }
              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.feed(5);
              } else {
                printer.feed(1);
              }
              //台号
              if (value[i].bDLPrinterType == "EPSON") {
                printer.text(
                  EscHelper.alginCeterPrint(
                      width: 48, content: "檯:${value[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              } else {
                printer.text(
                  "檯:${value[i].mTableNo}",
                  linesAfter: 1,
                  styles: const PosStyles(
                    width: PosTextSize.size3,
                    height: PosTextSize.size3,
                    align: PosAlign.center,
                    bold: true,
                  ),
                  containsChinese: true,
                );
              }
              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.feed(18);
              } else {
                printer.feed(1);
              }
              printer.cut();
              printStatus = true;
            }
            editstatus(mInvoiceDetailID);
          } else {
            ///连续打印
            if (value[0].bDLPrinterType != "" &&
                value[0].bDLPrinterType == "EPSON") {
              printer.text(
                EscHelper.alginCeterPrint(width: 48, content: "上菜单"),
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                ),
                containsChinese: true,
              );
            } else {
              printer.text(
                "上菜单",
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                  bold: true,
                ),
                containsChinese: true,
              );
            }
            printer.feed(value[0].bDLPrinterType == "EPSON" ? 3 : 1);
            //台号
            if (value[0].bDLPrinterType == "EPSON") {
              printer.text(
                EscHelper.alginCeterPrint(
                    width: 48, content: "檯:${value[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  bold: true,
                ),
                containsChinese: true,
              );
            } else {
              printer.text(
                "檯:${value[0].mTableNo}",
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                  bold: true,
                ),
                containsChinese: true,
              );
            }

            if (value[0].bDLPrinterType != "" &&
                value[0].bDLPrinterType == "EPSON") {
              printer.feed(4);
            }
            //单号
            printer.row([
              PosColumn(
                  text: "${value[0].mStationCode}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "單號：",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].mInvoiceNo}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size2,
                    height: PosTextSize.size2,
                    bold: true,
                  ))
            ]);
            //日期人数
            printer.row([
              PosColumn(
                  text: "${value[0].invoiceDate}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].invoiceTime}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "人數：",
                  width: 2,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    bold: true,
                  )),
              PosColumn(
                  text: "${value[0].mPnum}",
                  width: 2,
                  containsChinese: true,
                  styles: const PosStyles(
                    width: PosTextSize.size1,
                    height: PosTextSize.size2,
                    align: PosAlign.left,
                    bold: true,
                  )),
            ]);
            if (value[0].bDLPrinterType != "" &&
                value[0].bDLPrinterType == "EPSON") {
              printer.feed(2);
            } else {
              printer.feed(1);
            }
            for (int i = 0; i < value.length; i++) {
              printStatus = false;
              mInvoiceDetailID.add(value[i].mInvoiceDetailID);

              //名称
              var printName = EscHelper.strToList(
                  str: value[i].mBarcodeName ?? "", splitLenth: 20);

              if (printName.isNotEmpty) {
                for (int j = 0; j < printName.length; j++) {
                  if (j == 0) {
                    printer.text(
                        '${value[i].mQty}${EscHelper.fillSpace(4 - EscHelper.strWidth(value[i].mQty))}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  } else if (printName[j].isNotEmpty) {
                    printer.text(
                        '${EscHelper.fillSpace(4)}${printName[j]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printName[j]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }
              //备注
              if (value[i].mRemarks != '') {
                var printRemarks = EscHelper.strToList(
                    str: value[i].mRemarks ?? "", splitLenth: 20);
                if (printRemarks.isNotEmpty) {
                  for (int k = 0; k < printRemarks.length; k++) {
                    printer.text(
                        '${EscHelper.fillSpace(value[i].bDLPrinterType == "EPSON" ? 4 : 5)}${printRemarks[k]}${EscHelper.fillSpace(20 - EscHelper.strWidth(printRemarks[k]))}',
                        linesAfter: 0,
                        styles: const PosStyles(
                          height: PosTextSize.size2,
                          width: PosTextSize.size2,
                          bold: true,
                        ),
                        containsChinese: true);
                  }
                }
              }

              //价格
              if (isPrintPrice == 0) {
                if (value[i].bDLPrinterType == "EPSON") {
                  printer.text(
                    "${EscHelper.fillSpace(24 - EscHelper.strWidth("\$${value[i].mPrice}"))}\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                } else {
                  printer.text(
                    "\$${value[i].mPrice}",
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right,
                    ),
                  );
                }
              }
              if (value[i].bDLPrinterType != "" &&
                  value[i].bDLPrinterType == "EPSON") {
                printer.feed(5);
              } else {
                printer.feed(1);
              }
            }
            //台号
            if (value[0].bDLPrinterType == "EPSON") {
              printer.text(
                EscHelper.alginCeterPrint(
                    width: 48, content: "檯:${value[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  bold: true,
                ),
                containsChinese: true,
              );
            } else {
              printer.text(
                "檯:${value[0].mTableNo}",
                linesAfter: 1,
                styles: const PosStyles(
                  width: PosTextSize.size3,
                  height: PosTextSize.size3,
                  align: PosAlign.center,
                  bold: true,
                ),
                containsChinese: true,
              );
            }
            if (value[0].bDLPrinterType != "" &&
                value[0].bDLPrinterType == "EPSON") {
              printer.feed(18);
            }
            printer.cut();
            printStatus = true;
            //修改发票明细状态
            editstatus(mInvoiceDetailID);
          }
        });
        printer.disconnect();
        printStatus = true;
      } else {
        print("打印機$key連接失敗");
        printStatus = true;
      }
    } else {
      printStatus = true;
    }
  });
}

///打印二维码
Future<void> printQrCode(
    NetworkPrinter printer, List<QrCodeData> printData) async {
  if (printData.isNotEmpty) {
    List invoiceNo = [];
    printStatus = false;
    for (var element in printData) {
      final PosPrintResult linkret =
          await printer.connect(element.ip!, port: 9100);

      if (PosPrintResult.success == linkret) {
        Image? printerImage;
        try {
          if (element.mPrinterType == "SPRT") {
            try {
              Response<List<int>> res = await Dio().get<List<int>>(
                  element.imageUrl!,
                  options: Options(responseType: ResponseType.bytes));
              if (res.statusCode == 200) {
                Uint8List imageData = Uint8List.fromList(res.data!);
                if (imageData.isNotEmpty) {
                  printerImage = decodeImage(imageData);
                }
              }
            } on DioException {
              print("获取二维码资源错误");
            }
          }
          printer.text(
            EscHelper.alginCeterPrint(
                width: 48, content: element.mNameChinese!),
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
            ),
            containsChinese: true,
          );

          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          printer.text(
            EscHelper.alginCeterPrint(
                width: 48, content: element.mNameEnglish!),
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
            ),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          var address =
              EscHelper.strToList(str: element.mAddress ?? "", splitLenth: 48);

          for (int i = 0; i < address.length; i++) {
            printer.text(
              EscHelper.alginCeterPrint(width: 48, content: address[i]),
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
              ),
              containsChinese: true,
            );
          }

          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          printer.text(
            EscHelper.alginCeterPrint(
                width: 48,
                content:
                    "檯名/單號: ${element.mTableNo!} / \x1d\x21\x11${element.mInvoiceNo!.substring(element.mInvoiceNo!.length - 4)}"),
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          printer.text(
            "\x1d\x21\x01員工${"${EscHelper.fillSpace(6 - EscHelper.strWidth("員工"))}:${element.mSalesmanCode}${EscHelper.fillSpace(22 - EscHelper.strWidth(element.mSalesmanCode))}收銀機${EscHelper.fillSpace(6 - EscHelper.strWidth("收銀機"))}:${element.mSalesmanCode}"}",
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ),
            containsChinese: true,
          );

          printer.text(
            "日期${"${EscHelper.fillSpace(6 - EscHelper.strWidth("日期"))}:${element.mInvoiceDate}${EscHelper.fillSpace(22 - EscHelper.strWidth(element.mInvoiceDate))}人數${EscHelper.fillSpace(6 - EscHelper.strWidth("人數"))}:${element.mPnum}"}",
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          printStatus = false;
          if (element.mPrinterType == "SPRT") {
            if (printerImage != null) {
              printer.image(printerImage);
            }
          } else {
            printer.qrcode(element.url!, size: QRSize.Size8);
          }
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          printer.text(
            EscHelper.alginCeterPrint(width: 24, content: "請掃描上面二維碼自助點餐"),
            styles: const PosStyles(
              bold: true,
              width: PosTextSize.size2,
              height: PosTextSize.size2,
            ),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 25 : 2);
          printer.cut();
          printStatus = true;
          printer.disconnect();
          invoiceNo.add(element.mInvoiceNo);
        } on DioException catch (e) {
          printStatus = true;
          print("dio====>${e.message}}");
        } catch (e) {
          printStatus = true;
          print("打印二维码异常====>$e}");
        }
      } else {
        printStatus = true;
        print("打印機${element.ip}連接失敗");
      }
    }
    if (invoiceNo.isNotEmpty) {
      printStatus = false;
      await editPrintInvoice(invoiceNo);
    } else {
      printStatus = true;
    }
  }
}

///打印上菜单
Future<void> printUpper(NetworkPrinter printer, UpperMenu printdata) async {
  printStatus = false;
  List<UpperMenuData> upperMenuData = printdata.upperMenuData!;
  Map<String?, List<UpperMenuData>> upperGroup =
      groupBy(upperMenuData, (UpperMenuData rows) => rows.invoiceNo);
  upperGroup.forEach((key, value) async {
    printStatus = false;
    final PosPrintResult linkret =
        await printer.connect(printdata.ip!, port: 9100);
    if (PosPrintResult.success == linkret) {
      printStatus = false;

      if (printdata.mPrinterType == "EPSON") {
        printer.text(
          EscHelper.alginCeterPrint(width: 16, content: "上菜單"),
          styles: const PosStyles(
              width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
          containsChinese: true,
        );
      } else {
        printer.text(
          "上菜單",
          styles: const PosStyles(
              width: PosTextSize.size3,
              height: PosTextSize.size3,
              align: PosAlign.center,
              bold: true),
          containsChinese: true,
        );
      }

      printer.feed(1);
      if (printdata.mPrinterType == "EPSON") {
        printer.text(
          EscHelper.alginCeterPrint(
              width: 16, content: "檯：${value[0].mTableNo}"),
          styles: const PosStyles(
              width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
          containsChinese: true,
        );
      } else {
        printer.text(
          "檯：${value[0].mTableNo}",
          styles: const PosStyles(
              width: PosTextSize.size3,
              height: PosTextSize.size3,
              align: PosAlign.center,
              bold: true),
          containsChinese: true,
        );
      }

      printer.feed(1);
      printer.text(
          "員工${EscHelper.fillSpace(8 - EscHelper.strWidth('員工'))}:${value[0].mSalesmanCode}${EscHelper.fillSpace(20 - EscHelper.strWidth(value[0].mSalesmanCode))}單號${EscHelper.fillSpace(8 - EscHelper.strWidth('單號'))}:\x1d\x21\x11${value[0].mInvoiceNo}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
          linesAfter: 0);
      printer.text(
        "\x1d\x21\x01日期${EscHelper.fillSpace(8 - EscHelper.strWidth('日期'))}:${value[0].invoiceDate}${EscHelper.fillSpace(20 - EscHelper.strWidth(value[0].invoiceDate))}收銀機${EscHelper.fillSpace(8 - EscHelper.strWidth('收銀機'))}:${value[0].mStationCode}",
        styles: const PosStyles(
            width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        containsChinese: true,
      );
      printer.text(
          "入坐時間${EscHelper.fillSpace(8 - EscHelper.strWidth('入坐時間'))}:${value[0].invoiceTime}${EscHelper.fillSpace(20 - EscHelper.strWidth(value[0].invoiceTime))}人數${EscHelper.fillSpace(8 - EscHelper.strWidth('人數'))}:${value[0].mPnum}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
          linesAfter: 0);
      printer.text(
          "結賬時間${EscHelper.fillSpace(8 - EscHelper.strWidth('結賬時間'))}:${EscHelper.fillSpace(20)}檯${EscHelper.fillSpace(8 - EscHelper.strWidth('檯'))}:${value[0].mTableNo}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
          linesAfter: 0);
      printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");

      for (var item in value) {
        //名稱
        final printName =
            EscHelper.strToList(str: item.mBarcodeName ?? "", splitLenth: 30);
        for (int i = 0; i < printName.length; i++) {
          if (i == 0) {
            printer.text(
              "${item.invoiceTime}${EscHelper.fillSpace(8 - EscHelper.strWidth(item.invoiceTime))}${printName[i]}${EscHelper.fillSpace(30 - EscHelper.strWidth(printName[i]))}${item.mQty}${EscHelper.fillSpace(2 - EscHelper.strWidth(item.mQty))}${EscHelper.fillSpace(8 - EscHelper.strWidth(item.mPrice))}${item.mPrice}",
              styles: const PosStyles(
                  width: PosTextSize.size1,
                  height: PosTextSize.size2,
                  bold: true),
              linesAfter: 0,
              containsChinese: true,
            );
          } else if (printName[i].isNotEmpty) {
            printer.text(
              "${EscHelper.fillSpace(8)}${printName[i]}${EscHelper.fillSpace(30 - EscHelper.strWidth(printName[i]))}${EscHelper.fillSpace(10)}",
              styles: const PosStyles(
                  width: PosTextSize.size1,
                  height: PosTextSize.size2,
                  bold: true),
              linesAfter: 0,
              containsChinese: true,
            );
          }
        }
        //備註
        final printRemaks =
            EscHelper.strToList(str: item.mRemarks ?? "", splitLenth: 29);
        for (int k = 0; k < printRemaks.length; k++) {
          printer.text(
            "${EscHelper.fillSpace(9)}${printRemaks[k]}${EscHelper.fillSpace(29 - EscHelper.strWidth(printRemaks[k]))}${EscHelper.fillSpace(10)}",
            styles: const PosStyles(
                width: PosTextSize.size1,
                height: PosTextSize.size2,
                bold: true),
            linesAfter: 0,
            containsChinese: true,
          );
        }
      }
      printer.text(EscHelper.fillhr(lenght: 24),
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ));

      printer.text(
        "${EscHelper.fillSpace(48 - EscHelper.strWidth(value[0].mAmount))}${value[0].mAmount}",
        styles: const PosStyles(
            width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        containsChinese: true,
      );
      printer.feed(2);

      printer.barcode(
          Barcode.code39(
            "${value[0].mInvoiceNo}".split(""),
          ),
          height: printdata.mPrinterType == "EPSON" ? 220 : 60);

      printer.feed(printdata.mPrinterType == "EPSON" ? 20 : 1);
      printer.cut();
      printer.disconnect();
      //修改BDL欄位
      editBDL(key!);
    } else {
      printStatus = true;
    }
  });
}

///打印收据
Future<void> printReceipt(
    NetworkPrinter printer, List<Receipt> printdata) async {
  printStatus = false;
  Map<String?, List<Receipt>> recieptGroup =
      groupBy(printdata, (Receipt rows) => rows.tInvoiceID!.toString());

  recieptGroup.forEach((key, value) async {
    for (var item in value) {
      printStatus = false;
      final PosPrintResult linkret =
          await printer.connect(item.mLanIP!, port: 9100);
      if (PosPrintResult.success == linkret) {
        printStatus = false;
        //修改 mPrintInvoice(1=>0)
        editPrintInvoices(item.mInvoiceNo!);
        //中文名称
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(
                width: 24, content: "${item.mNameChinese}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mNameChinese}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }
        //英文名称
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(
                width: 24, content: "${item.mNameEnglish}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mNameEnglish}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }
        //地址
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(width: 24, content: "${item.mAddress}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mAddress}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }

        printer.feed(1);
        printer.hr();
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(width: 24, content: "收據"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "收據",
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                align: PosAlign.center,
                bold: true),
            containsChinese: true,
          );
        }

        printer.text(
          "檯/單號${EscHelper.fillSpace(16 - EscHelper.strWidth("檯/單號"))}${item.mTableNo}${EscHelper.fillSpace(16 - EscHelper.strWidth("${item.mTableNo}"))} ${EscHelper.fillSpace(8 - EscHelper.strWidth(item.mInvoiceNo))}\x1d\x21\x11${item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4)}",
          containsChinese: true,
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        );
        printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        printer.text(
          "\x1d\x21\x01人數${EscHelper.fillSpace(8 - EscHelper.strWidth('人數'))}:${item.mPnum}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.mPnum))}客戶${EscHelper.fillSpace(8 - EscHelper.strWidth('客戶'))}:${item.mCustomerCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.text(
          "入座時間${EscHelper.fillSpace(8 - EscHelper.strWidth('入座時間'))}:${item.mInvoiceDate}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.mInvoiceDate))}收銀機${EscHelper.fillSpace(8 - EscHelper.strWidth('收銀機'))}:${item.mStationCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.text(
          "結賬時間${EscHelper.fillSpace(8 - EscHelper.strWidth('結賬時間'))}:${item.payTime}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.payTime))}員工${EscHelper.fillSpace(8 - EscHelper.strWidth('員工'))}:${item.mSalesmanCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.feed(2);
        printer.text(
          "項目${EscHelper.fillSpace(34 - EscHelper.strWidth('項目'))}數量${EscHelper.fillSpace(6 - EscHelper.strWidth("數量"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('金額'))}金額",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        final List<Detail> detail = item.detail!;
        if (detail.isNotEmpty) {
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.strToList(
                str: detail[i].mPrintName ?? "", splitLenth: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                printer.text(
                  "${printName[j]}${EscHelper.fillSpace(34 - EscHelper.strWidth(printName[j]))}${detail[i].mQty}${EscHelper.fillSpace(6 - EscHelper.strWidth("${detail[i].mQty}"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('${detail[i].mAmount}'))}${detail[i].mAmount}",
                  styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true),
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        printer.text(
            "小計${EscHelper.fillSpace(24 - EscHelper.strWidth("小計"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mNetAmt}"))}${item.mNetAmt}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));

        printer.text(
            "服務費${EscHelper.fillSpace(24 - EscHelper.strWidth("服務費"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mCharge}"))}${item.mCharge}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "折扣${EscHelper.fillSpace(24 - EscHelper.strWidth("折扣"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mDiscRate}"))}${item.mDiscRate}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "折扣(\$)${EscHelper.fillSpace(24 - EscHelper.strWidth("折扣(\$)"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mDiscAmt}"))}${item.mDiscAmt}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "合計${EscHelper.fillSpace(24 - EscHelper.strWidth("合計"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mAmount}"))}${item.mAmount}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "付款金額${EscHelper.fillSpace(24 - EscHelper.strWidth("付款金額"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mPayAmount}"))}${item.mPayAmount}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "找零${EscHelper.fillSpace(24 - EscHelper.strWidth("找零"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mChange}"))}${item.mChange}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        printer.text(
          "支付方式${EscHelper.fillSpace(34 - EscHelper.strWidth('支付方式'))}金額${EscHelper.fillSpace(6 - EscHelper.strWidth("金額"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('小費'))}小費",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        List<PayType> payType = item.payType!;
        if (payType.isNotEmpty) {
          for (int i = 0; i < payType.length; i++) {
            printer.text(
              "${payType[i].mPaytype}${EscHelper.fillSpace(34 - EscHelper.strWidth(payType[i].mPaytype))}${payType[i].mAmount}${EscHelper.fillSpace(6 - EscHelper.strWidth("${payType[i].mAmount}"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('${payType[i].mTips}'))}${payType[i].mTips}",
              styles: const PosStyles(
                  width: PosTextSize.size1,
                  height: PosTextSize.size2,
                  bold: true),
              containsChinese: true,
            );
          }
        }
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");

        printer.feed(item.mPrinterType == "EPSON" ? 20 : 1);
        printer.cut();
        printer.disconnect();
        printStatus = true;
      } else {
        printStatus = true;
      }
    }
  });
}

///打印客户记录
Future<void> printCustomerRecord(
    NetworkPrinter printer, List<Receipt> printdata) async {
  printStatus = false;
  Map<String?, List<Receipt>> recieptGroup =
      groupBy(printdata, (Receipt rows) => rows.tInvoiceID!.toString());

  recieptGroup.forEach((key, value) async {
    for (var item in value) {
      printStatus = false;
      final PosPrintResult linkret =
          await printer.connect(item.mLanIP!, port: 9100);
      if (PosPrintResult.success == linkret) {
        printStatus = false;
        //修改 mPrintInvoice(1=>0)
        editPrintInvoices(item.mInvoiceNo!);
        //中文名称
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(
                width: 24, content: "${item.mNameChinese}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mNameChinese}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }
        //英文名称
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(
                width: 24, content: "${item.mNameEnglish}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mNameEnglish}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }
        //地址
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(width: 24, content: "${item.mAddress}"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "${item.mAddress}",
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
              bold: true,
            ),
            containsChinese: true,
          );
        }

        printer.feed(1);
        printer.hr();
        if (item.mPrinterType == "EPSON") {
          printer.text(
            EscHelper.alginCeterPrint(width: 24, content: "客戶記錄"),
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                bold: true),
            containsChinese: true,
          );
        } else {
          printer.text(
            "客戶記錄",
            styles: const PosStyles(
                width: PosTextSize.size2,
                height: PosTextSize.size2,
                align: PosAlign.center,
                bold: true),
            containsChinese: true,
          );
        }

        printer.text(
          "檯/單號${EscHelper.fillSpace(16 - EscHelper.strWidth("檯/單號"))}${item.mTableNo}${EscHelper.fillSpace(16 - EscHelper.strWidth("${item.mTableNo}"))} ${EscHelper.fillSpace(8 - EscHelper.strWidth(item.mInvoiceNo))}\x1d\x21\x11${item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4)}",
          containsChinese: true,
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        );
        printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        printer.text(
          "\x1d\x21\x01人數${EscHelper.fillSpace(8 - EscHelper.strWidth('人數'))}:${item.mPnum}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.mPnum))}客戶${EscHelper.fillSpace(8 - EscHelper.strWidth('客戶'))}:${item.mCustomerCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.text(
          "入座時間${EscHelper.fillSpace(8 - EscHelper.strWidth('入座時間'))}:${item.mInvoiceDate}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.mInvoiceDate))}收銀機${EscHelper.fillSpace(8 - EscHelper.strWidth('收銀機'))}:${item.mStationCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.text(
          "結賬時間${EscHelper.fillSpace(8 - EscHelper.strWidth('結賬時間'))}:${item.payTime}${EscHelper.fillSpace(20 - EscHelper.strWidth(item.payTime))}員工${EscHelper.fillSpace(8 - EscHelper.strWidth('員工'))}:${item.mSalesmanCode}",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.feed(2);
        printer.text(
          "項目${EscHelper.fillSpace(34 - EscHelper.strWidth('項目'))}數量${EscHelper.fillSpace(6 - EscHelper.strWidth("數量"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('金額'))}金額",
          styles: const PosStyles(
              width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        final List<Detail> detail = item.detail!;
        if (detail.isNotEmpty) {
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.strToList(
                str: detail[i].mPrintName ?? "", splitLenth: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                printer.text(
                  "${printName[j]}${EscHelper.fillSpace(34 - EscHelper.strWidth(printName[j]))}${detail[i].mQty}${EscHelper.fillSpace(6 - EscHelper.strWidth("${detail[i].mQty}"))}${EscHelper.fillSpace(8 - EscHelper.strWidth('${detail[i].mAmount}'))}${detail[i].mAmount}",
                  styles: const PosStyles(
                      width: PosTextSize.size1,
                      height: PosTextSize.size2,
                      bold: true),
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        printer.text(
            "小計${EscHelper.fillSpace(24 - EscHelper.strWidth("小計"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mNetAmt}"))}${item.mNetAmt}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));

        printer.text(
            "服務費${EscHelper.fillSpace(24 - EscHelper.strWidth("服務費"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mCharge}"))}${item.mCharge}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "折扣${EscHelper.fillSpace(24 - EscHelper.strWidth("折扣"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mDiscRate}"))}${item.mDiscRate}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "折扣(\$)${EscHelper.fillSpace(24 - EscHelper.strWidth("折扣(\$)"))}${EscHelper.fillSpace(24 - EscHelper.strWidth("${item.mDiscAmt}"))}${item.mDiscAmt}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size1,
              height: PosTextSize.size2,
              bold: true,
            ));
        printer.text(
            "合計${EscHelper.fillSpace(12 - EscHelper.strWidth("合計"))}${EscHelper.fillSpace(12 - EscHelper.strWidth("${item.mAmount}"))}${item.mAmount}",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              bold: true,
            ));

        //分割線
        printer.text("\x1B\x21\x30${EscHelper.fillhr(lenght: 24)}");
        printer.text("客戶簽署",
            containsChinese: true,
            styles: const PosStyles(
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              bold: false,
            ));

        printer.feed(2);

        printer.barcode(
            Barcode.code39(
              item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split(""),
            ),
            height: item.mPrinterType == "EPSON" ? 220 : 60);

        printer.feed(item.mPrinterType == "EPSON" ? 20 : 1);
        printer.cut();
        printer.disconnect();
        printStatus = true;
      } else {
        printStatus = true;
      }
    }
  });
}

//修改发票明细打印标识P->Y
Future<void> editstatus(List ids) async {
  printStatus = false;
  UserData? loginUser = getLoginInfo();

  Map<String, dynamic> queryData = {
    "dsn": loginUser!.dsn!.toJson(),
    "company": loginUser.company,
    'ids': jsonEncode(ids)
  };

  try {
    Dio dio = Dio();
    dio.options.baseUrl = Config.baseurl;
    dio.options.contentType = "application/json; charset=utf-8";
    dio.options.validateStatus = (status) => status != null;

    var ret = await dio.get(Config.editstatus, queryParameters: queryData);
    if (ret.statusCode == 200) {
      printStatus = true;
    }
  } on DioException {
    //errorLoding('修改發票明細狀態请求错误');
    printStatus = true;
  }
}

///修改二维码PrintInvoice栏位值(2->0)
Future<void> editPrintInvoice(List list) async {
  printStatus = false;
  UserData? loginUser = getLoginInfo();
  Map<String, dynamic> queryData = {
    "dsn": loginUser!.dsn!.toJson(),
    "company": loginUser.company,
    'conditions': jsonEncode(list)
  };

  try {
    Dio dio = Dio();
    dio.options.baseUrl = Config.baseurl;
    dio.options.contentType = "application/json; charset=utf-8";
    dio.options.validateStatus = (status) => status != null;

    var ret =
        await dio.get(Config.editPrintInvoice, queryParameters: queryData);
    if (ret.statusCode == 200) {
      printStatus = true;
    }
  } on DioException catch (e) {
    printStatus = true;
    print('修改二維碼欄位请求错误${e.message}');
  } catch (e) {
    print('修改二維碼欄位请求错误');
    printStatus = true;
  }
}

///修改上菜单栏BDL位值1->0
Future<void> editBDL(String invoiceNo) async {
  printStatus = false;
  UserData? loginUser = getLoginInfo();
  Map<String, dynamic> queryData = {
    "dsn": loginUser!.dsn!.toJson(),
    "company": loginUser.company,
    'invoiceNo': invoiceNo
  };

  try {
    Dio dio = Dio();
    dio.options.baseUrl = Config.baseurl;
    dio.options.contentType = "application/json; charset=utf-8";
    dio.options.validateStatus = (status) => status != null;

    var ret = await dio.get(Config.editBDL, queryParameters: queryData);
    if (ret.statusCode == 200) {
      printStatus = true;
    }
  } on DioException catch (e) {
    printStatus = true;
    print('修改上菜單欄位请求错误${e.message}');
  } catch (e) {
    printStatus = true;
    print('修改上菜單欄位请求错误$e');
  }
}

//修改打印發票PrintInvoice(1->0)
Future<void> editPrintInvoices(String invoiceNo) async {
  printStatus = false;
  UserData? loginUser = getLoginInfo();
  Map<String, dynamic> queryData = {
    "dsn": loginUser!.dsn!.toJson(),
    "company": loginUser.company,
    'invoiceNo': invoiceNo
  };

  try {
    Dio dio = Dio();
    dio.options.baseUrl = Config.baseurl;
    dio.options.contentType = "application/json; charset=utf-8";
    dio.options.validateStatus = (status) => status != null;

    var ret =
        await dio.get(Config.editPrintInvoices, queryParameters: queryData);
    if (ret.statusCode == 200) {
      //printStatus = true;
    }
  } on DioException {
    printStatus = true;
    print('修改發票欄位请求错误');
  }
}
