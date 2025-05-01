import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';


// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class UserViewPagee extends StatefulWidget {
  @override
  _UserViewPageState1 createState() => _UserViewPageState1();
}

class _UserViewPageState1 extends State<UserViewPagee> {
  List<Patient> patients = [];
  bool isLoading = true;
  String? errorMessage;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _patientNoController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const String baseUrl = 'http://192.168.68.140:8000';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/patients'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          patients = data.map((patientData) => Patient(
            name: patientData['name'] ?? 'No Name',
            age: patientData['age']?.toString() ?? '',
            patientNo: patientData['patientNo']?.toString() ?? '',
            roomNo: patientData['roomNo']?.toString() ?? '',
            id: patientData['id']?.toString() ?? '',
          )).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading patients: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _addPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/patients/add'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _nameController.text,
            'age': _ageController.text,
            'patientNo': _patientNoController.text,
            'roomNo': _roomNoController.text,
          }),
        );

        if (response.statusCode == 201) {
          _nameController.clear();
          _ageController.clear();
          _patientNoController.clear();
          _roomNoController.clear();
          Navigator.of(context).pop();
          await _fetchPatients();
        } else {
          throw Exception('Failed to add patient: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding patient: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Patient"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Age'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter age';
                    if (int.tryParse(value) == null) return 'Age must be an integer';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _patientNoController,
                  decoration: InputDecoration(labelText: 'Patient Number'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter patient number' : null,
                ),
                TextFormField(
                  controller: _roomNoController,
                  decoration: InputDecoration(labelText: 'Room Number'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter room number' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: _addPatient,
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, size: 28),
            SizedBox(width: 10),
            Text('Saline monitoring page'),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchPatients,
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.teal, size: 36),
                          title: Text(patient.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Age: ${patient.age}'),
                              Text('Patient No: ${patient.patientNo}'),
                              Text('Room No: ${patient.roomNo}'),
                              Text('Saline Level: ${patient.salineML.toStringAsFixed(1)}ml'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalinePage(
                                  patient: patient,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _showAddPatientDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("+ Add",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var patient in patients) {
      patient.dispose();
    }
    _nameController.dispose();
    _ageController.dispose();
    _patientNoController.dispose();
    _roomNoController.dispose();
    super.dispose();
  }
}

class Patient {
  final String name;
  final String age;
  final String patientNo;
  final String roomNo;
  final String id;
  double salineML = 1000.0;
  Timer? timer;
  bool lowAlertShown = false;
  bool criticalAlertShown = false;
  bool dangerAlertShown = false;

  final AudioPlayer player = AudioPlayer();
  final FlutterTts tts = FlutterTts();


  Patient({
    required this.name,
    required this.age,
    this.patientNo = '',
    this.roomNo = '',
    this.id = '',
  }) {
    startMonitoring();
  }

  // Initialize TTS (call this in constructor)
  void _initTts() async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.9); // Slightly slower for clarity
  }


  void startMonitoring() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      salineML -= 1000 / 100; // ≈16.67 ml/sec
      if (salineML < 0) salineML = 0;
      checkAlerts();
    });
  }

  void checkAlerts() async {
    if (salineML <= 50 && !dangerAlertShown) {
      print("50ml alert condition met");
      dangerAlertShown = true;
      await player.play(AssetSource('beep.mp3'), volume: 1.0);
      await _speakAlert("Critical! ${name}'s saline at 50 milliliters in Room ${roomNo}");
      await tts.awaitSpeakCompletion(true);
      showCriticalNotification("Critical saline alert for $name (50ml)!");
    } else if (salineML <= 100 && !criticalAlertShown) {
      criticalAlertShown = true;
      // await beepMultiple(1);
      await _speakAlert("Warning! ${name}'s saline at 100 milliliters in Room ${roomNo}");
      await tts.awaitSpeakCompletion(true);
      showSimpleNotification("Warning: $name saline dropped to 100ml!");
    } else if (salineML <= 200 && !lowAlertShown) {
      lowAlertShown = true;
      // await beepMultiple(1);
      await _speakAlert("Low saline alert for ${name}, 200 milliliters remaining");
      // Prevent overlapping announcements
      await tts.awaitSpeakCompletion(true);
      showSimpleNotification("$name saline getting low (200ml).");
      await tts.setVoice({"name": "en-us-x-sfg#male_1-local"}); // Male voice
    }
  }

  Future<void> beepMultiple(int times) async {
    for (int i = 0; i < times; i++) {
      await player.play(AssetSource('beep.mp3'), volume: 1.0);
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<void> _speakAlert(String message) async {
    await tts.speak(message);
  }



  void refillSaline() {
    salineML = 1000.0;
    lowAlertShown = false;
    criticalAlertShown = false;
    dangerAlertShown = false;
    player.stop();
  }

  void dispose() {
    tts.stop();  // Important!****
    timer?.cancel();
    player.dispose();
  }

  void showSimpleNotification(String message) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void showCriticalNotification(String message) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    HapticFeedback.heavyImpact();
  }
}

class SalinePage extends StatefulWidget {
  final Patient patient;

  SalinePage({required this.patient});

  @override
  _SalinePageState createState() => _SalinePageState();
}

class _SalinePageState extends State<SalinePage> with SingleTickerProviderStateMixin {
  late Timer updateTimer;
  AnimationController? _controller;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();
    startFlashing();
    updateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() {});
    });
  }

  void startFlashing() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withOpacity(0.2),
    ).animate(_controller!);
  }

  @override
  void dispose() {
    updateTimer.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String getStatus() {
    if (widget.patient.salineML > 600) return "Full";
    if (widget.patient.salineML > 200) return "Normal";
    return "Low";
  }

  Color getStatusColor() {
    if (widget.patient.salineML > 600) return Colors.green;
    if (widget.patient.salineML > 200) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.patient.name} Monitoring"),
        backgroundColor: Colors.teal,


        actions: [
          IconButton(
            icon: Icon(Icons.volume_off),
            onPressed: () => widget.patient.tts.stop(),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade50,
      body: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return Container(
            color: (widget.patient.salineML <= 50)
                ? _colorAnimation!.value
                : Colors.transparent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircularProgressIndicator(
                          value: widget.patient.salineML / 1000,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              getStatusColor()),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_drink,
                              size: 40, color: Colors.teal),
                          Text(
                            "${widget.patient.salineML.toStringAsFixed(0)} ml",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          Text(
                            getStatus(),
                            style: TextStyle(
                              fontSize: 20,
                              color: getStatusColor(),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.patient.refillSaline();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding:
                      EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Refill Saline",
                        style: TextStyle(
                            color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}