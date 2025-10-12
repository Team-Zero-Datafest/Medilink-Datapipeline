"""
SQLAlchemy models for medical records database
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Date, DateTime, Numeric, Text, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import JSONB, ARRAY
from sqlalchemy.orm import relationship
from app import db

class Facility(db.Model):
    __tablename__ = 'facilities'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    state = Column(String(100), nullable=False)
    lga = Column(String(100), nullable=False)
    lat = Column(Numeric(10, 8))
    lon = Column(Numeric(11, 8))
    type = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    patients = relationship('Patient', back_populates='facility', lazy='dynamic')
    medical_records = relationship('MedicalRecord', back_populates='facility', lazy='dynamic')
    triage_visits = relationship('TriageVisit', back_populates='facility', lazy='dynamic')
    
    def __repr__(self):
        return f'<Facility {self.name} - {self.state}>'


class Patient(db.Model):
    __tablename__ = 'patients'
    
    id = Column(Integer, primary_key=True)
    facility_id = Column(Integer, ForeignKey('facilities.id'), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    sex = Column(String(10), nullable=False)
    dob = Column(Date, nullable=False)
    phone = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    facility = relationship('Facility', back_populates='patients')
    medical_records = relationship('MedicalRecord', back_populates='patient', lazy='dynamic')
    triage_visits = relationship('TriageVisit', back_populates='patient', lazy='dynamic')
    record_requests = relationship('RecordRequest', back_populates='patient', lazy='dynamic')
    
    def __repr__(self):
        return f'<Patient {self.first_name} {self.last_name}>'


class MedicalRecord(db.Model):
    __tablename__ = 'medical_records'
    
    id = Column(Integer, primary_key=True)
    patient_id = Column(Integer, ForeignKey('patients.id'), nullable=False)
    facility_id = Column(Integer, ForeignKey('facilities.id'), nullable=False)
    record_type = Column(String(100))
    data = Column(JSONB, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    patient = relationship('Patient', back_populates='medical_records')
    facility = relationship('Facility', back_populates='medical_records')
    
    def __repr__(self):
        return f'<MedicalRecord {self.id} - Patient {self.patient_id}>'


class TriageVisit(db.Model):
    __tablename__ = 'triage_visits'
    
    id = Column(Integer, primary_key=True)
    patient_id = Column(Integer, ForeignKey('patients.id'), nullable=False)
    facility_id = Column(Integer, ForeignKey('facilities.id'), nullable=False)
    triage_level = Column(Integer, nullable=False)
    likely_conditions = Column(ARRAY(Text))
    recommendations = Column(ARRAY(Text))
    language = Column(String(10), default='en')
    provider = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    patient = relationship('Patient', back_populates='triage_visits')
    facility = relationship('Facility', back_populates='triage_visits')
    
    def __repr__(self):
        return f'<TriageVisit {self.id} - Level {self.triage_level}>'


class RecordRequest(db.Model):
    __tablename__ = 'record_requests'
    
    id = Column(Integer, primary_key=True)
    requester_facility_id = Column(Integer, ForeignKey('facilities.id'), nullable=False)
    target_facility_id = Column(Integer, ForeignKey('facilities.id'), nullable=False)
    patient_id = Column(Integer, ForeignKey('patients.id'), nullable=False)
    reason = Column(Text)
    status = Column(String(50), default='pending')
    created_at = Column(DateTime, default=datetime.utcnow)
    acted_at = Column(DateTime)
    
    # Relationships
    patient = relationship('Patient', back_populates='record_requests')
    
    def __repr__(self):
        return f'<RecordRequest {self.id} - Status: {self.status}>'