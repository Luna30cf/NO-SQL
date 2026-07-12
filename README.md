# LoreGraph

LoreGraph est une plateforme collaborative de création d’univers narratifs utilisant une persistance polyglotte.

## Démarrage

Prérequis :

- Docker Desktop lancé ;
- Python 3.14 installé ;
- PowerShell.

Cloner puis lancer :

```powershell
git clone https://github.com/Luna30cf/NO-SQL.git
cd NO-SQL
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Le script :

- crée `.env` depuis `.env.example` ;
- crée `.venv` si nécessaire ;
- installe les dépendances ;
- démarre PostgreSQL, MongoDB, Redis et Neo4j ;
- attend que les bases soient disponibles ;
- lance FastAPI ;
- lance le frontend ;
- ouvre le navigateur.

Accès :

- Frontend : `http://127.0.0.1:5173`
- Swagger : `http://127.0.0.1:8000/docs`
- Santé : `http://127.0.0.1:8000/api/v1/health`
- Neo4j Browser : `http://127.0.0.1:7474`

## Initialisation automatique

Un premier démarrage sur des volumes vierges charge automatiquement :

- `init.sql` puis `seed.sql` dans PostgreSQL ;
- `mongo/init.js` dans MongoDB ;
- `redis/seed.sh` dans Redis ;
- `neo4j/schema.cypher`, `neo4j/seed.cypher` et `neo4j/relations.cypher` dans Neo4j.

Les mêmes identifiants sont partagés entre les bases :

- `project_001`
- `chapter_001`, `chapter_002`
- `character_001` à `character_006`
- `user_001` à `user_003`

## Vérification de reproductibilité

```powershell
docker compose down -v
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Puis :

```powershell
curl.exe http://127.0.0.1:8000/api/v1/health
docker exec loregraph-postgres psql -U loregraph -d loregraph -c "SELECT COUNT(*) FROM projects;"
docker exec loregraph-mongodb mongosh --quiet --eval "db.getSiblingDB('loregraph').characters.countDocuments()"
docker exec loregraph-redis redis-cli DBSIZE
docker exec loregraph-neo4j cypher-shell -u neo4j -p change_me "MATCH (n) RETURN count(n);"
```

## Arrêt

```powershell
powershell -ExecutionPolicy Bypass -File .\stop.ps1
```
