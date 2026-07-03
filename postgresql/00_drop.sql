-- ============================================================
-- LoreGraph — PostgreSQL
-- 00_drop.sql : suppression de toutes les tables
-- Exécuter avant de relancer 01_create.sql pour repartir d'un état vide.
-- ============================================================

DROP TABLE IF EXISTS publications       CASCADE;
DROP TABLE IF EXISTS chapter_versions   CASCADE;
DROP TABLE IF EXISTS chapters           CASCADE;
DROP TABLE IF EXISTS project_members    CASCADE;
DROP TABLE IF EXISTS projects           CASCADE;
DROP TABLE IF EXISTS users              CASCADE;
