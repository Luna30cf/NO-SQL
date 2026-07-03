from app.repositories.project_repository import ProjectRepository
from app.schemas.project import ProjectCreate


class ProjectService:
    def __init__(self, projects: ProjectRepository):
        self.projects = projects

    async def create(self, payload: ProjectCreate) -> dict:
        return await self.projects.create(payload)

    async def get(self, project_id: str) -> dict:
        return await self.projects.get(project_id)

    async def list(self, limit: int, offset: int) -> list[dict]:
        return await self.projects.list(limit, offset)
