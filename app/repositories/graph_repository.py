from app.core.errors import NotFoundError
from app.schemas.graph import RelationshipCreate


class GraphRepository:
    def __init__(self, driver):
        self.driver = driver

    async def upsert_character(self, character_id: str, name: str, project_id: str) -> None:
        query = '''
            MERGE (c:Character {id: $character_id})
            SET c.name = $name, c.project_id = $project_id
        '''
        async with self.driver.session() as session:
            await session.run(
                query,
                character_id=character_id,
                name=name,
                project_id=project_id,
            )

    async def delete_character(self, character_id: str) -> None:
        async with self.driver.session() as session:
            await session.run(
                "MATCH (c:Character {id: $id}) DETACH DELETE c",
                id=character_id,
            )

    async def create_relationship(self, payload: RelationshipCreate) -> dict:
        allowed_types = {
            "ALLY_OF",
            "ENEMY_OF",
            "PARENT_OF",
            "SIBLING_OF",
            "MEMBER_OF",
            "PARTICIPATED_IN",
            "OWNS",
            "MENTIONS",
        }
        if payload.relationship_type not in allowed_types:
            raise ValueError("Type de relation non autorisé.")

        query = f'''
            MATCH (source {{id: $source_id}})
            MATCH (target {{id: $target_id}})
            MERGE (source)-[r:{payload.relationship_type}]->(target)
            SET r += $properties
            RETURN
                source.id AS source_id,
                target.id AS target_id,
                type(r) AS relationship_type,
                properties(r) AS properties
        '''

        async with self.driver.session() as session:
            result = await session.run(
                query,
                source_id=payload.source_id,
                target_id=payload.target_id,
                properties=payload.properties,
            )
            record = await result.single()

        if record is None:
            raise NotFoundError("Un des nœuds est introuvable.")
        return dict(record)

    async def character_network(self, character_id: str, depth: int = 2) -> list[dict]:
        depth = min(max(depth, 1), 4)
        query = f'''
            MATCH (source:Character {{id: $id}})
            MATCH path = (source)-[*1..{depth}]-(target)
            WHERE source <> target
            RETURN DISTINCT
                target.id AS target_id,
                labels(target) AS labels,
                target.name AS name,
                length(path) AS distance
            ORDER BY distance, name
            LIMIT 100
        '''
        async with self.driver.session() as session:
            result = await session.run(query, id=character_id)
            return [dict(record) async for record in result]

    async def shortest_path(self, source_id: str, target_id: str) -> dict:
        query = '''
            MATCH (source {id: $source_id}), (target {id: $target_id})
            MATCH path = shortestPath((source)-[*..8]-(target))
            RETURN
                [node IN nodes(path) |
                    {id: node.id, name: node.name, labels: labels(node)}
                ] AS nodes,
                [relation IN relationships(path) |
                    {
                        type: type(relation),
                        properties: properties(relation)
                    }
                ] AS relationships
        '''
        async with self.driver.session() as session:
            result = await session.run(
                query,
                source_id=source_id,
                target_id=target_id,
            )
            record = await result.single()

        if record is None:
            raise NotFoundError("Aucun chemin trouvé.")
        return dict(record)

    async def timeline(self, project_id: str) -> list[dict]:
        query = '''
            MATCH (event:Event {project_id: $project_id})
            OPTIONAL MATCH (event)-[:PRECEDES]->(next:Event)
            RETURN
                event.id AS event_id,
                event.name AS name,
                event.date AS date,
                collect(next.id) AS next_events
            ORDER BY date
        '''
        async with self.driver.session() as session:
            result = await session.run(query, project_id=project_id)
            return [dict(record) async for record in result]
