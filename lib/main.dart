import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AlarmScreen(),
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
    // Use the current timestamp modulo a large prime number (for example) to get a unique ID that fits in 31 bits.
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
      await setAlarm(alarmInfo); // Schedule the alarm after adding it to the list
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
void alarmCallback() {
  print("Alarm Fired!");
  // Here you can add the logic to show notifications or any other functionality.
}
