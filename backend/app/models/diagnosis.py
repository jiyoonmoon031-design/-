from sqlalchemy import Column, Integer, String, Float, DateTime
from datetime import datetime
from app.core.database import Base

class Diagnosis(Base):
    __tablename__ = "diagnoses"

    id = Column(Integer, primary_key=True, index=True)
    image_id = Column(Integer, nullable=True)
    disease_name = Column(String(100), nullable=False)
    confidence = Column(Float, nullable=False)
    severity_level = Column(String(50), nullable=False)
    recommendation = Column(String(255), nullable=True)
    action_status = Column(String(50), default="PENDING")
    created_at = Column(DateTime, default=datetime.utcnow)