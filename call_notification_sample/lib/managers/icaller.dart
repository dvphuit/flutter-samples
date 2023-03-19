import 'package:flutter/material.dart';
import 'package:ios_call_notification_sample/screens/call_screen.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';

abstract class ICaller with WidgetsBindingObserver {
  static ICaller get instance {
    throw UnimplementedError();
  }

  var appLifecycleState = AppLifecycleState.resumed;
  var hasLocalStream = false;
  bool hasRemoteStream = false;
  StringeeCall? call;
  BuildContext? context;
  String? callId;
  bool isInCall = false;
  var isIncoming = false;
  GlobalKey<CallScreenState>? callScreenKey;

  CallScreenState? get uiState => callScreenKey?.currentState;
  var preSpeaker = false;
  var isVideoCall = false;
  var isAppInBackground = false;
  var isMute = true;
  var speakerOn = true;
  var videoOn = true;
  var status = "N/A";
  StringeeSignalingState? signalingState;
  StringeeMediaState? mediaState;

  void setContext(BuildContext? context) {
    this.context = context;
  }

  void configBackgroundMode();

  void registerCallEvents() {
    final call = this.call!;
    if (call.eventStreamController.hasListener) return;
    print("[TEST] -> registerCallEvents");
    call.eventStreamController.stream.listen((event) {
      print("[TEST] -> call event = $event");
      Map<dynamic, dynamic> map = event;
      switch (map['eventType']) {
        case StringeeCallEvents.didChangeSignalingState:
          handleSignalingStateChangeEvent(map['body']);
          break;
        case StringeeCallEvents.didChangeMediaState:
          handleMediaStateChangeEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveCallInfo:
          handleReceiveCallInfoEvent(map['body']);
          break;
        case StringeeCallEvents.didHandleOnAnotherDevice:
          handleHandleOnAnotherDeviceEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveLocalStream:
          handleReceiveLocalStreamEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveRemoteStream:
          handleReceiveRemoteStreamEvent(map['body']);
          break;
        case StringeeCallEvents.didChangeAudioDevice:
          handleChangeAudioDeviceEvent(map['body']);
          break;
        default:
          break;
      }
    });
  }

  void handleSignalingStateChangeEvent(StringeeSignalingState? state) {
    print('[TEST] -> handleSignalingStateChangeEvent - $state');
    signalingState = state;
    uiState?.onStatusChange(state.toString().split('.')[1]);
    switch (state) {
      case StringeeSignalingState.calling:
        break;
      case StringeeSignalingState.ringing:
        break;
      case StringeeSignalingState.answered:
        if (mediaState != StringeeMediaState.connected && this.call == null) return;

        this.call!.setSpeakerphoneOn(speakerOn);
        callScreenKey?.currentState?.onSpeakerState(speakerOn);
        if (this.call!.isVideoCall && hasLocalStream) {
          callScreenKey?.currentState?.onReceiveLocalStream();
        }
        break;
      case StringeeSignalingState.busy:
        clearDataEndDismiss('busy');
        break;
      case StringeeSignalingState.ended:
        clearDataEndDismiss('end');
        break;
      default:
        break;
    }
  }

  void handleChangeAudioDeviceEvent(AudioDevice? audioDevice) {
    print('handleChangeAudioDeviceEvent - $audioDevice');
    switch (audioDevice) {
      case AudioDevice.speakerPhone:
      case AudioDevice.earpiece:
        speakerOn = preSpeaker;
        if (this.call != null) {
          this.call!.setSpeakerphoneOn(speakerOn);
          callScreenKey?.currentState?.onSpeakerState(speakerOn);
        }
        break;
      case AudioDevice.bluetooth:
      case AudioDevice.wiredHeadset:
        preSpeaker = speakerOn;
        speakerOn = false;
        if (this.call != null) {
          this.call!.setSpeakerphoneOn(speakerOn);
          callScreenKey?.currentState?.onSpeakerState(speakerOn);
        }
        break;
      case AudioDevice.none:
      default:
        print('handleChangeAudioDeviceEvent - non audio devices connected');
        break;
    }
  }

  void handleMediaStateChangeEvent(StringeeMediaState? state) {
    print('[TEST] -> handleMediaStateChangeEvent - $state - $signalingState - $speakerOn');
    mediaState = state;
    uiState?.onStatusChange(state.toString().split('.')[1]);
    switch (state) {
      case StringeeMediaState.connected:
        if (signalingState == StringeeSignalingState.answered && this.call!.isVideoCall && hasLocalStream) {
          uiState?.onReceiveLocalStream();
        }
        if (signalingState == StringeeSignalingState.answered) {
          if (this.call != null) {
            this.call!.setSpeakerphoneOn(speakerOn);
          }
        }
        break;
      case StringeeMediaState.disconnected:
        break;
      default:
        break;
    }
  }

  void handleReceiveCallInfoEvent(Map<dynamic, dynamic>? info) {
    print('handleReceiveCallInfoEvent - $info');
  }

  void handleHandleOnAnotherDeviceEvent(StringeeSignalingState? state) {
    print('handleHandleOnAnotherDeviceEvent - $state');
  }

  void handleReceiveLocalStreamEvent(String? callId) {
    print('handleReceiveLocalStreamEvent - $callId');
    hasLocalStream = true;
    uiState?.onReceiveLocalStream();
  }

  void handleReceiveRemoteStreamEvent(String? callId) {
    print('[TEST] -> handleReceiveRemoteStreamEvent - $callId');
    if (call?.isVideoCall == true) {
      hasRemoteStream = true;
      uiState?.onReceiveRemoteStream();
    }
  }

  void handleIncomingCallEvent(BuildContext context, StringeeCall call) {
    print("[TEST] -> handleIncomingCallEvent, callId: " + call.id!);
    this.call = call;
    this.context = context;
    this.isIncoming = true;
    this.isVideoCall = call.isVideoCall;
    this.speakerOn = this.isVideoCall;
    this.preSpeaker = this.speakerOn;
    this.videoOn = this.isVideoCall;
    this.callId = call.id;
    registerCallEvents();

    if (isInCall) {
      reject();
    } else {
      this.call?.initAnswer().then((event) {
        bool status = event['status'];
        if (!status) {
          clearDataEndDismiss('init answer');
        }
      });

      if (!isAppInBackground) {
        showCallScreen();
      } else {
        isIncoming = true;
      }
    }
  }

  void showCallScreen() {
    if (context == null) return;
    print("[TEST] -> show call screen");
    callScreenKey = GlobalKey<CallScreenState>();
    CallScreen callScreen = CallScreen(
      key: callScreenKey,
      fromUserId: call?.to,
      toUserId: call?.from,
      isVideo: call?.isVideoCall == true,
      incoming: true,
    );
    Navigator.push(
      context!,
      MaterialPageRoute(builder: (context) => callScreen),
    );
  }

  void makeCall(Map<dynamic, dynamic> parameters);

  void answer() {
    print('[TEST] -> answer');
    this.call?.answer().then((result) {
      bool status = result['status'];
      if (status) {
        signalingState = StringeeSignalingState.answered;
        uiState?.changeToCallingUI();
        isInCall = true;
        isIncoming = false;
      } else {
        clearDataEndDismiss('answer');
      }
      return result;
    });
  }

  void hangup() {
    print('[TEST] -> hangup');
    call?.hangup().then((result) {
      if (result['status']) {
        // clearDataEndDismiss('hangup');
      }
    });
  }

  void reject() {
    print('[TEST] -> reject');
    call?.reject().then((result) {
      if (result['status']) {
        // clearDataEndDismiss('reject');
      }
    });
  }

  void switchCamera() {
    call?.switchCamera().then((result) {
      bool status = result['status'];
      if (status) {}
    });
  }

  void toggleMute() {
    isMute = !isMute;
    call?.mute(isMute).then((result) {
      bool status = result['status'];
      if (!status) {
        isMute = !isMute;
      } else {
        uiState?.onMuteState(isMute);
      }
    });
  }

  void toggleSpeaker() {
    speakerOn = !speakerOn;
    call?.setSpeakerphoneOn(speakerOn).then((result) {
      bool status = result['status'];
      if (!status) {
        speakerOn = !speakerOn;
      } else {
        uiState?.onSpeakerState(speakerOn);
      }
    });
  }

  void toggleVideo() {
    videoOn = !videoOn;
    call?.enableVideo(videoOn).then((result) {
      bool status = result['status'];
      if (!status) {
        videoOn = !videoOn;
      }
      uiState?.onVideoState(videoOn);
    });
  }

  void clearDataEndDismiss(String tag) {
    print('[TEST][$tag] -> clearDataEndDismiss');
    WidgetsBinding.instance.removeObserver(this);
    this.call?.destroy();
    this.call = null;

    isAppInBackground = false;
    isIncoming = false;
    videoOn = false;
    speakerOn = false;
    preSpeaker = false;
    videoOn = false;
    isMute = false;
    hasLocalStream = false;
    isInCall = false;
    callId = "";
    uiState?.dismiss();
  }
}
