import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';

class User {
  int? id; // 新增一个 id 主鍵
  String user;
  String userid;
  List<List<double>> modelData;
  int? checkin = 0; // 0 未打卡 1 已打卡
  String checktime;

  User({
    this.id,
    required this.user,
    required this.userid,
    required this.modelData,
    int? checkin,
    String? checktime
  }) : this.checkin = checkin ?? 0,this.checktime = checktime ?? '';

  static User fromMap(Map<String, dynamic> user) {
    List<List<double>> modelData = [];
    List<double> perData = [];
    List<dynamic> decodedData = jsonDecode(user['model_data']);
    // String decodestring = user['model_data'];
    decodedData.forEach((list) {
      (list as List<dynamic>).forEach((value){
        if(value is String){
          perData.add(double.parse(value));
        }else{
          perData.add(value);
        }
      });
      modelData.add(perData);
      perData = [];
    });

    return new User(
      id: user['id'],
      user: user['user'],
      userid: user['userid'],
      modelData: modelData,
      checkin: user['checkin'],
      checktime: user['checktime']
    );
  }

  toMap() {
    List<dynamic> encodedData = modelData.map((e) => e.map((e) => e.toString()).toList()).toList();

    return {
      'id': id,
      'user': user,
      'userid': userid,
      'model_data': jsonEncode(encodedData),
      'checkin': checkin,
      'checktime':checktime
    };
  }
}
