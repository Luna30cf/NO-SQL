from app.core.config import get_settings
from app.core.errors import NotFoundError
from app.repositories.chapter_repository import ChapterRepository
from app.repositories.redis_repository import RedisRepository
from app.schemas.chapter import ChapterCreate


class ChapterService:
    def __init__(
        self,
        chapters: ChapterRepository,
        redis: RedisRepository,
    ):
        self.chapters = chapters
        self.redis = redis
        self.settings = get_settings()

    async def create(self, payload: ChapterCreate) -> dict:
        return await self.chapters.create(payload)

    async def get(self, chapter_id: str) -> dict:
        return await self.chapters.get(chapter_id)

    async def list_by_project(self, project_id: str) -> list[dict]:
        return await self.chapters.list_by_project(project_id)

    async def publish(self, chapter_id: str) -> dict:
        return await self.chapters.publish(chapter_id)

    async def save_draft(self, chapter_id: str, user_id: str, content: str) -> dict:
        await self.chapters.get(chapter_id)
        await self.redis.save_draft(
            chapter_id,
            user_id,
            content,
            self.settings.draft_ttl_seconds,
        )
        return {
            "chapter_id": chapter_id,
            "user_id": user_id,
            "content": content,
            "ttl_seconds": self.settings.draft_ttl_seconds,
        }

    async def get_draft(self, chapter_id: str, user_id: str) -> dict:
        content, ttl = await self.redis.get_draft(chapter_id, user_id)
        if content is None:
            raise NotFoundError("Brouillon introuvable ou expiré.")
        return {
            "chapter_id": chapter_id,
            "user_id": user_id,
            "content": content,
            "ttl_seconds": ttl,
        }

    async def acquire_lock(self, chapter_id: str, user_id: str) -> dict:
        await self.chapters.get(chapter_id)
        acquired = await self.redis.acquire_lock(
            chapter_id,
            user_id,
            self.settings.lock_ttl_seconds,
        )
        owner_id = user_id if acquired else await self.redis.get_lock_owner(chapter_id)
        return {
            "chapter_id": chapter_id,
            "owner_id": owner_id,
            "acquired": acquired,
            "ttl_seconds": self.settings.lock_ttl_seconds,
        }
