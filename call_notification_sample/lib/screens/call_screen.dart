import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ios_call_notification_sample/managers/icaller.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';

import '../managers/android_call_manager.dart';
import '../managers/ios_call_manager.dart';

bool isAndroid = Platform.isAndroid;

class CallScreen extends StatefulWidget {
  final String? toUserId;
  final String? fromUserId;
  final bool incoming;
  final bool isVideo;

  CallScreen({
    Key? key,
    required this.fromUserId,
    required this.toUserId,
    required this.incoming,
    this.isVideo = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CallScreenState();
  }
}

class CallScreenState extends State<CallScreen> {
  bool showIncomingUI = false;
  late ICaller iCaller;

  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      iCaller = AndroidCallManager.instance;
    } else {
      iCaller = IOSCallManager.instance;
    }
    showIncomingUI = widget.incoming;
  }

  @override
  Widget build(BuildContext context) {
    print("[TEST] -> CallScreen showIncomingUI = $showIncomingUI");
    Widget nameCalling = new Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 120.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(bottom: 15.0),
            child: new Text(
              "${widget.toUserId}",
              style: new TextStyle(
                color: Colors.white,
                fontSize: 35.0,
              ),
            ),
          ),
          new Container(
            alignment: Alignment.center,
            child: new Text(
              iCaller.status,
              style: new TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          )
        ],
      ),
    );

    Widget bottomContainer = new Container(
      padding: EdgeInsets.only(bottom: 30.0),
      alignment: Alignment.bottomCenter,
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: showIncomingUI
              ? <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      new GestureDetector(
                        onTap: rejectCallTapped,
                        child: Image.asset(
                          'images/end.png',
                          height: 75.0,
                          width: 75.0,
                        ),
                      ),
                      new GestureDetector(
                        onTap: acceptCallTapped,
                        child: Image.asset(
                          'images/answer.png',
                          height: 75.0,
                          width: 75.0,
                        ),
                      ),
                    ],
                  )
                ]
              : <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new ButtonSpeaker(),
                      new ButtonMicro(),
                      new ButtonVideo(isVideo: widget.isVideo),
                    ],
                  ),
                  new Container(
                    padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: new GestureDetector(
                      onTap: endCallTapped,
                      child: Image.asset(
                        'images/end.png',
                        height: 75.0,
                        width: 75.0,
                      ),
                    ),
                  )
                ]),
    );

    Widget localView = iCaller.hasLocalStream
        ? new StringeeVideoView(
            iCaller.callId,
            true,
            alignment: Alignment.topRight,
            margin: EdgeInsets.only(top: 100.0, right: 25.0),
            height: 200.0,
            width: 150.0,
            scalingType: ScalingType.fill,
          )
        : Placeholder();

    Widget remoteView = iCaller.hasRemoteStream
        ? new StringeeVideoView(
            iCaller.callId,
            false,
            isMirror: false,
            scalingType: ScalingType.fill,
          )
        : Placeholder();

    return new Scaffold(
      backgroundColor: Colors.black,
      body: new Stack(
        children: <Widget>[
          remoteView,
          localView,
          nameCalling,
          bottomContainer,
          widget.isVideo ? ButtonSwitchCamera() : Placeholder(),
        ],
      ),
    );
  }


  void endCallTapped() {
    iCaller.hangup();
  }

  void acceptCallTapped() {
    iCaller.answer();
  }

  void rejectCallTapped() {
    iCaller.reject();
  }

  void changeToCallingUI() {
    setState(() {
      showIncomingUI = false;
    });
  }

  void dismiss() {
    Navigator.pop(context);
  }

  void onMuteState(bool isMute) {
    setState(() {

    });
  }

  void onReceiveLocalStream() {
    setState(() {

    });
  }

  void onReceiveRemoteStream() {
    setState(() {

    });
  }

  void onSpeakerState(bool isSpeakerOn) {
    if (mounted) {
      setState(() {

      });
    }
  }

  void onStatusChange(String status) {
    setState(() {

    });
  }

  void onVideoState(bool isVideoEnable) {
    setState(() {

    });
  }
}

class ButtonSwitchCamera extends StatefulWidget {
  ButtonSwitchCamera({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSwitchCameraState();
}

class _ButtonSwitchCameraState extends State<ButtonSwitchCamera> {
  void _toggleSwitchCamera() {
    iCaller.switchCamera();
  }

  late ICaller iCaller;
  @override
  void initState() {
    if (isAndroid) {
      iCaller = IOSCallManager.instance;
    } else {
      iCaller = AndroidCallManager.instance;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 50.0, top: 50.0),
        child: new GestureDetector(
          onTap: _toggleSwitchCamera,
          child: Image.asset(
            'images/switch_camera.png',
            height: 30.0,
            width: 30.0,
          ),
        ),
      ),
    );
  }
}

class ButtonSpeaker extends StatefulWidget {
  ButtonSpeaker({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSpeakerState();
}

class _ButtonSpeakerState extends State<ButtonSpeaker> {
  void _toggleSpeaker() {
    iCaller.toggleSpeaker();
  }

  late ICaller iCaller;
  @override
  void initState() {
    if (isAndroid) {
      iCaller = IOSCallManager.instance;
    } else {
      iCaller = AndroidCallManager.instance;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: _toggleSpeaker,
      child: Image.asset(
        iCaller.speakerOn
            ? 'images/ic_speaker_on.png'
            : 'images/ic_speaker_off.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonMicro extends StatefulWidget {
  ButtonMicro({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonMicroState();
}

class _ButtonMicroState extends State<ButtonMicro> {
  void _toggleMicro() {
    iCaller.toggleMute();
  }

  late ICaller iCaller;
  @override
  void initState() {
    if (isAndroid) {
      iCaller = IOSCallManager.instance;
    } else {
      iCaller = AndroidCallManager.instance;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: _toggleMicro,
      child: Image.asset(
        iCaller.isMute ? 'images/ic_mute.png' : 'images/ic_mic.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonVideo extends StatefulWidget {
  final bool isVideo;

  ButtonVideo({Key? key, required this.isVideo}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonVideoState();
}

class _ButtonVideoState extends State<ButtonVideo> {
  void _toggleVideo() {
    iCaller.toggleVideo();
  }

  late ICaller iCaller;
  @override
  void initState() {
    if (isAndroid) {
      iCaller = IOSCallManager.instance;
    } else {
      iCaller = AndroidCallManager.instance;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: widget.isVideo ? _toggleVideo : null,
      child: Image.asset(
        iCaller.videoOn
            ? 'images/ic_video.png'
            : 'images/ic_video_off.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}
