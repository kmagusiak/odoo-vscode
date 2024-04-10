SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET row_security = off;

-- Reset configuration parameters
SELECT NULL AS "Reset configuration";

UPDATE ir_config_parameter
SET value = CURRENT_DATE + INTERVAL '2 month'
WHERE key = 'database.expiration_date';

-- Force "admin" password
SELECT NULL AS "Reset admin passwords";
UPDATE res_users SET password = 'admin';
-- Reset totp_secret (2FA) if it exists
DO $$
BEGIN
	UPDATE res_users SET totp_secret = null;
EXCEPTION WHEN OTHERS THEN
	NULL;
END;
$$;
