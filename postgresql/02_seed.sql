-- ============================================================
-- LoreGraph — PostgreSQL
-- 02_seed.sql : jeu de données de démonstration
--
-- Contenu :
--   • 15 utilisateurs
--   • 5 projets (IDs 1-5, partagés avec MongoDB et Neo4j)
--   • ~15 membres de projet
--   • 100 chapitres (IDs 1-100, partagés avec MongoDB et Neo4j)
--   • ~185 versions de chapitres
--   • 30 publications (chapitres au statut 'published')
-- ============================================================


-- ----------------------------------------------------------
-- 1. UTILISATEURS (15)
-- Les IDs explicites (OVERRIDING SYSTEM VALUE) garantissent
-- la cohérence avec les références MongoDB / Neo4j.
-- ----------------------------------------------------------
INSERT INTO users (id, username, email, password_hash, created_at)
OVERRIDING SYSTEM VALUE
VALUES
    (1,  'alice_morel',    'alice.morel@lorebook.fr',    '$2b$10$hash_alice',    '2024-01-10 08:00:00'),
    (2,  'ben_lacroix',    'ben.lacroix@lorebook.fr',    '$2b$10$hash_ben',      '2024-01-12 09:15:00'),
    (3,  'camille_dupont', 'camille.dupont@lorebook.fr', '$2b$10$hash_camille',  '2024-01-15 10:30:00'),
    (4,  'damien_renaud',  'damien.renaud@lorebook.fr',  '$2b$10$hash_damien',   '2024-01-18 11:00:00'),
    (5,  'elise_martin',   'elise.martin@lorebook.fr',   '$2b$10$hash_elise',    '2024-01-20 14:00:00'),
    (6,  'felix_gautier',  'felix.gautier@lorebook.fr',  '$2b$10$hash_felix',    '2024-02-01 09:00:00'),
    (7,  'gaelle_bernard', 'gaelle.bernard@lorebook.fr', '$2b$10$hash_gaelle',   '2024-02-05 10:00:00'),
    (8,  'hugo_lambert',   'hugo.lambert@lorebook.fr',   '$2b$10$hash_hugo',     '2024-02-08 11:00:00'),
    (9,  'iris_petit',     'iris.petit@lorebook.fr',     '$2b$10$hash_iris',     '2024-02-10 13:00:00'),
    (10, 'julien_moreau',  'julien.moreau@lorebook.fr',  '$2b$10$hash_julien',   '2024-02-15 14:00:00'),
    (11, 'karine_simon',   'karine.simon@lorebook.fr',   '$2b$10$hash_karine',   '2024-02-20 09:30:00'),
    (12, 'leo_fontaine',   'leo.fontaine@lorebook.fr',   '$2b$10$hash_leo',      '2024-02-22 10:00:00'),
    (13, 'mia_blanc',      'mia.blanc@lorebook.fr',      '$2b$10$hash_mia',      '2024-03-01 08:30:00'),
    (14, 'noel_pierre',    'noel.pierre@lorebook.fr',    '$2b$10$hash_noel',     '2024-03-05 09:00:00'),
    (15, 'olivia_roux',    'olivia.roux@lorebook.fr',    '$2b$10$hash_olivia',   '2024-03-10 10:00:00');

SELECT setval('users_id_seq', 15, true);


-- ----------------------------------------------------------
-- 2. PROJETS (5)
-- IDs 1-5 : référencés dans MongoDB (projectId) et Neo4j.
-- ----------------------------------------------------------
INSERT INTO projects (id, title, description, owner_id, status, created_at, updated_at)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Les Chroniques de Valcor',
        'Saga médiévale-fantastique suivant la chute et le rétablissement du royaume de Valcor à travers les yeux du prince déchu Aelric.',
        1, 'active',     '2024-01-20 10:00:00', '2025-03-15 16:00:00'),

    (2, 'L''Ère des Ombres',
        'Récit dystopique dans un monde où la magie des ombres a étouffé toute lumière. Une résistance tente de briser l''emprise des Silencieux.',
        2, 'active',     '2024-02-10 11:00:00', '2025-04-01 14:00:00'),

    (3, 'Le Cycle de Nirvath',
        'Épopée de science-fantasy centrée sur la redécouverte des cristaux de Nirvath et la guerre entre les tribus qui en dépendent.',
        3, 'active',     '2024-03-01 09:00:00', '2025-04-20 11:00:00'),

    (4, 'Au-delà du Voile',
        'Thriller fantastique explorant un monde parallèle accessible à travers un voile dimensionnel. Quatre explorateurs tentent de rentrer chez eux.',
        4, 'completed',  '2024-03-15 08:00:00', '2025-02-28 17:00:00'),

    (5, 'La Dernière Flamme',
        'Roman d''apprentissage magique : une pyromancienne découvre qu''elle est la dernière gardienne d''un feu sacré que le monde croyait éteint.',
        5, 'active',     '2024-04-01 10:00:00', '2025-05-10 12:00:00');

SELECT setval('projects_id_seq', 5, true);


-- ----------------------------------------------------------
-- 3. MEMBRES DES PROJETS
-- Chaque projet a 3-4 membres avec des rôles distincts.
-- Permet de tester les jointures multi-tables et les
-- requêtes de contrôle d'accès.
-- ----------------------------------------------------------
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES
    -- Projet 1 : Les Chroniques de Valcor
    (1,  1, 'owner',  '2024-01-20 10:00:00'),  -- alice_morel
    (1,  2, 'editor', '2024-01-22 11:00:00'),  -- ben_lacroix
    (1,  6, 'writer', '2024-01-25 09:00:00'),  -- felix_gautier
    (1, 11, 'reader', '2024-02-01 14:00:00'),  -- karine_simon (lectrice)

    -- Projet 2 : L'Ère des Ombres
    (2,  2, 'owner',  '2024-02-10 11:00:00'),  -- ben_lacroix
    (2,  3, 'editor', '2024-02-12 10:00:00'),  -- camille_dupont
    (2,  7, 'writer', '2024-02-15 09:00:00'),  -- gaelle_bernard
    (2, 12, 'writer', '2024-02-20 13:00:00'),  -- leo_fontaine

    -- Projet 3 : Le Cycle de Nirvath
    (3,  3, 'owner',  '2024-03-01 09:00:00'),  -- camille_dupont
    (3,  4, 'editor', '2024-03-03 10:00:00'),  -- damien_renaud
    (3,  8, 'writer', '2024-03-05 11:00:00'),  -- hugo_lambert
    (3, 13, 'reader', '2024-03-10 14:00:00'),  -- mia_blanc (lectrice)

    -- Projet 4 : Au-delà du Voile
    (4,  4, 'owner',  '2024-03-15 08:00:00'),  -- damien_renaud
    (4,  5, 'editor', '2024-03-17 09:00:00'),  -- elise_martin
    (4,  9, 'writer', '2024-03-20 10:00:00'),  -- iris_petit

    -- Projet 5 : La Dernière Flamme
    (5,  5, 'owner',  '2024-04-01 10:00:00'),  -- elise_martin
    (5, 10, 'editor', '2024-04-03 11:00:00'),  -- julien_moreau
    (5, 14, 'writer', '2024-04-05 09:00:00'),  -- noel_pierre
    (5, 15, 'writer', '2024-04-10 13:00:00');  -- olivia_roux

-- alice_morel est aussi membre lectrice du projet 5
-- (illustre un utilisateur présent dans plusieurs projets)
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES (5, 1, 'reader', '2024-04-15 10:00:00');  -- alice_morel


-- ----------------------------------------------------------
-- 4. CHAPITRES (100)
-- IDs 1-100 : référencés dans MongoDB (appearances.chapterId)
-- et Neo4j (noeuds Chapter). Distribution par projet :
--   Projet 1 : chapitres  1-20
--   Projet 2 : chapitres 21-40
--   Projet 3 : chapitres 41-60
--   Projet 4 : chapitres 61-80
--   Projet 5 : chapitres 81-100
--
-- Distribution des statuts par projet (20 chapitres chacun) :
--   Chapitres locaux  1- 6 → 'published'
--   Chapitres locaux  7-11 → 'approved'
--   Chapitres locaux 12-15 → 'review'
--   Chapitres locaux 16-20 → 'draft'
-- ----------------------------------------------------------
DO $$
DECLARE
    v_proj_idx     INT;
    v_local        INT;
    v_global_id    INT;
    v_status       VARCHAR(20);
    v_words        INT;
    v_author       INT;
    v_created      TIMESTAMP;
    v_updated      TIMESTAMP;

    -- Auteurs par projet : [propriétaire, co-auteur 1, co-auteur 2]
    -- Index : v_authors[proj_idx][pos]
    v_authors      INT[][] := ARRAY[
        ARRAY[1,  2,  6],   -- projet 1 : alice, ben, felix
        ARRAY[2,  3,  7],   -- projet 2 : ben, camille, gaelle
        ARRAY[3,  4,  8],   -- projet 3 : camille, damien, hugo
        ARRAY[4,  5,  9],   -- projet 4 : damien, elise, iris
        ARRAY[5, 10, 14]    -- projet 5 : elise, julien, noel
    ];

    -- Sous-titres narratifs communs aux 20 positions (1 → 20)
    v_subtitles    TEXT[] := ARRAY[
        'Les origines',          -- 1
        'Le premier pas',        -- 2
        'La révélation',         -- 3
        'L''éveil',              -- 4
        'Les anciens',           -- 5
        'La chute',              -- 6
        'L''alliance',           -- 7
        'La trahison',           -- 8
        'Le sacrifice',          -- 9
        'L''espoir brisé',       -- 10
        'L''obscurité',          -- 11
        'La quête',              -- 12
        'Le retour',             -- 13
        'La confrontation',      -- 14
        'L''abîme',              -- 15
        'La renaissance',        -- 16
        'La dernière chance',    -- 17
        'Le combat',             -- 18
        'L''apothéose',          -- 19
        'L''épilogue'            -- 20
    ];

    -- Préfixes de titre par projet
    v_proj_labels  TEXT[] := ARRAY[
        'Chroniques de Valcor',
        'L''Ère des Ombres',
        'Le Cycle de Nirvath',
        'Au-delà du Voile',
        'La Dernière Flamme'
    ];
BEGIN
    FOR v_proj_idx IN 1..5 LOOP
        FOR v_local IN 1..20 LOOP
            v_global_id := (v_proj_idx - 1) * 20 + v_local;

            -- Statut et nombre de mots selon la position dans le projet
            IF v_local <= 6 THEN
                v_status := 'published';
                v_words  := 3500 + (v_global_id * 127) % 2000;
            ELSIF v_local <= 11 THEN
                v_status := 'approved';
                v_words  := 2500 + (v_global_id * 113) % 1500;
            ELSIF v_local <= 15 THEN
                v_status := 'review';
                v_words  := 1500 + (v_global_id * 97)  % 1500;
            ELSE
                v_status := 'draft';
                v_words  := 500  + (v_global_id * 73)  % 1200;
            END IF;

            -- Rotation des auteurs parmi les 3 membres rédacteurs du projet
            v_author := v_authors[v_proj_idx][((v_local - 1) % 3) + 1];

            -- Horodatages progressifs et cohérents
            v_created := NOW() - INTERVAL '1 day' * (365 - v_global_id * 3);
            v_updated := v_created + INTERVAL '1 day' * (v_local % 10 + 2);

            INSERT INTO chapters (
                id, project_id, author_id,
                title, chapter_number,
                status, word_count,
                created_at, updated_at
            )
            OVERRIDING SYSTEM VALUE
            VALUES (
                v_global_id,
                v_proj_idx,
                v_author,
                'Chapitre ' || v_local || ' — ' || v_subtitles[v_local],
                v_local,
                v_status,
                v_words,
                v_created,
                v_updated
            );
        END LOOP;
    END LOOP;

    -- Correction de la séquence après insertions explicites
    PERFORM setval('chapters_id_seq', 100, true);
END;
$$;


-- ----------------------------------------------------------
-- 5. VERSIONS DES CHAPITRES (~185 enregistrements)
-- Nombre de versions selon le statut :
--   published → 3 versions
--   approved  → 2 versions
--   review    → 1 version
--   draft     → 1 version
-- ----------------------------------------------------------
DO $$
DECLARE
    v_chap_id      INT;
    v_status       VARCHAR(20);
    v_max_ver      INT;
    v_author_id    INT;
    v_created_at   TIMESTAMP;

    v_summaries    TEXT[] := ARRAY[
        'Première ébauche — structure initiale rédigée',
        'Révision intermédiaire — dialogues enrichis et rythme corrigé',
        'Version finale — relecture complète et validation éditoriale'
    ];
BEGIN
    FOR v_chap_id IN 1..100 LOOP
        SELECT status, author_id, created_at
            INTO v_status, v_author_id, v_created_at
        FROM chapters WHERE id = v_chap_id;

        CASE v_status
            WHEN 'published' THEN v_max_ver := 3;
            WHEN 'approved'  THEN v_max_ver := 2;
            ELSE                  v_max_ver := 1;
        END CASE;

        FOR v_ver_num IN 1..v_max_ver LOOP
            INSERT INTO chapter_versions (
                chapter_id, version_number,
                content_summary, created_by, created_at
            )
            VALUES (
                v_chap_id,
                v_ver_num,
                v_summaries[v_ver_num],
                v_author_id,
                v_created_at + (v_ver_num * INTERVAL '7 days')
            );
        END LOOP;
    END LOOP;
END;
$$;


-- ----------------------------------------------------------
-- 6. PUBLICATIONS (30 enregistrements)
-- Uniquement pour les chapitres au statut 'published'.
-- Le responsable de publication est le propriétaire du projet.
-- ----------------------------------------------------------
DO $$
DECLARE
    v_chap_id      INT;
    v_publisher    INT;
    v_updated_at   TIMESTAMP;
BEGIN
    FOR v_chap_id IN 1..100 LOOP
        -- Ne traiter que les chapitres publiés
        IF NOT EXISTS (
            SELECT 1 FROM chapters WHERE id = v_chap_id AND status = 'published'
        ) THEN
            CONTINUE;
        END IF;

        -- Propriétaire du projet = responsable de publication
        SELECT pm.user_id, c.updated_at
            INTO v_publisher, v_updated_at
        FROM chapters c
        JOIN project_members pm ON pm.project_id = c.project_id
                                AND pm.role = 'owner'
        WHERE c.id = v_chap_id
        LIMIT 1;

        INSERT INTO publications (chapter_id, published_by, published_at, notes)
        VALUES (
            v_chap_id,
            v_publisher,
            v_updated_at + INTERVAL '2 days',
            'Publication officielle — chapitre relu et validé par l''équipe éditoriale.'
        );
    END LOOP;
END;
$$;
