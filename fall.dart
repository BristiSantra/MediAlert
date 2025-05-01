import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



// ------------------ USER VIEW PAGE for fall detection ----------------------

class UserViewPage extends StatefulWidget {
  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  List<Map<String, dynamic>> patients = [];
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
          patients = List<Map<String, dynamic>>.from(data);
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
          // Clear form and refresh patient list
          _nameController.clear();
          _ageController.clear();
          _patientNoController.clear();
          _roomNoController.clear();
          Navigator.of(context).pop();
          await _fetchPatients(); // Refresh the list
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
            Text('Welcome!'),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.orange.shade50,
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
                          title: Text(patient['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Age: ${patient['age'] ?? 'N/A'}'),
                              Text('Patient No: ${patient['patientNo'] ?? 'N/A'}'),
                              Text('Room No: ${patient['roomNo'] ?? 'N/A'}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserInputPage(
                                      patientName: patients[index]['name']!,
                                      patientId: patients[index]['id']!,
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
    _nameController.dispose();
    _ageController.dispose();
    _patientNoController.dispose();
    _roomNoController.dispose();
    super.dispose();
  }
}
//--------------fall detection calculation-------------------------------

////////////////
class SensorPage extends StatefulWidget {
  final String patientName;
  final String patientId;
  final Map<String, dynamic>? initialValues;

  const SensorPage({
    Key? key,
    required this.patientName,
    required this.patientId,
    this.initialValues,
  }) : super(key: key);

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  double? accelValue;  // Changed from motionValue
  double? gyroValue;   // Changed from tiltingValue
  String? bpValue;
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialValues != null) {
      accelValue = widget.initialValues!['motion'];  // Still using 'motion' key from input
      gyroValue = widget.initialValues!['tilting'];  // Still using 'tilting' key from input
      bpValue = widget.initialValues!['bp'];

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFallAlert();
      });
    }
  }

  void _showFallAlert() {
    if (_alertShown) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('FALL CONFIRMED', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Patient: ${widget.patientName}'),
            SizedBox(height: 10),
            Text('Accelerometer: ${accelValue?.toStringAsFixed(2)} m/s²'),  // Updated label
            Text('Gyroscope: ${gyroValue?.toStringAsFixed(2)} °/s'),        // Updated label
            Text('BP: $bpValue mmHg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _alertShown = true);
            },
            child: Text('ACKNOWLEDGE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fall Details - ${widget.patientName}'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                if (accelValue != null)
                  _buildSensorIndicator(
                    'Accelerometer',  // Updated label
                    accelValue!,
                    'm/s²',
                    maxValue: 30.0,
                    threshold: 15.0,
                  ),
                if (gyroValue != null)
                  _buildSensorIndicator(
                    'Gyroscope',     // Updated label
                    gyroValue!,
                    '°/s',
                    maxValue: 400.0,
                    threshold: 200.0,
                  ),
                if (bpValue != null)
                  _buildBpIndicator(bpValue!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(
      String title,
      double value,
      String unit, {
        required double maxValue,
        required double threshold,
      }) {
    final isCritical = value > threshold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: (value / maxValue).clamp(0.0, 1.0),
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCritical ? Colors.red : Colors.green,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.red : Colors.green,
          ),
        ),
        if (isCritical)
          Text(
            'ABNORMAL',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildBpIndicator(String bp) {
    final parts = bp.split('/');
    final systolic = int.tryParse(parts[0]) ?? 0;
    final diastolic = int.tryParse(parts[1]) ?? 0;
    final isCritical = systolic < 100;  // Changed to check for low BP

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: (systolic / 180).clamp(0.0, 1.0),
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCritical ? Colors.red : Colors.green,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  bp,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  'mmHg',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Blood Pressure',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.red : Colors.green,
          ),
        ),
        if (isCritical)
          Text(
            'LOW',  // Changed from 'HIGH'
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
////////////////////////////////////////////////////////////////////////////////////
class CircularSensorIndicator extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final double? minValue;
  final String unit;

  const CircularSensorIndicator(
      {Key? key,
        required this.title,
        required this.value,
        required this.maxValue,
        this.unit = '',
        this.minValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percentage = (minValue != null)
        ? ((value - minValue!) / (maxValue - minValue!)).clamp(0.0, 1.0)
        : (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
            ),
            Column(
              children: [
                Text(
                  unit == "hPa"
                      ? value.toStringAsFixed(0)
                      : value.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent.shade700),
                ),
                Text(unit,
                    style:
                    TextStyle(fontSize: 18, color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent.shade700)),
      ],
    );
  }
}

class BloodPressureIndicator extends StatelessWidget {
  final int systolic;
  final int diastolic;

  const BloodPressureIndicator(
      {Key? key, required this.systolic, required this.diastolic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normalize systolic and diastolic for progress indicator (optional)
    // Assuming max systolic 180, min 90; max diastolic 120, min 60
    double sysPercent = ((systolic - 90) / (180 - 90)).clamp(0.0, 1.0);
    double diaPercent = ((diastolic - 60) / (120 - 60)).clamp(0.0, 1.0);

    double avgPercent = (sysPercent + diaPercent) / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: avgPercent,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
            ),
            Column(
              children: [
                Text(
                  "$systolic / $diastolic",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent.shade700),
                ),
                Text("mmHg",
                    style:
                    TextStyle(fontSize: 18, color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text("Blood Pressure",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent.shade700)),
      ],
    );
  }
}



/////////////////////user Input page////////////////////////
class UserInputPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const UserInputPage({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  _UserInputPageState createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _motionController = TextEditingController();
  final _tiltingController = TextEditingController();
  final _bpController = TextEditingController();

  String? _result;
  bool _isLoading = false;

  static const String _baseUrl = 'http://192.168.68.140:8000';

  Future<void> _checkFallCondition() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check_fall'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'motion_value': double.parse(_motionController.text),
          'tilting_value': double.parse(_tiltingController.text),
          'blood_pressure': _bpController.text,
          'patient_id': widget.patientId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _result = data['status']);

        if (_result == 'weak') {
          _showFallDetectedDialog();
        } else {
          _showGoodStateDialog();
        }
      } else {
        throw Exception('Failed to check fall condition');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFallDetectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('FALL DETECTED!', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Patient ${widget.patientName} has likely fallen.'),
            SizedBox(height: 10),
            Text('Motion: ${_motionController.text} m/s²'),
            Text('Tilting: ${_tiltingController.text} °/s'),
            Text('BP: ${_bpController.text} mmHg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SensorPage(
                    patientName: widget.patientName,
                    patientId: widget.patientId,
                    initialValues: {
                      'motion': double.parse(_motionController.text),
                      'tilting': double.parse(_tiltingController.text),
                      'bp': _bpController.text,
                    },
                  ),
                ),
              );
            },
            child: Text('VIEW DETAILS'),
          ),
        ],
      ),
    );
  }

  void _showGoodStateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GOOD STATE', style: TextStyle(color: Colors.green)),
        content: Text('Patient ${widget.patientName} is in good condition.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Fall Check - ${widget.patientName}'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter Sensor Values:', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              _buildInputField('Motion Value (m/s²)', _motionController),
              _buildInputField('Tilting Value (°/s)', _tiltingController),
              _buildInputField('Blood Pressure (mmHg)', _bpController, isBP: true),
              SizedBox(height: 20),
              if (_result != null)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _result == 'weak' ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Result: ${_result!.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 18,
                      color: _result == 'weak' ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkFallCondition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('CHECK FALL CONDITION', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isBP = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isBP ? TextInputType.text : TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          hintText: isBP ? 'e.g. 120/80' : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter a value';
          if (isBP) {
            if (!RegExp(r'^\d+/\d+$').hasMatch(value)) return 'Enter in format 120/80';
          } else {
            if (double.tryParse(value) == null) return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
  @override
  void dispose() {
    _motionController.dispose();
    _tiltingController.dispose();
    _bpController.dispose();
    super.dispose();
  }
}