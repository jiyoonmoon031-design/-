import requests #다른 서버에 HTTP 요청을 보내는 라이브러리

#AI 서버 주소
AI_BASE_URL = "https://shrunk-canister-come.ngrok-free.dev"

def request_ai_diagnosis(image_path: str): #image_path 업로드된 이미지 파일 경로
    with open(image_path, "rb") as f: #이미지를 바이너리 모드로 열기, 이미지 파일은 텍스트가 아닌 바이너리 데이터이기 때문
        files = {"file": f} #file이라는 이름으로 이미지를 받음, AI 서버와 이름이 같아야함, 구조 정의

        response = requests.post( #
            f"{AI_BASE_URL}/predict",
            files=files, #files에 값 넣기
            timeout=30
        )

        response.raise_for_status() #응답 실패시 에러 발생
        ai_result = response.json()
        print("AI 응답 전체:", ai_result)
        print("AI 응답 key 목록:", list(ai_result.keys()))
        print("gradcam_path:", ai_result.get("gradcam_url"))
        print("recommendation_text:", ai_result.get("action_text"))
        return ai_result #AI 서버가 반환한 JSON 결과를 딕셔너리로 반환
