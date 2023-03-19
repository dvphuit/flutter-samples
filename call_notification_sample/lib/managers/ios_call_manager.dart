import 'package:callkeep/callkeep.dart';
import 'package:flutter/material.dart';
import 'package:ios_call_notification_sample/managers/icaller.dart';
import 'package:ios_call_notification_sample/managers/instance_manager.dart';

class IOSCallManager extends ICaller {
  static IOSCallManager? _instance;

  static ICaller get instance {
    return _instance ??= IOSCallManager._internal();
  }
  static IOSCallManager get shared {
    return instance as IOSCallManager;
  }

  IOSCallManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final callKeep = FlutterCallkeep();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('didChangeAppLifecycleState = $state');
    appLifecycleState = state;
    if (state == AppLifecycleState.resumed && call != null) {
      isAppInBackground = false;
      showCallScreen();
    }

    if (state == AppLifecycleState.inactive) {
      isAppInBackground = true;
    }
  }

  @override
  void makeCall(Map<dynamic, dynamic> parameters) {
    this.call!.makeCall(parameters).then((result) {
      this.callId = this.call!.id;
      bool status = result['status'];
      int? code = result['code'];
      String? message = result['message'];
      print(
          'MakeCall CallBack --- $status - $code - $message - ${this.call!.id} - ${this.call!.from} - ${this.call!.to}');
      isInCall = status;
      if (!status) {
        clearDataEndDismiss('make call');
      }
    });
  }

  void onPushKitIncomingCall(CallKeepDidDisplayIncomingCall event){
    print("[TEST][PushKit] -> incoming = ${event.toString()}");
  }

  void onPushKitAnswerCall(CallKeepPerformAnswerCallAction event){
    print("[TEST][PushKit] -> answer = ${event.toString()}");
  }

  void onPushKitEndCall(CallKeepPerformEndCallAction event){
    print("[TEST][PushKit] -> end = ${event.toString()}");
  }

  void onPushKitMute(CallKeepDidPerformSetMutedCallAction event){
    print("[TEST][PushKit] -> mute = ${event.toString()}");
  }

  void onPushKitActivateAudioSession(CallKeepDidActivateAudioSession event){
    print("[TEST][PushKit] -> event = ${event.toString()}");
  }

  @override
  void configBackgroundMode() {
    callKeep.endAllCalls();
    callKeep.on(CallKeepPushKitToken(), onPushKitToken);
    callKeep.on(CallKeepDidDisplayIncomingCall(), onPushKitIncomingCall);
    callKeep.on(CallKeepPushKitReceivedNotification(), onPushKitNotification);
    callKeep.on(CallKeepPerformAnswerCallAction(), onPushKitAnswerCall);
    callKeep.on(CallKeepPerformEndCallAction(), onPushKitEndCall);
    callKeep.on(CallKeepDidPerformSetMutedCallAction(), onPushKitMute);
    callKeep.on(CallKeepDidActivateAudioSession(), onPushKitActivateAudioSession);

    callKeep.setup(context, <String, dynamic>{
      'ios': {
        'appName': 'VinfaMedi',
      }
    });
  }

  static void onPushKitToken(CallKeepPushKitToken event) {
    print('[onPushKitToken] token => ${event.token}');
    if (event.token != null) {
      StringeeUtil.setPushToken(event.token!);
    }
  }

  static Future<void> onPushKitNotification(CallKeepPushKitReceivedNotification event) async {
    print('[TEST] onPushKitNotification, callId: ${event.callId}, callStatus: ${event.callStatus}, uuid: ${event.uuid}, serial: ${event.serial}');
    String callId = event.callId!;
    String? callStatus = event.callStatus;
    String? uuid = event.uuid;
    int? serial = event.serial;

    // call khong hop le => can end o day
    if (callId.isEmpty || callStatus != "started") {
      print("[TEST] -> onPushKitNotification invalid call");
      callKeep.endCall(uuid!);
      return;
    }

    // call da duoc xu ly roi thi ko xu ly lai => can end callkit da duoc show ben native
    // if (IOSCallManager.shared.checkIfCallIsHandledOrNot(callId, serial) == true) {
    //   print("[TEST] -> onPushKitNotification in call");
    //   callKeep.endCall(uuid!);
    //   IOSCallManager.shared.removeSyncCallFromHandledCallList(callId, serial);
    //   return;
    // }

    // Chưa có sync call (Trường hợp cuộc gọi mới) => tạo sync call và lưu lại thông tin
    // SyncCall? syncCall = IOSCallManager.shared.syncCall;
    // if (syncCall == null) {
    //   print("[TEST] -> onPushKitNotification new call");
    //   syncCall = new SyncCall();
    //   syncCall.callId = callId;
    //   syncCall.serial = serial;
    //   syncCall.uuid = uuid;
    //   IOSCallManager.shared.syncCall = syncCall;
    //   IOSCallManager.shared.currentUuid = event.uuid;
    //   IOSCallManager.shared.startTimeoutForIncomingCall();
    //   return;
    // }

    // Đã có sync call nhưng là của cuộc gọi khác => end callkit này (callkit vừa được show bên native)
    // if (!syncCall.isThisCall(callId, serial)) {
    //   print("[TEST] -> onPushKitNotification in this call");
    //   // _callKit.endCall(uuid);
    //   callKeep.endCall(uuid!);
    //   return;
    // }

    // Đã có sync call, thông tin cuộc gọi là trùng khớp, nhưng đã show callkit rồi => end callkit vừa show
    // if (syncCall.showedCallkit() && syncCall.uuid != uuid) {
    //   print("[TEST] -> onPushKitNotification another call");
    //   // _callKit.endCall(uuid);
    //   callKeep.endCall(uuid!);
    // }
  }
}
