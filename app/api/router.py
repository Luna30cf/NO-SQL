from fastapi import APIRouter

from app.api.routes.characters import router as characters_router
from app.api.routes.chapters import router as chapters_router
from app.api.routes.graph import router as graph_router
from app.api.routes.health import router as health_router
from app.api.routes.projects import router as projects_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(projects_router)
api_router.include_router(chapters_router)
api_router.include_router(characters_router)
api_router.include_router(graph_router)
