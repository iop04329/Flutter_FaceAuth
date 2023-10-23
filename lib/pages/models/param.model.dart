import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';

class Param {
  int? id; // 新增一个 id 主鍵
  String key;
  String val;

  Param({
    this.id,
    required this.key,
    required this.val,
  });

  static Param fromMap(Map<String, dynamic> user) {
    return new Param(
      id: user['id'],
      key: user['key'],
      val: user['value'],
    );
  }

  toMap() {

    return {
      'id': id,
      'key': key,
      'value': val,
    };
  }
}
