from fastapi import Request

from app.infrastructure.database import DatabaseManager
from app.repositories.character_repository import CharacterRepository
from app.repositories.chapter_repository import ChapterRepository
from app.repositories.graph_repository import GraphRepository
from app.repositories.project_repository import ProjectRepository
from app.repositories.redis_repository import RedisRepository
from app.services.character_service import CharacterService
from app.services.chapter_service import ChapterService
from app.services.graph_service import GraphService
from app.services.project_service import ProjectService


def get_database(request: Request) -> DatabaseManager:
    return request.app.state.database


def get_project_service(request: Request) -> ProjectService:
    db = get_database(request)
    return ProjectService(ProjectRepository(db.postgres))


def get_chapter_service(request: Request) -> ChapterService:
    db = get_database(request)
    return ChapterService(
        chapters=ChapterRepository(db.postgres),
        redis=RedisRepository(db.redis),
    )


def get_character_service(request: Request) -> CharacterService:
    db = get_database(request)
    return CharacterService(
        characters=CharacterRepository(db.mongo),
        graph=GraphRepository(db.neo4j),
        redis=RedisRepository(db.redis),
    )


def get_graph_service(request: Request) -> GraphService:
    db = get_database(request)
    return GraphService(GraphRepository(db.neo4j))
