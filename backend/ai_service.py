import random
import requests

AI_BASE_URL = "http://shrunk-canister-come.ngrok-free.dev"

def request_ai_diagnosis(image_path: str):
    with open(image_path, "rb") as f:
        files = {"file": f}

        response = requests.post(
            f"{AI_BASE_URL}/predict",
            files=files,
            timeout=30
        )

        response.raise_for_status()

        return response.json()