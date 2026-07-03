from fastapi import APIRouter, Depends, Query, Response, status

from app.api.dependencies import get_character_service
from app.schemas.character import (
    CharacterCreate,
    CharacterResponse,
    CharacterUpdate,
    PopularCharacter,
)
from app.services.character_service import CharacterService

router = APIRouter(prefix="/characters", tags=["Personnages"])


@router.post("", response_model=CharacterResponse, status_code=status.HTTP_201_CREATED)
async def create_character(
    payload: CharacterCreate,
    service: CharacterService = Depends(get_character_service),
):
    return await service.create(payload)


@router.get("", response_model=list[CharacterResponse])
async def list_characters(
    project_id: str | None = None,
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    service: CharacterService = Depends(get_character_service),
):
    return await service.list(project_id, limit, offset)


@router.get("/popular", response_model=list[PopularCharacter])
async def popular_characters(
    limit: int = Query(default=10, ge=1, le=100),
    service: CharacterService = Depends(get_character_service),
):
    return await service.popular(limit)


@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(
    character_id: str,
    service: CharacterService = Depends(get_character_service),
):
    return await service.get(character_id)


@router.patch("/{character_id}", response_model=CharacterResponse)
async def update_character(
    character_id: str,
    payload: CharacterUpdate,
    service: CharacterService = Depends(get_character_service),
):
    return await service.update(character_id, payload)


@router.delete("/{character_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_character(
    character_id: str,
    service: CharacterService = Depends(get_character_service),
):
    await service.delete(character_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
