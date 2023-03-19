/*
    Ý tưởng:
    Trên iOS 13, luồng nhận cuộc gọi onIncomingCall event từ Stringee SDK và luồng nhận push từ apple sẽ là bất đồng bộ.
    Để apply theo rule mới của apple, sử dụng class này để map giữa push và call
    Một thời điểm sẽ chỉ có 1 cuộc gọi được xử lý, các cuộc khác đến khi đang có cuộc gọi thì sẽ reject.

    Đối tượng này sẽ wrap 1 StringeeCall object và lưu 1 số trạng thái của cuộc gọi
**/

import 'package:ios_call_notification_sample/managers/background_manager.dart';
import 'package:ios_call_notification_sample/managers/ios_call_manager.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';

class SyncCall {
  StringeeCall? stringeeCall;

  int? serial = 1;
  String? callId = '';
  String? uuid = ''; // uuid da su dung de show callkit
  StringeeSignalingState? callState = StringeeSignalingState.calling; // trang thai cua StringeeCall

  bool userRejected = false;
  bool userAnswered = false;
  bool callAnswered = false;

  // AudioSession của iOS đã được active thì khi answer call của Stringee mới kết nối thoại được
  bool audioSessionActived = false;

  bool endedCallkit = false;
  bool endedStringeeCall = false;

  bool isMute = false;
  bool isSpeaker = false;
  bool videoEnabled = false;
  bool hasLocalStream = false;
  bool hasRemoteStream = false;
  var _status = '';

  // Thêm biến này để check nếu là lần đầu media connected thì nếu là cuộc gọi video sẽ cho audio ra loa ngoài
  bool mediaFirstTimeConnected = false;

  set status(value) {
    _status = value;
    updateUI();
  }

  get status => _status;

  bool showedCallkit() {
    return uuid!.isNotEmpty;
  }

  bool isThisCall(String? callId, int? serial) {
    return this.callId == callId && this.serial == serial;
  }

  bool ended() {
    bool callkitEndStatus = false;
    if (uuid!.isEmpty) {
      callkitEndStatus = true;
    } else {
      callkitEndStatus = endedCallkit;
    }
    return callkitEndStatus && endedStringeeCall;
  }

  void attachCall(StringeeCall call) {
    stringeeCall = call;
    serial = call.serial;
    callId = call.id;
    videoEnabled = call.isVideoCall;
  }

  void answerCallkitCall() {
    if (uuid?.isEmpty == true) return;
    BackgroundManager.callKeep.answerIncomingCall(uuid!);
  }

  void answerIfConditionPassed() {
    /*
      Voi iOS, Answer StringeeCall khi thoa man cac yeu to:
      1. Da nhan duoc su kien incomingCall (có StringeeCall object) hoac incomingCall2 (co StringeeCall2 object)
      2. User da click answer
      3. Chua goi ham answer cua StringeeCall lan nao
      4. AudioSession da active
    **/
    if (!userAnswered || callAnswered || !audioSessionActived || stringeeCall == null) {
      print('answerIfConditionPassed, condition has not been passed, userAnswered: ' +
          userAnswered.toString() +
          ", callAnswered: " +
          callAnswered.toString() +
          ", audioSessionActived: " +
          audioSessionActived.toString());
      return;
    }

    // Cập nhật giao diện từ incomingCall ==> calling
    if (IOSCallManager.shared.callScreenKey != null && IOSCallManager.shared.callScreenKey!.currentState != null) {
      IOSCallManager.shared.callScreenKey!.currentState!.changeToCallingUI();
    }

    if (stringeeCall != null) {
      stringeeCall!.answer().then((result) {
        String message = result['message'];
        bool status = result['status'];
        print("answer: " + message);
        callAnswered = true;
        if (!status) {
          endCallIfNeed();
        }
      });
    }
  }

  void endCall() {
    endedCallkit = true;
    userRejected = true;
    print("[TEST] -> syncCall stringee = $stringeeCall, state = $callState");
    if (hasStringeeCall() && callState != StringeeSignalingState.busy && callState != StringeeSignalingState.ended) {
      print("[TEST] -> syncCall end");
      if (callAnswered) {
        hangup();
      } else {
        reject();
      }
    } else {
      print("[TEST] -> syncCall missed");
      // IOSCallManager.shared.clearDataEndDismiss();
    }
  }

  Future<bool?> reject() async {
    print("[TEST] -> synCall = reject");
    if (stringeeCall == null) {
      print("SyncCall reject failed, call: " + stringeeCall.toString());
      return false;
    }

    bool? status;
    await stringeeCall?.reject().then((result) {
      String message = result['message'];
      status = result['status'];
      print("SyncCall reject, message: " + message);
      endCallIfNeed();
    });
    return status;
  }

  Future<bool?> hangup() async {
    print("[TEST] -> synCall = hangup");
    if (stringeeCall == null) {
      print("SyncCall hangup failed, call: " + stringeeCall.toString());
      return false;
    }

    bool? status;
    await stringeeCall?.hangup().then((result) {
      String message = result['message'];
      status = result['status'];
      print("SyncCall hangup, message: " + message + ", status: " + status.toString());
      endCallIfNeed();
    });
    return status;
  }

  void mute({bool? isMute}) {
    if (stringeeCall == null) {
      print("SyncCall mute failed, call: " + stringeeCall.toString());
      return;
    }

    if (isMute != null) {
      this.isMute = isMute;
    } else {
      this.isMute = !this.isMute;
    }

    stringeeCall?.mute(this.isMute);
    updateUI();
  }

  Future<bool> setSpeakerphoneOn() async {
    if (stringeeCall == null) {
      print("SyncCall setSpeakerphoneOn failed, call: " + stringeeCall.toString());
      return false;
    }

    isSpeaker = !isSpeaker;
    await stringeeCall?.setSpeakerphoneOn(isSpeaker);
    updateUI();
    return true;
  }

  void switchCamera() {
    if (stringeeCall == null) {
      print("SyncCall switchCamera failed, call: " + stringeeCall.toString());
      return;
    }

    stringeeCall?.switchCamera();
  }

  Future<bool> enableVideo() async {
    if (stringeeCall == null) {
      print("SyncCall enableVideo failed, call: " + stringeeCall.toString());
      return false;
    }

    videoEnabled = !videoEnabled;
    await stringeeCall?.enableVideo(videoEnabled);

    updateUI();
    return true;
  }

  void routeAudioToSpeakerIfNeed() {
    if (mediaFirstTimeConnected) {
      return;
    }

    if ((stringeeCall != null && stringeeCall!.isVideoCall)) {
      mediaFirstTimeConnected = true;
      isSpeaker = false;
      setSpeakerphoneOn();
    }
  }

  void endCallIfNeed() {
    // IOSCallManager.shared.clearDataEndDismiss();
  }

  void updateUI() {
    IOSCallManager.shared.callScreenKey?.currentState?.setState(() {});
  }

  bool hasStringeeCall() {
    return stringeeCall != null;
  }

  void destroy() {
    stringeeCall?.destroy();
  }

  @override
  String toString() {
    return "uuid=$uuid, userAnswered=$userAnswered";
  }
}
