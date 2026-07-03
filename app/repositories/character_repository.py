from pymongo import ReturnDocument

from app.core.errors import ConflictError, NotFoundError
from app.schemas.character import CharacterCreate, CharacterUpdate


class CharacterRepository:
    def __init__(self, database):
        self.collection = database.characters

    async def create(self, payload: CharacterCreate) -> dict:
        document = payload.model_dump()
        document["_id"] = document.pop("id")

        if await self.collection.find_one({"_id": document["_id"]}):
            raise ConflictError("Un personnage avec cet identifiant existe déjà.")

        await self.collection.insert_one(document)
        return self._serialize(document)

    async def get(self, character_id: str) -> dict:
        document = await self.collection.find_one({"_id": character_id})
        if document is None:
            raise NotFoundError("Personnage introuvable.")
        return self._serialize(document)

    async def list(self, project_id: str | None, limit: int, offset: int) -> list[dict]:
        query = {"project_id": project_id} if project_id else {}
        cursor = self.collection.find(query).skip(offset).limit(limit).sort("name", 1)
        return [self._serialize(document) async for document in cursor]

    async def update(self, character_id: str, payload: CharacterUpdate) -> dict:
        updates = payload.model_dump(exclude_none=True)
        if not updates:
            return await self.get(character_id)

        document = await self.collection.find_one_and_update(
            {"_id": character_id},
            {"$set": updates},
            return_document=ReturnDocument.AFTER,
        )

        if document is None:
            raise NotFoundError("Personnage introuvable.")
        return self._serialize(document)

    async def delete(self, character_id: str) -> None:
        result = await self.collection.delete_one({"_id": character_id})
        if result.deleted_count == 0:
            raise NotFoundError("Personnage introuvable.")

    @staticmethod
    def _serialize(document: dict) -> dict:
        data = dict(document)
        data["id"] = str(data.pop("_id"))
        return data
