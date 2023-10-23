import 'dart:async';
import 'package:flutter/material.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:face_net_authentication/services/pub_service.dart';

class databaseMusicpage extends StatefulWidget {
  const databaseMusicpage({Key? key}) : super(key: key);

  @override
  State<databaseMusicpage> createState() => _databaseMusicpageState();
}

class _databaseMusicpageState extends State<databaseMusicpage> {
  DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool loading = false;
  List<Param>? params;
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  PermissionStatus? _storagePermissionStatus;
  String searchkey = '音樂';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkAndRequestPermissions();
    _initial();
  }

  void _initial() async {
    setState(() => loading = true);
    // await _dbHelper.createFakeDate();
    await _dbHelper.createTableIfNotExists(DatabaseHelper.param_table);
    updateParams();
    setState(() => loading = false);
  }

  //權限
  Future<void> _checkAndRequestPermissions() async {
    final storagePermissionStatus = await Permission.storage.status;
    setState(() {
      _storagePermissionStatus = storagePermissionStatus;
    });

    if (_storagePermissionStatus != PermissionStatus.granted) {
      final status = await Permission.storage.request();
      setState(() {
        _storagePermissionStatus = status;
      });
    }
  }

  void updateParams() async {
    List<Param> result = await _dbHelper.queryByColumnLike(DatabaseHelper.param_table, DatabaseHelper.columnKey, searchkey);
    setState(() {
      params = result;
    });
  }

  void deleteAllParam() async {
    await _dbHelper.deleteByColLike(DatabaseHelper.param_table, DatabaseHelper.columnKey, searchkey);
    await _dbHelper.deleteByCol(DatabaseHelper.param_table, DatabaseHelper.columnKey, Music.ring.description);
    _dbHelper.deleteByCol(DatabaseHelper.param_table, DatabaseHelper.columnKey, Music.already.description).then((value) => {updateParams()});
  }

  void deleteParam(int id) {
    _dbHelper.deleteDataById(id, DatabaseHelper.param_table).then((value) => {updateParams()});
  }

  Future<void> _pickMusic() async {
    // 從文件庫中選擇音樂文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    print(result);
    //處理每個文件存到DB  1.判斷副檔名須為mp3
    if (result != null) {
      result.files.forEach((element) {
        String extension = path.extension(element.path!);
        if (extension == '.mp3') {
          _addMusicToDB(element);
        }
      });
    }
    updateParams();
  }

  Future<String> _pickMusic2() async {
    // 從文件庫中選擇音樂文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    print(result);
    //處理每個文件存到DB  1.判斷副檔名須為mp3
    if (result != null) {
      return result.files[0].path!;
    }
    return '';
  }

  Future<void> _showDialog() async {
    String selectedValue = Music.ring.description;
    String musicpath = '';
    String filename = '';
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "新增音樂",
                style: TextStyle(fontSize: 20),
              ),
              content: SizedBox(
                width: 90,
                height: 90,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 120,
                        child: DropdownButton<String>(
                          value: selectedValue,
                          isExpanded: true,
                          items: [Music.ring.description, Music.success.description, Music.fail.description, Music.already.description]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedValue = newValue!;
                            });
                          },
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                            child: Icon(Icons.music_note, color: Colors.grey),
                            onTap: () async {
                              musicpath = await _pickMusic2();
                              setState(
                                () {
                                  filename = path.basename(musicpath);
                                },
                              );
                            }),
                        Text('$filename'),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
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
                    if (musicpath != '') {
                      _addMusicModeToDB(selectedValue, musicpath);
                    }
                    Navigator.of(context).pop();
                    updateParams();
                  },
                ),
              ],
            );
          });
        });
  }

  void _addMusicToDB(PlatformFile file) {
    Param pr = Param(key: '音樂', val: file.path!);
    _dbHelper.insertParam(pr);
  }

  void _addMusicModeToDB(String Mode, String file) {
    Param pr = Param(key: Mode, val: file);
    _dbHelper.insertParam(pr);
  }

  Future<void> playMusic({PlatformFile? file, String? path}) async {
    // 播放音樂的程式碼
    audioPlayer.setVolume(0.8);
    if (file != null)
      audioPlayer.open(Audio.file(file.path!));
    else if (path != null) audioPlayer.open(Audio.file(path));
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
                              Text('${param.key}        $filename'),
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
                              label: '播放',
                              onPressed: (BuildContext) async {
                                playMusic(path: param.val);
                              }),
                        ],
                        motion: DrawerMotion(),
                      ),
                    );
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
          children: [Text('音樂列表')],
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
                  case '清除所有音樂':
                    DatabaseHelper _dataBaseHelper = DatabaseHelper.instance;
                    deleteAllParam();
                    break;
                  case '播放音樂':
                    print('播放音樂');
                    break;
                  case '新增音樂':
                    _showDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'清除所有音樂', '播放音樂', '新增音樂'}.map((String choice) {
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
