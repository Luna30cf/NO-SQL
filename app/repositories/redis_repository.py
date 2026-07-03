import json

from redis.asyncio import Redis


class RedisRepository:
    def __init__(self, client: Redis):
        self.client = client

    async def get_json(self, key: str) -> dict | None:
        value = await self.client.get(key)
        return json.loads(value) if value else None

    async def set_json(self, key: str, value: dict, ttl: int) -> None:
        await self.client.set(key, json.dumps(value, default=str), ex=ttl)

    async def delete(self, key: str) -> None:
        await self.client.delete(key)

    async def save_draft(
        self,
        chapter_id: str,
        user_id: str,
        content: str,
        ttl: int,
    ) -> None:
        key = f"draft:chapter:{chapter_id}:user:{user_id}"
        await self.client.set(key, content, ex=ttl)

    async def get_draft(self, chapter_id: str, user_id: str) -> tuple[str | None, int]:
        key = f"draft:chapter:{chapter_id}:user:{user_id}"
        async with self.client.pipeline(transaction=False) as pipe:
            pipe.get(key)
            pipe.ttl(key)
            content, ttl = await pipe.execute()
        return content, ttl

    async def acquire_lock(
        self,
        chapter_id: str,
        user_id: str,
        ttl: int,
    ) -> bool:
        key = f"lock:chapter:{chapter_id}"
        result = await self.client.set(key, user_id, nx=True, ex=ttl)
        return bool(result)

    async def get_lock_owner(self, chapter_id: str) -> str | None:
        return await self.client.get(f"lock:chapter:{chapter_id}")

    async def increment_character_popularity(self, character_id: str) -> None:
        await self.client.zincrby("popular:characters", 1, character_id)

    async def popular_characters(self, limit: int) -> list[dict]:
        rows = await self.client.zrevrange(
            "popular:characters",
            0,
            limit - 1,
            withscores=True,
        )
        return [
            {"character_id": character_id, "score": float(score)}
            for character_id, score in rows
        ]
