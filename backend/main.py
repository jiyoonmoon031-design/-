from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import os
import shutil
from uuid import uuid4
from ai_service import request_ai_diagnosis
from database import Base, engine, get_db
import models
import schemas
from security import hash_password, verify_password, create_access_token, verify_access_token
from datetime import datetime, timedelta
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from utils.location_utils import calculate_distance_km
from utils.location_utils import geocode_address, calculate_distance_km
from sqlalchemy import or_
from collections import Counter

app = FastAPI() #백엔드 앱을 만드는 코드 @app.get, @app.post 이런식으로 붙여서 API를 만듬
security = HTTPBearer() #토큰 인증방식 사용 즉, 로그인 후 받은 토큰을 Authorization: Bearer... 형태로 보냄

# 테이블 생성
Base.metadata.create_all(bind=engine) #models.py에 정의한 테이블들을 실제 DB에 생성해주는 코드

@app.exception_handler(RequestValidationError) #에러 등록 시스템, RequestValidationError: 입력값 검증 에러가 발생했을때 실행
async def validation_exception_handler(request, exc):  #async def: 비동기로 실행되는 함수, 다른 일과 동시에 할 수 있음, request: 사용자 요청 정보(어떤 api 호출했는지 등), exc:발생한 에러 정보(어떤 에러인지 등)
    for err in exc.errors(): #발생한 에러들 하나씩 확인, exc: 발생한 에러 정보(["body",email]이런형태)
        if err["loc"][-1] == "email": #에러가 email일 경우
            return JSONResponse(  #전용 메시지 반환
                status_code=400, #이 함수에서 오류코드 400일때 아래 메시지 출력
                content={
                    "success": False,
                    "message": "올바른 이메일 형식이 아닙니다."
                },
            )

    return JSONResponse( # 그 외 모든 에러 메시지
        status_code=400, #오류코드
        content={
            "success": False,
            "message": "입력값이 올바르지 않습니다." #메시지
        },
    )

@app.post("/auth/signup") #회원가입 기능
def signup(request: schemas.SignupRequest, db: Session = Depends(get_db)): #schemas.SignupRequest를 요청: schemas에 지정된 형태로 입력해야함, depends(get_db): DB 연결을 자동으로 가져옴
    allowed_roles = ["GENERAL_USER", "FARM_MANAGER"] #역할 검사, 가입할 때는 일반 사용자와 농장 관리자만 가능하게함
    if request.user_role not in allowed_roles: #여기서 request: 검증을 통과한 회원가입 입력 데이터, user_role은 schemas에 정의되어 있는 속성
        raise HTTPException( #오류 발생, HTTP 요청에서 사용할 에러
            status_code=status.HTTP_400_BAD_REQUEST, #오류코드 400: 잘못된 요청, 클라이언트 오류
            detail="user_role은 GENERAL_USER 또는 FARM_MANAGER만 가능합니다."
        )

    existing_user = db.query(models.User).filter(models.User.email == request.email).first() #models: models.py 안에 있는 클래스, db.query(): 데이터 조회, 
    if existing_user: #이메일이 중복될 경우
        raise HTTPException( #오류 발생
            status_code=status.HTTP_400_BAD_REQUEST, #오류코드 400
            detail="이미 사용 중인 이메일입니다."
        )

    if len(request.password) < 8: #비밀번호 길이가 8 미만일 경우
        raise HTTPException( #오류 발생
            status_code=status.HTTP_400_BAD_REQUEST, #오류코드 400
            detail="비밀번호는 8자 이상이어야 합니다."
        )

    hashed_password = hash_password(request.password) #비밀번호 암호화: 비밀번호를 그대로 저장하지 않고 해시로 바꿈, security.py 파일에서 hash_password 가져옴

    new_user = models.User( #사용자 생성
        email=request.email, 
        password_hash=hashed_password,
        name=request.name,
        user_role=request.user_role,
        account_status="ACTIVE"
    )

    db.add(new_user) #DB에 추가할 객체 등록
    db.commit() #변경사항을 DB에 실제로 저장
    db.refresh(new_user) #새로고침

    return { #결과 반환
        "success": True,
        "message": "회원가입이 완료되었습니다.",
        "data": {
            "user_id": new_user.user_id,
            "email": new_user.email,
            "name": new_user.name,
            "user_role": new_user.user_role,
            "account_status": new_user.account_status
        }
    }
# 입력검사 -> 중복검사 -> 암호화 -> DB 저장 -> 응답

@app.post("/auth/login", response_model=schemas.LoginResponse) #로그인 API
def login(request: schemas.LoginRequest, db: Session = Depends(get_db)): 
    user = db.query(models.User).filter(models.User.email == request.email).first() #이메일로 사용자 찾기

    if user is None: #데이터에 존재하지 않을 경우
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, #인증 안 됨 오류(로그인 필요)
            detail="존재하지 않는 이메일입니다."
        )

    if user.account_status != "ACTIVE": #계정 활성상태 검사
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, # 접근 권한 없음 오류 -> 비활성화상태이므로 권한 없음
            detail="비활성화된 계정입니다."
        ) #비활성화 계정은 관리자가 해제 가능

    if not verify_password(request.password, user.password_hash): #입략 비밀번호와 DB의 해시 비밀번호 비교, verify_password: 입력한 비밀번호가 맞는지 확인하는 함수
        raise HTTPException(  #비밀번호를 해시처리해서 데이터베이스의 해시값과 비교하는게 아닌, 해당 이메일의 데이터에서 salt정보를 가져와 이 정보대로 해시처리를 하여 비밀번호를 비교함
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="비밀번호가 올바르지 않습니다."
        )

    access_token = create_access_token( #토큰 생성, '나는 로그인한 사용자다'를 증명하는 것, create_access_token: 로그인 성공 시 사용자 인증용 토큰(JWT)을 만드는 함수
        data={ #필요성 : 요청할 때마다 서버가 계속해서 이 사람은 로그인을 한 사람인가? 계속 확인해야함 -> 토큰을 발급받으면 '로그인한 상태인가'를 토큰 확인만 가지고 확인 가능, 그렇지 않으면 요청할때마다 로그인해야함
            "user_id": user.user_id, 
            "email": user.email,
            "user_role": user.user_role
        }
    )

    return { #토큰과 사용자 기본 정보 반환
        "success" : True,
        "access_token" : access_token,
        "token_type" : "bearer",
        "user": {
            "user_id": user.user_id,
            "name": user.name,
            "user_role": user.user_role
        }
    }
# 이메일 확인 -> 계정 상태 확인 -> 비밀번호 확인 -> 토큰 발급

def get_current_user( #공통 인증 함수: 로그인한 사용자가 누구인지 알아내는 공통 함수
    credentials: HTTPAuthorizationCredentials = Depends(security),#HTTPAuthorizationCredentials: 타입임,  Depends(security): 사용자가 보낸 Authorization 헤더에서 토큰 정보를 불러옴
    db: Session = Depends(get_db)
):
    token = credentials.credentials #토큰 꺼내기, .credentials: 실제 토큰 문자열, credentails는 객체로 안에 scheme, credentials 같은 정보가 있음

    payload = verify_access_token(token) #토큰 검증
    if payload is None: #토큰 검증 실패했을 경우
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="유효하지 않은 토큰입니다."
        )

    user_id = payload.get("user_id") #토큰 안의 user_id 추출
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰에 user_id가 없습니다."
        )

    user = db.query(models.User).filter(models.User.user_id == user_id).first() #DB에서 실제 사용자 조회
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사용자를 찾을 수 없습니다."
        )

    return user #유저 반환
#필요성: 사용자 정보 반환


def require_farm_manager( #농장 관리자 전용 검사
    current_user: models.User = Depends(get_current_user) #current_user에 models.User 타입으로 정보를 저장함
):
    if current_user.user_role != "FARM_MANAGER": #사용자의 역할이 농장 관리자가 아닐 경우
        raise HTTPException( #오류 발생
            status_code=status.HTTP_403_FORBIDDEN, #403: 접근 권한 없음 오류 코드
            detail="농장 관리자만 접근할 수 있습니다."
        )
    return current_user #다른 함수에서 이 함수를 호출할 때를 위한 반환


def severity_to_score(level: str) -> int: #심각도를 숫자로 변환: 대시보드 평균 심각도 계산할 때 사용
    mapping = {
        "HEALTHY": 0,
        "MILD": 1,
        "MODERATE": 2,
        "SEVERE": 3
    }
    return mapping.get(level, 0) #mapping에서 level에 해당하는 값 가져오고, 없으면 0 반환


def get_manager_zone_ids(db: Session, manager_user_id: int): #해당 농장 관리자가 소유한 농장들의 구역 ID 목록을 가져오는 함수
    zones = db.query(models.Zone).join( #Farm의 farm_id와 Zone의 farm_id를 연결해서 해당 농장에 속한 구역들을 가져옴
        models.Farm, models.Zone.farm_id == models.Farm.farm_id
    ).filter(
        models.Farm.manager_user_id == manager_user_id, #해당 사용자의 농장이 맞는지 확인
        models.Zone.is_deleted == False #삭제된 구역은 조회하지 않음
    ).all()

    return [z.zone_id for z in zones] # zones 안에 있는 각 객체에서 zone_id만 뽑아서 리스트로 반환


@app.get("/users/me", response_model=schemas.UserMeResponse) #내 정보 조회, schemas.UserMeResponse 형식으로 입력받음
def read_users_me(current_user: models.User = Depends(get_current_user)): #로그인한 사용자의 기본 정보를 불러옴
    return {
        "user_id": current_user.user_id,
        "email": current_user.email,
        "name": current_user.name,
        "user_role": current_user.user_role,
        "account_status": current_user.account_status
    }


@app.patch("/users/me/role") #역할 변경
def update_user_role(  #사용자의 역할 정보 조회
    request: schemas.UpdateRoleRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    allowed_roles = ["GENERAL_USER", "FARM_MANAGER"]
    if request.user_role not in allowed_roles: #없는 역할이 조회된 경우
        raise HTTPException( #오류 발생
            status_code=status.HTTP_400_BAD_REQUEST, #잘못된 요청(입력값 문제) 오류
            detail="user_role은 GENERAL_USER 또는 FARM_MANAGER만 가능합니다."
        )

    if current_user.user_role == request.user_role: #같은 역할을 선택했을 경우
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 해당 역할을 사용 중입니다."
        )

    current_user.user_role = request.user_role #현재 역할을 요청받은 값으로 변경
    db.commit() 
    db.refresh(current_user)

    return { # 역할 변경 결과 반환
        "success": True,
        "message": "사용자 역할이 변경되었습니다.",
        "data": {
            "user_id": current_user.user_id,
            "email": current_user.email,
            "name": current_user.name,
            "user_role": current_user.user_role,
            "account_status": current_user.account_status
        }
    }

#task--------------------------------추후에 위치 API과 연동하기---------------------------------- 
@app.post("/farms",response_model=schemas.FarmSaveResponse)
def create_farm(
    request: schemas.FarmCreateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    if not request.farm_name.strip():
        raise HTTPException(status_code=400, detail="farm_name은 필수입니다.")

    if not request.farm_location or not request.farm_location.strip():
        raise HTTPException(status_code=400, detail="farm_location은 필수입니다.")

    geo = geocode_address(request.farm_location)

    new_farm = models.Farm(
        manager_user_id=current_user.user_id,
        farm_name=request.farm_name,
        farm_location=request.farm_location,
        farm_description=request.farm_description,
        share_consent_level="PRIVATE",
        latitude=geo["latitude"],
        longitude=geo["longitude"],
        public_region_label=geo["public_region_label"]
    )

    db.add(new_farm)
    db.commit()
    db.refresh(new_farm)

    return {
        "success": True,
        "message": "농장이 등록되었습니다.",
        "data": {
            "farm_id": new_farm.farm_id,
            "farm_name": new_farm.farm_name,
            "farm_location": new_farm.farm_location,
            "farm_description": new_farm.farm_description,
            "latitude": new_farm.latitude,
            "longitude": new_farm.longitude,
            "public_region_label": new_farm.public_region_label,
            "share_consent_level": new_farm.share_consent_level
        }
    }


@app.get("/farms", response_model=schemas.FarmListResponse) #농장 조회, get: 조회
def get_farms( #농장 정보 불러옴
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    farms = db.query(models.Farm).filter(
        models.Farm.manager_user_id == current_user.user_id
    ).all()

    return { #농장 정보 반환
        "success": True,
        "data": [
            {
                "farm_id": farm.farm_id,
                "farm_name": farm.farm_name,
                "farm_location": farm.farm_location,
                "farm_description": farm.farm_description
            }
            for farm in farms
        ]
    }


@app.patch("/farms/{farm_id}", response_model=schemas.FarmSaveResponse)
def update_farm(
    farm_id: int,
    request: schemas.FarmUpdateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    farm = db.query(models.Farm).filter(
        models.Farm.farm_id == farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None:
        raise HTTPException(status_code=404, detail="농장을 찾을 수 없습니다.")

    if not request.farm_name.strip():
        raise HTTPException(status_code=400, detail="farm_name은 필수입니다.")

    if not request.farm_location or not request.farm_location.strip():
        raise HTTPException(status_code=400, detail="farm_location은 필수입니다.")

    # 주소가 수정되었으면 다시 위도/경도 변환
    geo = geocode_address(request.farm_location)

    farm.farm_name = request.farm_name
    farm.farm_location = request.farm_location
    farm.farm_description = request.farm_description
    farm.latitude = geo["latitude"]
    farm.longitude = geo["longitude"]
    farm.public_region_label = geo["public_region_label"]

    db.commit()
    db.refresh(farm)

    return {
        "success": True,
        "message": "농장 정보가 수정되었습니다.",
        "data": {
            "farm_id": farm.farm_id,
            "farm_name": farm.farm_name,
            "farm_location": farm.farm_location,
            "farm_description": farm.farm_description,
            "latitude": farm.latitude,
            "longitude": farm.longitude,
            "public_region_label": farm.public_region_label,
            "share_consent_level": farm.share_consent_level,
        }
    }

@app.delete("/farms/{farm_id}")
def delete_farm(
    farm_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    farm = db.query(models.Farm).filter(
        models.Farm.farm_id == farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None:
        raise HTTPException(status_code=404, detail="농장을 찾을 수 없습니다.")

    zones = db.query(models.Zone).filter(
        models.Zone.farm_id == farm_id
    ).all()

    zone_ids = [zone.zone_id for zone in zones]

    diagnoses = db.query(models.Diagnosis).filter(
        models.Diagnosis.farm_id == farm_id
    ).all()

    diagnosis_ids = [
        diagnosis.diagnosis_id
        for diagnosis in diagnoses
    ]

    try:
        if diagnosis_ids:
            db.query(models.DetectionResult).filter(
                models.DetectionResult.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.TreatmentAlert).filter(
                models.TreatmentAlert.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.CalendarEvent).filter(
                models.CalendarEvent.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.Diagnosis).filter(
                models.Diagnosis.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

        if zone_ids:
            db.query(models.CalendarEvent).filter(
                models.CalendarEvent.zone_id.in_(zone_ids)
            ).delete(synchronize_session=False)

            db.query(models.Zone).filter(
                models.Zone.zone_id.in_(zone_ids)
            ).delete(synchronize_session=False)

        db.delete(farm)
        db.commit()

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="농장 삭제 중 오류가 발생했습니다."
        )

    return {
        "success": True,
        "message": "농장과 연결된 구역이 삭제되었습니다."
    }

#task-------------------------추후에 zone테이블의 bed, building 변수 삭제----------
@app.post("/zones", response_model=schemas.ZoneSaveResponse) # post: 생성
def create_zone(
    request: schemas.ZoneCreateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    if not request.zone_name_or_code.strip():#.strip(): 앞뒤 공백 제거, 구역 이름을 입력하지 않았을 경우
        raise HTTPException(status_code=400, detail="zone_name_or_code는 필수입니다.")

    farm = db.query(models.Farm).filter( # 농장 테이블에서, 내 농장 아이디, 유저 아이디를 비교하여 내 농장 정보를 가져옴 
        models.Farm.farm_id == request.farm_id, 
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None: # 조회된 농장이 없을 경우
        raise HTTPException(status_code=404, detail="대상 농장을 찾을 수 없습니다.")

    new_zone = models.Zone(  #입력받은 데이터로 new_zone 데이터를 구성
        farm_id=request.farm_id,
        zone_name_or_code=request.zone_name_or_code,
        crop_name=request.crop_name,
        zone_description=request.zone_description,
        is_deleted=False
    )

    db.add(new_zone) #db에 new_zone 추가 -> 위에서 models.Zoze으로 형식을 정했으니 자동으로 Zone 테이블에 저장됨
    db.commit() # add 적용
    db.refresh(new_zone) #새로고침

    return {
        "success": True,
        "message": "구역이 등록되었습니다.",
        "data": {
            "zone_id": new_zone.zone_id,
            "farm_id": new_zone.farm_id,
            "zone_name_or_code": new_zone.zone_name_or_code,
            "crop_name": new_zone.crop_name,
            "zone_description": new_zone.zone_description,
            "is_deleted": new_zone.is_deleted
        }
    }


@app.get("/zones", response_model=schemas.ZoneListResponse) #구역 조회, get: 조회
def get_zones(
    farm_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    farm = db.query(models.Farm).filter( #농장 테이블에서 농장 아이디, 사용자 아이디를 비교하여 내 농장 정보 조회
        models.Farm.farm_id == farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None: #농장이 없을 경우
        raise HTTPException(status_code=404, detail="농장을 찾을 수 없습니다.")

    zones = db.query(models.Zone).filter( #구역 테이블에서 입력한 구역 아이디/명이 일치하고, 삭제하지 않은 구역정보 저장
        models.Zone.farm_id == farm_id,
        models.Zone.is_deleted == False
    ).all()

    return {
        "success": True,
        "data": [
            {
                "zone_id": zone.zone_id,
                "zone_name_or_code": zone.zone_name_or_code,
                "crop_name": zone.crop_name,
                "zone_description": zone.zone_description
            }
            for zone in zones
        ]
    }


@app.patch("/zones/{zone_id}", response_model=schemas.ZoneSaveResponse) #구역 정보 수정, patch: 수정
def update_zone(
    zone_id: int,
    request: schemas.ZoneUpdateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    zone = db.query(models.Zone).filter(
        models.Zone.zone_id == zone_id,
        models.Zone.is_deleted == False
    ).first()

    if zone is None:
        raise HTTPException(status_code=404, detail="구역을 찾을 수 없습니다.")

    farm = db.query(models.Farm).filter(
        models.Farm.farm_id == zone.farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None:
        raise HTTPException(status_code=403, detail="본인 농장의 구역만 수정할 수 있습니다.")

    if not request.zone_name_or_code.strip():
        raise HTTPException(status_code=400, detail="zone_name_or_code는 필수입니다.")

    zone.zone_name_or_code = request.zone_name_or_code
    zone.crop_name = request.crop_name
    zone.zone_description = request.zone_description

    db.commit()
    db.refresh(zone)

    return {
        "success": True,
        "message": "구역 정보가 수정되었습니다.",
        "data": {
            "zone_id": zone.zone_id,
            "farm_id": zone.farm_id,
            "zone_name_or_code": zone.zone_name_or_code,
            "crop_name": zone.crop_name,
            "zone_description": zone.zone_description,
            "is_deleted": zone.is_deleted
        }
    }

@app.delete("/zones/{zone_id}")
def delete_zone(
    zone_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    zone = db.query(models.Zone).join(
        models.Farm,
        models.Zone.farm_id == models.Farm.farm_id
    ).filter(
        models.Zone.zone_id == zone_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if zone is None:
        raise HTTPException(
            status_code=404,
            detail="구역을 찾을 수 없습니다."
        )

    try:
        diagnoses = db.query(models.Diagnosis).filter(
            models.Diagnosis.zone_id == zone_id
        ).all()

        diagnosis_ids = [
            diagnosis.diagnosis_id
            for diagnosis in diagnoses
        ]

        if diagnosis_ids:
            db.query(models.DetectionResult).filter(
                models.DetectionResult.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.TreatmentAlert).filter(
                models.TreatmentAlert.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.CalendarEvent).filter(
                models.CalendarEvent.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

            db.query(models.Diagnosis).filter(
                models.Diagnosis.diagnosis_id.in_(diagnosis_ids)
            ).delete(synchronize_session=False)

        db.query(models.CalendarEvent).filter(
            models.CalendarEvent.zone_id == zone_id
        ).delete(synchronize_session=False)

        db.delete(zone)

        db.commit()

        return {
            "success": True,
            "message": "구역과 연결된 진단 기록이 삭제되었습니다."
        }

    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=500,
            detail="구역 삭제 중 오류가 발생했습니다."
        )
    
@app.post("/diagnoses/upload",response_model=schemas.DiagnosisUploadResponse)
def upload_and_diagnose(
    file: UploadFile = File(...), #이미지파일
    zone_id: int | None = Form(None), #구역 (선택)
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    image_asset = None

    try:
        selected_zone_id = None
        zone=None
        if current_user.user_role == "FARM_MANAGER": # 관리자라면 구역 입력 필수
            if zone_id is None:
                raise HTTPException(status_code=400, detail="관리자는 구역을 선택해야 합니다.")

            zone = db.query(models.Zone).join(
                models.Farm, models.Zone.farm_id == models.Farm.farm_id
            ).filter(
                models.Zone.zone_id == zone_id,
                models.Zone.is_deleted == False,
                models.Farm.manager_user_id == current_user.user_id
            ).first()

            if zone is None:
                raise HTTPException(status_code=403, detail="접근 가능한 구역이 아닙니다.")

            selected_zone_id = zone.zone_id

        allowed_extensions = [".jpg", ".jpeg", ".png"]
        ext = os.path.splitext(file.filename)[1].lower() #파일 이름은 '이름'+'확장자'로 분리 -> ('image','jpg), 두번째값([1]) 확장자 추출
        if ext not in allowed_extensions: #파일 형식이 지원되지 않는 형식일 때
            raise HTTPException(status_code=400, detail="지원하지 않는 이미지 형식입니다.")

        os.makedirs("uploads/originals", exist_ok=True) #os.makedirs(): 폴더를 생성하는 함수. uploads/originals: 만들고 싶은 폴더 경로, exist_ok: 이미 폴더가 있어도 에러 내지 말고 넘어가라

        unique_filename = f"{uuid4()}{ext}" #파일 이름이 중복되지 않도록 방지, uuid(): 랜덤한 고유값 생성, 랜덤한 고유값에 ext(확장자) 합치기
        save_path = os.path.join("uploads/originals", unique_filename)#파일을 저장할 경로 생성, 파일 경로와 파일이름 합침

        with open(save_path, "wb") as buffer: #save_path 위치에 파일을 "쓰기 모드"로 열기, with...as buffer: 파일을 열고 작업이 끝나면 자동으로 닫아줌
            shutil.copyfileobj(file.file, buffer)#한 파일의 내용을 다른 파일로 그대로 복사

        image_asset = models.ImageAsset(
            user_id=current_user.user_id,
            original_image_path=save_path
        )
        db.add(image_asset)
        db.commit()
        db.refresh(image_asset)
#task-----------------------------confidence_flag 유지할지 추후에 결정-------------------------
        ai_result = request_ai_diagnosis(save_path) #진단결과 저장

        confidence = ai_result["confidence_score"]
        low_confidence_flag = 0.5 <= confidence < 0.7
        retake_recommended_flag = confidence < 0.5

        diagnosis = models.Diagnosis(
            user_id=current_user.user_id,
            farm_id=zone.farm_id if zone else None,
            zone_id=selected_zone_id,
            image_asset_id=image_asset.image_asset_id,
            crop_name=ai_result["crop_name"],
            part_name=ai_result["part_name"],
            disease_name=ai_result["disease_name"],
            class_name=ai_result["class_name"],
            has_disease=ai_result["has_disease"],
            confidence_score=confidence,
            severity_level=ai_result["severity_level"],
            recommendation_text=ai_result.get("recommendation_text"),
            low_confidence_flag=low_confidence_flag,
            retake_recommended_flag=retake_recommended_flag,
            action_status="PENDING",
            gradcam_path=ai_result.get("gradcam_path"),
        )
        db.add(diagnosis)
        db.commit()
        db.refresh(diagnosis)

        detections = ai_result.get("detections", []) #병변영역 정보 저장
        for det in detections:
            detection = models.DetectionResult(
                diagnosis_id=diagnosis.diagnosis_id,
                bbox_xmin=det["bbox_xmin"],
                bbox_ymin=det["bbox_ymin"],
                bbox_xmax=det["bbox_xmax"],
                bbox_ymax=det["bbox_ymax"],
            )
            db.add(detection)

        db.commit()

        calendar_event = models.CalendarEvent(
            user_id=current_user.user_id,
            farm_id=diagnosis.farm_id,
            zone_id=diagnosis.zone_id,
            diagnosis_id=diagnosis.diagnosis_id,
            event_type="DIAGNOSIS",
            title=f"{diagnosis.crop_name} - {diagnosis.disease_name}",
            crop_name=diagnosis.crop_name,
            disease_name=diagnosis.disease_name,
            severity_level=diagnosis.severity_level,
            event_date=diagnosis.diagnosed_at
        )
        db.add(calendar_event)
        db.commit()

        return {
            "success": True,
            "message": "진단이 완료되었습니다.",
            "data": {
                "diagnosis_id": diagnosis.diagnosis_id,
                "farm_id": diagnosis.farm_id,
                "zone_id": diagnosis.zone_id,
                "crop_name": diagnosis.crop_name,
                "part_name": diagnosis.part_name,
                "disease_name": diagnosis.disease_name,
                "class_name": diagnosis.class_name,
                "has_disease": diagnosis.has_disease,
                "confidence_score": diagnosis.confidence_score,
                "severity_level": diagnosis.severity_level,
                "recommendation_text": diagnosis.recommendation_text,
                "low_confidence_flag": diagnosis.low_confidence_flag,
                "retake_recommended_flag": diagnosis.retake_recommended_flag,
                "gradcam_path": diagnosis.gradcam_path,
                "detections": detections
            }
        }

    except HTTPException: #에러 출력
        raise

    except Exception as e: #예외 에러 처리
        db.rollback() #DB 작업 취소

        failure = models.DiagnosisFailure( #진단 실패 기록 저장
            user_id=current_user.user_id,
            image_asset_id=image_asset.image_asset_id if image_asset else None,
            failure_stage="analysis",
            error_code="DIAGNOSIS_FAILED",
            error_message=str(e),
            retryable_flag=True
        )
        db.add(failure) 
        db.commit()

        raise HTTPException(status_code=500, detail=f"진단 처리 중 오류가 발생했습니다: {str(e)}")


@app.get("/diagnoses/history",response_model=schemas.DiagnosisHistoryResponse) #진단이력 조회
def get_diagnosis_history(
    crop_name: str | None = None,
    severity_level: str | None = None,
    action_status: str | None = None,
    disease_name: str | None = None,
    farm_id: int | None = None,
    zone_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    query = db.query(models.Diagnosis)

    if current_user.user_role == "GENERAL_USER":
        query = query.filter(models.Diagnosis.user_id == current_user.user_id)
    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)
        if not manager_zone_ids:
            return {"success": True, "data": []}
        query = query.filter(models.Diagnosis.zone_id.in_(manager_zone_ids))

    if crop_name:
        query = query.filter(models.Diagnosis.crop_name == crop_name)

    if severity_level:
        query = query.filter(models.Diagnosis.severity_level == severity_level)

#task---------------추후에 농장 관리자 역할로 진단이력을 조회할 경우 농장별, 구역별, 심각도별로 수정 예정----------
    if current_user.user_role == "FARM_MANAGER":
        if disease_name:
            query = query.filter(models.Diagnosis.disease_name == disease_name)
        if farm_id is not None:
            query = query.filter(models.Diagnosis.farm_id == farm_id)
        if zone_id is not None:
            query = query.filter(models.Diagnosis.zone_id == zone_id)
        
    diagnoses = query.order_by(models.Diagnosis.diagnosed_at.desc()).all()

    return {
        "success": True,
        "data": [
            {
                "diagnosis_id": d.diagnosis_id,
                "crop_name": d.crop_name,
                "disease_name": d.disease_name,
                "severity_level": d.severity_level,
                "action_status": d.action_status,
                "diagnosed_at": d.diagnosed_at,
                "zone_id": d.zone_id,
            }
            for d in diagnoses
        ]
    }

#task--------------지금 농장 관리자의 진단 이력 조회가 농장/구역 비교로 농장을 조회함 -> 이건 농장 주인-알바생을 염두로 한 코드임. 추후에 어떻게 할지 결정
#만약에 기존으로 유지하려면 농장 주인이 알바생을 자신의 농장테이블로 초대를 하는 코드를 추가해야함
@app.get("/diagnoses/{diagnosis_id}",response_model=schemas.DiagnosisDetailResponse) #진단결과 상세 조회
def get_diagnosis_detail(
    diagnosis_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    diagnosis = db.query(models.Diagnosis).filter(
        models.Diagnosis.diagnosis_id == diagnosis_id
    ).first()

    if diagnosis is None:
        raise HTTPException(status_code=404, detail="진단 결과를 찾을 수 없습니다.")

    if current_user.user_role == "GENERAL_USER":
        if diagnosis.user_id != current_user.user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다.")
    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)
        if diagnosis.zone_id not in manager_zone_ids:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다.")

    detections = db.query(models.DetectionResult).filter(
        models.DetectionResult.diagnosis_id == diagnosis_id
    ).all()

    return {
        "success": True,
        "data": {
            "diagnosis_id": diagnosis.diagnosis_id,
            "crop_name": diagnosis.crop_name,
            "part_name": diagnosis.part_name,
            "disease_name": diagnosis.disease_name,
            "class_name": diagnosis.class_name,
            "has_disease": diagnosis.has_disease,
            "confidence_score": diagnosis.confidence_score,
            "severity_level": diagnosis.severity_level,
            "recommendation_text": diagnosis.recommendation_text,
            "low_confidence_flag": diagnosis.low_confidence_flag,
            "retake_recommended_flag": diagnosis.retake_recommended_flag,
            "gradcam_path": diagnosis.gradcam_path,
            "action_status": diagnosis.action_status,
            "diagnosed_at": diagnosis.diagnosed_at,
            "detections": [
                {
                    "bbox_xmin": d.bbox_xmin,
                    "bbox_ymin": d.bbox_ymin,
                    "bbox_xmax": d.bbox_xmax,
                    "bbox_ymax": d.bbox_ymax,
                }
                for d in detections
            ]
        }
    }

@app.get("/dashboard", response_model=schemas.DashboardResponse) #대시보드 조회: 상단 KPI용(평균 심각도, 조치 완료율, 최근 진단 병해 수), 최근 7일만 조회
def get_dashboard(
    farm_id: int | None=None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=29)

    query = db.query(models.Diagnosis)

    if current_user.user_role == "GENERAL_USER":
        query = query.filter(models.Diagnosis.user_id == current_user.user_id)
    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)
        if not manager_zone_ids:
            return {
                "success": True,
                "data": {
                    "kpi": {
                        "average_severity": 0,
                        "completion_rate": 0,
                        "disease_count": 0
                    },
                    "total_records": 0,
                    "has_enough_data_for_graph": False
                }
            }
        query = query.filter(models.Diagnosis.zone_id.in_(manager_zone_ids))

        if farm_id is not None:
            query = query.filter(models.Diagnosis.farm_id == farm_id)
    
    query = query.filter(
        models.Diagnosis.diagnosed_at >= start_date,
        models.Diagnosis.diagnosed_at <= end_date
    )
    
    diagnoses = query.all()

    total_count = len(diagnoses)
    disease_cases = [d for d in diagnoses if d.has_disease]

    average_severity = 0
    if total_count > 0: #평균 심각도 계산
        average_severity = sum(severity_to_score(d.severity_level) for d in diagnoses) / total_count

#task------조치 완료율: 조치 완료한 진단 기록 수/조치 알림 설정한 진단 기록 수로 수정
     # 조치 완료율 계산: 완료된 조치 알림 수 / 전체 조치 알림 수
    diagnosis_ids = [d.diagnosis_id for d in diagnoses] #diagnoses 리스트에서 id만 뽑아서 리스트 만듦

    total_alert_count = 0
    completed_alert_count = 0

    if diagnosis_ids:
        alert_query = db.query(models.TreatmentAlert).filter( #treatmentalert테이블에 있는 진단id들의 알림만 가져옴
            models.TreatmentAlert.diagnosis_id.in_(diagnosis_ids)
        )

        total_alert_count = alert_query.count() #최근 7일동안 알림설정을 한 진단 내역만 카운트

        completed_alert_count = alert_query.filter( #조치 상태가 completed인 진단만 카운트
            models.TreatmentAlert.alert_status == "COMPLETED"
        ).count()

    completion_rate = 0
    if total_alert_count > 0:
        completion_rate = completed_alert_count / total_alert_count
    
    disease_count = len(disease_cases) #

    return {
        "success": True,
        "data": {
            "kpi": {
                "average_severity": average_severity,
                "completion_rate": completion_rate,
                "disease_count": disease_count
            },
            "total_records": total_count,
            "has_enough_data_for_graph": total_count >= 5
        }
    }

@app.get("/dashboard/group-kpi", response_model=schemas.GroupKPIResponse)
def get_dashboard_group_kpi(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    end_date = datetime.now()
    start_date = end_date - timedelta(days=29)

    query = db.query(models.Diagnosis).filter(
        models.Diagnosis.diagnosed_at >= start_date,
        models.Diagnosis.diagnosed_at <= end_date
    )

    if current_user.user_role == "GENERAL_USER":
        query = query.filter(
            models.Diagnosis.user_id == current_user.user_id
        )

        diagnoses = query.all()

        group_map = {}

        for d in diagnoses:
            key = d.crop_name

            if key not in group_map:
                group_map[key] = {
                    "crop_name": d.crop_name,
                    "diagnoses": []
                }

            group_map[key]["diagnoses"].append(d)

        data = []

        for key, group in group_map.items():
            group_diagnoses = group["diagnoses"]

            total_records = len(group_diagnoses)

            severity_scores = [
                severity_to_score(d.severity_level)
                for d in group_diagnoses
            ]

            average_severity = (
                round(sum(severity_scores) / len(severity_scores), 2)
                if severity_scores else 0
            )

            disease_diagnoses = [
                d for d in group_diagnoses
                if d.has_disease == True
            ]

            disease_count = len(disease_diagnoses)

            completed_count = len([
                d for d in disease_diagnoses
                if d.action_status == "COMPLETED"
            ])

            completion_rate = (
                round(completed_count / disease_count, 4)
                if disease_count > 0 else 0
            )

            data.append({
                "crop_name": group["crop_name"],
                "average_severity": average_severity,
                "completion_rate": completion_rate,
                "disease_count": disease_count,
                "total_records": total_records,
            })

        return {
            "success": True,
            "data": data
        }

    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)

        if not manager_zone_ids:
            return {
                "success": True,
                "data": []
            }

        query = query.filter(
            models.Diagnosis.zone_id.in_(manager_zone_ids)
        )

        diagnoses = query.all()
        zone_rows = db.query(models.Zone).filter(
            models.Zone.zone_id.in_(manager_zone_ids)
        ).all()

        zone_name_map = {
            zone.zone_id: zone.zone_name_or_code
            for zone in zone_rows
        }
        group_map = {}

        for d in diagnoses:
            if d.farm_id is None or d.zone_id is None:
                continue

            key = (d.farm_id, d.zone_id)

            if key not in group_map:
                group_map[key] = {
                    "farm_id": d.farm_id,
                    "zone_id": d.zone_id,
                    "crop_name": d.crop_name,
                    "diagnoses": []
                }

            group_map[key]["diagnoses"].append(d)

        data = []

        for key, group in group_map.items():
            group_diagnoses = group["diagnoses"]

            total_records = len(group_diagnoses)

            severity_scores = [
                severity_to_score(d.severity_level)
                for d in group_diagnoses
            ]

            average_severity = (
                round(sum(severity_scores) / len(severity_scores), 2)
                if severity_scores else 0
            )

            disease_diagnoses = [
                d for d in group_diagnoses
                if d.has_disease == True
            ]

            disease_count = len(disease_diagnoses)

            completed_count = len([
                d for d in disease_diagnoses
                if d.action_status == "COMPLETED"
            ])

            completion_rate = (
                round(completed_count / disease_count, 4)
                if disease_count > 0 else 0
            )

            data.append({
                "farm_id": group["farm_id"],
                "zone_id": group["zone_id"],
                "zone_name": zone_name_map.get(group["zone_id"], f"구역 {group['zone_id']}"),
                "crop_name": group["crop_name"],
                "average_severity": average_severity,
                "completion_rate": completion_rate,
                "disease_count": disease_count,
                "total_records": total_records,
            })

        return {
            "success": True,
            "data": data
        }

    return {
        "success": False,
        "message": "허용되지 않은 사용자 역할입니다."
    }

@app.get("/dashboard/group-charts",response_model=schemas.GroupChartsResponse)
def get_dashboard_group_charts(
    crop_name: str | None = None,
    farm_id: int | None = None,
    zone_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    end_date = datetime.now()
    start_date = end_date - timedelta(days=29)

    query = db.query(models.Diagnosis)

    if current_user.user_role == "GENERAL_USER":
        query = query.filter(models.Diagnosis.user_id == current_user.user_id)

        if crop_name:
            query = query.filter(models.Diagnosis.crop_name == crop_name)

    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)

        if not manager_zone_ids:
            return {
                "success": True,
                "data": {
                    "daily_severity_by_disease": [],
                    "disease_frequency": [],
                    "disease_distribution": [],
                    "total_records": 0,
                    "has_enough_data_for_graph": False
                }
            }

        query = query.filter(models.Diagnosis.zone_id.in_(manager_zone_ids))

        if farm_id is not None:
            query = query.filter(models.Diagnosis.farm_id == farm_id)

        if zone_id is not None:
            query = query.filter(models.Diagnosis.zone_id == zone_id)

    query = query.filter(
        models.Diagnosis.diagnosed_at >= start_date,
        models.Diagnosis.diagnosed_at <= end_date
    )

    diagnoses = query.all()

    daily_severity_by_disease_map = {}
    disease_frequency_map = {}

    for d in diagnoses:
        if not d.has_disease:
            continue

        date_key = d.diagnosed_at.strftime("%Y-%m-%d")
        disease_name = d.disease_name

        if disease_name not in daily_severity_by_disease_map:
            daily_severity_by_disease_map[disease_name] = {}

        if date_key not in daily_severity_by_disease_map[disease_name]:
            daily_severity_by_disease_map[disease_name][date_key] = []

        daily_severity_by_disease_map[disease_name][date_key].append(
            severity_to_score(d.severity_level)
        )

        if disease_name not in disease_frequency_map:
            disease_frequency_map[disease_name] = 0

        disease_frequency_map[disease_name] += 1

    daily_severity_by_disease = []

    for disease_name, date_map in daily_severity_by_disease_map.items():
        date_data = []

        for date_key, scores in date_map.items():
            date_data.append({
                "date": date_key,
                "average_severity": round(sum(scores) / len(scores), 2)
            })

        date_data.sort(key=lambda x: x["date"])

        daily_severity_by_disease.append({
            "disease_name": disease_name,
            "data": date_data
        })

    disease_frequency = [
        {
            "disease_name": disease_name,
            "count": count
        }
        for disease_name, count in disease_frequency_map.items()
    ]

    disease_frequency.sort(key=lambda x: x["count"], reverse=True)

    total_disease_count = sum(disease_frequency_map.values())

    disease_distribution = []

    for disease_name, count in disease_frequency_map.items():
        disease_distribution.append({
            "disease_name": disease_name,
            "count": count,
            "ratio": round(count / total_disease_count, 4)
            if total_disease_count > 0 else 0
        })

    disease_distribution.sort(key=lambda x: x["count"], reverse=True)

    return {
        "success": True,
        "data": {
            "daily_severity_by_disease": daily_severity_by_disease,
            "disease_frequency": disease_frequency,
            "disease_distribution": disease_distribution,
            "total_records": len(diagnoses),
            "has_enough_data_for_graph": len(diagnoses) >= 5
        }
    }
@app.get("/calendar/events",response_model=schemas.CalendarEventResponse) # 기간 조회
def get_calendar_events(
    start_date: datetime,
    end_date: datetime,
    farm_id: int | None = None,
    zone_id: int | None = None,
    crop_name: str | None = None,
    severity_level: str | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    query = db.query(models.CalendarEvent).filter(
        models.CalendarEvent.user_id == current_user.user_id,
        models.CalendarEvent.event_date >= start_date,
        models.CalendarEvent.event_date <= end_date
    )

    if farm_id is not None:
        query = query.filter(models.CalendarEvent.farm_id == farm_id)

    if zone_id is not None:
        query = query.filter(models.CalendarEvent.zone_id == zone_id)

    if crop_name is not None and crop_name != "전체":
        query = query.filter(models.CalendarEvent.crop_name == crop_name)

    if severity_level is not None and severity_level != "":
        query = query.filter(
            models.CalendarEvent.severity_level == severity_level
        )

    events = query.order_by(models.CalendarEvent.event_date.asc()).all()

    return {
        "success": True,
        "data": [
            {
                "event_id": e.event_id,
                "event_type": e.event_type,
                "diagnosis_id": e.diagnosis_id,
                "care_type": e.care_type,
                "title": e.title,
                "memo": e.memo,
                "crop_name": e.crop_name,
                "disease_name": e.disease_name,
                "severity_level": e.severity_level,
                "farm_id": e.farm_id,
                "zone_id": e.zone_id,
                "event_date": e.event_date
            }
            for e in events
        ]
    }

@app.get("/calendar/events/by-date", response_model=schemas.CalendarEventResponse) #특정 날짜 조회
def get_events_by_date(
    date: datetime,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    start = date.replace(hour=0, minute=0, second=0) #범위 하루 전체
    end = date.replace(hour=23, minute=59, second=59)

    events = db.query(models.CalendarEvent).filter( #해당 날짜만
        models.CalendarEvent.user_id == current_user.user_id,
        models.CalendarEvent.event_date >= start,
        models.CalendarEvent.event_date <= end
    ).all()

    return {
        "success": True,
        "data": [
            {
                "event_id": e.event_id,
                "event_type": e.event_type,
                "diagnosis_id": e.diagnosis_id,
                "title": e.title,
                "crop_name": e.crop_name,
                "disease_name": e.disease_name,
                "severity_level": e.severity_level,
                "zone_id": e.zone_id,
                "event_date": e.event_date
            }
            for e in events
        ]
    }

@app.get("/alerts/treatment")
def get_treatment_alerts(
    crop_name: str | None = None,
    severity_level: str | None = None,
    farm_id: int | None = None,
    zone_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    query = db.query(models.TreatmentAlert, models.Diagnosis).join(
        models.Diagnosis,
        models.TreatmentAlert.diagnosis_id == models.Diagnosis.diagnosis_id
    )

    if current_user.user_role == "GENERAL_USER":
        query = query.filter(
            models.TreatmentAlert.user_id == current_user.user_id,
            models.Diagnosis.user_id == current_user.user_id
        )

        if crop_name:
            query = query.filter(models.Diagnosis.crop_name == crop_name)

    elif current_user.user_role == "FARM_MANAGER":
        manager_zone_ids = get_manager_zone_ids(db, current_user.user_id)

        if not manager_zone_ids:
            return {
                "success": True,
                "data": {
                    "summary": {
                        "completed": 0,
                        "hold": 0,
                        "remind_later": 0
                    },
                    "alerts": []
                }
            }

        query = query.filter(
            models.Diagnosis.zone_id.in_(manager_zone_ids)
        )

        if farm_id is not None:
            query = query.filter(models.Diagnosis.farm_id == farm_id)

        if zone_id is not None:
            query = query.filter(models.Diagnosis.zone_id == zone_id)

    if severity_level:
        query = query.filter(models.Diagnosis.severity_level == severity_level)

    rows = query.order_by(models.TreatmentAlert.created_at.desc()).all()

    data = []
    for alert, diagnosis in rows:
        data.append({
            "alert_id": alert.alert_id,
            "alert_status": alert.alert_status,
            "alert_response": alert.alert_response,
            "scheduled_at": alert.scheduled_at,
            "diagnosis_id": diagnosis.diagnosis_id,
            "farm_id": diagnosis.farm_id,
            "zone_id": diagnosis.zone_id,
            "crop_name": diagnosis.crop_name,
            "disease_name": diagnosis.disease_name,
            "severity_level": diagnosis.severity_level,
            "confidence_score": diagnosis.confidence_score,
            "action_status": diagnosis.action_status,
            "diagnosed_at": diagnosis.diagnosed_at,
        })

    completed_count = sum(1 for item in data if item["alert_response"] == "COMPLETED")
    hold_count = sum(1 for item in data if item["alert_response"] == "HOLD")
    remind_later_count = sum(1 for item in data if item["alert_response"] == "REMIND_LATER")

    return {
        "success": True,
        "data": {
            "summary": {
                "completed": completed_count,
                "hold": hold_count,
                "remind_later": remind_later_count
            },
            "alerts": data
        }
    }


@app.post("/alerts/{alert_id}/respond")
def respond_treatment_alert(
    alert_id: int,
    request: schemas.RespondTreatmentAlertRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    allowed = ["COMPLETED", "HOLD", "REMIND_LATER"]
    if request.alert_response not in allowed:
        raise HTTPException(status_code=400, detail="허용되지 않은 응답입니다.")

    alert = db.query(models.TreatmentAlert).filter(
        models.TreatmentAlert.alert_id == alert_id,
        models.TreatmentAlert.user_id == current_user.user_id
    ).first()

    if alert is None:
        raise HTTPException(status_code=404, detail="알림을 찾을 수 없습니다.")

    diagnosis = db.query(models.Diagnosis).filter(
        models.Diagnosis.diagnosis_id == alert.diagnosis_id
    ).first()

    if diagnosis is None:
        raise HTTPException(status_code=404, detail="연결된 진단 결과를 찾을 수 없습니다.")

    alert.alert_status = "RESPONDED"
    alert.alert_response = request.alert_response
    alert.responded_at = datetime.now()

    if request.alert_response == "COMPLETED":
        diagnosis.action_status = "COMPLETED"

        treatment_event = models.CalendarEvent(
            user_id=current_user.user_id,
            zone_id=diagnosis.zone_id,
            diagnosis_id=diagnosis.diagnosis_id,
            event_type="TREATMENT",
            title=f"{diagnosis.crop_name} - 방제 완료",
            crop_name=diagnosis.crop_name,
            disease_name=diagnosis.disease_name,
            severity_level=diagnosis.severity_level,
            event_date=datetime.now()
        )
        db.add(treatment_event)
        alert.alert_status = "CLOSED"

    elif request.alert_response == "HOLD":
        diagnosis.action_status = "PENDING"
        alert.alert_status = "CLOSED"

    elif request.alert_response == "REMIND_LATER":
        diagnosis.action_status = "PENDING"

        new_alert = models.TreatmentAlert(
            diagnosis_id=diagnosis.diagnosis_id,
            user_id=current_user.user_id,
            alert_status="SCHEDULED",
            scheduled_at=datetime.now() + timedelta(days=1)
        )
        db.add(new_alert)
        alert.alert_status = "CLOSED"

    db.commit()

    return {
        "success": True,
        "message": "알림 응답이 처리되었습니다."
    }

@app.patch("/farms/{farm_id}/share-consent", response_model=schemas.FarmShareConsentResponse)
def update_farm_share_consent(
    farm_id: int,
    request: schemas.FarmShareConsentRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    allowed_levels = ["FULL_PUBLIC", "PARTIAL_PUBLIC", "PRIVATE"]

    if request.share_consent_level not in allowed_levels:
        raise HTTPException(
            status_code=400,
            detail="share_consent_level은 FULL_PUBLIC, PARTIAL_PUBLIC, PRIVATE만 가능합니다."
        )

    farm = db.query(models.Farm).filter(
        models.Farm.farm_id == farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if farm is None:
        raise HTTPException(status_code=404, detail="농장을 찾을 수 없습니다.")

    zones = db.query(models.Zone).filter(
        models.Zone.farm_id == farm_id,
        models.Zone.is_deleted == False
    ).all()

    farm.share_consent_level = request.share_consent_level

    # 1. 전체 공개: 해당 농장의 모든 구역 공개
    if request.share_consent_level == "FULL_PUBLIC":
        for zone in zones:
            zone.share_enabled_flag = True

    # 2. 비공개: 모든 구역 비공개
    elif request.share_consent_level == "PRIVATE":
        for zone in zones:
            zone.share_enabled_flag = False

    # 3. 일부 공개: 선택한 구역만 공개
    elif request.share_consent_level == "PARTIAL_PUBLIC":
        if not request.shared_zone_ids:
            raise HTTPException(
                status_code=400,
                detail="PARTIAL_PUBLIC 선택 시 공개할 구역을 1개 이상 선택해야 합니다."
            )

        valid_zone_ids = [zone.zone_id for zone in zones]

        for zone_id in request.shared_zone_ids:
            if zone_id not in valid_zone_ids:
                raise HTTPException(
                    status_code=400,
                    detail="본인 농장에 속하지 않거나 삭제된 구역은 공개할 수 없습니다."
                )

        for zone in zones:
            zone.share_enabled_flag = zone.zone_id in request.shared_zone_ids

    db.commit()
    db.refresh(farm)

    return {
        "success": True,
        "message": "공유 동의 설정이 저장되었습니다.",
        "data": {
            "farm_id": farm.farm_id,
            "share_consent_level": farm.share_consent_level,
            "shared_zones": [
                {
                    "zone_id": zone.zone_id,
                    "zone_name_or_code": zone.zone_name_or_code,
                    "share_enabled_flag": zone.share_enabled_flag
                }
                for zone in zones
            ]
        }
    }

@app.get("/farms/nearby", response_model=schemas.NearbyFarmsResponse)
def get_nearby_farms(
    base_farm_id: int,
    radius_km: float = 30,
    sort_by: str = "distance",
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    base_farm = db.query(models.Farm).filter(
        models.Farm.farm_id == base_farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if base_farm is None:
        raise HTTPException(status_code=404, detail="기준 농장을 찾을 수 없습니다.")

    if base_farm.latitude is None or base_farm.longitude is None:
        raise HTTPException(
            status_code=400,
            detail="기준 농장의 위도/경도 정보가 없습니다. 농장 주소를 먼저 등록하거나 수정해주세요."
        )


    candidate_farms = db.query(models.Farm).filter(
        models.Farm.farm_id != base_farm.farm_id,
        models.Farm.share_consent_level != "PRIVATE",
        models.Farm.latitude.isnot(None),
        models.Farm.longitude.isnot(None)
    ).all()

    result = []

    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)

    for farm in candidate_farms:
        distance = calculate_distance_km(
            base_farm.latitude,
            base_farm.longitude,
            farm.latitude,
            farm.longitude
        )

        if distance > radius_km:
            continue

        zone_query = db.query(models.Zone).filter(
            models.Zone.farm_id == farm.farm_id,
            models.Zone.is_deleted == False
        )

        if farm.share_consent_level == "PARTIAL_PUBLIC":
            zone_query = zone_query.filter(
                models.Zone.share_enabled_flag == True
            )

        shared_zones = zone_query.all()
        shared_zone_ids = [zone.zone_id for zone in shared_zones]

        if farm.share_consent_level == "PARTIAL_PUBLIC" and not shared_zone_ids:
            continue

        diagnosis_query = db.query(models.Diagnosis).filter(
            models.Diagnosis.farm_id == farm.farm_id,
            models.Diagnosis.diagnosed_at >= start_date,
            models.Diagnosis.diagnosed_at <= end_date
        )

        if farm.share_consent_level == "PARTIAL_PUBLIC":
            diagnosis_query = diagnosis_query.filter(
                models.Diagnosis.zone_id.in_(shared_zone_ids)
            )

        diagnoses = diagnosis_query.all()

        crop_names = sorted(list(set([
            d.crop_name for d in diagnoses
            if d.crop_name
        ])))

        disease_names = sorted(list(set([
            d.disease_name for d in diagnoses
            if d.has_disease and d.disease_name
        ])))

        total_count = len(diagnoses)
        disease_count = len([d for d in diagnoses if d.has_disease])

        if total_count == 0:
            recent_status_summary = "최근 7일 진단 데이터 없음"
        else:
            recent_status_summary = f"최근 7일 진단 {total_count}건, 병해 {disease_count}건"

        zone_risks = []

        for zone in shared_zones:
            zone_diagnoses = [
                d for d in diagnoses
                if d.zone_id == zone.zone_id
            ]

            zone_total = len(zone_diagnoses)
            zone_disease_count = len([
                d for d in zone_diagnoses
                if d.has_disease
            ])

            if zone_total == 0:
                disease_ratio = 0
                risk_level = "DATA_INSUFFICIENT"
                risk_label = "데이터 부족"
                data_status = "NO_DATA"
            else:
                disease_ratio = zone_disease_count / zone_total

                if zone_total <= 2:
                    data_status = "REFERENCE_ONLY"
                else:
                    data_status = "ENOUGH_DATA"

                if disease_ratio == 0:
                    risk_level = "SAFE"
                    risk_label = "안전"
                elif disease_ratio < 0.3:
                    risk_level = "NORMAL"
                    risk_label = "보통"
                else:
                    risk_level = "DANGER"
                    risk_label = "위험"

            zone_risks.append({
                "zone_id": zone.zone_id,
                "zone_name_or_code": zone.zone_name_or_code,
                "crop_name": zone.crop_name,
                "total_diagnosis_count": zone_total,
                "disease_count": zone_disease_count,
                "disease_ratio": round(disease_ratio, 4),
                "risk_level": risk_level,
                "risk_label": risk_label,
                "data_status": data_status
            })

        result.append({
            "farm_id": farm.farm_id,
            "farm_name": farm.farm_name,

            # 지도 마커 표시용
            "latitude": farm.latitude,
            "longitude": farm.longitude,

            "distance_km": round(distance, 2),
            "public_region_label": farm.public_region_label,
            "share_consent_level": farm.share_consent_level,
            "crop_names": crop_names,
            "disease_names": disease_names,
            "recent_status_summary": recent_status_summary,
            "zone_risks": zone_risks
        })

    if sort_by == "name":
        result.sort(key=lambda x: x["farm_name"])
    else:
        result.sort(key=lambda x: x["distance_km"])

    return {
        "success": True,
        "data": {
            "base_farm": {
                "farm_id": base_farm.farm_id,
                "farm_name": base_farm.farm_name,

                # 내 농장 지도 중심 표시용
                "latitude": base_farm.latitude,
                "longitude": base_farm.longitude,

                "public_region_label": base_farm.public_region_label,
                "share_consent_level": base_farm.share_consent_level
            },
            "radius_km": radius_km,
            "count": len(result),
            "farms": result
        }
    }

@app.get("/farms/nearby/{farm_id}/risk-detail", response_model=schemas.NearbyFarmRiskDetailResponse) #인근 농장 상세 조회
def get_nearby_farm_risk_detail( 
    farm_id: int,
    base_farm_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_farm_manager)
):
    # 1. 기준 농장 확인: 내 농장이어야 함
    base_farm = db.query(models.Farm).filter(
        models.Farm.farm_id == base_farm_id,
        models.Farm.manager_user_id == current_user.user_id
    ).first()

    if base_farm is None:
        raise HTTPException(status_code=404, detail="기준 농장을 찾을 수 없습니다.")

    if base_farm.latitude is None or base_farm.longitude is None:
        raise HTTPException(
            status_code=400,
            detail="기준 농장의 위치 정보가 없습니다."
        )

    # 2. 조회 대상 인근 농장 확인
    target_farm = db.query(models.Farm).filter(
        models.Farm.farm_id == farm_id,
        models.Farm.share_consent_level != "PRIVATE",
        models.Farm.latitude.isnot(None),
        models.Farm.longitude.isnot(None)
    ).first()

    if target_farm is None:
        raise HTTPException(
            status_code=404,
            detail="조회 가능한 공개 농장을 찾을 수 없습니다."
        )

    # 3. 반경 30km 안인지 확인
    distance_km = calculate_distance_km(
        base_farm.latitude,
        base_farm.longitude,
        target_farm.latitude,
        target_farm.longitude
    )

    if distance_km > 30:
        raise HTTPException(
            status_code=403,
            detail="반경 30km 밖의 농장은 조회할 수 없습니다."
        )

    # 4. 공개 구역 조회
    zone_query = db.query(models.Zone).filter(
        models.Zone.farm_id == target_farm.farm_id,
        models.Zone.is_deleted == False
    )

    if target_farm.share_consent_level == "PARTIAL_PUBLIC":
        zone_query = zone_query.filter(
            models.Zone.share_enabled_flag == True
        )

    zones = zone_query.all()

    if target_farm.share_consent_level == "PARTIAL_PUBLIC" and not zones:
        return {
            "success": True,
            "data": {
                "farm": {
                    "farm_id": target_farm.farm_id,
                    "farm_name": target_farm.farm_name,
                    "distance_km": round(distance_km, 2),
                    "public_region_label": target_farm.public_region_label,
                    "share_consent_level": target_farm.share_consent_level,
                },
                "zones": []
            }
        }

    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)

    zone_details = []

    for zone in zones:
        diagnoses = db.query(models.Diagnosis).filter(
            models.Diagnosis.zone_id == zone.zone_id,
            models.Diagnosis.diagnosed_at >= start_date,
            models.Diagnosis.diagnosed_at <= end_date
        ).all()

        total_count = len(diagnoses)

        moderate_count = len([
            d for d in diagnoses
            if d.severity_level == "MODERATE"
        ])

        severe_count = len([
            d for d in diagnoses
            if d.severity_level == "SEVERE"
        ])

        moderate_or_severe = [
            d for d in diagnoses
            if d.severity_level in ["MODERATE", "SEVERE"]
        ]

        if total_count == 0:
            prevention_score = 0
            alert_level = "DATA_INSUFFICIENT"
            alert_label = "데이터 부족"
            data_status = "NO_DATA"
        else:
            prevention_score = (
                (0.6 * moderate_count + 1.0 * severe_count) / total_count
            )

            if total_count <= 2:
                data_status = "REFERENCE_ONLY"
            else:
                data_status = "ENOUGH_DATA"

            if prevention_score == 0:
                alert_level = "SAFE"
                alert_label = "안전"
            elif prevention_score < 0.15:
                alert_level = "WATCH"
                alert_label = "관찰"
            elif prevention_score < 0.35:
                alert_level = "CAUTION"
                alert_label = "주의"
            else:
                alert_level = "WARNING"
                alert_label = "경고"

        disease_counter = Counter([
            d.disease_name for d in moderate_or_severe
            if d.disease_name
        ])

        top_disease = None
        if disease_counter:
            disease_name, count = disease_counter.most_common(1)[0]
            top_disease = {
                "disease_name": disease_name,
                "count": count
            }

        last_risky_diagnosis = None
        if moderate_or_severe:
            last_risky_diagnosis = max(
                moderate_or_severe,
                key=lambda d: d.diagnosed_at
            )

        last_risky_date = (
            last_risky_diagnosis.diagnosed_at.date().isoformat()
            if last_risky_diagnosis else None
        )

        other_diseases = []
        for disease_name, count in disease_counter.most_common():
            if top_disease and disease_name == top_disease["disease_name"]:
                continue

            disease_diagnoses = [
                d for d in moderate_or_severe
                if d.disease_name == disease_name
            ]

            latest = max(
                disease_diagnoses,
                key=lambda d: d.diagnosed_at
            )

            other_diseases.append({
                "disease_name": disease_name,
                "count": count,
                "last_occurred_date": latest.diagnosed_at.date().isoformat()
            })

        # 최근 7일 일별 MODERATE + SEVERE 건수
        daily_risky_counts = []
        for i in range(7):
            day = (start_date + timedelta(days=i)).date()

            count = len([
                d for d in moderate_or_severe
                if d.diagnosed_at.date() == day
            ])

            daily_risky_counts.append({
                "date": day.isoformat(),
                "count": count
            })

        zone_details.append({
            "zone_id": zone.zone_id,
            "zone_name_or_code": zone.zone_name_or_code,
            "crop_name": zone.crop_name,

            "prevention_alert": {
                "score": round(prevention_score, 4),
                "alert_level": alert_level,
                "alert_label": alert_label,
                "data_status": data_status,
            },

            "recent_7days": {
                "total_diagnosis_count": total_count,
                "moderate_count": moderate_count,
                "severe_count": severe_count,
                "moderate_or_severe_count": moderate_count + severe_count,
            },

            "top_disease": top_disease,
            "last_moderate_or_severe_date": last_risky_date,
            "other_diseases": other_diseases,
            "daily_risky_counts": daily_risky_counts,
        })

    return {
        "success": True,
        "data": {
            "farm": {
                "farm_id": target_farm.farm_id,
                "farm_name": target_farm.farm_name,
                "distance_km": round(distance_km, 2),
                "public_region_label": target_farm.public_region_label,
                "share_consent_level": target_farm.share_consent_level,
            },
            "zones": zone_details
        }
    }