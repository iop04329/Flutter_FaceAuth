import 'dart:ui';

enum Music { ring, success, fail, already }

extension MusicExtension on Music {
  String get description {
    switch (this) {
      case Music.ring:
        return '打卡鐘音樂';
      case Music.success:
        return '成功音樂';
      case Music.fail:
        return '失敗音樂';
      case Music.already:
        return '已打卡音樂';
      default:
        return '';
    }
  }
}

enum Param_enum {url,exposure,coldtime,showtime,}

extension ParamExtension on Param_enum {
  String get description {
    switch (this) {
      case Param_enum.url:
        return '網址';
      case Param_enum.exposure:
        return '曝光值';
      case Param_enum.coldtime:
        return '冷卻';
      case Param_enum.showtime:
        return '顯示';
      default:
        return '';
    }
  }
}

class pub_service {
  late DateTime lastPopTime;
  bool isDebug = true; //控制dlib暫時不要開啟
  double centerX = 0;
  double centerY = 0;
  Size? widgetSize;

  Rect? WindowRect;
  bool isOverlay = false;

  Future initialize() async {
    lastPopTime = DateTime.now();
  }

  void setWindowRect(double x, double y) {
    int lineLen = 70; //控制框線長度
    int Xoffset = 100; //控制離中心的距離
    int Yoffset = 120; //控制離中心的距離
    centerX = x;
    centerY = y;
    double top = centerY - Yoffset;
    double left = centerX - Xoffset;
    double bottom = centerY + Yoffset;
    double right = centerX + Xoffset;
    WindowRect = Rect.fromLTRB(left, top, right, bottom);
  }

  bool checkRectOverlap(Rect rect1, Rect rect2, double overlapRatio) {
    Rect overlapRect = rect1.intersect(rect2);
    double overlapArea = overlapRect.width * overlapRect.height;
    double rect1Area = rect1.width * rect1.height;
    double ratio = overlapArea / rect1Area;

    return ratio >= overlapRatio;
  }

  Rect scaleRect({required Rect rect, required Size imageSize, required Size widgetSize}) {
    double scaleX = widgetSize.width / imageSize.width;
    double scaleY = widgetSize.height / imageSize.height;
    return Rect.fromLTRB(
      (widgetSize.width - rect.left.toDouble() * scaleX),
      rect.top.toDouble() * scaleY,
      widgetSize.width - rect.right.toDouble() * scaleX,
      rect.bottom.toDouble() * scaleY,
    );
  }

  bool intervalClick(int needTime) {
    // 防重复提交
    if (lastPopTime == null || DateTime.now().difference(lastPopTime) > Duration(seconds: needTime)) {
      // print(lastPopTime);
      lastPopTime = DateTime.now();
      print("允許點擊");
      return true;
    } else {
      // lastPopTime = DateTime.now(); //如果不注释这行,则强制用户一定要间隔2s后才能成功点击. 而不是以上一次点击成功的时间开始计算.
      print("請勿重複點擊！");
      return false;
    }
  }
}
