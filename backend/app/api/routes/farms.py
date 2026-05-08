from fastapi import APIRouter

router = APIRouter()

@router.get("/test")
def records_test():
    return {"message": "farms route ok"}