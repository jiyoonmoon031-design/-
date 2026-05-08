from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Float
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users" #users 테이블

    user_id = Column(Integer, primary_key=True, index=True) #사용자 고유 ID
    email = Column(String(255), unique=True, nullable=False, index=True) #로그인용 이메일
    password_hash = Column(String(255), nullable=False) #암호화된 비밀번호
    name = Column(String(100), nullable=False) #사용자 이름
    user_role = Column(String(20), nullable=False) #역할
    account_status = Column(String(20), nullable=False, default="ACTIVE") #계정 상태
    created_at = Column(DateTime(timezone=True), server_default=func.now()) #생성 시간
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now()) #수정 시간


class Farm(Base):
    __tablename__ = "farms"

    farm_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    manager_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    farm_name = Column(String(100), nullable=False)
    farm_location = Column(String(255), nullable=True)
    farm_description = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    share_consent_level = Column(String(20), nullable=False, default="PRIVATE")
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    public_region_label = Column(String(100), nullable=True)
    

class Zone(Base):
    __tablename__ = "zones"

    zone_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    farm_id = Column(Integer, ForeignKey("farms.farm_id"), nullable=False)
    zone_name_or_code = Column(String(100), nullable=False)
    crop_name = Column(String(100), nullable=True)
    zone_description = Column(String(255), nullable=True)
    is_deleted = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    share_enabled_flag = Column(Boolean, nullable=False, default=False)

class ImageAsset(Base):
    __tablename__ = "image_assets"

    image_asset_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    original_image_path = Column(String(255), nullable=False)
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())


class Diagnosis(Base):
    __tablename__ = "diagnoses"

    diagnosis_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    farm_id = Column(Integer, ForeignKey("farms.farm_id"), nullable=True)
    zone_id = Column(Integer, ForeignKey("zones.zone_id"), nullable=True)
    image_asset_id = Column(Integer, ForeignKey("image_assets.image_asset_id"), nullable=False)

    crop_name = Column(String(100), nullable=False)
    part_name = Column(String(50), nullable=False)
    disease_name = Column(String(100), nullable=False)
    class_name = Column(String(150), nullable=False)

    has_disease = Column(Boolean, nullable=False)
    confidence_score = Column(Float, nullable=False)
    severity_level = Column(String(20), nullable=False)

    recommendation_text = Column(String(1000), nullable=True)
    low_confidence_flag = Column(Boolean, nullable=False, default=False)
    retake_recommended_flag = Column(Boolean, nullable=False, default=False)
    action_status = Column(String(20), nullable=False, default="PENDING")
    gradcam_path = Column(String(255), nullable=True)

    diagnosed_at = Column(DateTime(timezone=True), server_default=func.now())


class DetectionResult(Base):
    __tablename__ = "detection_results"

    detection_result_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    diagnosis_id = Column(Integer, ForeignKey("diagnoses.diagnosis_id"), nullable=False)
    bbox_xmin = Column(Integer, nullable=False)
    bbox_ymin = Column(Integer, nullable=False)
    bbox_xmax = Column(Integer, nullable=False)
    bbox_ymax = Column(Integer, nullable=False)


class DiagnosisFailure(Base):
    __tablename__ = "diagnosis_failures"

    failure_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    image_asset_id = Column(Integer, ForeignKey("image_assets.image_asset_id"), nullable=True)

    failure_stage = Column(String(50), nullable=False)
    error_code = Column(String(100), nullable=True)
    error_message = Column(String(1000), nullable=True)
    retryable_flag = Column(Boolean, nullable=False, default=True)
    failed_at = Column(DateTime(timezone=True), server_default=func.now())

class CalendarEvent(Base):
    __tablename__ = "calendar_events"

    event_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    farm_id = Column(Integer, ForeignKey("farms.farm_id"), nullable=True)
    zone_id = Column(Integer, ForeignKey("zones.zone_id"), nullable=True)
    diagnosis_id = Column(Integer, ForeignKey("diagnoses.diagnosis_id"), nullable=True)

    event_type = Column(String(20), nullable=False)  # DIAGNOSIS / TREATMENT / CARE
    care_type = Column(String(20), nullable=True)    # WATERING / FERTILIZING / OTHER_CARE
    title = Column(String(255), nullable=False)
    memo = Column(String(1000), nullable=True)

    crop_name = Column(String(100), nullable=True)
    disease_name = Column(String(100), nullable=True)
    severity_level = Column(String(20), nullable=True)

    event_date = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class TreatmentAlert(Base):
    __tablename__ = "treatment_alerts"

    alert_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    diagnosis_id = Column(Integer, ForeignKey("diagnoses.diagnosis_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    alert_status = Column(String(20), nullable=False, default="SCHEDULED")
    alert_response = Column(String(20), nullable=True)  # COMPLETED / HOLD / REMIND_LATER

    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    responded_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())