import os

os.environ.setdefault("POSTGRES_DSN", "postgresql://user:pass@localhost:5432/test")
os.environ.setdefault("MONGODB_URI", "mongodb://localhost:27017")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("NEO4J_URI", "bolt://localhost:7687")
os.environ.setdefault("NEO4J_USER", "neo4j")
os.environ.setdefault("NEO4J_PASSWORD", "password")

from app.core.config import Settings


def test_cors_origins_parsing():
    settings = Settings(
        cors_origins="http://localhost:3000,http://localhost:5173",
    )
    assert settings.cors_origins == [
        "http://localhost:3000",
        "http://localhost:5173",
    ]
