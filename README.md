# background_print

## 项目介绍

后台打印功能，用于打印二维码、上菜单、厨房、收据、客户记录

- 后台修改数据后务必同步到前台
- 系统设置全部云打印设置成 N
- 打印二维码用系统设置的上菜单打印机，获取数据条件发票表 mPrintInvoice=2,mBTemp=1,打印完成后修改 mPrintInvoice=0
- 打印上菜单用系统设置的上菜单打印机，获取数据条件发票表 mPrintBDL=1,打印完成后修改 mPrintBDL=0
- 打印厨房用食品所属类目二打印机，获取数据条件发票明细表 mIsPrint=P,打印完成后修改 mIsPrint=Y
- 打印收据用系统设置的发票打印机，获取数据条件发票表 mPrintInvoice=1,打印完成后修改 mPrintInvoice=0
- 打印客户记录用系统设置的发票打印机，获取数据条件发票表 mPrintInvoice=3,打印完成后修改 mPrintInvoice=0
- mPrintInvoice 1 收据 2 二维码 3 客户记录

## <a href="build/app/outputs/flutter-apk/bgPrint.apk" download>APK 下载</a>

## [APK 下载](https://github.com/rosscarsen/backgroud-print/blob/main/build/app/outputs/flutter-apk/bgPrint.apk)
