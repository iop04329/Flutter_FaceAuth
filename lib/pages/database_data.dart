import 'dart:async';
import 'package:face_net_authentication/pages/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/services/pub_service.dart';
import 'package:face_net_authentication/pages/models/param.model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';

class databaseDatapage extends StatefulWidget {
  const databaseDatapage({Key? key}) : super(key: key);

  @override
  State<databaseDatapage> createState() => _databaseDatapageState();
}

class _databaseDatapageState extends State<databaseDatapage> {
  DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool loading = false;
  List<Param> params = [];
  final TextEditingController _valTextEditingController = TextEditingController(text: '');
  Dio dio = Dio();

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
    updateParams();
    setState(() => loading = false);
  }

  void updateParams() async {
    List<Param> result = await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.url.description);
    result.addAll(await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.exposure.description));
    result.addAll(await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.coldtime.description));
    result.addAll(await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.showtime.description));
    setState(() {
      params = result;
    });
  }

  void deleteParam(int id) {
    _dbHelper.deleteDataById(id, DatabaseHelper.param_table).then((value) => {updateParams()});
  }

  void insert_update_Param(String key, String val) async {
    if (key != '' && val != '') {
      List<Param> res = await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, key);
      if (res.isNotEmpty) {
        await _dbHelper.updateParamVal(res[0].id!, val);
      } else {
        Param pr = Param(key: key, val: val);
        await _dbHelper.insertParam(pr);
      }
    }
  }

  void testUrl() async {
    List<Param> urlParam = await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, Param_enum.url.description);
    if (urlParam.isNotEmpty) {
      // String uri = '${urlParam[0].val}?who=0014';
      // final url = Uri.parse(uri);
      // var res = await dio.requestUri(url);
      dio.options.baseUrl = urlParam[0].val;
      var res = await dio.get('', queryParameters: {'who': '0014'});
      showGeneralDialog(
          context: context,
          pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
            return AlertDialog(
                surfaceTintColor: Colors.transparent,
                alignment: Alignment(0.0, -0.7),
                content: Container(
                  height: 20,
                  child: Text('${res.data}'),
                ));
          },
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 500));
      await Future.delayed(Duration(milliseconds: 1000)).then((value) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      showGeneralDialog(
          context: context,
          pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
            return AlertDialog(
                surfaceTintColor: Colors.transparent,
                alignment: Alignment(0.0, -0.7),
                content: Container(
                  height: 20,
                  child: Text('請先新增url參數'),
                ));
          },
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 500));
      await Future.delayed(Duration(milliseconds: 1000)).then((value) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _showDialog({String? key, String? val}) async {
    String selectedValue = Param_enum.url.description;
    if (val != null) selectedValue = key!;
    if (val != null)
      _valTextEditingController.text = val;
    else
      _valTextEditingController.text = '';
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "設定參數",
                style: TextStyle(fontSize: 20),
              ),
              content: Container(
                  width: 200,
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 120,
                          child: DropdownButton<String>(
                            value: selectedValue,
                            isExpanded: true,
                            items: [
                              Param_enum.url.description,
                              Param_enum.exposure.description,
                              Param_enum.coldtime.description,
                              Param_enum.showtime.description
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) async {
                              List<Param> pr = await _dbHelper.queryByColumn(DatabaseHelper.param_table, DatabaseHelper.columnKey, newValue!);
                              if (pr.isNotEmpty) _valTextEditingController.text = pr[0].val;
                              if (pr.isEmpty) _valTextEditingController.text = '';
                              selectedValue = newValue;
                              setState(() {});
                            },
                          )),
                      SizedBox(
                        width: 150,
                        child: AppTextField(
                          controller: _valTextEditingController,
                          labelText: "值",
                        ),
                      ),
                    ],
                  )),
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
                    String key = selectedValue;
                    String val = _valTextEditingController.text;
                    insert_update_Param(key, val);
                    updateParams();
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
          child: params.length == 0
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
                  itemCount: params.length,
                  itemBuilder: (context, index) {
                    Param param = params[index];
                    String filename = param.val;
                    return Slidable(
                        child: Card(
                          elevation: 5.0,
                          child: ListTile(
                              leading: Text('${param.key}'),
                              title: Expanded(
                                child: Text(
                                  '$filename',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
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
                                label: '修改參數',
                                onPressed: (BuildContext) async {
                                  await _showDialog(key: param.key, val: param.val);
                                  updateParams();
                                }),
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
          children: [Text('參數設定')],
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
                  case '新增參數':
                    await _showDialog();
                    break;
                  case '發送Url測試':
                    testUrl();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'清除資料表', '新增參數', '發送Url測試'}.map((String choice) {
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
