from app.repositories.graph_repository import GraphRepository
from app.schemas.graph import RelationshipCreate


class GraphService:
    def __init__(self, graph: GraphRepository):
        self.graph = graph

    async def create_relationship(self, payload: RelationshipCreate) -> dict:
        return await self.graph.create_relationship(payload)

    async def character_network(self, character_id: str, depth: int) -> dict:
        relations = await self.graph.character_network(character_id, depth)
        return {
            "character_id": character_id,
            "relations": relations,
        }

    async def shortest_path(self, source_id: str, target_id: str) -> dict:
        return await self.graph.shortest_path(source_id, target_id)

    async def timeline(self, project_id: str) -> list[dict]:
        return await self.graph.timeline(project_id)
