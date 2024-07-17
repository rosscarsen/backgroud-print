// ignore_for_file: public_member_api_docs, sort_constructors_first

class LoginModel {
  UserData? data;
  String? info;
  int? status;

  LoginModel({this.data, this.info, this.status});

  LoginModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? UserData.fromJson(json['data']) : null;
    info = json['info'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['info'] = info;
    data['status'] = status;
    return data;
  }

  @override
  String toString() => 'LoginModle(data: $data, info: $info, status: $status)';
}

class UserData {
  String? company;
  String? userCode;
  String? pwd;
  Dsn? dsn;

  UserData({this.company, this.pwd, this.dsn, this.userCode});

  UserData.fromJson(Map<String, dynamic> json) {
    company = json['company'];
    pwd = json['userCode'];
    userCode = json['pwd'];
    dsn = json['dsn'] != null ? Dsn.fromJson(json['dsn']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['company'] = company;
    data['userCode'] = userCode;
    data['pwd'] = pwd;
    if (dsn != null) {
      data['dsn'] = dsn!.toJson();
    }
    return data;
  }

  @override
  String toString() =>
      'Data(company: $company,userCode: $userCode, pwd: $pwd, dsn: $dsn)';
}

class Dsn {
  String? type;
  String? hostname;
  String? database;
  String? username;
  String? password;
  int? hostport;
  String? charset;
  String? prefix;

  Dsn(
      {this.type,
      this.hostname,
      this.database,
      this.username,
      this.password,
      this.hostport,
      this.charset,
      this.prefix});

  Dsn.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    hostname = json['hostname'];
    database = json['database'];
    username = json['username'];
    password = json['password'];
    hostport = json['hostport'];
    charset = json['charset'];
    prefix = json['prefix'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['hostname'] = hostname;
    data['database'] = database;
    data['username'] = username;
    data['password'] = password;
    data['hostport'] = hostport;
    data['charset'] = charset;
    data['prefix'] = prefix;
    return data;
  }

  @override
  String toString() {
    return 'Dsn(type: $type, hostname: $hostname, database: $database, username: $username, password: $password, hostport: $hostport, charset: $charset, prefix: $prefix)';
  }
}
