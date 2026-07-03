# LoreGraph — Application API

Application support du projet de persistance polyglotte.

Cette partie contient uniquement l'application :
- API FastAPI ;
- configuration ;
- validation des données ;
- routes métier ;
- connexion aux quatre moteurs ;
- couche de services et repositories ;
- gestion des erreurs ;
- tests unitaires de base ;
- Dockerfile de l'API.

Elle ne contient pas :
- le `docker-compose.yml` des quatre bases ;
- les schémas SQL ;
- les scripts MongoDB ;
- les seeds Redis ;
- les contraintes et seeds Neo4j ;
- le dossier de conception.

## Prérequis

- Python 3.14
- PostgreSQL
- MongoDB
- Redis
- Neo4j

## Installation locale

```bash
py -3.14 -m venv .venv
```

Sous Windows :

```powershell
.venv\Scripts\activate
```

Sous Linux/macOS :

```bash
source .venv/bin/activate
```

Puis :

```bash
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

Documentation interactive :

- Swagger : `http://localhost:8000/docs`
- ReDoc : `http://localhost:8000/redoc`
- Santé : `http://localhost:8000/api/v1/health`

## Hypothèses de modèle

L'application attend les éléments suivants.

### PostgreSQL

Tables utilisées :
- `users`
- `projects`
- `project_members`
- `chapters`
- `chapter_versions`
- `publications`

### MongoDB

Collections utilisées :
- `characters`
- `locations`
- `items`
- `events`
- `notes`

### Redis

Clés principales :
- `cache:character:{character_id}`
- `draft:chapter:{chapter_id}:user:{user_id}`
- `lock:chapter:{chapter_id}`
- `popular:characters`
- `session:{session_id}`

### Neo4j

Labels principaux :
- `Character`
- `Faction`
- `Location`
- `Event`
- `Item`
- `Chapter`

Relations principales :
- `ALLY_OF`
- `ENEMY_OF`
- `PARENT_OF`
- `SIBLING_OF`
- `MEMBER_OF`
- `PARTICIPATED_IN`
- `PRECEDES`
- `MENTIONS`

## Lancer les tests

```bash
pytest
```

## Vérification syntaxique

```bash
python -m compileall app
```

## Compatibilité Python 3.14

Cette version utilise exclusivement des dépendances compatibles Python 3.14 :

- `asyncpg >= 0.31.0`
- `pydantic >= 2.13.0`
- `pydantic-settings >= 2.14.2`
- `orjson >= 3.11.9`
- API asynchrone native de PyMongo via `AsyncMongoClient`

Avant l'installation, vérifiez :

```powershell
python --version
```

Le résultat doit commencer par `Python 3.14`.
