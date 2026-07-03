-- ============================================================
-- LoreGraph — PostgreSQL
-- 01_create.sql : création du schéma relationnel
-- Six tables normalisées avec clés, contraintes et index.
-- ============================================================

-- ----------------------------------------------------------
-- TABLE : users
-- Comptes des auteurs et contributeurs de la plateforme.
-- ----------------------------------------------------------
CREATE TABLE users (
    id            SERIAL       PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- TABLE : projects
-- Projets narratifs (univers fictifs gérés dans LoreGraph).
-- Un projet appartient à un propriétaire (owner_id).
-- La suppression du propriétaire est bloquée tant qu'il
-- possède des projets (ON DELETE RESTRICT).
-- ----------------------------------------------------------
CREATE TABLE projects (
    id          SERIAL       PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    owner_id    INTEGER      NOT NULL
                    REFERENCES users(id) ON DELETE RESTRICT,
    status      VARCHAR(20)  NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'archived', 'completed')),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- TABLE : project_members
-- Table d'association users ↔ projects avec rôle.
-- Clé primaire composite (project_id, user_id) : un
-- utilisateur ne peut avoir qu'un seul rôle par projet.
-- La suppression d'un projet entraîne la suppression de
-- ses membres (ON DELETE CASCADE).
-- ----------------------------------------------------------
CREATE TABLE project_members (
    project_id  INTEGER     NOT NULL
                    REFERENCES projects(id) ON DELETE CASCADE,
    user_id     INTEGER     NOT NULL
                    REFERENCES users(id)    ON DELETE CASCADE,
    role        VARCHAR(20) NOT NULL DEFAULT 'writer'
                    CHECK (role IN ('owner', 'editor', 'writer', 'reader')),
    joined_at   TIMESTAMP   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (project_id, user_id)
);

-- ----------------------------------------------------------
-- TABLE : chapters
-- Chapitres rattachés à un projet. Le numéro de chapitre
-- est unique au sein d'un projet (UNIQUE project_id,
-- chapter_number). Le nombre de mots ne peut pas être
-- négatif (CHECK). La suppression d'un projet supprime
-- ses chapitres (ON DELETE CASCADE). La suppression d'un
-- auteur est bloquée s'il a rédigé des chapitres
-- (ON DELETE RESTRICT).
-- ----------------------------------------------------------
CREATE TABLE chapters (
    id             SERIAL       PRIMARY KEY,
    project_id     INTEGER      NOT NULL
                       REFERENCES projects(id) ON DELETE CASCADE,
    author_id      INTEGER      NOT NULL
                       REFERENCES users(id)    ON DELETE RESTRICT,
    title          VARCHAR(300) NOT NULL,
    chapter_number INTEGER      NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'draft'
                       CHECK (status IN ('draft', 'review', 'approved', 'published')),
    word_count     INTEGER               CHECK (word_count >= 0),
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (project_id, chapter_number)
);

-- ----------------------------------------------------------
-- TABLE : chapter_versions
-- Historique des versions successives d'un chapitre.
-- Une version est identifiée par (chapter_id, version_number).
-- La suppression d'un chapitre supprime toutes ses versions.
-- ----------------------------------------------------------
CREATE TABLE chapter_versions (
    id             SERIAL    PRIMARY KEY,
    chapter_id     INTEGER   NOT NULL
                       REFERENCES chapters(id) ON DELETE CASCADE,
    version_number INTEGER   NOT NULL,
    content_summary TEXT,
    created_by     INTEGER   NOT NULL
                       REFERENCES users(id)    ON DELETE RESTRICT,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (chapter_id, version_number)
);

-- ----------------------------------------------------------
-- TABLE : publications
-- Enregistrement officiel de la publication d'un chapitre.
-- UNIQUE(chapter_id) : un chapitre ne peut être publié
-- qu'une seule fois. La suppression d'un chapitre publié
-- est bloquée (ON DELETE RESTRICT) pour garantir la
-- traçabilité éditoriale.
-- ----------------------------------------------------------
CREATE TABLE publications (
    id           SERIAL    PRIMARY KEY,
    chapter_id   INTEGER   NOT NULL
                     REFERENCES chapters(id) ON DELETE RESTRICT,
    published_by INTEGER   NOT NULL
                     REFERENCES users(id)    ON DELETE RESTRICT,
    published_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notes        TEXT,
    UNIQUE (chapter_id)
);

-- ----------------------------------------------------------
-- INDEX
-- Créés sur les colonnes fréquemment utilisées en filtre
-- ou en jointure pour accélérer les lectures.
-- ----------------------------------------------------------
CREATE INDEX idx_projects_owner        ON projects        (owner_id);
CREATE INDEX idx_project_members_user  ON project_members (user_id);
CREATE INDEX idx_chapters_project      ON chapters        (project_id);
CREATE INDEX idx_chapters_author       ON chapters        (author_id);
CREATE INDEX idx_chapters_status       ON chapters        (status);
CREATE INDEX idx_chapter_versions_chap ON chapter_versions (chapter_id);
CREATE INDEX idx_publications_chapter  ON publications    (chapter_id);
