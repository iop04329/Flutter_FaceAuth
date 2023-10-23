import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/database_user.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:face_net_authentication/pages/sign-up.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/pub_service.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import 'app_text_field.dart';

class AuthActionButton extends StatefulWidget {
  AuthActionButton({Key? key, this.user, required this.onPressed, required this.isLogin, required this.reload, bool? isManual})
      : isManual = isManual ?? false,
        super(key: key);
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  final User? user;
  final isManual;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  final MLService _mlService = locator<MLService>();
  final CameraService _cameraService = locator<CameraService>();
  final pub_service _pubService = locator<pub_service>();

  final TextEditingController _userTextEditingController = TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController = TextEditingController(text: '');

  User? predictedUser;
  bool isClick = false;

  Future _signUp(context) async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    //判斷是否已註冊
    String name = widget.user == null ? _userTextEditingController.text : widget.user!.user;
    String userid = widget.user == null ? _passwordTextEditingController.text : widget.user!.userid;
    User? user;
    List predictedData = _mlService.predictedData;
    List<double> predictedDataAsDouble = predictedData.cast<double>();
    if(widget.user == null){
      user = await _databaseHelper.getUserByUserId(userid);
    } else{
      user = widget.user;
    }
    if (predictedDataAsDouble.length == 0) return; //沒有偵測到人臉 不做登入
    //判斷新增user還是新增人臉
    try {
      if (user == null) {
        //新註冊
        if (_mlService.is5SignUp) {
          User userToSave = User(
            user: name,
            userid: userid,
            modelData: _mlService.userListface, //指向_mlService.user5face記憶體位置 因為它是一個物件
          );
          await _databaseHelper.insertUser(userToSave);
          _mlService.userListface = []; //初始化
        } else {
          List<List<double>> models = [];
          models.add(predictedDataAsDouble);

          User userToSave = User(
            user: name,
            userid: userid,
            modelData: models,
          );
          await _databaseHelper.insertUser(userToSave);
        }
      } else {
        //更新
        if (_mlService.is5SignUp) {
          _mlService.userListface.forEach((element) {
            user!.modelData.add(element);
          });
        } else {
          user.modelData.add(predictedDataAsDouble);
        }
        await _databaseHelper.updateModelData(user.id!, user.modelData);
      }
    } catch (e) {
      print('Error AuthActionButton _signUp => $e');
    }

    this._mlService.setPredictedData([]);

    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => SignUp()),
    // );
    _mlService.is5SignUp
        ? widget.isManual
            ? Navigator.popUntil(context, ModalRoute.withName('/signupManual'))
            : Navigator.popUntil(context, ModalRoute.withName('/signup'))
        : Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => databaseUserpage()));

    // Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    if (this.predictedUser!.userid == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Profile(
                    this.predictedUser!.user,
                    imagePath: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('員工編號錯誤!'),
          );
        },
      );
    }
  }

  Future<User?> _predictUser() async {
    User? userAndPass = await _mlService.predict();
    return userAndPass;
  }

  Future onTap() async {
    try {
      _pubService.intervalClick(2);
      bool faceDetected = await widget.onPressed(); //這邊觸發 父類執行onPressed 那邊進行重繪後 這邊接續執行
      if (faceDetected) {
        if (widget.isLogin) {
          var user = await _predictUser();
          if (user != null) {
            this.predictedUser = user;
          }
        }
        PersistentBottomSheetController bottomSheetController = Scaffold.of(context).showBottomSheet((context) => signSheet(context));
        bottomSheetController.closed.whenComplete(() => widget.reload());
      }
    } catch (e) {
      print('AuthActionButton onTap() => error:$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue[200],
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '拍照',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }

  signSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && predictedUser != null
              ? Container(
                  child: Text(
                    '歡迎回來, ' + predictedUser!.user + '.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : widget.isLogin
                  ? Container(
                      child: Text(
                      '未找到使用者 😞',
                      style: TextStyle(fontSize: 20),
                    ))
                  : Container(),
          Container(
            child: Column(
              children: [
                !widget.isLogin
                    ? widget.user == null
                        ? AppTextField(controller: _userTextEditingController, labelText: "使用者名稱")
                        : Container()
                    : Container(),
                SizedBox(height: 10),
                !widget.isLogin
                    ? widget.user == null
                        ? AppTextField(
                            controller: _passwordTextEditingController,
                            labelText: "員工編號",
                            isPassword: false,
                          )
                        : Container()
                    : Container(),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                widget.isLogin && predictedUser != null
                    ? InkWell(
                        onTap: () async {
                          _signIn(context);
                        },
                        child: AppButton(text: '登入', icon: Icon(Icons.login, color: Colors.white)))
                    : !widget.isLogin
                        ? InkWell(
                            onTap: () async {
                              await _signUp(context);
                            },
                            child: AppButton(text: '註冊', icon: Icon(Icons.person_add, color: Colors.white)))
                        : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
