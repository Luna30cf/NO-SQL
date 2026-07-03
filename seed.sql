INSERT INTO users (id, username, email)
VALUES
    ('user_001', 'karl', 'karl@example.com'),
    ('user_002', 'alice', 'alice@example.com'),
    ('user_003', 'bob', 'bob@example.com')
ON CONFLICT (id) DO NOTHING;