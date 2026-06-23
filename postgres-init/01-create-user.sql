-- This script runs automatically when the PostgreSQL container starts.
-- It ensures the photoalbum database and user exist for local development.
-- NOTE: For Azure Database for PostgreSQL the application uses passwordless
-- (managed identity) authentication; this script is only for local Docker usage.

-- Create the photoalbum role if it does not already exist
DO
$$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'photoalbum') THEN
      CREATE ROLE photoalbum LOGIN PASSWORD 'photoalbum';
   END IF;
END
$$;

-- Grant privileges on the current database to the photoalbum role
GRANT ALL PRIVILEGES ON DATABASE photoalbum TO photoalbum;
GRANT ALL ON SCHEMA public TO photoalbum;
