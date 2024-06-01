-- https://pgtune.leopard.in.ua/
-- Example postgres configuration for development
--
-- Adapted for development from
-- OS Type: linux
-- DB Type: oltp
-- Total Memory (RAM): 8 GB
-- CPUs num: 12
-- Data Storage: ssd

-- ALTER SYSTEM SET max_connections = '300';
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
-- ALTER SYSTEM SET checkpoint_completion_target = '0.9';
ALTER SYSTEM SET wal_buffers = '16MB';
-- ALTER SYSTEM SET default_statistics_target = '100';
ALTER SYSTEM SET random_page_cost = '1.5';
ALTER SYSTEM SET effective_io_concurrency = '1';
ALTER SYSTEM SET work_mem = '2MB';
-- ALTER SYSTEM SET huge_pages = 'off';
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET max_worker_processes = '12';
ALTER SYSTEM SET max_parallel_workers_per_gather = '4';
ALTER SYSTEM SET max_parallel_workers = '12';
ALTER SYSTEM SET max_parallel_maintenance_workers = '4';
