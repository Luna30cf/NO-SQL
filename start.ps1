$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host ""
Write-Host "=== LoreGraph - lancement automatique ===" -ForegroundColor Cyan
Write-Host ""

# 1. Configuration
if (-not (Test-Path ".env")) {
    if (-not (Test-Path ".env.example")) {
        Write-Host "Erreur : .env.example est introuvable." -ForegroundColor Red
        exit 1
    }

    Copy-Item ".env.example" ".env"
    Write-Host "[OK] .env créé automatiquement depuis .env.example" -ForegroundColor Green
}
else {
    Write-Host "[OK] .env déjà présent" -ForegroundColor Green
}

# 2. Environnement Python
if (-not (Test-Path ".venv\Scripts\python.exe")) {
    Write-Host "[...] Création de l'environnement Python" -ForegroundColor Yellow
    python -m venv .venv
    & ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
    & ".\.venv\Scripts\python.exe" -m pip install -r requirements.txt
    Write-Host "[OK] Environnement Python prêt" -ForegroundColor Green
}
else {
    try {
        & ".\.venv\Scripts\python.exe" -c "import fastapi, uvicorn, pydantic, redis, neo4j, pymongo" 2>$null
        Write-Host "[OK] Dépendances Python déjà installées" -ForegroundColor Green
    }
    catch {
        Write-Host "[...] Installation des dépendances Python" -ForegroundColor Yellow
        & ".\.venv\Scripts\python.exe" -m pip install -r requirements.txt
        Write-Host "[OK] Dépendances installées" -ForegroundColor Green
    }
}

# 3. Bases Docker
Write-Host "[...] Démarrage des bases Docker" -ForegroundColor Yellow
docker compose up -d

$containers = @(
    "loregraph-postgres",
    "loregraph-mongodb",
    "loregraph-redis",
    "loregraph-neo4j"
)

$timeout = 120
$elapsed = 0

while ($elapsed -lt $timeout) {
    $allReady = $true

    foreach ($container in $containers) {
        $status = docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" $container 2>$null

        if ($status -notin @("healthy", "running")) {
            $allReady = $false
            break
        }
    }

    if ($allReady) {
        break
    }

    Start-Sleep -Seconds 3
    $elapsed += 3
}

if ($elapsed -ge $timeout) {
    Write-Host "Erreur : les conteneurs ne sont pas prêts après $timeout secondes." -ForegroundColor Red
    docker compose ps
    exit 1
}

Write-Host "[OK] Les quatre bases sont prêtes" -ForegroundColor Green

# 4. Initialisation Neo4j seulement si la base est vide
$nodeCount = docker exec loregraph-neo4j cypher-shell -u neo4j -p change_me --format plain "MATCH (n) RETURN count(n) AS total;" 2>$null |
    Select-String -Pattern '^\d+$' |
    Select-Object -First 1

if (-not $nodeCount -or [int]$nodeCount.Line -eq 0) {
    Write-Host "[...] Initialisation de Neo4j" -ForegroundColor Yellow

    Get-Content ".\neo4j\schema.cypher" -Raw |
        docker exec -i loregraph-neo4j cypher-shell -u neo4j -p change_me

    Get-Content ".\neo4j\seed.cypher" -Raw |
        docker exec -i loregraph-neo4j cypher-shell -u neo4j -p change_me

    Get-Content ".\neo4j\relations.cypher" -Raw |
        docker exec -i loregraph-neo4j cypher-shell -u neo4j -p change_me

    Write-Host "[OK] Neo4j initialisé" -ForegroundColor Green
}
else {
    Write-Host "[OK] Neo4j contient déjà des données" -ForegroundColor Green
}

# 5. Lancement API
$apiCommand = @"
Set-Location '$root'
& '.\.venv\Scripts\python.exe' -m uvicorn app.main:app --reload
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $apiCommand
Write-Host "[OK] API FastAPI lancée" -ForegroundColor Green

# 6. Attente API
$apiReady = $false

for ($i = 0; $i -lt 30; $i++) {
    try {
        $health = Invoke-RestMethod "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 2

        if ($health.status -eq "healthy") {
            $apiReady = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $apiReady) {
    Write-Host "Attention : l'API n'a pas répondu à temps. Vérifiez le terminal FastAPI." -ForegroundColor Yellow
}

# 7. Lancement frontend
$frontendCommand = @"
Set-Location '$root\frontend'
& '$root\.venv\Scripts\python.exe' -m http.server 5173
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCommand
Write-Host "[OK] Frontend lancé" -ForegroundColor Green

Start-Sleep -Seconds 2
Start-Process "http://127.0.0.1:5173"

Write-Host ""
Write-Host "LoreGraph est disponible sur http://127.0.0.1:5173" -ForegroundColor Cyan
Write-Host "Swagger : http://127.0.0.1:8000/docs" -ForegroundColor Cyan
Write-Host ""
