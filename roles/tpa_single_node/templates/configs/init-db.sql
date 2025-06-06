-- ensure we have the database
SELECT 'CREATE DATABASE ' || :'db_name'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'db_name')\gexec

-- create the user (if it doesn't exist)
CREATE OR REPLACE FUNCTION add_user_if_not_exists(username NAME) RETURNS integer
    AS $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles
        WHERE rolname = username) THEN

        EXECUTE FORMAT('CREATE ROLE "%I" LOGIN', username);

    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

SELECT add_user_if_not_exists(:'db_user');

-- now set the password
ALTER USER :db_user WITH PASSWORD :'db_password';

-- grant permission to connect
GRANT CONNECT ON DATABASE :db_name TO :db_user;

-- grant permissions on database
\connect :db_name

GRANT USAGE ON SCHEMA public TO :db_user;

-- grant on existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO :db_user;

-- grant on future tables
ALTER DEFAULT PRIVILEGES
    IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :db_user;

