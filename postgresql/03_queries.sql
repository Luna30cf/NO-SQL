-- ============================================================
-- LoreGraph — PostgreSQL
-- 03_queries.sql : requêtes représentatives
--
-- Sections :
--   1. CREATE — Insertions
--   2. READ   — Sélections, filtres, tris
--   3. READ   — Jointures multi-tables
--   4. READ   — Agrégations et statistiques
--   5. UPDATE — Mises à jour
--   6. DELETE — Suppressions
--   7. Transactions
-- ============================================================


-- ============================================================
-- SECTION 1 — CREATE : insertions
-- ============================================================

-- [C-1] Créer un nouvel utilisateur
INSERT INTO users (username, email, password_hash)
VALUES ('thomas_vidal', 'thomas.vidal@lorebook.fr', '$2b$10$hash_thomas');

-- [C-2] Créer un nouveau projet narratif
INSERT INTO projects (title, description, owner_id, status)
VALUES (
    'Le Miroir des Âges',
    'Un alchimiste découvre un miroir capable de traverser le temps.',
    1,
    'active'
);

-- [C-3] Ajouter un membre à un projet existant
INSERT INTO project_members (project_id, user_id, role)
VALUES (1, 15, 'writer');

-- [C-4] Créer un nouveau chapitre dans un projet
INSERT INTO chapters (project_id, author_id, title, chapter_number, status, word_count)
VALUES (1, 1, 'Chapitre 21 — Le secret des ruines', 21, 'draft', 1200);

-- [C-5] Enregistrer une version d'un chapitre
INSERT INTO chapter_versions (chapter_id, version_number, content_summary, created_by)
VALUES (1, 1, 'Première ébauche — trame narrative posée.', 1);


-- ============================================================
-- SECTION 2 — READ : sélections simples, filtres et tris
-- ============================================================

-- [R-1] Liste de tous les utilisateurs (ordre alphabétique)
SELECT id, username, email, created_at
FROM users
ORDER BY username;

-- [R-2] Projets actifs triés par date de création
SELECT id, title, status, created_at
FROM projects
WHERE status = 'active'
ORDER BY created_at;

-- [R-3] Chapitres d'un projet donnés, triés par numéro
-- (exemple : projet 1 - Les Chroniques de Valcor)
SELECT id, chapter_number, title, status, word_count, updated_at
FROM chapters
WHERE project_id = 1
ORDER BY chapter_number;

-- [R-4] Chapitres au statut 'review' (en attente de validation)
SELECT c.id, c.title, c.project_id, c.updated_at
FROM chapters c
WHERE c.status = 'review'
ORDER BY c.updated_at;

-- [R-5] Chapitres publiés avec leur date de publication
SELECT c.id, c.title, p.published_at
FROM chapters c
JOIN publications p ON p.chapter_id = c.id
ORDER BY p.published_at DESC;


-- ============================================================
-- SECTION 3 — READ : jointures multi-tables
-- ============================================================

-- [J-1] Liste des chapitres d'un projet avec leur auteur
-- (réponse directe au cas d'usage du sujet)
SELECT
    c.chapter_number,
    c.title,
    c.status,
    c.word_count,
    u.username    AS auteur,
    c.updated_at  AS derniere_modification
FROM chapters c
JOIN users u ON u.id = c.author_id
WHERE c.project_id = 1
ORDER BY c.chapter_number;

-- [J-2] Membres d'un projet avec leur rôle et leur email
SELECT
    u.username,
    u.email,
    pm.role,
    pm.joined_at
FROM project_members pm
JOIN users u ON u.id = pm.user_id
WHERE pm.project_id = 2
ORDER BY pm.role, u.username;

-- [J-3] Projets avec leur propriétaire (nom d'utilisateur)
SELECT
    p.id,
    p.title,
    p.status,
    u.username AS proprietaire,
    p.created_at
FROM projects p
JOIN users u ON u.id = p.owner_id
ORDER BY p.created_at;

-- [J-4] Historique complet des versions d'un chapitre
-- avec le nom du contributeur
SELECT
    cv.version_number,
    cv.content_summary,
    u.username    AS contributeur,
    cv.created_at AS date_version
FROM chapter_versions cv
JOIN users u ON u.id = cv.created_by
WHERE cv.chapter_id = 1
ORDER BY cv.version_number;

-- [J-5] Chapitres publiés avec détail de publication
-- (projet, auteur, responsable de publication)
SELECT
    p.title          AS projet,
    c.chapter_number AS num,
    c.title          AS chapitre,
    u_author.username  AS auteur,
    u_pub.username     AS publie_par,
    pub.published_at   AS date_publication
FROM publications pub
JOIN chapters c         ON c.id    = pub.chapter_id
JOIN projects p         ON p.id    = c.project_id
JOIN users u_author     ON u_author.id = c.author_id
JOIN users u_pub        ON u_pub.id    = pub.published_by
ORDER BY p.title, c.chapter_number;

-- [J-6] Utilisateurs appartenant à plusieurs projets
-- avec tous leurs rôles (requête multi-jointure)
SELECT
    u.username,
    p.title  AS projet,
    pm.role,
    pm.joined_at
FROM users u
JOIN project_members pm ON pm.user_id    = u.id
JOIN projects        p  ON p.id          = pm.project_id
WHERE u.id IN (
    SELECT user_id
    FROM project_members
    GROUP BY user_id
    HAVING COUNT(DISTINCT project_id) > 1
)
ORDER BY u.username, p.title;

-- [J-7] Dernière version de chaque chapitre (sous-requête corrélée)
SELECT
    c.id,
    c.title,
    c.status,
    cv.version_number    AS derniere_version,
    cv.content_summary,
    cv.created_at        AS date_derniere_version
FROM chapters c
JOIN chapter_versions cv ON cv.chapter_id = c.id
WHERE cv.version_number = (
    SELECT MAX(version_number)
    FROM chapter_versions
    WHERE chapter_id = c.id
)
ORDER BY c.id;


-- ============================================================
-- SECTION 4 — READ : agrégations et statistiques
-- ============================================================

-- [A-1] Nombre de chapitres par statut dans un projet
-- (cas d'usage explicitement mentionné dans le sujet)
SELECT
    status,
    COUNT(*) AS nombre_chapitres
FROM chapters
WHERE project_id = 1
GROUP BY status
ORDER BY nombre_chapitres DESC;

-- [A-2] Nombre de mots moyen et total par projet
SELECT
    p.title                           AS projet,
    COUNT(c.id)                       AS nb_chapitres,
    ROUND(AVG(c.word_count))          AS mots_moyens,
    SUM(c.word_count)                 AS mots_total
FROM projects p
JOIN chapters c ON c.project_id = p.id
GROUP BY p.id, p.title
ORDER BY mots_total DESC;

-- [A-3] Utilisateurs appartenant à plusieurs projets (HAVING)
SELECT
    u.username,
    COUNT(DISTINCT pm.project_id) AS nb_projets
FROM users u
JOIN project_members pm ON pm.user_id = u.id
GROUP BY u.id, u.username
HAVING COUNT(DISTINCT pm.project_id) > 1
ORDER BY nb_projets DESC;

-- [A-4] Top 5 des auteurs les plus productifs (en nombre de chapitres)
SELECT
    u.username                AS auteur,
    COUNT(c.id)               AS nb_chapitres,
    SUM(c.word_count)         AS mots_total,
    ROUND(AVG(c.word_count))  AS mots_moyens
FROM users u
JOIN chapters c ON c.author_id = u.id
GROUP BY u.id, u.username
ORDER BY nb_chapitres DESC
LIMIT 5;

-- [A-5] Nombre de chapitres par statut — tous projets confondus
SELECT
    status,
    COUNT(*)                         AS nb_chapitres,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pourcentage
FROM chapters
GROUP BY status
ORDER BY nb_chapitres DESC;

-- [A-6] Statistiques de publication par projet
SELECT
    p.title                    AS projet,
    COUNT(c.id)                AS total_chapitres,
    COUNT(pub.id)              AS chapitres_publies,
    MAX(pub.published_at)      AS derniere_publication
FROM projects p
LEFT JOIN chapters     c   ON c.project_id   = p.id
LEFT JOIN publications pub ON pub.chapter_id  = c.id
GROUP BY p.id, p.title
ORDER BY chapitres_publies DESC;

-- [A-7] Répartition des rôles sur l'ensemble de la plateforme
SELECT
    role,
    COUNT(*) AS occurrences
FROM project_members
GROUP BY role
ORDER BY occurrences DESC;


-- ============================================================
-- SECTION 5 — UPDATE : mises à jour
-- ============================================================

-- [U-1] Passer un chapitre de 'review' à 'approved'
UPDATE chapters
SET status     = 'approved',
    updated_at = NOW()
WHERE id = 12;

-- [U-2] Corriger le nombre de mots après réécriture
UPDATE chapters
SET word_count = 4200,
    updated_at = NOW()
WHERE id = 7;

-- [U-3] Changer le rôle d'un membre dans un projet
UPDATE project_members
SET role = 'editor'
WHERE project_id = 1 AND user_id = 6;

-- [U-4] Archiver un projet terminé
UPDATE projects
SET status     = 'archived',
    updated_at = NOW()
WHERE id = 4;


-- ============================================================
-- SECTION 6 — DELETE : suppressions
-- ============================================================

-- [D-1] Retirer un membre d'un projet (sans supprimer l'utilisateur)
DELETE FROM project_members
WHERE project_id = 1 AND user_id = 11;

-- [D-2] Supprimer un chapitre en brouillon (et toutes ses versions
-- via ON DELETE CASCADE sur chapter_versions)
DELETE FROM chapters
WHERE id = 20 AND status = 'draft';

-- [D-3] Supprimer un utilisateur fictif ajouté en [C-1]
-- (n'est membre d'aucun projet, n'a rédigé aucun chapitre)
DELETE FROM users
WHERE username = 'thomas_vidal';


-- ============================================================
-- SECTION 7 — TRANSACTIONS
-- ============================================================

-- [T-1] Publication officielle d'un chapitre
-- Opération atomique : mise à jour du statut + enregistrement
-- de la publication. Si l'une des deux requêtes échoue,
-- l'ensemble est annulé (ROLLBACK automatique).
BEGIN;

    UPDATE chapters
    SET status     = 'published',
        updated_at = NOW()
    WHERE id = 15 AND status = 'approved';

    INSERT INTO publications (chapter_id, published_by, published_at, notes)
    VALUES (15, 3, NOW(), 'Publication validée après cycle de relecture complet.');

COMMIT;


-- [T-2] Transfert de propriété d'un projet
-- Scénario : alice_morel (user 1) cède son projet 1
-- à ben_lacroix (user 2).
BEGIN;

    -- Mettre à jour le propriétaire dans la table projects
    UPDATE projects
    SET owner_id   = 2,
        updated_at = NOW()
    WHERE id = 1;

    -- Mettre à jour le rôle de l'ancien propriétaire → editor
    UPDATE project_members
    SET role = 'editor'
    WHERE project_id = 1 AND user_id = 1;

    -- Mettre à jour le rôle du nouveau propriétaire → owner
    UPDATE project_members
    SET role = 'owner'
    WHERE project_id = 1 AND user_id = 2;

COMMIT;


-- [T-3] Ajout d'un membre avec vérification préalable
-- Scénario : on ajoute un utilisateur en tant que writer
-- seulement s'il n'est pas déjà membre du projet.
BEGIN;

    INSERT INTO project_members (project_id, user_id, role)
    SELECT 3, 15, 'writer'
    WHERE NOT EXISTS (
        SELECT 1 FROM project_members
        WHERE project_id = 3 AND user_id = 15
    );

COMMIT;
