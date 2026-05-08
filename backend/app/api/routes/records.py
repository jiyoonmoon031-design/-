from fastapi import APIRouter

router = APIRouter()

@router.get("/test")
def records_test():
    return {"message": "records route ok"}