import 'package:flutter/material.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/sign-up.dart';
import 'package:face_net_authentication/pages/sign-up manual.dart';

class databaseUserpage extends StatefulWidget {
  const databaseUserpage({Key? key}) : super(key: key);

  @override
  State<databaseUserpage> createState() => _databaseUserpageState();
}

class _databaseUserpageState extends State<databaseUserpage> {
  DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool loading = false;
  List<User>? users;
  final _controller = TextEditingController();
  MLService _mlService = locator<MLService>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initial();
  }

  void _initial() async {
    setState(() => loading = true);
    // await _dbHelper.createFakeDate();
    await _dbHelper.createTableIfNotExists(DatabaseHelper.user_table);
    users = await _dbHelper.queryAllUsers();
    setState(() => loading = false);
  }

  void updateUsers() {
    _dbHelper.queryAllUsers().then((result) {
      setState(() {
        users = result;
      });
    });
  }

  void deleteUser(int id) {
    _dbHelper.deleteDataById(id,DatabaseHelper.user_table).then((value) => {updateUsers()});
  }

  void updateUserCheckin(int id, int mode) {
    _dbHelper.updateCheckin(id, mode).then((value) => updateUsers());
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("請輸入數字(數字越小越嚴謹)",style: TextStyle(fontSize: 15),),
            content: TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            actions: [
              TextButton(
                child: Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("確定"),
                onPressed: () {
                  final double num = double.parse(_controller.text);
                  _mlService.setThreshold(num);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    late Widget body;
    final wd = MediaQuery.of(context).size.width;
    final hg = MediaQuery.of(context).size.height;

    if (loading) {
      body = Center(
        child: CircularProgressIndicator(),
      );
    } else {
      body = SingleChildScrollView(
        child: SafeArea(
          child: users!.length == 0
              ? Container(
                  height: hg - 80,
                  width: wd,
                  child: Center(
                      child: Text(
                    '無資料',
                    style: TextStyle(fontSize: 30),
                  )))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: users!.length,
                  itemBuilder: (context, index) {
                    User us = users![index];
                    Widget checkicon =
                        us.checktime != '' ? Text('${us.checktime.toString().substring(11,19)}', style: TextStyle(color: Colors.green)) : Text('未打卡', style: TextStyle(color: Colors.red));
                    return Slidable(
                        child: Card(
                          elevation: 5.0,
                          child: ListTile(
                              leading: Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                                Text('${us.userid}'),
                                Padding(padding: EdgeInsets.only(left: 20)),
                                Text('${us.user.toString()}'),
                                Padding(padding: EdgeInsets.only(left: 20)),
                                Text('人臉數:${us.modelData.length}')
                              ]),
                              trailing: checkicon),
                        ),
                        startActionPane: ActionPane(
                          children: [
                            SlidableAction(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: Icons.cancel,
                                label: '刪除',
                                onPressed: (BuildContext) {
                                  deleteUser(us.id!);
                                })
                          ],
                          motion: DrawerMotion(),
                        ),
                        endActionPane: ActionPane(
                          children: [
                            // SlidableAction(
                            //     backgroundColor: Colors.red,
                            //     foregroundColor: Colors.white,
                            //     icon: Icons.unpublished,
                            //     label: 'UnCheck',
                            //     onPressed: (BuildContext) {
                            //       updateUserCheckin(us.id!, 0);
                            //     }),
                            SlidableAction(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.face,
                                label: '註冊',
                                onPressed: (BuildContext) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignUpManual(user: us,)),
                                  );
                                }),
                            // SlidableAction(
                            //     backgroundColor: Colors.green,
                            //     foregroundColor: Colors.white,
                            //     icon: Icons.check_circle,
                            //     label: 'Check',
                            //     onPressed: (BuildContext) {
                            //       updateUserCheckin(us.id!, 1);
                            //     })
                          ],
                          motion: DrawerMotion(),
                        ));
                  }),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,children: [Text('員工詳細資訊'),Text('辨識率:${_mlService.threshold}')],),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10, top: 0),
            child: PopupMenuButton<String>(
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onSelected: (value) async {
                switch (value) {
                  case '清除資料表':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    await _dataBaseHelper.deleteAll(DatabaseHelper.user_table);
                    updateUsers();
                    break;
                  case '全部未打卡':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    users!.forEach((element) {
                      _dataBaseHelper.updateCheckin(element.id!, 0);
                    });
                    updateUsers();
                    break;
                  case '設定門檻':
                    _showDialog();
                    break;
                  case '刪除資料表':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    _dataBaseHelper.deleteTable(DatabaseHelper.user_table);
                    break;
                  case '初始化資料表':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    _dataBaseHelper.createTableIfNotExists(DatabaseHelper.user_table);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'清除資料表', '全部未打卡', '設定門檻','刪除資料表','初始化資料表'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
