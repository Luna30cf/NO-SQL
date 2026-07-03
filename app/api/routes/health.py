from fastapi import APIRouter, Depends
from fastapi.responses import ORJSONResponse

from app.api.dependencies import get_database
from app.infrastructure.database import DatabaseManager

router = APIRouter(tags=["Santé"])


@router.get("/health")
async def health(database: DatabaseManager = Depends(get_database)):
    checks = await database.health()
    healthy = all(checks.values())
    return ORJSONResponse(
        status_code=200 if healthy else 503,
        content={
            "status": "healthy" if healthy else "degraded",
            "services": checks,
        },
    )
