import 'dart:io';

import 'package:district/udp_transport.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class MyTaskHandler extends TaskHandler {
  static UdpTransport? _udpTransport;
  String? _id;
  String? _downloadDirectory;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    _id = await FlutterForegroundTask.getData(key: 'id');
    _downloadDirectory = await FlutterForegroundTask.getData(
      key: 'downloadDirectory',
    );

    _udpTransport = UdpTransport(
      id: _id!,
      sendToPeer: sendToPeer,
      downloadDirectory: _downloadDirectory!,
    );

    _udpTransport!.start();

    FlutterForegroundTask.updateService(
      notificationTitle: 'Service running...',
      notificationText: 'Connected peers: 0',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('onDestroy(isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {
    print('onTaskReceiveData: $data');

    if (data case int intData) {
      FlutterForegroundTask.updateService(
        notificationText: 'Connected peers: ${intData}',
      );
    } else if (data case Map<String, dynamic> json) {
      _udpTransport?.handleJson(json);
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
    if (id == "btn_stop") {
      print("Service stopped by notification button");
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    print('onNotificationPressed');
  }

  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }

  void sendToPeer(Object data) {
    FlutterForegroundTask.sendDataToMain(data);
  }
}

Future<void> requestPermissions() async {
  // Android 13+, you need to allow notification permission to display foreground service notification.
  //
  // iOS: If you need notification, ask for permission.
  final NotificationPermission notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  if (Platform.isAndroid) {
    // Android 12+, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Use this utility only if you provide services that require long-term survival,
    // such as exact alarm service, healthcare service, or Bluetooth communication.
    //
    // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
    // Using this permission may make app distribution difficult due to Google policy.
    if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      // When you call this function, will be gone to the settings page.
      // So you need to explain to the user why set it.
      await FlutterForegroundTask.openAlarmsAndRemindersSettings();
    }
  }
}

void initService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription:
          'This notification appears when the foreground service is running.',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<ServiceRequestResult> startService(
  String id,
  String downloadDirectory,
) async {
  FlutterForegroundTask.saveData(key: 'id', value: id);
  FlutterForegroundTask.saveData(
    key: 'downloadDirectory',
    value: downloadDirectory,
  );

  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      serviceTypes: [
        ForegroundServiceTypes.dataSync,
        ForegroundServiceTypes.remoteMessaging,
      ],
      serviceId: 256,
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      notificationIcon: null,
      notificationButtons: [
        const NotificationButton(id: 'btn_stop', text: 'Stop Service'),
      ],
      //notificationInitialRoute: '/second',
      callback: startCallback,
    );
  }
}

Future<ServiceRequestResult> stopService() {
  return FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}
