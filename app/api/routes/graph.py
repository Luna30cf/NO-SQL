from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import get_graph_service
from app.schemas.graph import (
    NetworkResponse,
    PathResponse,
    RelationshipCreate,
)
from app.services.graph_service import GraphService

router = APIRouter(prefix="/graph", tags=["Graphe"])


@router.post("/relationships", status_code=status.HTTP_201_CREATED)
async def create_relationship(
    payload: RelationshipCreate,
    service: GraphService = Depends(get_graph_service),
):
    return await service.create_relationship(payload)


@router.get("/characters/{character_id}/network", response_model=NetworkResponse)
async def character_network(
    character_id: str,
    depth: int = Query(default=2, ge=1, le=4),
    service: GraphService = Depends(get_graph_service),
):
    return await service.character_network(character_id, depth)


@router.get("/path/{source_id}/{target_id}", response_model=PathResponse)
async def shortest_path(
    source_id: str,
    target_id: str,
    service: GraphService = Depends(get_graph_service),
):
    return await service.shortest_path(source_id, target_id)


@router.get("/projects/{project_id}/timeline")
async def project_timeline(
    project_id: str,
    service: GraphService = Depends(get_graph_service),
):
    return await service.timeline(project_id)
