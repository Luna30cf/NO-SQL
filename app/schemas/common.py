from datetime import datetime

from pydantic import BaseModel, ConfigDict


class APIModel(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        str_strip_whitespace=True,
    )


class MessageResponse(APIModel):
    message: str


class TimestampedModel(APIModel):
    created_at: datetime | None = None
    updated_at: datetime | None = None
