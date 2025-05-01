
# backend.py
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from datetime import datetime
import pandas as pd

# Initialize Firebase
cred = credentials.Certificate("C:/Users/Savio/OneDrive/Desktop/Python/hospitech-43132-firebase-adminsdk-fbsvc-f7813aa3e4.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = Flask(__name__)

# ---------------------- Upload Dataset Endpoint ----------------------
@app.route('/C:/Users/Savio/OneDrive/Desktop/Python/Fall_Detection_Dataset.xlsx', methods=['POST'])
def upload_dataset():
    try:
        # Read the Excel file
        df = pd.read_excel(request.files['file'])
        
        # Convert to dictionary records
        records = df.to_dict('records')
        
        # Upload to Firestore
        batch = db.batch()
        collection_ref = db.collection('fall_dataset')
        
        for i, record in enumerate(records):
            doc_ref = collection_ref.document(f'record_{i}')
            batch.set(doc_ref, {
                'motion_value': record['Motion Value (m/s²)'],
                'tilting_value': record['Tiliting Value (°/s)'],
                'blood_pressure': record['Blood Pressure Value (mmHg)'],
                'detection': record['Detection'],
                'uploaded_at': datetime.now()
            })
        
        batch.commit()
        return jsonify({'message': f'Successfully uploaded {len(records)} records'}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- Fall Detection Logic ----------------------
def detect_fall(motion_value, tilting_value, systolic):
    # Your professor's detection criteria
    motion_threshold = 15.0  # m/s²
    tilting_threshold = 200.0  # °/s
    bp_threshold = 140  # mmHg (systolic)
    
    if (motion_value > motion_threshold and 
        tilting_value > tilting_threshold and 
        systolic > bp_threshold):
        return 'Weak'
    return 'Standard'

# ---------------------- Check Fall Endpoint ----------------------
# @app.route('/check_fall', methods=['POST'])
# def check_fall():
#     try:
#         data = request.get_json()
        
#         # Extract systolic BP from "120/80" format
#         bp_parts = data['blood_pressure'].split('/')
#         systolic = int(bp_parts[0])
        
#         # Perform detection
#         result = detect_fall(
#             data['motion_value'],
#             data['tilting_value'],
#             systolic
#         )
        
#         # Log to Firestore
#         db.collection('fall_checks').add({
#             'patient_id': data.get('patient_id'),
#             'motion_value': data['motion_value'],
#             'tilting_value': data['tilting_value'],
#             'blood_pressure': data['blood_pressure'],
#             'result': result,
#             'checked_at': datetime.now()
#         })
        
#         return jsonify({'status': result.lower()}), 200
    
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500
@app.route('/check_fall', methods=['POST'])
def check_fall():
    try:
        data = request.get_json()
        required_fields = ['motion_value', 'tilting_value', 'blood_pressure', 'patient_id']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        # Extract BP values
        bp_parts = data['blood_pressure'].split('/')
        systolic = int(bp_parts[0])
        diastolic = int(bp_parts[1]) if len(bp_parts) > 1 else 0

        # Updated detection logic
        motion_threshold = 15.0  # m/s²
        tilting_threshold = 200.0  # °/s
        bp_threshold = 100  # mmHg (systolic) - now checking for LOW BP
        
        is_fall = (
            data['motion_value'] > motion_threshold and
            data['tilting_value'] > tilting_threshold and
            systolic < bp_threshold  # Changed to less than
        )
        
        status = 'weak' if is_fall else 'standard'
        
        # Log to Firestore
        db.collection('fall_checks').add({
            'patient_id': data['patient_id'],
            'motion_value': data['motion_value'],
            'tilting_value': data['tilting_value'],
            'blood_pressure': data['blood_pressure'],
            'result': status,
            'checked_at': datetime.now()
        })
        
        return jsonify({'status': status}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------------- Existing Endpoints ----------------------
# ... (keep your existing nurse_login, patients endpoints) ...
# # ---------------------- Nurse Login (Existing) ----------------------
@app.route('/nurse_login', methods=['POST'])
def nurse_login():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400

        nurses_ref = db.collection('Nurse')
        query = nurses_ref.where('email', '==', email).where('password', '==', password).limit(1)
        results = query.stream()

        for nurse in results:
            nurse_data = nurse.to_dict()
            return jsonify({
                'message': 'Login successful',
                'userType': 'Nurse',
                'name': nurse_data.get('full_name', 'Nurse')
            }), 200

        return jsonify({'error': 'Invalid email or password'}), 401

    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

# ---------------------- Patient Endpoints (New) ----------------------
@app.route('/patients', methods=['GET'])
def get_patients():
    try:
        patients_ref = db.collection('patients')
        # patients = [doc.to_dict() for doc in patients_ref.stream()]
        # In get_patients endpoint:
        patients = [{'id': doc.id, **doc.to_dict()} for doc in patients_ref.stream()]
        return jsonify(patients), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/patients/add', methods=['POST'])
def add_patient():
    try:
        data = request.get_json()
        required_fields = ['name', 'age', 'patientNo', 'roomNo']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        doc_ref = db.collection('patients').document()
        doc_ref.set(data)
        return jsonify({'message': 'Patient added successfully', 'id': doc_ref.id}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# @app.route('/patients/<patient_id>', methods=['DELETE'])
# def delete_patient(patient_id):
#     try:
#         db.collection('patients').document(patient_id).delete()
#         return jsonify({'message': 'Patient deleted successfully'}), 200
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500
    
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='192.168.68.140', port=8000, debug=True)