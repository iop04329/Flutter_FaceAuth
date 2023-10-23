import 'dart:convert';
import 'dart:io';

import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  static final user_table = 'users';
  static final columnId = 'id';
  static final columnUser = 'user';
  static final columnUserId = 'userid';
  static final columnModelData = 'model_data';
  static final columnCheckIn = 'checkin';
  static final columnChecktime = 'checktime';

  static final param_table = 'params';
  static final columnKey = 'key';
  static final columnVal = 'value';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static late Database _database;
  Future<Database> get database async {
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
    
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $user_table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUser TEXT NOT NULL,
            $columnUserId TEXT NOT NULL,
            $columnModelData TEXT NOT NULL,
            $columnCheckIn INTEGER NOT NULL DEFAULT 0,
            $columnChecktime TEXT NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE $param_table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnKey TEXT NOT NULL,
            $columnVal TEXT NOT NULL
          )
          ''');
  }

  Future<void> createTableIfNotExists(String tb) async {
    final db = await instance.database;
    var tables = await db.rawQuery(
      "SELECT * FROM sqlite_master WHERE type='table' AND name='$tb';",
    );
    if (tables.isEmpty) {
      if (tb == user_table) {
        await db.execute('''
          CREATE TABLE $tb (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUser TEXT NOT NULL,
            $columnUserId TEXT NOT NULL,
            $columnModelData TEXT NOT NULL,
            $columnCheckIn INTEGER NOT NULL DEFAULT 0,
            $columnChecktime TEXT NOT NULL
          )
          ''');
      } else if (tb == param_table) {
        await db.execute('''
          CREATE TABLE $param_table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnKey TEXT NOT NULL,
            $columnVal TEXT NOT NULL
          )
          ''');
      }
    }
  }

  //判断表是否存在
  isTableExists(String tableName) async {
    final db = await instance.database;
    var sql = "SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'";
    var res = await db.rawQuery(sql);
    var returnRes = res.length > 0;
    return returnRes;
  }

  Future<void> updateCheckin(int id, int checkin) async {
    Database db = await instance.database;
    await db.update(
      user_table,
      {'$columnCheckIn': checkin},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateChecktime(int id, String time) async {
    Database db = await instance.database;
    await db.update(
      user_table,
      {'$columnChecktime': time},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateModelData(int id, List<List<double>> modelData) async {
    Database db = await instance.database;
    await db.update(
      user_table,
      {'model_data': jsonEncode(modelData)},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateParamTime(int id,String time) async {
    Database db = await instance.database;
    await db.update(
      param_table,
      {'$columnVal': time},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateParamVal(int id,String val) async {
    Database db = await instance.database;
    await db.update(
      param_table,
      {'$columnVal': val},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDataById(int id, String tb) async {
    Database db = await instance.database;
    await db.delete(
      tb,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<User?> getUserById(int id) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(
      user_table,
      columns: null,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first.cast());
    }
    return null;
  }

  Future<User?> getUserByName(String name) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      user_table,
      columns: null,
      where: '$columnUser = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUserId(String userid) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      user_table,
      columns: null,
      where: '$columnUserId = ?',
      whereArgs: [userid],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    Database db = await instance.database;
    return await db.insert(user_table, user.toMap());
  }

  Future<int> insertParam(Param pr) async {
    Database db = await instance.database;
    return await db.insert(param_table, pr.toMap());
  }

  Future<List<User>> queryAllUsers() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> users = await db.query(user_table);
    return users.map((u) => User.fromMap(u)).toList();
  }

  Future<List<Param>> queryAllParams() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> params = await db.query(param_table);
    return params.map((p) => Param.fromMap(p)).toList();
  }

  Future<List<Param>> queryByColumnLike(String tb,String col,String val) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> params = await db.query(tb,where: '$col LIKE ?',whereArgs: ['%$val%']);
    return params.map((p) => Param.fromMap(p)).toList();
  }

  Future<List<Param>> queryByColumn(String tb,String col,String val) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> params = await db.query(tb,where: '$col = ?',whereArgs: [val]);
    return params.map((p) => Param.fromMap(p)).toList();
  }

  //createFakeDate
  createFakeDate(String tb) async {
    var res = await isTableExists(tb);
    if (!res) return;
    if(tb == user_table){
      List<User> all = await queryAllUsers();
      bool isAdd = all.any((element) => element.user == 'play1');
      if (isAdd) return;
      User _fir = User(user: 'play1', userid: 'gg', modelData: [
        [0.315, 0.64884, 1, 35, 58, 9, 95, 1, 5]
      ]);
      User _sec = User(user: 'play2', userid: 'pp', modelData: [
        [0.555, 0.66684, 6, 37, 57, 0, 54, 5, 8]
      ]);
      User _thi = User(user: 'play3', userid: 'ee', modelData: [
        [0.58, 0.64884, 3, 35, 26, 11, 78, 9, 1]
      ]);
      await insertUser(_fir);
      await insertUser(_sec);
      await insertUser(_thi);
    }
    else if(tb == param_table){
      List<Param> all = await queryAllParams();
      bool isAdd = all.any((element) => element.key == 'testtime');
      if(isAdd) return;
    }
  }

  //刪除資料表中所有紀錄
  Future<int> deleteAll(String tb) async {
    Database db = await instance.database;
    var res = await isTableExists(tb);
    if (!res) _onCreate(db, _databaseVersion);
    return await db.delete(tb);
  }
  //刪除欄位中含有此字串
  Future<int> deleteByColLike(String tb, String col, String value) async {
  Database db = await instance.database;
  var res = await isTableExists(tb);
  if (!res) _onCreate(db, _databaseVersion);
  return await db.delete(tb, where: '$col LIKE ?', whereArgs: ['%$value%']);
  }
  //刪除欄位符合此字串
  Future<int> deleteByCol(String tb, String col, String value) async {
  Database db = await instance.database;
  var res = await isTableExists(tb);
  if (!res) _onCreate(db, _databaseVersion);
  return await db.delete(tb, where: '$col = ?', whereArgs: [value]);
  }
  //刪除資料表
  Future<void> deleteTable(String tb) async {
    final db = await instance.database;
    await db.execute("DROP TABLE IF EXISTS $tb");
  }
}
