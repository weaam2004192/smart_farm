// =================================================================
// === V5.2 - Refactored & Split Into Multiple Files ===
// =================================================================



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/controls_screen.dart';
import 'services/notification_service.dart';
import 'widgets/alarm_banner.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Farm Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
        cardColor: const Color(0xFF161B22),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
          titleLarge: TextStyle(color: Color(0xFFC9D1D9), fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF3FB950), size: 100),
              const SizedBox(height: 20),
              Text(
                'Smart Farm Pro',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: const Color(0xFFC9D1D9)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Initializing your farm...',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 16),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3FB950)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // All state is managed here
  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _isAlarmActive = false;
  String _alarmMessage = "";
  Color _alarmColor = Colors.transparent;

  bool _lampOn = false;
  bool _fanOn = false;

  final double _tempMax = 40.0;
  final double _tempMin = 30.0;
  final double _humidMax = 65.0;
  final double _humidMin = 50.0;

  final NotificationService _notificationService = NotificationService();
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();
    _notificationService.initialize();
    _requestNotificationPermission();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  void _setupFirebaseListeners() {
    final dbRef = FirebaseDatabase.instance.ref();

    dbRef.child('live_data').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
            _humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
            _checkAlarms();
          });
        }
      }
    });

    dbRef.child('controls/lamp').onValue.listen((event) {
      if (mounted) setState(() => _lampOn = event.snapshot.value as bool? ?? false);
    });
    dbRef.child('controls/fan').onValue.listen((event) {
      if (mounted) setState(() => _fanOn = event.snapshot.value as bool? ?? false);
    });
  }

  Future<void> _toggleControl(String path, bool currentValue) async {
    await FirebaseDatabase.instance.ref(path).set(!currentValue);
  }

  void _checkAlarms() {
    String newAlarmMessage = "";
    Color newAlarmColor = Colors.transparent;
    bool highTemp = _temperature > _tempMax;
    bool lowTemp = _temperature < _tempMin;
    bool highHumid = _humidity > _humidMax;
    bool lowHumid = _humidity < _humidMin;

    if (highTemp) {
      newAlarmMessage = "🔥 High Temp: ${_temperature.toStringAsFixed(1)}°C. Suggestion: Turn on Fan.";
      newAlarmColor = const Color(0xFFD73A49);
    } else if (lowTemp) {
      newAlarmMessage = "🥶 Low Temp: ${_temperature.toStringAsFixed(1)}°C. Suggestion: Turn on Heating Lamp.";
      newAlarmColor = const Color(0xFF2188FF);
    } else if (highHumid) {
      newAlarmMessage = "💧 High Humidity: ${_humidity.toStringAsFixed(1)}%. Suggestion: Turn on Fan.";
      newAlarmColor = const Color(0xFFD73A49);
    } else if (lowHumid) {
      newAlarmMessage = "💨 Low Humidity: ${_humidity.toStringAsFixed(1)}%. Suggestion: Turn on Heating Lamp.";
      newAlarmColor = const Color(0xFF2188FF);
    }

    if (mounted) {
      setState(() {
        _isAlarmActive = highTemp || lowTemp || highHumid || lowHumid;
        _alarmMessage = newAlarmMessage;
        _alarmColor = newAlarmColor;
      });
    }

    if (_isAlarmActive) {
      if (_notificationTimer == null || !_notificationTimer!.isActive) {
        _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          _notificationService.showNotification(
            title: 'Smart Farm Alert!',
            body: _alarmMessage,
          );
        });
        _notificationService.showNotification(
          title: 'Smart Farm Alert!',
          body: _alarmMessage,
        );
      }
    } else {
      _notificationTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(key: const PageStorageKey('DashboardScreen'), temperature: _temperature, humidity: _humidity),
      ControlsScreen(key: const PageStorageKey('ControlsScreen'), lampOn: _lampOn, fanOn: _fanOn, onToggle: _toggleControl),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard' : 'Controls'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            AlarmBanner(
              isAlarmActive: _isAlarmActive,
              alarmColor: _alarmColor,
              alarmMessage: _alarmMessage,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.toggle_on_rounded),
            label: 'Controls',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF3FB950),
        unselectedItemColor: const Color(0xFF8B949E),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
