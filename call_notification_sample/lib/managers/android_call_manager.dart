import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ios_call_notification_sample/managers/background_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import 'icaller.dart';
import 'instance_manager.dart' as InstanceManager;


class AndroidCallManager extends ICaller {
  static AndroidCallManager? _instance;

  static ICaller get instance {
    return _instance ??= AndroidCallManager._internal();
  }

  AndroidCallManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void configBackgroundMode() {
    _requestPermissions();
    BackgroundManager.configBackground(context);
  }

  static _requestPermissions() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
    ];
    if (androidInfo.version.sdkInt >= 31) {
      permissions.add(Permission.bluetoothConnect);
    }
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    print(statuses);

    if (androidInfo.version.sdkInt >= 33) {
      // Register permission for show notification in android 13
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .requestPermission();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('didChangeAppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      InstanceManager.localNotifications.cancel(0);
      isAppInBackground = false;
      if (InstanceManager.client.hasConnected && isIncoming) {
        showCallScreen();
      }
      return;
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
}
