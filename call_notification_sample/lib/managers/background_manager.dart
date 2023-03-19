import 'dart:convert';
import 'dart:io';

import 'package:callkeep/callkeep.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ios_call_notification_sample/managers/instance_manager.dart';

class BackgroundManager {
  static final callKeep = FlutterCallkeep();

  static void configBackground(BuildContext? context) {
    if (Platform.isAndroid) {
      Firebase.initializeApp().whenComplete(() async {
        FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) StringeeUtil.setPushToken(token);
      });
    }
  }

  static void configBackgroundIos({
    required BuildContext context,
    required void Function(CallKeepPerformAnswerCallAction event) answerCall,
    required void Function(CallKeepPerformEndCallAction event) endCall,
    required void Function(CallKeepDidPerformSetMutedCallAction event) didPerformSetMutedCallAction,
    required void Function(CallKeepDidActivateAudioSession event) didActivateAudioSession,
  }) {
    callKeep.on(CallKeepPushKitToken(), onPushKitToken);
    callKeep.on(CallKeepDidDisplayIncomingCall(), didDisplayIncomingCall);
    callKeep.on(CallKeepPushKitReceivedNotification(), onPushKitNotification);
    callKeep.on(CallKeepPerformAnswerCallAction(), answerCall);
    callKeep.on(CallKeepPerformEndCallAction(), endCall);
    callKeep.on(CallKeepDidPerformSetMutedCallAction(), didPerformSetMutedCallAction);
    callKeep.on(CallKeepDidActivateAudioSession(), didActivateAudioSession);

    callKeep.setup(context, <String, dynamic>{
      'ios': {
        'appName': 'VinfaMedi',
      },
      'android': {
        'alertTitle': 'Permissions required',
        'alertDescription': 'This application needs to access your phone accounts',
        'cancelButton': 'Cancel',
        'okButton': 'ok',
        // Required to get audio in background when using Android 11
        'foregroundService': {
          'channelId': 'com.company.my',
          'channelName': 'Foreground service for my app',
          'notificationTitle': 'My app is running on background',
          'notificationIcon': 'mipmap/ic_notification_launcher',
        },
      },
    });
  }

  static void didDisplayIncomingCall(CallKeepDidDisplayIncomingCall event) {
    // iosCallManager.endFakeCall(event.uuid);
    // iosCallManager.deleteSyncCallIfNeed();
    callKeep.endCall(event.uuid!);
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

/// Nhận và hiện notification khi app ở dưới background hoặc đã bị kill ở android
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage remoteMessage) async {
  await Firebase.initializeApp().whenComplete(() {
    print("Handling a background message: ${remoteMessage.data}");

    Map<dynamic, dynamic> _notiData = remoteMessage.data;
    Map<dynamic, dynamic> _data = json.decode(_notiData['data']);
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (_data['callStatus'] == 'started') {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_noti');
      final InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);

      flutterLocalNotificationsPlugin.initialize(initializationSettings).then((value) async {
        if (value!) {
          /// Create channel for notification
          const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.call,

            /// Set true for show App in lockScreen
            fullScreenIntent: true,
          );
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          /// Show notification
          await flutterLocalNotificationsPlugin.show(
            1234,
            'Incoming Call from ${_data['from']['alias']}',
            _data['from']['number'],
            platformChannelSpecifics,
          );
        }
      });
    } else if (_data['callStatus'] == 'ended') {
      flutterLocalNotificationsPlugin.cancel(1234);
    }
  });
}
