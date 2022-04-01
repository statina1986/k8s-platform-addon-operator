SELECT 'CREATE ROLE db_orders_bpmn_executor NOLOGIN' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'db_orders_bpmn_executor')\gexec ;
GRANT db_orders_bpmn_executor TO postgres ;
SELECT 'CREATE DATABASE orders_bpmn_executor WITH OWNER db_orders_bpmn_executor' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'orders_bpmn_executor')\gexec ;
