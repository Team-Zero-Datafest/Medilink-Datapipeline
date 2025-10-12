"""
Pydantic schemas for API request/response validation
"""
from __future__ import annotations
from datetime import date, datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ConfigDict


# Facility schemas
class FacilityCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    state: str = Field(..., min_length=1, max_length=100)
    lga: str = Field(..., min_length=1, max_length=100)
    lat: Optional[float] = None
    lon: Optional[float] = None
    type: Optional[str] = None


class FacilityOut(BaseModel):
    id: int
    name: str
    state: str
    lga: str
    lat: Optional[float]
    lon: Optional[float]
    type: Optional[str]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Patient schemas
class PatientCreate(BaseModel):
    facility_id: int = Field(..., gt=0)
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    sex: str = Field(..., pattern='^(M|F|Other)$')
    dob: date
    phone: Optional[str] = Field(None, max_length=20)


class PatientOut(BaseModel):
    id: int
    facility_id: int
    first_name: str
    last_name: str
    sex: str
    dob: date
    phone: Optional[str]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Medical Record schemas
class MedicalRecordCreate(BaseModel):
    patient_id: int = Field(..., gt=0)
    facility_id: int = Field(..., gt=0)
    record_type: Optional[str] = None
    data: Dict[str, Any] = Field(..., description="JSONB data containing medical record details")


class MedicalRecordOut(BaseModel):
    id: int
    patient_id: int
    facility_id: int
    record_type: Optional[str]
    data: Dict[str, Any]
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Triage schemas
class TriageVisitOut(BaseModel):
    id: int
    patient_id: int
    facility_id: int
    triage_level: int
    likely_conditions: Optional[List[str]]
    recommendations: Optional[List[str]]
    language: str
    provider: Optional[str]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Record Request schemas
class RecordRequestCreate(BaseModel):
    patient_id: int = Field(..., gt=0)
    target_facility_id: int = Field(..., gt=0)
    reason: Optional[str] = None


class RecordRequestOut(BaseModel):
    id: int
    requester_facility_id: int
    target_facility_id: int
    patient_id: int
    reason: Optional[str]
    status: str
    created_at: datetime
    acted_at: Optional[datetime]
    
    model_config = ConfigDict(from_attributes=True)