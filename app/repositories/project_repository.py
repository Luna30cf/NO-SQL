from psycopg import errors
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool

from app.core.errors import ConflictError, NotFoundError
from app.schemas.project import ProjectCreate


class ProjectRepository:
    def __init__(self, pool: AsyncConnectionPool):
        self.pool = pool

    async def create(self, payload: ProjectCreate) -> dict:
        query = """
            INSERT INTO projects (id, title, owner_id, description)
            VALUES (%s, %s, %s, %s)
            RETURNING id, title, owner_id, description, created_at
        """

        try:
            async with self.pool.connection() as connection:
                async with connection.cursor(row_factory=dict_row) as cursor:
                    await cursor.execute(
                        query,
                        (
                            payload.id,
                            payload.title,
                            payload.owner_id,
                            payload.description,
                        ),
                    )
                    row = await cursor.fetchone()

            return dict(row)

        except errors.UniqueViolation as exc:
            raise ConflictError(
                "Un projet avec cet identifiant existe déjà."
            ) from exc

    async def get(self, project_id: str) -> dict:
        async with self.pool.connection() as connection:
            async with connection.cursor(row_factory=dict_row) as cursor:
                await cursor.execute(
                    """
                    SELECT id, title, owner_id, description, created_at
                    FROM projects
                    WHERE id = %s
                    """,
                    (project_id,),
                )
                row = await cursor.fetchone()

        if row is None:
            raise NotFoundError("Projet introuvable.")

        return dict(row)

    async def list(self, limit: int, offset: int) -> list[dict]:
        async with self.pool.connection() as connection:
            async with connection.cursor(row_factory=dict_row) as cursor:
                await cursor.execute(
                    """
                    SELECT id, title, owner_id, description, created_at
                    FROM projects
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                    """,
                    (limit, offset),
                )
                rows = await cursor.fetchall()

        return [dict(row) for row in rows]