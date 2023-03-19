import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ios_call_notification_sample/managers/android_call_manager.dart';
import 'package:ios_call_notification_sample/managers/ios_call_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';

import 'icaller.dart';

StringeeClient client = StringeeClient();
FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

class StringeeUtil {
  static ICaller? iCaller;
  static String? pushToken;

  static void connect(String token) {
    if(Platform.isAndroid){
      iCaller = AndroidCallManager.instance;
    }else{
      iCaller = IOSCallManager.instance;
    }
    client.connect(token);
  }

  static void registEvents(BuildContext context) {
    client.eventStreamController.stream.listen((event) {
      Map<dynamic, dynamic> map = event;
      switch (map['eventType']) {
        case StringeeClientEvents.didConnect:
          _handleDidConnectEvent(context);
          break;
        case StringeeClientEvents.didDisconnect:
          handleDiddisconnectEvent();
          break;
        case StringeeClientEvents.didFailWithError:
          handleDidFailWithErrorEvent(map['body']['code'], map['body']['message']);
          break;
        case StringeeClientEvents.requestAccessToken:
          handleRequestAccessTokenEvent();
          break;
        case StringeeClientEvents.didReceiveCustomMessage:
          handleDidReceiveCustomMessageEvent(map['body']);
          break;
        case StringeeClientEvents.incomingCall:
          StringeeCall? call = map['body'];
          iCaller?.handleIncomingCallEvent(context, call!);
          break;
        default:
          break;
      }
    });
  }

  static void _handleDidConnectEvent(BuildContext context) {
    print("[TEST]: Stringee connected");
    iCaller?.setContext(context);
    iCaller?.configBackgroundMode();
  }


  static Future<void> setPushToken(String pushToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      _setPushToken(prefs, pushToken);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _refreshPushToken(prefs, token);
      });
    } else {
      _setPushToken(prefs, pushToken);
    }
  }

  static void _setPushToken(SharedPreferences prefs, String token) {
    bool? registered = (prefs.getBool("register") == null) ? false : prefs.getBool("register");
    if (registered == true) return;

    client.registerPush(token).then((value) {
      print('Register push ' + value['message']);
      if (value['status']) {
        prefs.setBool("register", true);
        prefs.setString("token", token);
      }
    });
  }

  static void _refreshPushToken(SharedPreferences prefs, String token) {
    client.unregisterPush(prefs.getString("token")!).then((value) {
      print('Unregister push ' + value['message']);
      if (value['status']) {
        ///Register với token mới
        prefs.setBool("register", false);
        prefs.remove("token");
        client.registerPush(token).then((value) {
          print('Register push ' + value['message']);
          if (value['status']) {
            prefs.setBool("register", true);
            prefs.setString("token", token);
          }
        });
      }
    });
  }

  static void handleDiddisconnectEvent() {
    print("handleDiddisconnectEvent");
    // if (!Platform.isAndroid) {
    //   IOSCallManager.shared.stopTimeoutForIncomingCall();
    // }
  }

  static void handleDidFailWithErrorEvent(int? code, String message) {
    print('code: ' + code.toString() + ', message: ' + message);
  }

  static void handleRequestAccessTokenEvent() {
    print('Request new access token');
  }

  static void handleDidReceiveCustomMessageEvent(Map<dynamic, dynamic> map) {
    print('from: ' + map['fromUserId'] + '\nmessage: ' + map['message']);
  }
}
