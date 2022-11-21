SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET row_security = off;

-- Reset configuration parameters
SELECT NULL AS "Reset configuration";

DELETE FROM ir_config_parameter
WHERE key = 'database.enterprise_code';

UPDATE ir_config_parameter
SET value = 'copy'
WHERE key = 'database.expiration_reason'
AND value != 'demo';

UPDATE ir_config_parameter
SET value = CURRENT_DATE + INTERVAL '2 month'
WHERE key = 'database.expiration_date';

DO $$
BEGIN
	UPDATE auth_oauth_provider SET enabled = false;
EXCEPTION WHEN undefined_table THEN
END;
$$;

-- Other objects
SELECT NULL AS "Remove generated assets";

DELETE FROM ir_attachment
WHERE name like '%.assets_%' AND public = true;

SELECT NULL AS "Disable CRON and mailservers";

UPDATE ir_cron SET active = false;
UPDATE ir_cron SET active = true
WHERE id IN (
	SELECT res_id
	FROM ir_model_data
	WHERE model = 'ir.cron'
	AND (
		(module = 'base' AND name = 'autovacuum_job')
	)
);

DO $$
BEGIN
	UPDATE ir_mail_server SET active = false;
	UPDATE mail_template SET mail_server_id = NULL;
EXCEPTION WHEN undefined_table THEN
END;
$$;

-- Force "admin" password
SELECT NULL AS "Reset admin passwords";
UPDATE res_users SET password = 'admin';
