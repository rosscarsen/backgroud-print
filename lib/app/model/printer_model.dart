// ignore_for_file: public_member_api_docs, sort_constructors_first
class PrinterModel {
  List<QrCodeData>? qrCodeData;
  List<Kitchen>? kitchen;
  int? isPrintPrice;
  UpperMenu? upperMenu;
  List<Receipt>? receipt;
  List<Receipt>? customerRecord;
  PrinterModel({
    this.qrCodeData,
    this.kitchen,
    this.isPrintPrice,
    this.upperMenu,
    this.receipt,
    this.customerRecord,
  });

  PrinterModel.fromJson(Map<String, dynamic> json) {
    if (json['qrCodeData'] != null) {
      qrCodeData = <QrCodeData>[];
      json['qrCodeData'].forEach((v) {
        qrCodeData!.add(QrCodeData.fromJson(v));
      });
    }
    if (json['kitchen'] != null) {
      kitchen = <Kitchen>[];
      json['kitchen'].forEach((v) {
        kitchen!.add(Kitchen.fromJson(v));
      });
    }
    isPrintPrice = json['isPrintPrice'];
    upperMenu = json['upperMenu'] != null
        ? UpperMenu.fromJson(json['upperMenu'])
        : null;
    if (json['receipt'] != null) {
      receipt = <Receipt>[];
      json['receipt'].forEach((v) {
        receipt!.add(Receipt.fromJson(v));
      });
    }
    if (json['customerRecord'] != null) {
      customerRecord = <Receipt>[];
      json['customerRecord'].forEach((v) {
        customerRecord!.add(Receipt.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (qrCodeData != null) {
      data['qrCodeData'] = qrCodeData!.map((v) => v.toJson()).toList();
    }
    if (kitchen != null) {
      data['kitchen'] = kitchen!.map((v) => v.toJson()).toList();
    }
    if (upperMenu != null) {
      data['upperMenu'] = upperMenu!.toJson();
    }
    data['isPrintPrice'] = isPrintPrice;
    if (receipt != null) {
      data['receipt'] = receipt!.map((v) => v.toJson()).toList();
    }
    if (customerRecord != null) {
      data['customerRecord'] = customerRecord!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'PrinterModel(qrCodeData: $qrCodeData, kitchen: $kitchen, isPrintPrice: $isPrintPrice, upperMenu: $upperMenu, receipt: $receipt, customerRecord: $customerRecord)';
  }
}

class UpperMenu {
  List<UpperMenuData>? upperMenuData;
  String? mPrinterType;
  String? ip;

  UpperMenu({this.upperMenuData, this.mPrinterType, this.ip});

  UpperMenu.fromJson(Map<String, dynamic> json) {
    if (json['upperMenuData'] != null) {
      upperMenuData = <UpperMenuData>[];
      json['upperMenuData'].forEach((v) {
        upperMenuData!.add(UpperMenuData.fromJson(v));
      });
    }
    mPrinterType = json['mPrinterType'];
    ip = json['ip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (upperMenuData != null) {
      data['upperMenuData'] = upperMenuData!.map((v) => v.toJson()).toList();
    }
    data['mPrinterType'] = mPrinterType;
    data['ip'] = ip;
    return data;
  }

  @override
  String toString() =>
      'UpperMenu(upperMenuData: $upperMenuData, mPrinterType: $mPrinterType, ip: $ip)';
}

class UpperMenuData {
  String? invoiceNo;
  String? mSalesmanCode;
  String? mStationCode;
  String? mPnum;
  String? mTableNo;
  String? mInvoiceNo;
  String? invoiceDate;
  String? invoiceTime;
  String? mQty;
  String? mtime;
  String? mRemarks;
  String? mBarcodeName;
  int? mInvoiceDetailID;
  String? mPrice;
  String? mAmount;

  UpperMenuData(
      {this.invoiceNo,
      this.mSalesmanCode,
      this.mStationCode,
      this.mPnum,
      this.mTableNo,
      this.mInvoiceNo,
      this.invoiceDate,
      this.invoiceTime,
      this.mQty,
      this.mtime,
      this.mRemarks,
      this.mBarcodeName,
      this.mInvoiceDetailID,
      this.mAmount,
      this.mPrice});

  UpperMenuData.fromJson(Map<String, dynamic> json) {
    invoiceNo = json['invoiceNo'];
    mAmount = json['mAmount'];
    mSalesmanCode = json['mSalesman_Code'];
    mStationCode = json['mStation_Code'];
    mPnum = json['mPnum'];
    mTableNo = json['mTableNo'];
    mInvoiceNo = json['mInvoice_No'];
    invoiceDate = json['invoiceDate'];
    invoiceTime = json['invoiceTime'];
    mQty = json['mQty'];
    mtime = json['mtime'];
    mRemarks = json['mRemarks'];
    mBarcodeName = json['mBarcode_Name'];
    mInvoiceDetailID = json['mInvoice_Detail_ID'];
    mPrice = json['mPrice'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['invoiceNo'] = invoiceNo;
    data['mAmount'] = mAmount;
    data['mSalesman_Code'] = mSalesmanCode;
    data['mStation_Code'] = mStationCode;
    data['mPnum'] = mPnum;
    data['mTableNo'] = mTableNo;
    data['mInvoice_No'] = mInvoiceNo;
    data['invoiceDate'] = invoiceDate;
    data['invoiceTime'] = invoiceTime;
    data['mQty'] = mQty;
    data['mtime'] = mtime;
    data['mRemarks'] = mRemarks;
    data['mBarcode_Name'] = mBarcodeName;
    data['mInvoice_Detail_ID'] = mInvoiceDetailID;
    data['mPrice'] = mPrice;
    return data;
  }

  @override
  String toString() {
    return 'UpperMenuData(invoiceNo: $invoiceNo, mSalesmanCode: $mSalesmanCode, mStationCode: $mStationCode, mPnum: $mPnum, mTableNo: $mTableNo, mInvoiceNo: $mInvoiceNo, invoiceDate: $invoiceDate, invoiceTime: $invoiceTime, mQty: $mQty, mtime: $mtime, mRemarks: $mRemarks, mBarcodeName: $mBarcodeName, mInvoiceDetailID: $mInvoiceDetailID, mPrice: $mPrice)';
  }
}

class QrCodeData {
  String? mInvoiceNo;
  String? mNameChinese;
  String? mNameEnglish;
  String? mAddress;
  String? mTableNo;
  String? mSalesmanCode;
  String? mInvoiceDate;
  String? mPnum;
  String? ip;
  String? mPrinterType;
  String? url;
  String? imageUrl;

  QrCodeData({
    this.mInvoiceNo,
    this.mNameChinese,
    this.mNameEnglish,
    this.mAddress,
    this.mTableNo,
    this.mSalesmanCode,
    this.mInvoiceDate,
    this.mPnum,
    this.mPrinterType,
    this.ip,
    this.url,
    this.imageUrl,
  });

  QrCodeData.fromJson(Map<String, dynamic> json) {
    mInvoiceNo = json['mInvoiceNo'];
    mNameChinese = json['mNameChinese'];
    mNameEnglish = json['mNameEnglish'];
    mAddress = json['mAddress'];
    mTableNo = json['mTableNo'];
    mSalesmanCode = json['mSalesman_Code'];
    mInvoiceDate = json['mInvoice_Date'];
    mPnum = json['mPnum'];
    ip = json['ip'];
    url = json['url'];
    imageUrl = json['imageUrl'];
    mPrinterType = json['mPrinterType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mInvoiceNo'] = mInvoiceNo;
    data['mNameChinese'] = mNameChinese;
    data['mNameEnglish'] = mNameEnglish;
    data['mAddress'] = mAddress;
    data['mTableNo'] = mTableNo;
    data['mSalesman_Code'] = mSalesmanCode;
    data['mInvoice_Date'] = mInvoiceDate;
    data['mPnum'] = mPnum;
    data['ip'] = ip;
    data['url'] = url;
    data['imageUrl'] = imageUrl;
    data['mPrinterType'] = mPrinterType;
    return data;
  }

  @override
  String toString() {
    return 'QrCodeData(mNameChinese: $mNameChinese, mNameEnglish: $mNameEnglish, mAddress: $mAddress, mTableNo: $mTableNo, mSalesmanCode: $mSalesmanCode, mInvoiceDate: $mInvoiceDate, mPnum: $mPnum, ip: $ip, url: $url)';
  }
}

class Kitchen {
  String? mStationCode;
  String? mPnum;
  String? mInvoiceNo;
  String? mTableNo;
  String? invoiceDate;
  String? invoiceTime;
  String? mQty;
  int? mContinue;
  int? mNonContinue;
  String? mRemarks;
  String? mBarcodeName;
  int? mInvoiceDetailID;
  String? mPrice;
  String? mDeviceName;
  String? mName;
  String? mLanIP;
  String? mPrinterType;
  String? bDLDeviceName;
  String? bDLName;
  String? bDLLanIP;
  String? bDLPrinterType;

  Kitchen({
    this.mStationCode,
    this.mPnum,
    this.mInvoiceNo,
    this.mTableNo,
    this.invoiceDate,
    this.invoiceTime,
    this.mQty,
    this.mContinue,
    this.mNonContinue,
    this.mRemarks,
    this.mBarcodeName,
    this.mInvoiceDetailID,
    this.mPrice,
    this.mDeviceName,
    this.mName,
    this.mLanIP,
    this.mPrinterType,
    this.bDLDeviceName,
    this.bDLName,
    this.bDLLanIP,
    this.bDLPrinterType,
  });

  Kitchen.fromJson(Map<String, dynamic> json) {
    mStationCode = json['mStation_Code'];
    mPnum = json['mPnum'];
    mInvoiceNo = json['mInvoice_No'];
    mTableNo = json['mTableNo'];
    invoiceDate = json['invoiceDate'];
    invoiceTime = json['invoiceTime'];
    mQty = json['mQty'];
    mContinue = json['mContinue'];
    mNonContinue = json['mNonContinue'];
    mRemarks = json['mRemarks'];
    mBarcodeName = json['mBarcode_Name'];
    mInvoiceDetailID = json['mInvoice_Detail_ID'];
    mPrice = json['mPrice'];
    mDeviceName = json['mDeviceName'];
    mName = json['mName'];
    mLanIP = json['mLanIP'];
    mPrinterType = json['mPrinterType'];
    bDLDeviceName = json['BDLDeviceName'];
    bDLName = json['BDLName'];
    bDLLanIP = json['BDLLanIP'];
    bDLPrinterType = json['BDLPrinterType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mStation_Code'] = mStationCode;
    data['mPnum'] = mPnum;
    data['mInvoice_No'] = mInvoiceNo;
    data['mTableNo'] = mTableNo;
    data['invoiceDate'] = invoiceDate;
    data['invoiceTime'] = invoiceTime;
    data['mQty'] = mQty;
    data['mContinue'] = mContinue;
    data['mNonContinue'] = mNonContinue;
    data['mRemarks'] = mRemarks;
    data['mBarcode_Name'] = mBarcodeName;
    data['mInvoice_Detail_ID'] = mInvoiceDetailID;
    data['mPrice'] = mPrice;
    data['mDeviceName'] = mDeviceName;
    data['mName'] = mName;
    data['mLanIP'] = mLanIP;
    data['mPrinterType'] = mPrinterType;
    data['BDLDeviceName'] = bDLDeviceName;
    data['BDLName'] = bDLName;
    data['BDLLanIP'] = bDLLanIP;
    data['BDLPrinterType'] = bDLPrinterType;
    return data;
  }

  @override
  String toString() {
    return 'Kitchen(mStationCode: $mStationCode, mPnum: $mPnum, mInvoiceNo: $mInvoiceNo, mTableNo: $mTableNo, invoiceDate: $invoiceDate, invoiceTime: $invoiceTime, mQty: $mQty, mContinue: $mContinue, mRemarks: $mRemarks, mBarcodeName: $mBarcodeName, mInvoiceDetailID: $mInvoiceDetailID, mPrice: $mPrice, mDeviceName: $mDeviceName, mName: $mName, mLanIP: $mLanIP, mPrinterType: $mPrinterType, bDLDeviceName: $bDLDeviceName, bDLName: $bDLName, bDLLanIP: $bDLLanIP, bDLPrinterType: $bDLPrinterType)';
  }
}

class Receipt {
  String? mNetAmt;
  String? mPayAmount;
  String? mChange;
  String? mAmount;
  String? mDiscRate;
  String? mDiscAmt;
  String? mCharge;
  int? tInvoiceID;
  String? mTableNo;
  String? mTableName;
  String? mPnum;
  String? mStationCode;
  String? mSalesmanCode;
  String? mCustomerCode;
  String? mInvoiceDate;
  String? mLanIP;
  String? mPrinterType;
  String? payTime;
  List<Detail>? detail;
  List<PayType>? payType;
  String? mNameEnglish;
  String? mNameChinese;
  String? mAddress;
  String? mInvoiceNo;

  Receipt({
    this.mNetAmt,
    this.mPayAmount,
    this.mChange,
    this.mAmount,
    this.mDiscRate,
    this.mDiscAmt,
    this.mCharge,
    this.tInvoiceID,
    this.mTableNo,
    this.mTableName,
    this.mPnum,
    this.mStationCode,
    this.mSalesmanCode,
    this.mCustomerCode,
    this.mInvoiceDate,
    this.detail,
    this.payType,
    this.mLanIP,
    this.mPrinterType,
    this.payTime,
    this.mNameEnglish,
    this.mNameChinese,
    this.mAddress,
    this.mInvoiceNo,
  });

  Receipt.fromJson(Map<String, dynamic> json) {
    mNetAmt = json['mNet_Amt'];
    mPayAmount = json['mPayAmount'];
    mChange = json['mChange'];
    mAmount = json['mAmount'];
    mDiscRate = json['mDisc_Rate'];
    mDiscAmt = json['mDisc_Amt'];
    mCharge = json['mCharge'];
    tInvoiceID = json['T_Invoice_ID'];
    mTableNo = json['mTableNo'];
    mTableName = json['mTableName'];
    mPnum = json['mPnum'];
    mStationCode = json['mStation_Code'];
    mSalesmanCode = json['mSalesman_Code'];
    mCustomerCode = json['mCustomer_Code'];
    mInvoiceDate = json['mInvoice_Date'];
    mLanIP = json['mLanIP'];
    mPrinterType = json['mPrinterType'];
    payTime = json['payTime'];
    mNameEnglish = json['mName_English'];
    mNameChinese = json['mName_Chinese'];
    mAddress = json['mAddress'];
    mInvoiceNo = json['invoiceNo'];
    if (json['detail'] != null) {
      detail = <Detail>[];
      json['detail'].forEach((v) {
        detail!.add(Detail.fromJson(v));
      });
    }
    if (json['payType'] != null) {
      payType = <PayType>[];
      json['payType'].forEach((v) {
        payType!.add(PayType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mPayAmount'] = mPayAmount;
    data['mNet_Amt'] = mNetAmt;
    data['mChange'] = mChange;
    data['mAmount'] = mAmount;
    data['mDisc_Rate'] = mDiscRate;
    data['mDisc_Amt'] = mDiscAmt;
    data['mCharge'] = mCharge;
    data['T_Invoice_ID'] = tInvoiceID;
    data['mTableNo'] = mTableNo;
    data['mTableName'] = mTableName;
    data['mPnum'] = mPnum;
    data['mStation_Code'] = mStationCode;
    data['mSalesman_Code'] = mSalesmanCode;
    data['mCustomer_Code'] = mCustomerCode;
    data['mInvoice_Date'] = mInvoiceDate;
    data['mLanIP'] = mLanIP;
    data['mPrinterType'] = mPrinterType;
    data['payTime'] = payTime;
    data['mName_English'] = mNameEnglish;
    data['mName_Chinese'] = mNameChinese;
    data['mAddress'] = mAddress;
    data['invoiceNo'] = mInvoiceNo;
    if (detail != null) {
      data['detail'] = detail!.map((v) => v.toJson()).toList();
    }
    if (payType != null) {
      data['payType'] = payType!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'Receipt(mPayAmount: $mPayAmount, mChange: $mChange, mAmount: $mAmount, mDiscRate: $mDiscRate, mDiscAmt: $mDiscAmt, mCharge: $mCharge, tInvoiceID: $tInvoiceID, mTableNo: $mTableNo, mTableName: $mTableName, mPnum: $mPnum, mStationCode: $mStationCode, mSalesmanCode: $mSalesmanCode, mCustomerCode: $mCustomerCode, mInvoiceDate: $mInvoiceDate, mLanIP: $mLanIP, mPrinterType: $mPrinterType, payTime: $payTime, detail: $detail, payType: $payType, mNameEnglish: $mNameEnglish, mInvoiceNo: $mInvoiceNo)';
  }
}

class Detail {
  String? mPrintName;
  String? mQty;
  String? mAmount;

  Detail({this.mPrintName, this.mQty, this.mAmount});

  Detail.fromJson(Map<String, dynamic> json) {
    mPrintName = json['mPrintName'];
    mQty = json['mQty'];
    mAmount = json['mAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mPrintName'] = mPrintName;
    data['mQty'] = mQty;
    data['mAmount'] = mAmount;
    return data;
  }

  @override
  String toString() =>
      'Detail(mPrintName: $mPrintName, mQty: $mQty, mAmount: $mAmount)';
}

class PayType {
  String? mPaytype;
  String? mAmount;
  String? mTips;

  PayType({this.mPaytype, this.mAmount, this.mTips});

  PayType.fromJson(Map<String, dynamic> json) {
    mPaytype = json['mPaytype'];
    mAmount = json['mAmount'];
    mTips = json['mTips'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mPaytype'] = mPaytype;
    data['mAmount'] = mAmount;
    data['mTips'] = mTips;
    return data;
  }

  @override
  String toString() =>
      'PayType(mPaytype: $mPaytype, mAmount: $mAmount, mTips: $mTips)';
}
