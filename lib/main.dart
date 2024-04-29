import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
  initializeNotifications();
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.alarm_app/settings');
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  Future<void> checkPermission() async {
    try {
      final granted = await platform.invokeMethod('checkExactAlarmPermission');
      setState(() {
        _permissionGranted = granted;
      });
    } catch (e) {
      print('Failed to check exact alarm permission: $e');
      setState(() {
        _permissionGranted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _permissionGranted ? const AlarmScreen() : const PermissionRequestScreen(),
    );
  }
}

class PermissionRequestScreen extends StatelessWidget {
  const PermissionRequestScreen({super.key});

  static const platform = MethodChannel('com.example.alarm_app/settings');

  Future<void> openAppSettings() async {
    try {
      await platform.invokeMethod('openSettingsForExactAlarm');
    } catch (e) {
      print("Failed to open settings: '$e'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Permission Needed"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'This app requires permission to schedule exact alarms to function properly.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  AlarmScreenState createState() => AlarmScreenState();
}

class AlarmInfo {
  TimeOfDay time;
  int id;

  AlarmInfo({required this.time, required this.id});
}

class AlarmScreenState extends State<AlarmScreen> {
  List<AlarmInfo> alarms = [];

  int generateAlarmId() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return currentTimestamp % 1000000007;
  }

  void _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final int id = generateAlarmId();
      final alarmInfo = AlarmInfo(time: time, id: id);
      setState(() {
        alarms.add(alarmInfo);
      });
      await setAlarm(alarmInfo);
    }
  }

  Future<void> setAlarm(AlarmInfo alarmInfo) async {
    final now = DateTime.now();
    final alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarmInfo.time.hour,
      alarmInfo.time.minute,
    );

    final scheduleAlarmDateTime = alarmDateTime.isBefore(now)
        ? alarmDateTime.add(const Duration(days: 1))
        : alarmDateTime;

    await AndroidAlarmManager.oneShotAt(
      scheduleAlarmDateTime,
      alarmInfo.id,
      alarmCallback,
      wakeup: true,
      exact: true,
    );

    print("Alarm ${alarmInfo.id} set for $scheduleAlarmDateTime");
  }

  void cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
    setState(() {
      alarms.removeWhere((alarm) => alarm.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Alarms'),
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return ListTile(
            title: Text('Alarm set for: ${alarm.time.format(context)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => cancelAlarm(alarm.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickTime,
        child: const Icon(Icons.add),
      ),
    );
  }
}

@pragma('vm:entry-point')
void alarmCallback() async {
  print("Alarm Fired!");
  await showNotification(0, "Alarm Fired!", "Your alarm is ringing!");
}

Future<void> showNotification(int id, String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x');
}
