-- R__users_permissions.sql
-- Uso principal: grants/permissões
-- Seguro para reexecução no Flyway
-- Usuários criados apenas se não existirem

--------------------------------------------------
-- CREATE USERS (idempotente)
--------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'demo_user'
    ) THEN
        CREATE ROLE demo_user LOGIN PASSWORD 'demo_user' CONNECTION LIMIT 10;
    END IF;
END $$;

ALTER ROLE demo_user SET statement_timeout = 10000;


DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'api_user'
    ) THEN
        CREATE ROLE api_user LOGIN PASSWORD 'userapi';
    END IF;
END $$;


DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'noharmcare'
    ) THEN
        CREATE ROLE noharmcare LOGIN PASSWORD 'noharmcare';
    END IF;
END $$;

--------------------------------------------------
-- DATABASE ACCESS
--------------------------------------------------

GRANT CONNECT ON DATABASE postgres TO demo_user;

--------------------------------------------------
-- DEMO_USER
--------------------------------------------------

GRANT USAGE ON SCHEMA demo TO demo_user;

GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA demo
TO demo_user;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA demo
TO demo_user;

GRANT SELECT
ON TABLE demo.usuario,
         demo.prescricao_audit,
         demo.presmed_audit
TO demo_user;

GRANT DELETE
ON TABLE demo.checkedindex
TO demo_user;

GRANT INSERT
ON TABLE public.bulletin,
         demo.prescricao_audit,
         demo.presmed_audit
TO demo_user;

GRANT USAGE, SELECT
ON SEQUENCE public.bulletin_idbulletin_seq
TO demo_user;

--------------------------------------------------
-- API_USER
--------------------------------------------------

GRANT USAGE ON SCHEMA demo TO api_user;

GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA demo
TO api_user;

GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA demo
TO api_user;

GRANT SELECT
ON TABLE demo.usuario
TO api_user;

GRANT DELETE
ON TABLE demo.segmentosetor,
         demo.outlier
TO api_user;

GRANT SELECT, INSERT, DELETE
ON TABLE demo.checkedindex
TO api_user;

GRANT SELECT, UPDATE, INSERT, DELETE
ON TABLE demo.prescricaoagg
TO api_user;

--------------------------------------------------
-- DEFAULT PRIVILEGES (recomendado)
-- Novas tabelas futuras já herdam grants
--------------------------------------------------

ALTER DEFAULT PRIVILEGES IN SCHEMA demo
GRANT SELECT, INSERT, UPDATE ON TABLES TO demo_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA demo
GRANT USAGE, SELECT ON SEQUENCES TO demo_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA demo
GRANT SELECT, INSERT, UPDATE ON TABLES TO api_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA demo
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO api_user;