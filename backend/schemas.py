from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime


class SignupRequest(BaseModel): #회원가입 요청
    email: EmailStr
    password: str
    name: str
    user_role: str

class LoginRequest(BaseModel): #로그인 요청
    email: EmailStr
    password: str


class LoginUserInfo(BaseModel): #로그인 응답
    user_id: int
    name: str
    user_role: str


class LoginResponse(BaseModel):
    success: bool
    access_token: str
    token_type: str
    user: LoginUserInfo


class UserMeResponse(BaseModel):
    user_id: int
    email: EmailStr
    name: str
    user_role: str
    account_status: str

class UpdateRoleRequest(BaseModel):
    user_role: str

class FarmResponse(BaseModel):
    farm_id: int
    farm_name: str
    farm_location: str | None = None
    farm_description: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    public_region_label: str | None = None

class FarmCreateRequest(BaseModel): #농장 등록 요청
    farm_name: str
    farm_location: str | None = None
    farm_description: str | None = None

class FarmUpdateRequest(BaseModel): #농장 수정 요청
    farm_name: str
    farm_location: str | None = None
    farm_description: str | None = None

class FarmSaveResponse(BaseModel): #농장 수정/등록 응답
    success: bool
    message: str
    data: FarmResponse

class FarmListItem(BaseModel):
    farm_id: int
    farm_name: str
    farm_location: str | None = None
    farm_description: str | None = None

class FarmListResponse(BaseModel): #농장 조회 응답
    success: bool
    data: list[FarmListItem]

class ZoneResponse(BaseModel):
    zone_id: int
    farm_id: int
    zone_name_or_code: str
    crop_name: str | None = None
    zone_description: str | None = None
    is_deleted: bool

class ZoneCreateRequest(BaseModel): #구역 생성 요청
    farm_id: int
    zone_name_or_code: str
    crop_name: str | None = None
    zone_description: str | None = None

class ZoneUpdateRequest(BaseModel): #구역 수정 요청
    zone_name_or_code: str
    crop_name: str | None = None
    zone_description: str | None = None

class ZoneSaveResponse(BaseModel): #구역 등록/수정 응답
    success: bool
    message: str
    data: ZoneResponse

class ZoneListItem(BaseModel): 
    zone_id: int
    zone_name_or_code: str
    crop_name: str | None = None
    zone_description: str | None = None

class ZoneListResponse(BaseModel): #구역 조회 응답
    success: bool
    data: list[ZoneListItem]

class DetectionBoxResponse(BaseModel):
    bbox_xmin: int
    bbox_ymin: int
    bbox_xmax: int
    bbox_ymax: int

class DiagnosisResponse(BaseModel):
    diagnosis_id: int
    farm_id: Optional[int] = None
    zone_id: Optional[int] = None
    crop_name: str
    part_name: str
    disease_name: str
    class_name: str
    has_disease: bool
    confidence_score: float
    severity_level: str
    recommendation_text: Optional[str]
    low_confidence_flag: bool
    retake_recommended_flag: bool
    gradcam_path: Optional[str]
    detections: List[DetectionBoxResponse]

class DiagnosisUploadResponse(BaseModel):
    success: bool
    message: str
    data: DiagnosisResponse

class DiagnosisHistoryItem(BaseModel):
    diagnosis_id: int
    crop_name: str
    disease_name: str
    severity_level: str
    action_status: str
    diagnosed_at: datetime
    zone_id: int | None = None

class DiagnosisHistoryResponse(BaseModel): #진단이력 응답
    success: bool
    data: list[DiagnosisHistoryItem]

class DiagnosisDetailResponse(BaseModel):
    success: bool
    data: DiagnosisResponse

# 공통 KPI
class KPI(BaseModel):
    average_severity: float
    completion_rate: float
    disease_count: int


# 상단 KPI용
class DashboardData(BaseModel):
    kpi: KPI
    total_records: int
    has_enough_data_for_graph: bool

class DashboardResponse(BaseModel):
    success: bool
    data: DashboardData

# group-kpi용
class GroupKPI(KPI):
    total_records: int

class CropGroupKPI(GroupKPI):
    crop_name: str

class ZoneGroupKPI(GroupKPI):
    farm_id: int
    zone_id: int
    zone_name: str
    crop_name: str

class GroupKPIResponse(BaseModel):
    success: bool
    data: list[dict]  # 간단하게

class DailySeverityPoint(BaseModel):
    date: str
    average_severity: float

#일별 심각도 추세 그래프
class DailySeverityByDisease(BaseModel):
    disease_name: str
    data: list[DailySeverityPoint]

#병해별 발생 빈도
class DiseaseFrequencyItem(BaseModel):
    disease_name: str
    count: int

#병해별 분포
class DiseaseDistributionItem(BaseModel):
    disease_name: str
    count: int
    ratio: float

class GroupChartsData(BaseModel):
    daily_severity_by_disease: list[DailySeverityByDisease]
    disease_frequency: list[DiseaseFrequencyItem]
    disease_distribution: list[DiseaseDistributionItem]
    total_records: int
    has_enough_data_for_graph: bool

class GroupChartsResponse(BaseModel):
    success: bool
    data: GroupChartsData

class UpdateActionStatusRequest(BaseModel):
    action_status: str

class CreateTreatmentAlertRequest(BaseModel):
    diagnosis_id: int
    scheduled_at: datetime

class RespondTreatmentAlertRequest(BaseModel):
    alert_response: str

class CalendarEventItem(BaseModel):
    event_id: int
    event_type: str
    diagnosis_id: int | None = None
    care_type: str | None = None
    title: str
    memo: str | None = None
    crop_name: str | None = None
    disease_name: str | None = None
    severity_level: str | None = None
    farm_id: int | None = None
    zone_id: int | None = None
    event_date: datetime

class CalendarEventResponse(BaseModel):
    success: bool
    data: list[CalendarEventItem]

class FarmShareConsentRequest(BaseModel):
    share_consent_level: str
    shared_zone_ids: Optional[List[int]] = []

class SharedZoneResponse(BaseModel):
    zone_id: int
    zone_name_or_code: str
    share_enabled_flag: bool

class FarmShareConsentData(BaseModel):
    farm_id: int
    share_consent_level: str
    shared_zones: list[SharedZoneResponse]

class FarmShareConsentResponse(BaseModel):
    success: bool
    message: str
    data: FarmShareConsentData

class NearbyBaseFarm(BaseModel):
    farm_id: int
    farm_name: str
    latitude: float
    longitude: float
    public_region_label: str | None = None
    share_consent_level: str


class NearbyZoneRisk(BaseModel):
    zone_id: int
    zone_name_or_code: str
    crop_name: str | None = None
    total_diagnosis_count: int
    disease_count: int
    disease_ratio: float
    risk_level: str
    risk_label: str
    data_status: str


class NearbyFarmItem(BaseModel):
    farm_id: int
    farm_name: str
    latitude: float
    longitude: float
    distance_km: float
    public_region_label: str | None = None
    share_consent_level: str
    crop_names: list[str]
    disease_names: list[str]
    recent_status_summary: str
    zone_risks: list[NearbyZoneRisk]


class NearbyFarmsData(BaseModel):
    base_farm: NearbyBaseFarm
    radius_km: float
    count: int
    farms: list[NearbyFarmItem]


class NearbyFarmsResponse(BaseModel):
    success: bool
    data: NearbyFarmsData

class PreventionAlert(BaseModel):
    score: float
    alert_level: str
    alert_label: str
    data_status: str

class Recent7Days(BaseModel):
    total_diagnosis_count: int
    moderate_count: int
    severe_count: int
    moderate_or_severe_count: int


class TopDisease(BaseModel):
    disease_name: str
    count: int


class OtherDisease(BaseModel):
    disease_name: str
    count: int
    last_occurred_date: str


class DailyRiskyCount(BaseModel):
    date: str
    count: int

class NearbyFarmZoneDetail(BaseModel):
    zone_id: int
    zone_name_or_code: str
    crop_name: str | None = None

    prevention_alert: PreventionAlert
    recent_7days: Recent7Days

    top_disease: TopDisease | None = None
    last_moderate_or_severe_date: str | None = None

    other_diseases: list[OtherDisease]
    daily_risky_counts: list[DailyRiskyCount]

class NearbyFarmInfo(BaseModel):
    farm_id: int
    farm_name: str
    distance_km: float
    public_region_label: str | None = None
    share_consent_level: str

class NearbyFarmRiskDetailData(BaseModel):
    farm: NearbyFarmInfo
    zones: list[NearbyFarmZoneDetail]


class NearbyFarmRiskDetailResponse(BaseModel):
    success: bool
    data: NearbyFarmRiskDetailData