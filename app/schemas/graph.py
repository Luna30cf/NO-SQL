from pydantic import Field

from app.schemas.common import APIModel


class RelationshipCreate(APIModel):
    source_id: str
    target_id: str
    relationship_type: str = Field(pattern=r"^[A-Z_]+$")
    properties: dict = Field(default_factory=dict)


class PathResponse(APIModel):
    nodes: list[dict]
    relationships: list[dict]


class NetworkResponse(APIModel):
    character_id: str
    relations: list[dict]
