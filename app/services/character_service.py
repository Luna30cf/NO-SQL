from app.core.config import get_settings
from app.repositories.character_repository import CharacterRepository
from app.repositories.graph_repository import GraphRepository
from app.repositories.redis_repository import RedisRepository
from app.schemas.character import CharacterCreate, CharacterUpdate


class CharacterService:
    def __init__(
        self,
        characters: CharacterRepository,
        graph: GraphRepository,
        redis: RedisRepository,
    ):
        self.characters = characters
        self.graph = graph
        self.redis = redis
        self.settings = get_settings()

    async def create(self, payload: CharacterCreate) -> dict:
        character = await self.characters.create(payload)
        try:
            await self.graph.upsert_character(
                character_id=character["id"],
                name=character["name"],
                project_id=character["project_id"],
            )
        except Exception:
            await self.characters.delete(character["id"])
            raise
        return character

    async def get(self, character_id: str) -> dict:
        cache_key = f"cache:character:{character_id}"
        cached = await self.redis.get_json(cache_key)
        if cached is not None:
            await self.redis.increment_character_popularity(character_id)
            return cached

        character = await self.characters.get(character_id)
        await self.redis.set_json(
            cache_key,
            character,
            self.settings.cache_ttl_seconds,
        )
        await self.redis.increment_character_popularity(character_id)
        return character

    async def list(
        self,
        project_id: str | None,
        limit: int,
        offset: int,
    ) -> list[dict]:
        return await self.characters.list(project_id, limit, offset)

    async def update(self, character_id: str, payload: CharacterUpdate) -> dict:
        character = await self.characters.update(character_id, payload)
        await self.redis.delete(f"cache:character:{character_id}")
        await self.graph.upsert_character(
            character_id=character["id"],
            name=character["name"],
            project_id=character["project_id"],
        )
        return character

    async def delete(self, character_id: str) -> None:
        await self.characters.delete(character_id)
        await self.redis.delete(f"cache:character:{character_id}")
        await self.graph.delete_character(character_id)

    async def popular(self, limit: int) -> list[dict]:
        return await self.redis.popular_characters(limit)
