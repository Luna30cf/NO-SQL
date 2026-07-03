# Dossier de conception — LoreGraph
## Section PostgreSQL — Composante relationnelle du système

---

## 1. Présentation de la base

Dans l'architecture polyglotte de **LoreGraph**, PostgreSQL prend en charge les données **transactionnelles et administratives** de la plateforme : les comptes utilisateurs, les projets narratifs, les membres et leurs rôles, les chapitres et leur cycle de vie éditorial.

Ces données partagent trois caractéristiques qui rendent le modèle relationnel obligatoire :

- **Structure stable et prévisible** : un utilisateur a toujours un identifiant, un nom et un e-mail ; un chapitre a toujours un numéro, un statut et un auteur. Il n'y a pas de champs variables d'un enregistrement à l'autre, contrairement aux fiches de personnages stockées dans MongoDB.
- **Intégrité référentielle forte** : on ne peut pas créer un chapitre pour un projet inexistant, ni publier un chapitre par un utilisateur inconnu. PostgreSQL garantit ces règles nativement via les clés étrangères.
- **Opérations transactionnelles** : la publication d'un chapitre, le transfert de propriété d'un projet ou l'ajout contrôlé d'un membre sont des opérations qui doivent réussir entièrement ou être annulées. SQL et les transactions ACID répondent exactement à ce besoin.

---

## 2. Modèle relationnel

Le schéma comprend **six tables normalisées**, reflétant les entités et associations du domaine.

### 2.1 Table `users`

Stocke les comptes des auteurs et contributeurs.

| Colonne         | Type          | Contraintes                 |
|-----------------|---------------|-----------------------------|
| `id`            | SERIAL        | PK                          |
| `username`      | VARCHAR(50)   | NOT NULL, UNIQUE            |
| `email`         | VARCHAR(100)  | NOT NULL, UNIQUE            |
| `password_hash` | VARCHAR(255)  | NOT NULL                    |
| `created_at`    | TIMESTAMP     | NOT NULL, DEFAULT NOW()     |

**Justification :** les contraintes UNIQUE sur `username` et `email` garantissent qu'aucun doublon de compte ne peut exister. La suppression d'un utilisateur est bloquée par référence (ON DELETE RESTRICT) dès qu'il est propriétaire d'un projet ou auteur d'un chapitre.

---

### 2.2 Table `projects`

Stocke les projets narratifs (les univers fictifs).

| Colonne       | Type         | Contraintes                                               |
|---------------|--------------|-----------------------------------------------------------|
| `id`          | SERIAL       | PK                                                        |
| `title`       | VARCHAR(200) | NOT NULL                                                  |
| `description` | TEXT         | nullable                                                  |
| `owner_id`    | INTEGER      | NOT NULL, FK → `users.id` ON DELETE RESTRICT              |
| `status`      | VARCHAR(20)  | NOT NULL, CHECK IN ('active', 'archived', 'completed')    |
| `created_at`  | TIMESTAMP    | NOT NULL, DEFAULT NOW()                                   |
| `updated_at`  | TIMESTAMP    | NOT NULL, DEFAULT NOW()                                   |

**Justification :** le champ `status` est contraint par un CHECK pour éviter toute valeur incohérente. La relation avec `users` via `owner_id` est essentielle : on sait toujours qui est responsable d'un projet.

> **Identifiants partagés :** les `id` 1 à 5 de cette table sont utilisés comme `projectId` dans les documents MongoDB et comme référence dans les nœuds Neo4j. C'est la clé de la cohérence inter-bases.

---

### 2.3 Table `project_members`

Table d'association entre `users` et `projects`, enrichie d'un rôle.

| Colonne      | Type        | Contraintes                                                        |
|--------------|-------------|--------------------------------------------------------------------|
| `project_id` | INTEGER     | PK partielle, FK → `projects.id` ON DELETE CASCADE                 |
| `user_id`    | INTEGER     | PK partielle, FK → `users.id` ON DELETE CASCADE                    |
| `role`       | VARCHAR(20) | NOT NULL, CHECK IN ('owner', 'editor', 'writer', 'reader')         |
| `joined_at`  | TIMESTAMP   | NOT NULL, DEFAULT NOW()                                            |

La clé primaire composite `(project_id, user_id)` garantit qu'un utilisateur ne peut avoir qu'un seul rôle par projet.

**Justification :** cette table modélise une association **many-to-many** avec attribut (le rôle), ce que le modèle relationnel gère naturellement. Une collection MongoDB n'apporterait ici aucun avantage et rendrait les requêtes de contrôle d'accès bien plus complexes.

---

### 2.4 Table `chapters`

Chapitres rattachés à un projet, avec leur cycle de vie éditorial.

| Colonne          | Type         | Contraintes                                                          |
|------------------|--------------|----------------------------------------------------------------------|
| `id`             | SERIAL       | PK                                                                   |
| `project_id`     | INTEGER      | NOT NULL, FK → `projects.id` ON DELETE CASCADE                       |
| `author_id`      | INTEGER      | NOT NULL, FK → `users.id` ON DELETE RESTRICT                         |
| `title`          | VARCHAR(300) | NOT NULL                                                             |
| `chapter_number` | INTEGER      | NOT NULL                                                             |
| `status`         | VARCHAR(20)  | NOT NULL, CHECK IN ('draft', 'review', 'approved', 'published')      |
| `word_count`     | INTEGER      | CHECK >= 0                                                           |
| `created_at`     | TIMESTAMP    | NOT NULL, DEFAULT NOW()                                              |
| `updated_at`     | TIMESTAMP    | NOT NULL, DEFAULT NOW()                                              |

Contrainte supplémentaire : `UNIQUE (project_id, chapter_number)` — deux chapitres du même projet ne peuvent pas porter le même numéro.

> **Identifiants partagés :** les `id` 1 à 100 de cette table correspondent aux `chapterId` référencés dans les tableaux d'`appearances` des documents de personnages en MongoDB, et aux nœuds `Chapter` dans Neo4j.

---

### 2.5 Table `chapter_versions`

Historique des versions successives d'un chapitre.

| Colonne           | Type      | Contraintes                                      |
|-------------------|-----------|--------------------------------------------------|
| `id`              | SERIAL    | PK                                               |
| `chapter_id`      | INTEGER   | NOT NULL, FK → `chapters.id` ON DELETE CASCADE   |
| `version_number`  | INTEGER   | NOT NULL                                         |
| `content_summary` | TEXT      | nullable                                         |
| `created_by`      | INTEGER   | NOT NULL, FK → `users.id` ON DELETE RESTRICT     |
| `created_at`      | TIMESTAMP | NOT NULL, DEFAULT NOW()                          |

Contrainte : `UNIQUE (chapter_id, version_number)` — les numéros de version sont séquentiels et uniques par chapitre.

---

### 2.6 Table `publications`

Enregistrement officiel de la mise en ligne d'un chapitre.

| Colonne        | Type      | Contraintes                                       |
|----------------|-----------|---------------------------------------------------|
| `id`           | SERIAL    | PK                                                |
| `chapter_id`   | INTEGER   | NOT NULL, UNIQUE, FK → `chapters.id` RESTRICT     |
| `published_by` | INTEGER   | NOT NULL, FK → `users.id` ON DELETE RESTRICT      |
| `published_at` | TIMESTAMP | NOT NULL, DEFAULT NOW()                           |
| `notes`        | TEXT      | nullable                                          |

La contrainte `UNIQUE (chapter_id)` empêche la double publication d'un même chapitre. Le `ON DELETE RESTRICT` sur `chapter_id` préserve la traçabilité : on ne peut pas supprimer un chapitre une fois publié.

---

## 3. Schéma relationnel

```
users (id, username, email, password_hash, created_at)
  │
  ├─── projects (id, title, description, owner_id→users, status, ...)
  │       │
  │       ├─── project_members (project_id→projects, user_id→users, role, joined_at)
  │       │
  │       └─── chapters (id, project_id→projects, author_id→users, title,
  │               │       chapter_number, status, word_count, ...)
  │               │
  │               ├─── chapter_versions (id, chapter_id→chapters, version_number,
  │               │                      content_summary, created_by→users, ...)
  │               │
  │               └─── publications (id, chapter_id→chapters UNIQUE,
  │                                  published_by→users, published_at, notes)
  │
  └─── (référencé par project_members, chapters, chapter_versions, publications)
```

---

## 4. Justification du choix relationnel

### Pourquoi SQL pour ces données ?

| Critère                  | Situation dans LoreGraph                                                       |
|--------------------------|--------------------------------------------------------------------------------|
| **Schéma fixe**          | Tous les utilisateurs ont les mêmes champs ; les chapitres aussi.              |
| **Intégrité**            | Un chapitre sans projet ou sans auteur n'a pas de sens — les FK l'empêchent.  |
| **Jointures nécessaires**| « Chapitres d'un projet avec leur auteur » = JOIN naturel entre 2 tables.     |
| **Transactions ACID**    | La publication (UPDATE + INSERT) doit être atomique.                          |
| **Contrôle d'accès**     | Les rôles par projet nécessitent une table d'association avec contrainte.     |

### Pourquoi pas MongoDB pour ces données ?

MongoDB aurait été pertinent si les utilisateurs ou les chapitres avaient des structures variables. Or ici, chaque utilisateur, projet et chapitre suit exactement le même schéma. Utiliser Mongo pour ces données reviendrait à renoncer à l'intégrité référentielle et aux transactions sans gain réel, ce qui serait contraire au principe de la persistance polyglotte : choisir la bonne base pour la bonne donnée.

---

## 5. Contraintes d'intégrité et règles de suppression

### Règles de suppression (ON DELETE)

| Relation                              | Règle appliquée  | Raison                                                              |
|---------------------------------------|------------------|---------------------------------------------------------------------|
| `projects.owner_id → users`           | RESTRICT         | On ne supprime pas un utilisateur propriétaire d'un projet actif.  |
| `project_members → projects`          | CASCADE          | Les membres disparaissent avec le projet.                          |
| `project_members → users`             | CASCADE          | Si un compte est supprimé, ses adhésions disparaissent aussi.       |
| `chapters → projects`                 | CASCADE          | Supprimer un projet supprime ses chapitres.                        |
| `chapters.author_id → users`          | RESTRICT         | On ne supprime pas l'auteur d'un chapitre existant.               |
| `chapter_versions → chapters`         | CASCADE          | L'historique suit le chapitre.                                     |
| `publications.chapter_id → chapters`  | RESTRICT         | Un chapitre publié ne peut pas être supprimé.                      |

### Contraintes CHECK

| Table            | Colonne     | Valeurs autorisées                                |
|------------------|-------------|---------------------------------------------------|
| `projects`       | `status`    | `'active'`, `'archived'`, `'completed'`           |
| `project_members`| `role`      | `'owner'`, `'editor'`, `'writer'`, `'reader'`     |
| `chapters`       | `status`    | `'draft'`, `'review'`, `'approved'`, `'published'`|
| `chapters`       | `word_count`| >= 0                                              |

---

## 6. Index définis

| Index                        | Colonne(s) indexée(s)         | Justification                                                  |
|------------------------------|-------------------------------|----------------------------------------------------------------|
| `idx_projects_owner`         | `projects(owner_id)`          | Recherche de tous les projets d'un utilisateur.                |
| `idx_project_members_user`   | `project_members(user_id)`    | Recherche des projets auxquels un utilisateur appartient.      |
| `idx_chapters_project`       | `chapters(project_id)`        | Filtre principal pour afficher les chapitres d'un projet.      |
| `idx_chapters_author`        | `chapters(author_id)`         | Lister les chapitres écrits par un auteur spécifique.          |
| `idx_chapters_status`        | `chapters(status)`            | Filtres fréquents par statut (`draft`, `published`, etc.).     |
| `idx_chapter_versions_chap`  | `chapter_versions(chapter_id)`| Récupérer toutes les versions d'un chapitre.                   |
| `idx_publications_chapter`   | `publications(chapter_id)`    | Vérifier si un chapitre est publié (déjà couvert par UNIQUE).  |

Les clés primaires et les contraintes UNIQUE bénéficient automatiquement d'un index B-tree. Les index listés ci-dessus complètent ceux générés automatiquement.

---

## 7. Requêtes représentatives commentées

### 7.1 Chapitres d'un projet avec leur auteur (jointure)

```sql
SELECT
    c.chapter_number,
    c.title,
    c.status,
    c.word_count,
    u.username    AS auteur
FROM chapters c
JOIN users u ON u.id = c.author_id
WHERE c.project_id = 1
ORDER BY c.chapter_number;
```

**Intérêt :** illustre le JOIN entre deux tables liées par une clé étrangère, cas d'usage fondamental d'une base relationnelle.

---

### 7.2 Nombre de chapitres par statut (agrégation)

```sql
SELECT
    status,
    COUNT(*) AS nombre_chapitres
FROM chapters
WHERE project_id = 1
GROUP BY status
ORDER BY nombre_chapitres DESC;
```

**Intérêt :** agrégation `GROUP BY` pour un tableau de bord éditorial. Résultat attendu sur le projet 1 : 6 `published`, 5 `approved`, 4 `review`, 5 `draft`.

---

### 7.3 Utilisateurs présents dans plusieurs projets (HAVING)

```sql
SELECT
    u.username,
    COUNT(DISTINCT pm.project_id) AS nb_projets
FROM users u
JOIN project_members pm ON pm.user_id = u.id
GROUP BY u.id, u.username
HAVING COUNT(DISTINCT pm.project_id) > 1
ORDER BY nb_projets DESC;
```

**Intérêt :** montre la puissance du modèle relationnel pour les requêtes d'appartenance multi-entités, difficiles à exprimer proprement sans SQL.

---

### 7.4 Historique des versions d'un chapitre

```sql
SELECT
    cv.version_number,
    cv.content_summary,
    u.username    AS contributeur,
    cv.created_at AS date_version
FROM chapter_versions cv
JOIN users u ON u.id = cv.created_by
WHERE cv.chapter_id = 1
ORDER BY cv.version_number;
```

**Intérêt :** jointure sur trois tables (chapter_versions → users) pour reconstuire l'historique éditorial complet.

---

### 7.5 Publication transactionnelle d'un chapitre

```sql
BEGIN;

    UPDATE chapters
    SET status     = 'published',
        updated_at = NOW()
    WHERE id = 15 AND status = 'approved';

    INSERT INTO publications (chapter_id, published_by, published_at, notes)
    VALUES (15, 3, NOW(), 'Chapitre validé après relecture complète.');

COMMIT;
```

**Intérêt :** démontre la propriété ACID d'une transaction SQL. Si l'une des deux opérations échoue, l'ensemble est annulé. Cela garantit qu'on ne peut jamais avoir un chapitre marqué `published` sans enregistrement correspondant dans `publications`, ni l'inverse.

---

### 7.6 Top 5 des auteurs les plus productifs

```sql
SELECT
    u.username,
    COUNT(c.id)               AS nb_chapitres,
    SUM(c.word_count)         AS mots_total,
    ROUND(AVG(c.word_count))  AS mots_moyens
FROM users u
JOIN chapters c ON c.author_id = u.id
GROUP BY u.id, u.username
ORDER BY nb_chapitres DESC
LIMIT 5;
```

**Intérêt :** agrégation multi-colonnes (`COUNT`, `SUM`, `AVG`) avec classement — cas typique de reporting éditorial.

---

## 8. Cohérence des identifiants entre les bases

L'une des problématiques clés de la persistance polyglotte est d'**éviter la duplication désordonnée** tout en permettant la cohérence entre bases. Dans LoreGraph, la stratégie retenue est l'**identifiant commun partagé** :

| Entité     | PostgreSQL              | MongoDB                          | Neo4j                   |
|------------|-------------------------|----------------------------------|-------------------------|
| Projet     | `projects.id` (1–5)     | `projectId: 1` dans les fiches  | Référence dans Cypher   |
| Chapitre   | `chapters.id` (1–100)   | `appearances[].chapterId`       | Nœud `Chapter` (id 1-100) |
| Utilisateur| `users.id` (1–15)       | Non stocké (seul projectId est partagé) | Non référencé directement |

**Principe :** les bases ne se joignent pas directement — il n'existe pas de requête SQL + MongoDB. C'est l'application qui fait le lien en interrogeant chaque base séparément, en utilisant l'identifiant commun pour relier les résultats. Par exemple, pour afficher un personnage et les métadonnées du chapitre où il apparaît :

1. MongoDB retourne `appearances: [{ chapterId: 4, role: "principal" }]`
2. L'application interroge PostgreSQL : `SELECT title, status FROM chapters WHERE id = 4`
3. Les deux résultats sont assemblés côté application

Ce découplage évite la duplication massive tout en maintenant la cohérence.

---

## 9. Contribution de PostgreSQL au tableau de répartition des données

| Donnée                       | Base choisie  | Justification                                                                         |
|------------------------------|---------------|---------------------------------------------------------------------------------------|
| Comptes utilisateurs         | PostgreSQL    | Schéma fixe, unicité email/username, base de l'authentification.                     |
| Projets narratifs            | PostgreSQL    | Entité centrale avec propriétaire, statut et contraintes relationnelles.             |
| Rôles et permissions         | PostgreSQL    | Association many-to-many avec attribut (rôle), intégrité forte requise.             |
| Chapitres (métadonnées)      | PostgreSQL    | Numérotation ordonnée, cycle de vie éditorial (draft → published), jointures.        |
| Versioning des chapitres     | PostgreSQL    | Historique séquentiel avec auteur — schéma stable, traçabilité.                     |
| Publications officielles     | PostgreSQL    | Enregistrement transactionnel, contrainte d'unicité par chapitre.                   |
| Contenu narratif des chapitres| MongoDB      | Texte riche et variable — pas stocké en SQL pour éviter des colonnes TEXT volumineuses. |
| Fiches personnages/lieux     | MongoDB       | Structure hétérogène selon le type d'entité — schéma flexible.                      |
| Sessions et brouillons       | Redis         | Données volatiles avec expiration automatique (TTL).                                |
| Relations entre personnages  | Neo4j         | Graphe de relations — jointures profondes impossibles efficacement en SQL.          |

---

## 10. Jeu de données

Le script `02_seed.sql` peuple la base avec un jeu de données réaliste et représentatif :

| Table               | Volume    | Détail                                                       |
|---------------------|-----------|--------------------------------------------------------------|
| `users`             | 15        | Noms et e-mails francophones réalistes                       |
| `projects`          | 5         | IDs 1–5, 4 projets actifs et 1 complété                     |
| `project_members`   | 19        | 3 à 4 membres par projet avec des rôles variés              |
| `chapters`          | 100       | IDs 1–100, 20 par projet, statuts distribués                |
| `chapter_versions`  | ~185      | 3 versions pour published, 2 pour approved, 1 pour les autres|
| `publications`      | 30        | 6 publications par projet (chapitres locaux 1–6)            |

**Distribution des statuts de chapitres :**
- 30 chapitres `published` (6 par projet)
- 25 chapitres `approved` (5 par projet)
- 20 chapitres `review` (4 par projet)
- 25 chapitres `draft` (5 par projet)

Cette distribution garantit que toutes les requêtes d'agrégation par statut produisent des résultats non triviaux et défendables à l'oral.
