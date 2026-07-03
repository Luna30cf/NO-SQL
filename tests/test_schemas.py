import pytest
from pydantic import ValidationError

from app.schemas.character import CharacterCreate
from app.schemas.project import ProjectCreate


def test_project_identifier_format():
    project = ProjectCreate(
        id="project_001",
        title="Les Royaumes Brisés",
        owner_id="user_001",
    )
    assert project.id == "project_001"


def test_invalid_character_identifier():
    with pytest.raises(ValidationError):
        CharacterCreate(
            id="bad-id",
            project_id="project_001",
            name="Aelric",
        )
