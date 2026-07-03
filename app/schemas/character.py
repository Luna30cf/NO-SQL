from typing import Any

from pydantic import Field

from app.schemas.common import APIModel


class CharacterCreate(APIModel):
    id: str = Field(pattern=r"^character_[A-Za-z0-9_-]+$")
    project_id: str = Field(pattern=r"^project_[A-Za-z0-9_-]+$")
    name: str = Field(min_length=1, max_length=150)
    aliases: list[str] = Field(default_factory=list)
    description: str | None = None
    physical_attributes: dict[str, Any] = Field(default_factory=dict)
    personality: dict[str, Any] = Field(default_factory=dict)
    abilities: list[dict[str, Any]] = Field(default_factory=list)
    appearances: list[dict[str, Any]] = Field(default_factory=list)
    custom_fields: dict[str, Any] = Field(default_factory=dict)


class CharacterUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    aliases: list[str] | None = None
    description: str | None = None
    physical_attributes: dict[str, Any] | None = None
    personality: dict[str, Any] | None = None
    abilities: list[dict[str, Any]] | None = None
    appearances: list[dict[str, Any]] | None = None
    custom_fields: dict[str, Any] | None = None


class CharacterResponse(CharacterCreate):
    pass


class PopularCharacter(APIModel):
    character_id: str
    score: float
