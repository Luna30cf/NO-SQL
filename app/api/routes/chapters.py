from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_chapter_service
from app.schemas.chapter import (
    ChapterCreate,
    ChapterResponse,
    DraftResponse,
    DraftSave,
    LockRequest,
    LockResponse,
)
from app.services.chapter_service import ChapterService

router = APIRouter(prefix="/chapters", tags=["Chapitres"])


@router.post("", response_model=ChapterResponse, status_code=status.HTTP_201_CREATED)
async def create_chapter(
    payload: ChapterCreate,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.create(payload)


@router.get("/{chapter_id}", response_model=ChapterResponse)
async def get_chapter(
    chapter_id: str,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.get(chapter_id)


@router.get("/project/{project_id}", response_model=list[ChapterResponse])
async def list_project_chapters(
    project_id: str,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.list_by_project(project_id)


@router.post("/{chapter_id}/publish", response_model=ChapterResponse)
async def publish_chapter(
    chapter_id: str,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.publish(chapter_id)


@router.put("/{chapter_id}/draft", response_model=DraftResponse)
async def save_draft(
    chapter_id: str,
    payload: DraftSave,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.save_draft(chapter_id, payload.user_id, payload.content)


@router.get("/{chapter_id}/draft/{user_id}", response_model=DraftResponse)
async def get_draft(
    chapter_id: str,
    user_id: str,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.get_draft(chapter_id, user_id)


@router.post("/{chapter_id}/lock", response_model=LockResponse)
async def lock_chapter(
    chapter_id: str,
    payload: LockRequest,
    service: ChapterService = Depends(get_chapter_service),
):
    return await service.acquire_lock(chapter_id, payload.user_id)
