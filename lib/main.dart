import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// Main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

// Main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sets the configuration for the top-level routing and styling.
    return MaterialApp(
      title: 'Alarm App',  // The title of the app displayed in the task manager.
      theme: ThemeData(
        primarySwatch: Colors.blue,  // Primary theme color of the app.
      ),
      home: const AlarmScreen(),  // Home screen of the app.
    );
  }
}

// Stateful widget for the alarm screen, manages the alarm setting UI.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  AlarmScreenState createState() => AlarmScreenState();
}

// State class for the AlarmScreen.
class AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay? _selectedTime;  // Holds the selected time for the alarm.

  // Function to open a time picker dialog and allow user to select a time.
  void _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),  // Set initial time in picker to now.
    );
    if (time != null && time != _selectedTime) {
      setState(() {
        _selectedTime = time;  // Update the selected time when new time is picked.
      });
    }
  }
  Future<void> setAlarm() async {
    if (_selectedTime != null) {
      final now = DateTime.now();
      final alarmTime = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
      await AndroidAlarmManager.oneShotAt(alarmTime, 0, alarmCallback,
          wakeup: true);
    }
  }

  static void alarmCallback() {
    print("Alarm Fired!");
// Here you can add the logic to show notifications or any other functionality.
  }

  @override
  Widget build(BuildContext context) {
    // Builds the user interface for the alarm screen.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Alarm'),  // AppBar with title.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickTime,  // Button to trigger time picker.
              child: const Text('Pick Alarm Time'),
            ),
            ElevatedButton(
              onPressed: () {
                setAlarm();
                final snackBar = SnackBar(
                  content: Text('Alarm set for ${_selectedTime!.format(context)}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: const Text('Set Alarm'),
            ),
            const SizedBox(height: 20),  // Spacing between button and text.
            Text(
              _selectedTime != null ? 'Alarm Time: ${_selectedTime!.format(context)}' : 'No Alarm Set',
              style: const TextStyle(fontSize: 24),  // Text style for the alarm time.
            ),
          ],
        ),
      ),
    );
  }
}
