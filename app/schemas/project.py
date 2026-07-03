from datetime import datetime

from pydantic import Field

from app.schemas.common import APIModel


class ProjectCreate(APIModel):
    id: str = Field(pattern=r"^project_[A-Za-z0-9_-]+$")
    title: str = Field(min_length=2, max_length=150)
    owner_id: str = Field(min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=2000)


class ProjectResponse(ProjectCreate):
    created_at: datetime
