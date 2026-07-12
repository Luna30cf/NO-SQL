INSERT INTO users (id, username, email)
VALUES
    ('user_001', 'karl', 'karl@example.com'),
    ('user_002', 'alice', 'alice@example.com'),
    ('user_003', 'bob', 'bob@example.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO projects (id, title, owner_id, description)
VALUES
    (
        'project_001',
        'Les Chroniques de Valcor',
        'user_001',
        'Univers de fantasy politique autour du retour du prince exilé Aelric.'
    )
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    owner_id = EXCLUDED.owner_id,
    description = EXCLUDED.description;

INSERT INTO project_members (project_id, user_id, role)
VALUES
    ('project_001', 'user_001', 'owner'),
    ('project_001', 'user_002', 'editor'),
    ('project_001', 'user_003', 'reader')
ON CONFLICT (project_id, user_id) DO UPDATE SET
    role = EXCLUDED.role;

INSERT INTO chapters (
    id,
    project_id,
    author_id,
    title,
    chapter_number,
    status
)
VALUES
    (
        'chapter_001',
        'project_001',
        'user_001',
        'Le retour d''Aelric',
        1,
        'draft'
    ),
    (
        'chapter_002',
        'project_001',
        'user_002',
        'Le conseil secret',
        2,
        'review'
    )
ON CONFLICT (id) DO UPDATE SET
    project_id = EXCLUDED.project_id,
    author_id = EXCLUDED.author_id,
    title = EXCLUDED.title,
    chapter_number = EXCLUDED.chapter_number,
    status = EXCLUDED.status;

INSERT INTO chapter_versions (
    chapter_id,
    version_number,
    content,
    created_by
)
VALUES
    (
        'chapter_001',
        1,
        'Le vent froid descendait des Monts Noirs lorsque Aelric franchit les portes de Valcor.',
        'user_001'
    ),
    (
        'chapter_002',
        1,
        'Dans les profondeurs de la Citadelle d''Onyx, le conseil se réunit en secret.',
        'user_002'
    )
ON CONFLICT (chapter_id, version_number) DO NOTHING;
