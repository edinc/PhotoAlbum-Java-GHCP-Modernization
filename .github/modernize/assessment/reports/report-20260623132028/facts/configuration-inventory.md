# Configuration & Externalized Settings Inventory

The Photo Album application has a simple, flat configuration landscape: two Spring property files (default and docker profile) plus Docker Compose environment variable overrides, with no external config server, secret store, or feature flag framework.

## Configuration Sources

| Source | Type | Path/Location | Notes |
|--------|------|---------------|-------|
| application.properties | Spring Boot properties | `src/main/resources/application.properties` | Default profile; active in local development and test runs |
| application-docker.properties | Spring Boot profile properties | `src/main/resources/application-docker.properties` | Activated by `SPRING_PROFILES_ACTIVE=docker`; used in containerized deployment |
| docker-compose.yml (environment section) | Docker Compose env vars | `docker-compose.yml` | Overrides datasource URL, username, password, and active profile at container runtime |
| oracle-init scripts | Oracle container init SQL | `oracle-init/01-create-user.sql`, `oracle-init/02-verify-user.sql` | Executed by the Oracle container on first startup; not read by the Spring application |

No Spring Cloud Config server, Bootstrap context (`bootstrap.properties`/`bootstrap.yml`), Kubernetes ConfigMaps/Secrets, HashiCorp Vault, Azure Key Vault, or AWS Secrets Manager integration is present.

## Build Profiles

No Maven build profiles are defined in `pom.xml`. The build uses a single, unconditional Maven lifecycle with `spring-boot-maven-plugin` for packaging. The multi-stage Dockerfile (`maven:3.9.6-eclipse-temurin-8` → `eclipse-temurin:8-jre`) implicitly defines a build stage and a runtime stage, but these are Dockerfile stages, not Maven profiles.

| Profile | Activation | Purpose | Key Dependencies/Plugins |
|---------|-----------|---------|--------------------------|
| (none — single build) | Always active | Compile and package JAR via `spring-boot-maven-plugin` | `spring-boot-maven-plugin` (repackage goal) |

## Runtime Profiles

| Profile | Activation Method | Config Files | Key Overrides vs Default |
|---------|------------------|-------------|--------------------------|
| default | Active when no profile is specified | `application.properties` | Base configuration; connects to `oracle-db:1521/FREEPDB1` |
| docker | `SPRING_PROFILES_ACTIVE=docker` env var (set in `docker-compose.yml`) | `application.properties` + `application-docker.properties` | JDBC URL changes to `oracle-db:1521:XE` (SID syntax instead of service name); logging levels reduced (`INFO`/`WARN` instead of `DEBUG`) |

## Properties Inventory

### photoalbum-java-app — Server & Encoding

| Property Key | Default (application.properties) | Docker Override | Source |
|-------------|----------------------------------|-----------------|--------|
| `server.port` | `8080` | `8080` (same) | application.properties |
| `server.servlet.encoding.charset` | `UTF-8` | `UTF-8` (same) | application.properties |
| `server.servlet.encoding.enabled` | `true` | `true` (same) | application.properties |
| `server.servlet.encoding.force` | `true` | `true` (same) | application.properties |

### photoalbum-java-app — Database

| Property Key | Default (application.properties) | Docker Override | Source |
|-------------|----------------------------------|-----------------|--------|
| `spring.datasource.url` | `jdbc:oracle:thin:@oracle-db:1521/FREEPDB1` | `jdbc:oracle:thin:@oracle-db:1521:XE` | application.properties / docker-compose env var |
| `spring.datasource.username` | `photoalbum` | `photoalbum` (same) | application.properties / docker-compose env var |
| `spring.datasource.password` | `photoalbum` | `photoalbum` (same) | application.properties / docker-compose env var |
| `spring.datasource.driver-class-name` | `oracle.jdbc.OracleDriver` | `oracle.jdbc.OracleDriver` (same) | application.properties |

### photoalbum-java-app — JPA / Hibernate

| Property Key | Default (application.properties) | Docker Override | Source |
|-------------|----------------------------------|-----------------|--------|
| `spring.jpa.database-platform` | `org.hibernate.dialect.OracleDialect` | same | application.properties |
| `spring.jpa.hibernate.ddl-auto` | `create` | `create` (same) | application.properties |
| `spring.jpa.show-sql` | `true` | `true` (same) | application.properties |
| `spring.jpa.properties.hibernate.format_sql` | `true` | `true` (same) | application.properties |

### photoalbum-java-app — File Upload

| Property Key | Default (application.properties) | Docker Override | Source |
|-------------|----------------------------------|-----------------|--------|
| `spring.servlet.multipart.max-file-size` | `10MB` | `10MB` (same) | application.properties |
| `spring.servlet.multipart.max-request-size` | `50MB` | `50MB` (same) | application.properties |
| `app.file-upload.max-file-size-bytes` | `10485760` (10 MiB) | `10485760` (same) | application.properties |
| `app.file-upload.allowed-mime-types` | `image/jpeg,image/png,image/gif,image/webp` | same | application.properties |
| `app.file-upload.max-files-per-upload` | `10` | `10` (same) | application.properties |

### photoalbum-java-app — Logging

| Property Key | Default (application.properties) | Docker Override | Source |
|-------------|----------------------------------|-----------------|--------|
| `logging.level.com.photoalbum` | `DEBUG` | `INFO` | application.properties / application-docker.properties |
| `logging.level.org.springframework.web` | `DEBUG` | `WARN` | application.properties / application-docker.properties |
| `logging.level.org.hibernate.SQL` | (not set) | `DEBUG` | application-docker.properties only |

## Startup Parameters & Resource Requirements

| Service | JVM / Runtime Options | Memory | CPU | Instance Count |
|---------|----------------------|--------|-----|----------------|
| photoalbum-java-app (Docker) | `-Xmx512m -Xms256m` (from `JAVA_OPTS` env var in Dockerfile) | No Docker `mem_limit` set | No CPU limit set | 1 (single container, `restart: on-failure`) |
| oracle-db | Oracle XE internal JVM | No Docker `mem_limit` set | No CPU limit set | 1 |

No Kubernetes resource requests/limits, Helm values, or cloud deployment resource definitions are present.

## Startup Dependency Chain

```
oracle-db  ──────────────────────────────────────────────────────────▶  photoalbum-java-app
  (Oracle Free 23ai container)                                               (Spring Boot JAR)
  healthcheck: healthcheck.sh                                                depends_on: oracle-db
  interval: 30s                                                              condition: service_healthy
  timeout: 10s                                                               restart: on-failure
  retries: 15
  start_period: 180s
```

**Mechanism**: Docker Compose `depends_on` with `condition: service_healthy`. The `photoalbum-java-app` container will not start until `oracle-db` reports healthy via Oracle's built-in `healthcheck.sh` script. The Oracle container allows up to 180 seconds startup before the healthcheck begins counting retries (15 retries × 30-second interval = up to 7.5 additional minutes). If Oracle never becomes healthy, the application container is never started. There is no Spring-level retry for the datasource connection; if the application starts and Oracle is not yet fully ready, the JPA datasource initialization will fail at startup. No actuator health endpoints or Kubernetes readiness/liveness probes are configured.

## Secrets & Sensitive Configuration

| Secret Reference | Type | Stored In | Value |
|-----------------|------|-----------|-------|
| `spring.datasource.username` | Database credential | `application.properties`, `application-docker.properties`, `docker-compose.yml` | [MASKED — hardcoded in plaintext] |
| `spring.datasource.password` | Database credential | `application.properties`, `application-docker.properties`, `docker-compose.yml` | [MASKED — hardcoded in plaintext] |
| `SPRING_DATASOURCE_USERNAME` | Database credential env var | `docker-compose.yml` environment section | [MASKED — hardcoded in plaintext] |
| `SPRING_DATASOURCE_PASSWORD` | Database credential env var | `docker-compose.yml` environment section | [MASKED — hardcoded in plaintext] |
| `ORACLE_PASSWORD` | Oracle admin password | `docker-compose.yml` environment section | [MASKED — hardcoded in plaintext] |
| `APP_USER_PASSWORD` | Oracle app user password | `docker-compose.yml` environment section | [MASKED — hardcoded in plaintext] |

### Secrets Provisioning Workflow

**Current state (insecure)**: All secrets are hardcoded as plaintext values in source-controlled files (`application.properties`, `application-docker.properties`, `docker-compose.yml`). There is no secrets provisioning workflow:

- No secret store (Vault, Azure Key Vault, AWS Secrets Manager) is referenced.
- No environment variable indirection (`${DB_PASSWORD}`) is used — values are literal strings.
- No encryption (Jasypt, DPAPI, sealed secrets) is applied.
- Credentials are identical (`photoalbum`/`photoalbum`) across username and password.
- Any developer with repository read access has full database credentials.

**Recommended target**: Externalize credentials to environment variables injected at runtime (CI/CD pipeline, Docker secrets, Kubernetes Secrets, or Azure Key Vault with managed identity). Remove all plaintext credentials from source-controlled files.

## Feature Flags

No feature flag framework is used. There are no `@ConditionalOnProperty`, `@ConditionalOnExpression`, `@ConditionalOnBean`, LaunchDarkly, Unleash, or custom toggle annotations in the codebase. All features are permanently enabled at build time.

| Flag Name | Default | Controlled By |
|-----------|---------|--------------|
| (none) | — | — |

## Framework & Runtime Versions

| Component | Version | Source |
|-----------|---------|--------|
| Java (source/target compatibility) | 8 (1.8) | `pom.xml` `<java.version>` and `<maven.compiler.source>` |
| Spring Boot | 2.7.18 | `pom.xml` parent BOM |
| Spring MVC | 5.3.x (managed by BOM) | spring-boot-starter-web transitive |
| Spring Data JPA | 2.7.x (managed by BOM) | spring-boot-starter-data-jpa transitive |
| Hibernate ORM | 5.6.x (managed by BOM) | spring-boot-starter-data-jpa transitive |
| Thymeleaf | 3.0.x (managed by BOM) | spring-boot-starter-thymeleaf transitive |
| Jackson | 2.13.x (managed by BOM) | spring-boot-starter-json transitive |
| Apache Commons IO | 2.11.0 | `pom.xml` explicit |
| Oracle JDBC (ojdbc8) | managed by Spring Boot BOM | `pom.xml` runtime scope |
| Maven (build tool) | 3.9.6 | Dockerfile build stage `maven:3.9.6-eclipse-temurin-8` |
| Docker base image (build) | `maven:3.9.6-eclipse-temurin-8` | `Dockerfile` FROM |
| Docker base image (runtime) | `eclipse-temurin:8-jre` | `Dockerfile` final stage FROM |
| Oracle Database | Free 23ai (`gvenzl/oracle-free:latest`) | `docker-compose.yml` |
