import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraHeader2 extends StatelessWidget {
  CameraHeader2(this.title,
      {this.onBackPressed, this.onSelectImage, this.onDetectMode, this.onServiceMode, bool? isManual, bool? isDlib, bool? serviceMode})
      : isManual = isManual ?? false,
        isDlib = isDlib ?? false,
        serviceMode = serviceMode ?? true;
  final String title;
  final void Function()? onBackPressed;
  final void Function()? onSelectImage;
  final void Function()? onDetectMode;
  final void Function()? onServiceMode;
  final isManual;
  final isDlib;
  final serviceMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            InkWell(
              onTap: onBackPressed,
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 50,
                width: 50,
                child: Center(child: Icon(Icons.arrow_back)),
              ),
            ),
            isManual
                ? InkWell(
                    onTap: onServiceMode,
                    child: Container(
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 50,
                      width: 50,
                      child: Center(
                        child: serviceMode ? Text('線上版') : Text('離線版'),
                      ),
                    ),
                  )
                : SizedBox(
                    width: 20,
                  )
          ]),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: isManual || isDlib
                ? [
                    InkWell(
                      onTap: onDetectMode,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 50,
                        width: 50,
                        child: Center(child: Icon(Icons.face)),
                      ),
                    ),
                    InkWell(
                      onTap: onSelectImage,
                      child: Container(
                        margin: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 50,
                        width: 50,
                        child: Center(child: Icon(Icons.image)),
                      ),
                    ),
                  ]
                : [
                    SizedBox(
                      width: 60,
                    )
                  ],
          )
        ],
      ),
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.black, Colors.transparent],
        ),
      ),
    );
  }
}
