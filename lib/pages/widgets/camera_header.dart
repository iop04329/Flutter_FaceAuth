import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CameraHeader extends StatelessWidget {
  CameraHeader(this.title, {this.onBackPressed, this.onServiceMode, bool? serviceMode});
  final String title;
  final void Function()? onBackPressed;
  final void Function()? onServiceMode;
  bool? serviceMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Stack(alignment: Alignment.center, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
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
                serviceMode == null
                    ? Container()
                    : InkWell(
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
                            child: serviceMode! ? Text('線上版') : Text('離線版'),
                          ),
                        ),
                      ),
              ],
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            // SizedBox(
            //   width: 90,
            // ),
            Text(
              DateFormat('MM/dd(E)\r\n  HH:mm:ss').format(DateTime.now()),
              style: TextStyle(color: Colors.white, fontSize: 17),
            )
          ],
        )
      ]),
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
