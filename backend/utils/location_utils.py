import os
import math
import requests
from fastapi import HTTPException
from dotenv import load_dotenv

load_dotenv()

KAKAO_REST_API_KEY = os.getenv("KAKAO_REST_API_KEY")


def geocode_address(address: str):
    if not KAKAO_REST_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="카카오 REST API 키가 설정되지 않았습니다."
        )

    url = "https://dapi.kakao.com/v2/local/search/address.json"
    headers = {
        "Authorization": f"KakaoAK {KAKAO_REST_API_KEY.strip()}"
    }
    params = {
        "query": address
    }

    try:
        response = requests.get(
            url,
            headers=headers,
            params=params,
            timeout=5
        )
    except requests.RequestException as e:
        raise HTTPException(
            status_code=500,
            detail=f"카카오 주소 API 요청 실패: {str(e)}"
        )

    print("KAKAO STATUS:", response.status_code)
    print("KAKAO BODY:", response.text)

    if response.status_code != 200:
        raise HTTPException(
            status_code=500,
            detail=f"주소 좌표 변환 실패: {response.text}"
        )

    data = response.json()

    if not data.get("documents"):
        raise HTTPException(
            status_code=400,
            detail="주소를 찾을 수 없습니다. 도로명 주소를 더 정확히 입력해주세요."
        )

    first = data["documents"][0]

    return {
        "latitude": float(first["y"]),
        "longitude": float(first["x"]),
        "public_region_label": first.get("address", {}).get("region_1depth_name", "")
    }


def calculate_distance_km(lat1, lon1, lat2, lon2):
    radius = 6371

    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)

    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return radius * c