import random
import requests

AI_BASE_URL = "http://127.0.0.1:9000"


def random_bbox():
    x1 = random.randint(20, 120)
    y1 = random.randint(20, 120)
    x2 = x1 + random.randint(80, 180)
    y2 = y1 + random.randint(80, 180)

    return {
        "bbox_xmin": x1,
        "bbox_ymin": y1,
        "bbox_xmax": x2,
        "bbox_ymax": y2,
    }


def make_result(crop_name, part_name, disease_name, disease_en=None):
    is_healthy = disease_name == "정상"

    if is_healthy:
        severity_level = "HEALTHY"
        confidence_score = round(random.uniform(0.85, 0.99), 2)
        has_disease = False
        detections = []
        recommendation_text = "현재 상태가 양호합니다. 주기적인 관찰을 유지하세요."
        class_name = f"{crop_name}_{part_name}_정상"
        gradcam_path = None
    else:
        severity_level = random.choice(["MILD", "MODERATE", "SEVERE"])
        confidence_score = round(random.uniform(0.65, 0.96), 2)
        has_disease = True
        detections = [random_bbox()]
        recommendation_text = f"{disease_name} 의심 증상이 있습니다. 감염 부위를 제거하고 통풍 관리 및 적절한 방제를 권장합니다."
        class_name = f"{crop_name}_{part_name}_{disease_name}"
        gradcam_path = f"uploads/gradcams/{crop_name}_{part_name}_{disease_name}.jpg"

    return {
        "crop_name": crop_name,
        "part_name": part_name,
        "disease_name": disease_name,
        "class_name": class_name,
        "has_disease": has_disease,
        "confidence_score": confidence_score,
        "severity_level": severity_level,
        "recommendation_text": recommendation_text,
        "gradcam_path": gradcam_path,
        "detections": detections,
    }


def request_ai_diagnosis(image_path: str):
    candidates = [
        # # 사과 - 과실
        # ("사과", "과실", "점무늬병", "blotch"),
        # ("사과", "과실", "정상", "healthy"),
        # ("사과", "과실", "부패", "rot"),
        # ("사과", "과실", "검은별무늬병", "scab"),

        # # 사과 - 잎
        # ("사과", "잎", "검은썩음병", "black rot"),
        # ("사과", "잎", "사과녹병", "cedar apple rust"),
        # ("사과", "잎", "정상", "healthy"),
        # ("사과", "잎", "검은별무늬병", "scab"),

        # # 옥수수 - 잎
        # ("옥수수", "잎", "회색잎반점병", "gray leaf spot"),
        # ("옥수수", "잎", "정상", "healthy"),
        # ("옥수수", "잎", "북부잎마름병", "northern leaf blight"),
        # ("옥수수", "잎", "녹병", "rust"),

        # # 포도 - 과실
        # ("포도", "과실", "탄저병", "anthracnose"),
        # ("포도", "과실", "정상", "healthy"),

        # # 포도 - 잎
        # ("포도", "잎", "탄저병", "anthracnose"),
        # ("포도", "잎", "검은썩음병", "black rot"),
        # ("포도", "잎", "노균병", "downy mildew"),
        # ("포도", "잎", "에스카병", "esca"),
        # ("포도", "잎", "정상", "healthy"),
        # ("포도", "잎", "잎마름병", "leaf blight"),

        # # 고추 - 과실
        # ("고추", "과실", "탄저병", "anthracnose"),
        # ("고추", "과실", "정상", "healthy"),

        # # 고추 - 잎
        # ("고추", "잎", "세균성점무늬병", "bacterial spot"),
        # ("고추", "잎", "정상", "healthy"),
        # ("고추", "잎", "흰가루병", "powdery mildew"),

        # 딸기 - 과실
        # ("딸기", "과실", "탄저병", "anthracnose"),
        # ("딸기", "과실", "회색곰팡이병", "gray mold"),
        # ("딸기", "과실", "정상", "healthy"),
        # ("딸기", "과실", "흰가루병", "powdery mildew"),

        # 딸기 - 잎
        ("딸기", "잎", "각진무늬병", "angular leaf spot"),
        ("딸기", "잎", "회색곰팡이병", "gray mold"),
        ("딸기", "잎", "정상", "healthy"),
        ("딸기", "잎", "잎마름병", "leaf scorch"),
        ("딸기", "잎", "잎반점병", "leaf spot"),
        ("딸기", "잎", "흰가루병", "powdery mildew"),

        # 토마토 - 잎
        ("토마토", "잎", "세균성점무늬병", "bacterial spot"),
        ("토마토", "잎", "겹무늬병", "early blight"),
        ("토마토", "잎", "회색곰팡이병", "gray mold"),
        ("토마토", "잎", "정상", "healthy"),
        ("토마토", "잎", "역병", "late blight"),
        ("토마토", "잎", "잎곰팡이병", "leaf mold"),
        ("토마토", "잎", "흰가루병", "powdery mildew"),
        ("토마토", "잎", "점무늬병", "septoria leaf spot"),
        ("토마토", "잎", "토마토모자이크바이러스", "tomato mosaic virus"),
    ]

    crop_name, part_name, disease_name, disease_en = random.choice(candidates)

    return make_result(
        crop_name=crop_name,
        part_name=part_name,
        disease_name=disease_name,
        disease_en=disease_en,
    )


# 실제 AI 서버 연결할 때는 위 request_ai_diagnosis를 주석 처리하고 아래를 사용
# def request_ai_diagnosis(image_path: str):
#     with open(image_path, "rb") as f:
#         files = {"file": f}
#         response = requests.post(f"{AI_BASE_URL}/predict", files=files, timeout=30)
#         response.raise_for_status()
#         return response.json()