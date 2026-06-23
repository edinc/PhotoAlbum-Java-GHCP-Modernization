# Modernization Summary — 002-transform-oracle-to-postgresql

## Final Status
**finalStatus:** success

## Success Criteria Status
| Criterion | Result |
|-----------|--------|
| passBuild | true |
| generateNewUnitTests | false |
| passUnitTests | true |

## Overview
Migrated the database layer of the Photo Album Spring Boot application from Oracle
Database to Azure Database for PostgreSQL, using passwordless (managed identity)
authentication. Project-specific guidance from
`.github/postgres-migrations/results/application_guidance/coding_notes.md` was applied
(NUMBER → bigint, sequence/identity handling).

## Changes Made

### Build (`pom.xml`)
- Removed the Oracle JDBC driver (`com.oracle.database.jdbc:ojdbc11`).
- Added `org.postgresql:postgresql` (managed by Spring Boot BOM).
- Added `spring-cloud-azure-dependencies` BOM `5.22.0` (compatible with Spring Boot 3.5.x).
- Added `com.azure.spring:spring-cloud-azure-starter-jdbc-postgresql` for passwordless auth.
- Updated project description to reference PostgreSQL.

### Configuration (`application.properties`, `application-docker.properties`)
- Replaced Oracle JDBC URL/driver with the Azure PostgreSQL JDBC URL using
  environment variables and `sslmode=require`.
- Removed datasource password; kept username as the managed identity name.
- Enabled `spring.datasource.azure.passwordless-enabled=true` and
  `spring.cloud.azure.credential.managed-identity-enabled=true`.
- Changed Hibernate dialect `OracleDialect` → `PostgreSQLDialect`.
- Added comments for service-principal auth and Azure sovereign cloud deployment.

### Entity (`Photo.java`)
- `columnDefinition = "NUMBER(19,0)"` → `"bigint"`.
- `columnDefinition = "TIMESTAMP DEFAULT SYSTIMESTAMP"` → `"timestamp DEFAULT CURRENT_TIMESTAMP"`.

### Repository (`PhotoRepository.java`) — native SQL conversions
- `ROWNUM <= 10` subquery → `LIMIT 10`.
- `NVL(...)` → `COALESCE(...)`.
- Oracle ROWNUM range pagination → `LIMIT (:endRow - :startRow + 1) OFFSET (:startRow - 1)`.
- `TO_CHAR` and window functions (`RANK() OVER`, `SUM() OVER`) retained (valid in PostgreSQL).
- Identifiers lowercased; SQL keywords kept uppercase per skill guidance.

### Service/Controller
- Updated Oracle references in comments and log messages to PostgreSQL.

### Support Files
- Replaced the Oracle DB service in `docker-compose.yml` with a PostgreSQL container
  (local-dev override of passwordless settings via env vars).
- Renamed `oracle-init/` → `postgres-init/` and converted the init SQL to PostgreSQL;
  removed obsolete Oracle-only scripts.

## Validation
- `mvn clean test` → BUILD SUCCESS, Tests run: 1, Failures: 0, Errors: 0.
- Consistency check (validation-check-consistency): no Critical/Major/Minor issues.
- No remaining Oracle references in source, configuration, or support files.

## Summary
The application's database layer is fully migrated from Oracle to Azure Database for
PostgreSQL with managed-identity passwordless authentication. All Oracle-specific SQL
and configuration were replaced with PostgreSQL equivalents, the build succeeds, and
unit tests pass.
