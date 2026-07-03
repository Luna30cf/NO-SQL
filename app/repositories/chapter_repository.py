from psycopg import errors
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool

from app.core.errors import ConflictError, NotFoundError
from app.schemas.chapter import ChapterCreate


class ChapterRepository:
    def __init__(self, pool: AsyncConnectionPool):
        self.pool = pool

    async def create(self, payload: ChapterCreate) -> dict:
        query = """
            INSERT INTO chapters (
                id, project_id, author_id, title, chapter_number, status
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING
                id, project_id, author_id, title,
                chapter_number, status, created_at, updated_at
        """

        try:
            async with self.pool.connection() as connection:
                async with connection.cursor(row_factory=dict_row) as cursor:
                    await cursor.execute(
                        query,
                        (
                            payload.id,
                            payload.project_id,
                            payload.author_id,
                            payload.title,
                            payload.chapter_number,
                            payload.status,
                        ),
                    )
                    row = await cursor.fetchone()

            return dict(row)

        except errors.UniqueViolation as exc:
            raise ConflictError(
                "Ce chapitre existe déjà ou son numéro est déjà utilisé."
            ) from exc

    async def get(self, chapter_id: str) -> dict:
        async with self.pool.connection() as connection:
            async with connection.cursor(row_factory=dict_row) as cursor:
                await cursor.execute(
                    """
                    SELECT
                        id, project_id, author_id, title,
                        chapter_number, status, created_at, updated_at
                    FROM chapters
                    WHERE id = %s
                    """,
                    (chapter_id,),
                )
                row = await cursor.fetchone()

        if row is None:
            raise NotFoundError("Chapitre introuvable.")

        return dict(row)

    async def list_by_project(self, project_id: str) -> list[dict]:
        async with self.pool.connection() as connection:
            async with connection.cursor(row_factory=dict_row) as cursor:
                await cursor.execute(
                    """
                    SELECT
                        id, project_id, author_id, title,
                        chapter_number, status, created_at, updated_at
                    FROM chapters
                    WHERE project_id = %s
                    ORDER BY chapter_number
                    """,
                    (project_id,),
                )
                rows = await cursor.fetchall()

        return [dict(row) for row in rows]

    async def publish(self, chapter_id: str) -> dict:
        async with self.pool.connection() as connection:
            async with connection.transaction():
                async with connection.cursor(row_factory=dict_row) as cursor:
                    await cursor.execute(
                        """
                        UPDATE chapters
                        SET status = 'published', updated_at = NOW()
                        WHERE id = %s
                        RETURNING
                            id, project_id, author_id, title,
                            chapter_number, status, created_at, updated_at
                        """,
                        (chapter_id,),
                    )
                    row = await cursor.fetchone()

                    if row is None:
                        raise NotFoundError("Chapitre introuvable.")

                    await cursor.execute(
                        """
                        INSERT INTO publications (chapter_id, published_at)
                        VALUES (%s, NOW())
                        """,
                        (chapter_id,),
                    )

        return dict(row)