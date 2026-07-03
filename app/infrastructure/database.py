from pymongo import AsyncMongoClient
from neo4j import AsyncGraphDatabase
from psycopg_pool import AsyncConnectionPool
from redis.asyncio import Redis

from app.core.config import Settings


class DatabaseManager:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.postgres: AsyncConnectionPool | None = None
        self.mongo_client: AsyncMongoClient | None = None
        self.mongo = None
        self.redis: Redis | None = None
        self.neo4j = None

    async def connect(self) -> None:
        self.postgres = AsyncConnectionPool(
            conninfo=self.settings.postgres_dsn,
            min_size=1,
            max_size=10,
            open=False,
        )
        await self.postgres.open()
        await self.postgres.wait()

        self.mongo_client = AsyncMongoClient(self.settings.mongodb_uri)
        self.mongo = self.mongo_client[self.settings.mongodb_database]

        self.redis = Redis.from_url(
            self.settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )

        self.neo4j = AsyncGraphDatabase.driver(
            self.settings.neo4j_uri,
            auth=(
                self.settings.neo4j_user,
                self.settings.neo4j_password,
            ),
        )

    async def disconnect(self) -> None:
        if self.postgres is not None:
            await self.postgres.close()

        if self.mongo_client is not None:
            await self.mongo_client.close()

        if self.redis is not None:
            await self.redis.aclose()

        if self.neo4j is not None:
            await self.neo4j.close()

    async def health(self) -> dict[str, bool]:
        checks = {
            "postgres": False,
            "mongodb": False,
            "redis": False,
            "neo4j": False,
        }

        try:
            async with self.postgres.connection() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute("SELECT 1")
                    row = await cursor.fetchone()
                    checks["postgres"] = row is not None and row[0] == 1
        except Exception:
            pass

        try:
            result = await self.mongo.command("ping")
            checks["mongodb"] = result.get("ok") == 1.0
        except Exception:
            pass

        try:
            checks["redis"] = bool(await self.redis.ping())
        except Exception:
            pass

        try:
            await self.neo4j.verify_connectivity()
            checks["neo4j"] = True
        except Exception:
            pass

        return checks