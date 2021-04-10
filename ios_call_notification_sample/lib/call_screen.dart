import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';
import 'call_manager.dart';
import 'sync_call.dart';

// StringeeCall globalCall;

class CallScreen extends StatefulWidget {
  // StringeeCall call;
  final String toUserId;
  final String fromUserId;
  bool isVideo = false;
  bool showIncomingUI = false;

  // bool hasLocalStream = false;
  // bool hasRemoteStream = false;
  // bool isSpeaker = false;
  // bool isMirror = true;

  bool dismissFuncCalled = false;

  CallScreen({
    Key key,
    @required this.fromUserId,
    @required this.toUserId,
    @required this.isVideo,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    print("CallScreen - createState");
    return CallScreenState();
  }
}

class CallScreenState extends State<CallScreen> {
  String status = "";
  // final GlobalKey<_ButtonMicroState> _buttonMicroStateKey = GlobalKey<_ButtonMicroState>();

  @override
  void initState() {
    print("CallScreen - initState");
    // TODO: implement initState
    super.initState();

    if (CallManager.shared.syncCall == null) {
      // Goi di
      makeOutgoingCall();
    } else {
      // Goi den
      widget.showIncomingUI = !CallManager.shared.syncCall.userAnswered;
    }
    // widget.showIncomingUI = widget.call != null;

    // Fix loi answer callkit trong background
    // if (CallManager.shared.syncCall != null && CallManager.shared.syncCall.userAnswered) {
    //   widget.showIncomingUI = false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    print("CallScreen - build");
    Widget NameCalling = new Container(
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
              '${CallManager.shared.syncCall != null ? CallManager.shared.syncCall.status : ""}',
              style: new TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          )
        ],
      ),
    );

    Widget BottomContainer = new Container(
      padding: EdgeInsets.only(bottom: 30.0),
      alignment: Alignment.bottomCenter,
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.showIncomingUI
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

    Widget localView = (CallManager.shared.syncCall.hasLocalStream)
        ? new StringeeVideoView(
      CallManager.shared.syncCall.stringeeCall.id,
      true,
      color: Colors.white,
      alignment: Alignment.topRight,
      isOverlay: true,
      isMirror: CallManager.shared.syncCall.isMirror,
      margin: EdgeInsets.only(top: 100.0, right: 25.0),
      height: 200.0,
      width: 150.0,
      scalingType: ScalingType.fill,
    )
        : Placeholder();

    Widget remoteView = (CallManager.shared.syncCall.hasRemoteStream)
        ? new StringeeVideoView(
      CallManager.shared.syncCall.stringeeCall.id,
      false,
      color: Colors.blue,
      isOverlay: false,
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
          NameCalling,
          BottomContainer,
          widget.isVideo ? ButtonSwitchCamera() : Placeholder(),
        ],
      ),
    );
  }

  Future makeOutgoingCall() async {
    // Neu la truong hop goi di thi can tao StringeeCall
    // if (globalCall == null) {
    //   globalCall = StringeeCall();
    // }

    // Listen events
    // globalCall.eventStreamController.stream.listen((event) {
    //   Map<dynamic, dynamic> map = event;
    //   switch (map['eventType']) {
    //     case StringeeCallEvents.didChangeSignalingState:
    //       handleSignalingStateChangeEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didChangeMediaState:
    //       handleMediaStateChangeEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didReceiveCallInfo:
    //       handleReceiveCallInfoEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didHandleOnAnotherDevice:
    //       handleHandleOnAnotherDeviceEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didReceiveLocalStream:
    //       handleReceiveLocalStreamEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didReceiveRemoteStream:
    //       handleReceiveRemoteStreamEvent(map['body']);
    //       break;
    //     case StringeeCallEvents.didChangeAudioDevice:
    //       if (Platform.isAndroid) {
    //         handleChangeAudioDeviceEvent(
    //             map['selectedAudioDevice'], globalCall);
    //       }
    //       break;
    //     default:
    //       break;
    //   }
    // });

    // if (widget.showIncomingUI) {
      // Truong hop cuoc goi den thi can goi ham initAnswer
      // globalCall.initAnswer().then((event) {
      //   bool status = event['status'];
      //   if (!status) {
      //     clearDataEndDismiss();
      //   }
      // });
    // } else {
      // Truong hop cuoc goi di thi can goi ham makeCall
      final parameters = {
        'from': widget.fromUserId,
        'to': widget.toUserId,
        'isVideoCall': widget.isVideo,
        'customData': null,
        'videoQuality': VideoQuality.hd,
      };

      var outgoingCall = StringeeCall();
      outgoingCall.makeCall(parameters).then((result) {
        bool status = result['status'];
        int code = result['code'];
        String message = result['message'];
        print(
            'MakeCall CallBack --- $status - $code - $message - ${outgoingCall.id} - ${outgoingCall.from} - ${outgoingCall.to}');

        var syncCall = SyncCall();
        syncCall.attachCall(outgoingCall);
        CallManager.shared.syncCall = syncCall;

        if (!status) {
          CallManager.shared.clearDataEndDismiss();
        }
      });
    // }
  }

  void endCallTapped() {
    // globalCall.hangup().then((result) {
    //   print('_endCallTapped -- ${result['message']}');
    //   bool status = result['status'];
    //   if (status) {
    //     if (Platform.isAndroid) {
    //       clearDataEndDismiss();
    //     }
    //   }
    // });
    print('endCallTapped');

    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.hangup().then((status) {
      if (Platform.isAndroid) {
        CallManager.shared.clearDataEndDismiss();
      }
    });
  }

  void acceptCallTapped() {
    // globalCall.answer().then((result) {
    //   print('_acceptCallTapped -- ${result['message']}');
    //   bool status = result['status'];
    //   if (!status) {
    //     clearDataEndDismiss();
    //   }
    // });
    //
    // // Thay doi tu giao dien incomingCall => giao dien calling
    // changeToCallingUI();accep

    // Tạm thời chưa xử lý button này vì các thư viện Callkit bên flutter chưa hỗ trở API để answer Callkit Call
    return;

    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.userAnswered = true;
    CallManager.shared.syncCall.answerIfConditionPassed();
  }

  void rejectCallTapped() {
    // globalCall.reject().then((result) {
    //   print('_rejectCallTapped -- ${result['message']}');
    //   if (Platform.isAndroid) {
    //     clearDataEndDismiss();
    //   }
    // });

    if (CallManager.shared.syncCall == null) {
      return;
    }
    CallManager.shared.syncCall.userRejected = true;
    CallManager.shared.syncCall.reject().then((status) {
      if (Platform.isAndroid) {
        CallManager.shared.clearDataEndDismiss();
      }
    });
  }

  void changeToCallingUI() {
    print("changeToCallingUI, before: " + widget.showIncomingUI.toString());
    setState(() {
      widget.showIncomingUI = false;
    });
    print("changeToCallingUI, after: " + widget.showIncomingUI.toString());
  }

  // void handleSignalingStateChangeEvent(StringeeSignalingState state) {
  //   print('handleSignalingStateChangeEvent - $state');
  //   setState(() {
  //     status = state.toString().split('.')[1];
  //   });
  //   CallManager.shared.syncCall.callState = state;
  //   switch (state) {
  //     case StringeeSignalingState.calling:
  //       break;
  //     case StringeeSignalingState.ringing:
  //       break;
  //     case StringeeSignalingState.answered:
  //       break;
  //     case StringeeSignalingState.busy:
  //       CallManager.shared.syncCall.endedStringeeCall = true;
  //       clearDataEndDismiss();
  //       break;
  //     case StringeeSignalingState.ended:
  //       CallManager.shared.syncCall.endedStringeeCall = true;
  //       clearDataEndDismiss();
  //       break;
  //     default:
  //       break;
  //   }
  // }
  //
  // void handleMediaStateChangeEvent(StringeeMediaState state) {
  //   print('handleMediaStateChangeEvent - $state');
  //   setState(() {
  //     status = state.toString().split('.')[1];
  //   });
  //   switch (state) {
  //     case StringeeMediaState.connected:
  //       break;
  //     case StringeeMediaState.disconnected:
  //       break;
  //     default:
  //       break;
  //   }
  // }
  //
  // void handleReceiveCallInfoEvent(Map<dynamic, dynamic> info) {
  //   print('handleReceiveCallInfoEvent - $info');
  // }
  //
  // void handleHandleOnAnotherDeviceEvent(StringeeSignalingState state) {
  //   print('handleHandleOnAnotherDeviceEvent - $state');
  // }
  //
  // void handleReceiveLocalStreamEvent(String callId) {
  //   print('handleReceiveLocalStreamEvent - $callId');
  //   setState(() {
  //     widget.hasLocalStream = true;
  //   });
  // }
  //
  // void handleReceiveRemoteStreamEvent(String callId) {
  //   print('handleReceiveRemoteStreamEvent - $callId');
  //   setState(() {
  //     widget.hasRemoteStream = true;
  //   });
  // }
  //
  // void handleChangeAudioDeviceEvent(
  //     AudioDevice audioDevice, StringeeCall call) {
  //   print('handleChangeAudioDeviceEvent - $audioDevice');
  //   switch (audioDevice) {
  //     case AudioDevice.speakerPhone:
  //     case AudioDevice.earpiece:
  //       if (call != null) {
  //         call.setSpeakerphoneOn(widget.isSpeaker);
  //       }
  //       break;
  //     case AudioDevice.bluetooth:
  //     case AudioDevice.wiredHeadset:
  //       widget.isSpeaker = false;
  //       if (call != null) {
  //         call.setSpeakerphoneOn(widget.isSpeaker);
  //       }
  //       break;
  //     case AudioDevice.none:
  //       print('handleChangeAudioDeviceEvent - non audio devices connected');
  //       break;
  //   }
  // }

  // void changeButtonMuteState(bool mute) {
  //   _buttonMicroStateKey.currentState.updateUI(mute);
  // }

  // void clearDataEndDismiss() {
  //   print('clearDataEndDismiss');
  //   if (widget.dismissFuncCalled) {
  //     return;
  //   }
  //   print('clearDataEndDismiss is executed');
  //   widget.dismissFuncCalled = !widget.dismissFuncCalled;
  //
  //   CallManager.shared.endCallkit();
  //   CallManager.shared.deleteSyncCallIfNeed();
  //   CallManager.shared.callScreenKey = null;
  //
  //   globalCall.destroy();
  //   Navigator.pop(context);
  // }

  void dismiss() {
    if (widget.dismissFuncCalled) {
      return;
    }
    widget.dismissFuncCalled = !widget.dismissFuncCalled;
    Navigator.pop(context);
  }
}

class ButtonSwitchCamera extends StatefulWidget {

  ButtonSwitchCamera({
    Key key
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSwitchCameraState();
}

class _ButtonSwitchCameraState extends State<ButtonSwitchCamera> {

  void _toggleSwitchCamera() {
    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.switchCamera();
    // globalCall.switchCamera(widget.isMirror).then((result) {
    //   bool status = result['status'];
    //   if (status) {}
    // });
  }

  @override
  void initState() {
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
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSpeakerState();
}

class _ButtonSpeakerState extends State<ButtonSpeaker> {

  void _toggleSpeaker() {
    // globalCall.setSpeakerphoneOn(!_isSpeaker).then((result) {
    //   bool status = result['status'];
    //   if (status) {
    //     setState(() {
    //       _isSpeaker = !_isSpeaker;
    //     });
    //   }
    // });

    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.setSpeakerphoneOn();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: _toggleSpeaker,
      child: Image.asset(
        CallManager.shared.syncCall.isSpeaker ? 'images/ic_speaker_off.png' : 'images/ic_speaker_on.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonMicro extends StatefulWidget {

  ButtonMicro({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonMicroState();
}

class _ButtonMicroState extends State<ButtonMicro> {

  void _toggleMicro() {
    // globalCall.mute(!_isMute).then((result) {
    //   bool status = result['status'];
    //   if (status) {
    //     setState(() {
    //       _isMute = !_isMute;
    //     });
    //   }
    // });

    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.mute();
  }

  // void updateUI(bool mute) {
  //   setState(() {
  //     _isMute = mute;
  //   });
  // }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: _toggleMicro,
      child: Image.asset(
        CallManager.shared.syncCall.isMute ? 'images/ic_mute.png' : 'images/ic_mic.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonVideo extends StatefulWidget {
  final bool isVideo;

  ButtonVideo({
    Key key,
    @required this.isVideo
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonVideoState();
}

class _ButtonVideoState extends State<ButtonVideo> {

  void _toggleVideo() {
    // globalCall.enableVideo(!_isVideoEnable).then((result) {
    //   bool status = result['status'];
    //   if (status) {
    //     setState(() {
    //       _isVideoEnable = !_isVideoEnable;
    //     });
    //   }
    // });

    if (CallManager.shared.syncCall == null) {
      return;
    }

    CallManager.shared.syncCall.enableVideo();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new GestureDetector(
      onTap: widget.isVideo ? _toggleVideo : null,
      child: Image.asset(
        CallManager.shared.syncCall.videoEnabled ? 'images/ic_video.png' : 'images/ic_video_off.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}
