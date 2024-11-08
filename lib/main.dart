import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const NotificationApp(),
    );
  }
}

class NotificationApp extends StatefulWidget {
  const NotificationApp({super.key});

  @override
  NotificationAppState createState() => NotificationAppState();
}

class NotificationAppState extends State<NotificationApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: '1');
  final TextEditingController _delayController = TextEditingController(text: '5'); // en secondes

  static const _padding = EdgeInsets.all(20.0);
  static const _sizedBoxHeight = SizedBox(height: 16);
  static const _biggerSizedBox = SizedBox(height: 30);
  static const _smallSizedBox = SizedBox(height: 10);
  static const _horizontalSpace = SizedBox(width: 16);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Vérification des permissions
    final notificationSettings = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );

    // Afficher le statut des permissions dans la console
    print('Statut des permissions iOS : $notificationSettings');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      requestCriticalPermission: true, // Ajout de cette permission
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Gérer la réponse à la notification ici
        print('Notification reçue : ${details.payload}');
      },
    );
  }

  Future<void> _scheduleNotifications() async {
    bool? confirm = await _showConfirmationDialog();
    if (!mounted) return;

    if (confirm != null && confirm) {
      String title = _titleController.text.trim();
      String body = _bodyController.text.trim();
      int? count = int.tryParse(_countController.text);
      int? delay = int.tryParse(_delayController.text);

      if (title.isEmpty || body.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs de texte.'),
          ),
        );
        return;
      }

      if (count == null || count <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nombre doit être un entier positif valide.'),
          ),
        );
        return;
      }

      if (delay == null || delay <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le délai doit être un entier positif valide en secondes.'),
          ),
        );
        return;
      }

      for (int i = 0; i < count; i++) {
        await _scheduleNotification(title, body, delay * (i + 1));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications programmées avec succès!'),
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer l\'envoi'),
          content: const Text('Êtes-vous sûr de vouloir programmer ces notifications ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _scheduleNotification(String title, String body, int delaySeconds) async {
    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000 + delaySeconds;
      
      print('Programmation notification : ID=$notificationId, Délai=$delaySeconds sec');

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(iOS: iOSPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds)),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('Notification programmée avec succès');
    } catch (e) {
      print('Erreur lors de la programmation de la notification : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotifStudio',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: _padding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _smallSizedBox,
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la notification',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                _sizedBoxHeight,
                TextField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Description de la notification',
                    prefixIcon: Icon(Icons.message),
                  ),
                  maxLines: 3,
                ),
                _sizedBoxHeight,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _countController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    _horizontalSpace,
                    Expanded(
                      child: TextField(
                        controller: _delayController,
                        decoration: const InputDecoration(
                          labelText: 'Délai (sec)',
                          prefixIcon: Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _biggerSizedBox,
                ElevatedButton(
                  onPressed: _scheduleNotifications,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Programmer les Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}