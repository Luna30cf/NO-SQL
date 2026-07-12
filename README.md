# LoreGraph

LoreGraph est une plateforme collaborative de création d’univers narratifs utilisant PostgreSQL, MongoDB, Redis et Neo4j derrière une API FastAPI.

## Lancement rapide

### Prérequis

- Docker Desktop doit être installé et lancé.
- Python 3.14 doit être installé.

### Démarrer le projet

Depuis PowerShell, à la racine du projet :

```powershell
.\start.ps1
```

Le script effectue automatiquement :

- la création de `.env` depuis `.env.example` ;
- la création de `.venv` si nécessaire ;
- l’installation des dépendances Python ;
- le démarrage des quatre bases Docker ;
- l’initialisation de Neo4j si la base est vide ;
- le lancement de FastAPI ;
- le lancement du frontend ;
- l’ouverture du navigateur.

La plateforme est disponible sur :

```text
http://127.0.0.1:5173
```

Swagger est disponible sur :

```text
http://127.0.0.1:8000/docs
```

### Arrêter le projet

```powershell
.\stop.ps1
```

## Configuration

Le fichier `.env.example` contient la configuration locale par défaut.

Au premier lancement, `start.ps1` crée automatiquement `.env` :

```powershell
Copy-Item .env.example .env
```

Il n’est donc pas nécessaire de recopier manuellement les variables d’environnement.

## Architecture

- PostgreSQL : utilisateurs, projets, chapitres, versions et publications.
- MongoDB : fiches de personnages riches et flexibles.
- Redis : brouillons temporaires, TTL, verrous d’édition et cache.
- Neo4j : relations entre personnages, événements, lieux, objets et factions.
- FastAPI : API commune.
- Frontend HTML/CSS/JavaScript : interface utilisateur.

## Réinitialisation complète

Pour supprimer les données persistées et repartir de zéro :

```powershell
docker compose down -v
.\start.ps1
```

Neo4j sera automatiquement réinitialisé au prochain lancement.

## Dépannage

### PowerShell bloque l’exécution du script

Exécuter une seule fois dans le terminal courant :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Puis :

```powershell
.\start.ps1
```

### Une base ne démarre pas

```powershell
docker compose ps
docker compose logs --tail=100
```

### Vérifier l’état général

```powershell
curl.exe http://127.0.0.1:8000/api/v1/health
```
