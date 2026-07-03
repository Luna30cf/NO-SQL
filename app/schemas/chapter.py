from datetime import datetime
from typing import Literal

from pydantic import Field

from app.schemas.common import APIModel


class ChapterCreate(APIModel):
    id: str = Field(pattern=r"^chapter_[A-Za-z0-9_-]+$")
    project_id: str = Field(pattern=r"^project_[A-Za-z0-9_-]+$")
    author_id: str
    title: str = Field(min_length=1, max_length=200)
    chapter_number: int = Field(ge=1)
    status: Literal["draft", "review", "published"] = "draft"


class ChapterResponse(ChapterCreate):
    created_at: datetime
    updated_at: datetime | None = None


class DraftSave(APIModel):
    user_id: str
    content: str = Field(min_length=1)


class DraftResponse(APIModel):
    chapter_id: str
    user_id: str
    content: str
    ttl_seconds: int


class LockRequest(APIModel):
    user_id: str


class LockResponse(APIModel):
    chapter_id: str
    owner_id: str
    acquired: bool
    ttl_seconds: int
