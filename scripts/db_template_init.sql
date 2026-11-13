-- Alter the template0
-- install required extensions
ALTER DATABASE template0 ALLOW_CONNECTIONS true;
\connect template0
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
ALTER FUNCTION unaccent(text) IMMUTABLE; -- for odoo indexes
-- the following may fail if the extension is not availble
-- but it does not prevent the container from starting
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
\connect template1
ALTER DATABASE template0 ALLOW_CONNECTIONS false;
