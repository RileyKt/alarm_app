import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/*
Alarm App
By: Riley Kneen-Teed
 */



// Global initialization of the local notifications plugin.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// Global navigation key to enable navigation from outside the widget tree, like handling notification taps.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensures that plugin services are initialized before the app starts.
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes the Android alarm manager plugin.
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
  // Initialize notification settings.
  initializeNotifications();
}

// Configures notification settings and handles notification taps.
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // Icon used for notifications on Android.

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: handleNotificationResponse, // Handles actions when notifications are tapped.
  );
}

// Handles actions when a notification is tapped.
void handleNotificationResponse(NotificationResponse response) {
  if (response.payload != null && navigatorKey.currentState != null) {
    final timeParts = response.payload!.split(':');
    final timeOfDay = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    navigatorKey.currentState!.push(MaterialPageRoute(
      builder: (_) => AlarmRingingScreen(time: timeOfDay), // Navigates to the alarm ringing screen.
    ));
  }
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
    checkPermission(); // Checks if the app has permission to schedule exact alarms.
  }

  // Checks and updates permission status.
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
      navigatorKey: navigatorKey,
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
      // Requests to open the settings page for exact alarm permissions.
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

  // Generates a unique ID for each alarm based on the current timestamp.
  int generateAlarmId() {
    int currentTimestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    return currentTimestamp % 1000000007;
  }

  // Allows the user to pick a time and set an alarm.
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

  // Schedules an alarm using Android Alarm Manager.
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

  // Cancels an alarm.
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
            title: Text(
              'Alarm set for: ${alarm.time.format(context)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.normal,
              ),
            ),
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

class AlarmRingingScreen extends StatelessWidget {
  final TimeOfDay time;

  const AlarmRingingScreen({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarm Ringing"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("The alarm set for ${time.format(context)} is now ringing!", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This button will navigate back to the previous screen.
                Navigator.pop(context);
              },
              child: const Text('Turn Off Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void alarmCallback() async {
  print("Alarm Fired!");
  // Triggers a notification when the alarm fires.
  await showNotification(0, "Alarm Fired!", "Your alarm is ringing!", TimeOfDay.now());
}

Future<void> showNotification(int id, String title, String body, TimeOfDay time) async {
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
      payload: '${time.hour}:${time.minute}');
}
