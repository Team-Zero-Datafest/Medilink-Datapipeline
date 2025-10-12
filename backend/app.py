"""
Flask API for Medical Records System
"""
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import DeclarativeBase
from datetime import datetime
import os
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)
CORS(app)

# Database configuration with validation
DB_HOST = os.getenv('POSTGRES_HOST')
DB_PORT = os.getenv('POSTGRES_PORT', '5432')
DB_USER = os.getenv('POSTGRES_USER')
DB_PASSWORD = os.getenv('POSTGRES_PASSWORD')
DB_NAME = os.getenv('POSTGRES_DB')

# Validate required environment variables
required_vars = {
    'POSTGRES_HOST': DB_HOST,
    'POSTGRES_USER': DB_USER,
    'POSTGRES_PASSWORD': DB_PASSWORD,
    'POSTGRES_DB': DB_NAME
}

missing_vars = [var for var, value in required_vars.items() if not value]
if missing_vars:
    logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
    logger.error("Please check your .env file and docker-compose.yaml")
    sys.exit(1)

# Ensure port is valid
try:
    DB_PORT = str(int(DB_PORT))  # Validate and convert to string
except (ValueError, TypeError):
    logger.error(f"Invalid POSTGRES_PORT value: {DB_PORT}. Using default 5432")
    DB_PORT = '5432'

DATABASE_URI = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
logger.info(f"Connecting to database: postgresql://{DB_USER}:***@{DB_HOST}:{DB_PORT}/{DB_NAME}")

app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ECHO'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_pre_ping': True,
    'pool_recycle': 300,
}

# Initialize database
class Base(DeclarativeBase):
    pass

db = SQLAlchemy(model_class=Base)
db.init_app(app)

# Import models after db is created
from models import Facility, Patient, MedicalRecord, TriageVisit, RecordRequest
from schemas import (
    FacilityCreate, FacilityOut,
    PatientCreate, PatientOut,
    MedicalRecordCreate, MedicalRecordOut,
    TriageVisitOut,
    RecordRequestCreate, RecordRequestOut
)


# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        with db.engine.connect() as conn:
            conn.execute(db.text('SELECT 1'))
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'database': 'connected'
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e)
        }), 503


@app.route('/', methods=['GET'])
def index():
    """Root endpoint"""
    return jsonify({
        'message': 'Medical Records API',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'facilities': '/api/facilities',
            'patients': '/api/patients',
            'medical_records': '/api/medical-records',
            'triage_visits': '/api/triage-visits',
            'analytics': '/api/analytics/facility-stats'
        }
    }), 200


# Facility endpoints
@app.route('/api/facilities', methods=['GET'])
def get_facilities():
    """Get all facilities with optional filtering"""
    try:
        query = db.session.query(Facility)
        
        state = request.args.get('state')
        lga = request.args.get('lga')
        facility_type = request.args.get('type')
        
        if state:
            query = query.filter(Facility.state.ilike(f'%{state}%'))
        if lga:
            query = query.filter(Facility.lga.ilike(f'%{lga}%'))
        if facility_type:
            query = query.filter(Facility.type.ilike(f'%{facility_type}%'))
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        facilities = query.paginate(page=page, per_page=per_page, error_out=False)
        
        return jsonify({
            'data': [FacilityOut.model_validate(f).model_dump() for f in facilities.items],
            'total': facilities.total,
            'page': page,
            'per_page': per_page,
            'pages': facilities.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting facilities: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/facilities/<int:facility_id>', methods=['GET'])
def get_facility(facility_id):
    """Get a specific facility by ID"""
    try:
        facility = db.session.get(Facility, facility_id)
        if not facility:
            return jsonify({'error': 'Facility not found'}), 404
        return jsonify(FacilityOut.model_validate(facility).model_dump()), 200
    except Exception as e:
        logger.error(f"Error getting facility {facility_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/facilities', methods=['POST'])
def create_facility():
    """Create a new facility"""
    try:
        data = request.get_json()
        facility_data = FacilityCreate(**data)
        
        facility = Facility(
            name=facility_data.name,
            state=facility_data.state,
            lga=facility_data.lga,
            lat=facility_data.lat,
            lon=facility_data.lon,
            type=facility_data.type
        )
        
        db.session.add(facility)
        db.session.commit()
        
        return jsonify(FacilityOut.model_validate(facility).model_dump()), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating facility: {str(e)}")
        return jsonify({'error': str(e)}), 400


# Patient endpoints
@app.route('/api/patients', methods=['GET'])
def get_patients():
    """Get all patients"""
    try:
        query = db.session.query(Patient)
        
        facility_id = request.args.get('facility_id', type=int)
        if facility_id:
            query = query.filter(Patient.facility_id == facility_id)
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        patients = query.paginate(page=page, per_page=per_page, error_out=False)
        
        return jsonify({
            'data': [PatientOut.model_validate(p).model_dump() for p in patients.items],
            'total': patients.total,
            'page': page,
            'per_page': per_page,
            'pages': patients.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting patients: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/patients/<int:patient_id>', methods=['GET'])
def get_patient(patient_id):
    """Get a specific patient by ID"""
    try:
        patient = db.session.get(Patient, patient_id)
        if not patient:
            return jsonify({'error': 'Patient not found'}), 404
        return jsonify(PatientOut.model_validate(patient).model_dump()), 200
    except Exception as e:
        logger.error(f"Error getting patient {patient_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/patients', methods=['POST'])
def create_patient():
    """Create a new patient"""
    try:
        data = request.get_json()
        patient_data = PatientCreate(**data)
        
        patient = Patient(
            facility_id=patient_data.facility_id,
            first_name=patient_data.first_name,
            last_name=patient_data.last_name,
            sex=patient_data.sex,
            dob=patient_data.dob,
            phone=patient_data.phone
        )
        
        db.session.add(patient)
        db.session.commit()
        
        return jsonify(PatientOut.model_validate(patient).model_dump()), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating patient: {str(e)}")
        return jsonify({'error': str(e)}), 400


# Medical Record endpoints
@app.route('/api/medical-records', methods=['GET'])
def get_medical_records():
    """Get medical records"""
    try:
        query = db.session.query(MedicalRecord)
        
        patient_id = request.args.get('patient_id', type=int)
        facility_id = request.args.get('facility_id', type=int)
        
        if patient_id:
            query = query.filter(MedicalRecord.patient_id == patient_id)
        if facility_id:
            query = query.filter(MedicalRecord.facility_id == facility_id)
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        records = query.order_by(MedicalRecord.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'data': [MedicalRecordOut.model_validate(r).model_dump() for r in records.items],
            'total': records.total,
            'page': page,
            'per_page': per_page,
            'pages': records.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting medical records: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/medical-records/<int:record_id>', methods=['GET'])
def get_medical_record(record_id):
    """Get a specific medical record"""
    try:
        record = db.session.get(MedicalRecord, record_id)
        if not record:
            return jsonify({'error': 'Medical record not found'}), 404
        return jsonify(MedicalRecordOut.model_validate(record).model_dump()), 200
    except Exception as e:
        logger.error(f"Error getting medical record {record_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/medical-records', methods=['POST'])
def create_medical_record():
    """Create a new medical record"""
    try:
        data = request.get_json()
        record_data = MedicalRecordCreate(**data)
        
        record = MedicalRecord(
            patient_id=record_data.patient_id,
            facility_id=record_data.facility_id,
            record_type=record_data.record_type,
            data=record_data.data
        )
        
        db.session.add(record)
        db.session.commit()
        
        return jsonify(MedicalRecordOut.model_validate(record).model_dump()), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating medical record: {str(e)}")
        return jsonify({'error': str(e)}), 400


# Triage Visit endpoints
@app.route('/api/triage-visits', methods=['GET'])
def get_triage_visits():
    """Get triage visits"""
    try:
        query = db.session.query(TriageVisit)
        
        patient_id = request.args.get('patient_id', type=int)
        facility_id = request.args.get('facility_id', type=int)
        
        if patient_id:
            query = query.filter(TriageVisit.patient_id == patient_id)
        if facility_id:
            query = query.filter(TriageVisit.facility_id == facility_id)
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        visits = query.order_by(TriageVisit.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'data': [TriageVisitOut.model_validate(v).model_dump() for v in visits.items],
            'total': visits.total,
            'page': page,
            'per_page': per_page,
            'pages': visits.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting triage visits: {str(e)}")
        return jsonify({'error': str(e)}), 500


# Analytics endpoint
@app.route('/api/analytics/facility-stats', methods=['GET'])
def get_facility_stats():
    """Get facility statistics"""
    try:
        total_facilities = db.session.query(Facility).count()
        total_patients = db.session.query(Patient).count()
        total_records = db.session.query(MedicalRecord).count()
        total_triage = db.session.query(TriageVisit).count()
        
        return jsonify({
            'total_facilities': total_facilities,
            'total_patients': total_patients,
            'total_medical_records': total_records,
            'total_triage_visits': total_triage
        }), 200
            
    except Exception as e:
        logger.error(f"Error getting facility stats: {str(e)}")
        return jsonify({'error': str(e)}), 500


# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    with app.app_context():
        logger.info("Starting Medical Records API...")
        logger.info(f"Database: postgresql://{DB_USER}:***@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    app.run(host='0.0.0.0', port=5000, debug=False)