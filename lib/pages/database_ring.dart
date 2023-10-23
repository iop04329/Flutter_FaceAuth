import 'dart:async';
import 'package:flutter/material.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:path/path.dart' as path;

class databaseRingpage extends StatefulWidget {
  const databaseRingpage({Key? key}) : super(key: key);

  @override
  State<databaseRingpage> createState() => _databaseRingpageState();
}

class _databaseRingpageState extends State<databaseRingpage> {
  DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool loading = false;
  List<Param>? params;
  final _controller = TextEditingController();
  TimeOfDay? dt;

  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  late Timer timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initial();
  }

  void _initial() async {
    setState(() => loading = true);
    // await _dbHelper.createFakeDate();
    await _dbHelper.createTableIfNotExists(DatabaseHelper.param_table);
    params = await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, '打卡');
    setState(() => loading = false);
  }

  void playMusic() {
    // 播放音樂的程式碼
    audioPlayer.setVolume(0.8);
    audioPlayer.open(Audio('assets/audios/Short_mistery_003.mp3'));
  }

  void updateParams() {
    _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, '打卡').then((result) {
      setState(() {
        params = result;
      });
    });
  }

  void deleteParam(int id) {
    _dbHelper.deleteDataById(id, DatabaseHelper.param_table).then((value) => {updateParams()});
  }

  void updateParamTime(int id, String time) {
    _dbHelper.updateParamTime(id, time).then((value) => updateParams());
  }

  Future<void> _showDialog() async {
    dt = null;
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "設定打卡鐘",
                style: TextStyle(fontSize: 20),
              ),
              content: SizedBox(
                width: 50,
                height: 50,
                child: Row(
                  children: [
                    InkWell(
                        child: Icon(Icons.timer, color: Colors.grey),
                        onTap: () async {
                          dt = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!);
                            },
                          );
                        }),
                  ],
                ),
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
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
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
          child: params!.length == 0
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
                  itemCount: params!.length,
                  itemBuilder: (context, index) {
                    Param param = params![index];
                    String filename = path.basename(param.val);
                    return Slidable(
                        child: Card(
                          elevation: 5.0,
                          child: ListTile(
                              leading: Icon(
                                Icons.key,
                                color: Colors.blue,
                              ),
                              title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                                Text('${param.key}      $filename'),
                              ])),
                        ),
                        startActionPane: ActionPane(
                          children: [
                            SlidableAction(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: Icons.cancel,
                                label: '刪除',
                                onPressed: (BuildContext) {
                                  deleteParam(param.id!);
                                })
                          ],
                          motion: DrawerMotion(),
                        ),
                        endActionPane: ActionPane(
                          children: [
                            SlidableAction(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                icon: Icons.update,
                                label: '修改時間',
                                onPressed: (BuildContext) async {
                                  //開啟show time
                                  await _showDialog();
                                  //修改值
                                  if (dt != null) {
                                    updateParamTime(param.id!, dt?.format(context) ?? '未選擇時間');
                                  }
                                }),
                            // SlidableAction(
                            //     backgroundColor: Colors.green,
                            //     foregroundColor: Colors.white,
                            //     icon: Icons.check_circle,
                            //     label: 'Check',
                            //     onPressed: (BuildContext) {
                            //       updateUserCheckin(param.id!, 1);
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [Text('打卡鐘設定')],
        ),
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
                    await _dataBaseHelper.deleteAll(DatabaseHelper.param_table);
                    updateParams();
                    break;
                  case '新增打卡時間':
                    await _showDialog();
                    if (dt != null) {
                      Param pr = Param(key: '打卡', val: dt?.format(context) ?? '未選擇時間');
                      _dbHelper.insertParam(pr);
                      updateParams();
                    }
                    print(dt?.format(context) ?? '未選擇時間');
                    break;
                  case '播放打卡音樂':
                    playMusic();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'新增打卡時間', '清除資料表', '播放打卡音樂'}.map((String choice) {
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
