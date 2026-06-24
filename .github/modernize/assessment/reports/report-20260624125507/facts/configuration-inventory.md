# Configuration & Externalized Settings Inventory

The application uses a small but important set of Spring properties, profile-specific property files, container environment variables, and Docker assets to switch between Oracle and H2-backed environments. Secrets handling is currently file- and compose-based rather than delegated to an external secret store.

## Configuration Sources

| Source | Type | Path/Location | Notes |
| --- | --- | --- | --- |
| Spring application properties | Properties file | `src/main/resources/application.properties` | Default runtime configuration, Oracle JDBC settings, upload limits, and logging |
| Docker Spring properties | Properties file | `src/main/resources/application-docker.properties` | Overrides for Docker profile, Oracle XE URL, and logging |
| Test Spring properties | Properties file | `src/test/resources/application-test.properties` | Uses H2 in-memory DB and test upload path |
| Docker Compose | YAML | `docker-compose.yml` | Defines Oracle and application services plus environment overrides |
| Docker image build | Dockerfile | `Dockerfile` | Sets container JVM options and packaging strategy |
| Oracle init scripts | SQL | `oracle-init/*.sql` | Creates or validates the database user and provides health checks |

## Build Profiles

| Profile | Activation | Purpose | Key Dependencies/Plugins |
| --- | --- | --- | --- |
| default Maven build | Automatic | Builds the Spring Boot JAR with Java 8 target settings | `spring-boot-maven-plugin` |

## Runtime Profiles

| Profile | Activation Method | Config Files | Key Overrides |
| --- | --- | --- | --- |
| default | Spring default when no explicit profile is set | `application.properties` | Oracle `FREEPDB1` connection, `server.port=8080`, `ddl-auto=create` |
| docker | `SPRING_PROFILES_ACTIVE=docker` in Docker Compose | `application.properties`, `application-docker.properties` | Oracle `XE` URL, container-oriented logging levels |
| test | `@ActiveProfiles("test")` in `PhotoAlbumApplicationTests` | `application-test.properties` | H2 in-memory DB, `ddl-auto=create-drop`, test upload path |

## Properties Inventory

| Property Key | Default | Profiles | Source |
| --- | --- | --- | --- |
| `server.port` | `8080` | default, docker | Spring properties |
| `spring.datasource.url` | Oracle JDBC URL | default, docker, test override | Spring properties / Docker env |
| `spring.datasource.username` | `[MASKED]` | default, docker, test override | Spring properties / Docker env |
| `spring.datasource.password` | `[MASKED]` | default, docker, test override | Spring properties / Docker env |
| `spring.datasource.driver-class-name` | Oracle driver or H2 driver | default, docker, test | Spring properties |
| `spring.jpa.database-platform` | OracleDialect / H2Dialect | default, docker, test | Spring properties |
| `spring.jpa.hibernate.ddl-auto` | `create` or `create-drop` | default, docker, test | Spring properties |
| `spring.jpa.show-sql` | `true` or `false` | default, docker, test | Spring properties |
| `spring.servlet.multipart.max-file-size` | `10MB` | default, docker | Spring properties |
| `spring.servlet.multipart.max-request-size` | `50MB` | default, docker | Spring properties |
| `app.file-upload.max-file-size-bytes` | `10485760` | default, docker, test | Spring properties |
| `app.file-upload.allowed-mime-types` | `image/jpeg,image/png,image/gif,image/webp` | default, docker, test | Spring properties |
| `app.file-upload.max-files-per-upload` | `10` | default, docker, test | Spring properties |
| `app.file-upload.upload-path` | `target/test-uploads` | test only | Spring test properties |
| `logging.level.*` | profile-specific logging levels | default, docker, test | Spring properties |

## Startup Parameters & Resource Requirements

| Service | JVM/Runtime Options | Memory | Instance Count |
| --- | --- | --- | --- |
| photo-album | `JAVA_OPTS="-Xmx512m -Xms256m"` from Dockerfile entrypoint | 256m initial heap, 512m max heap | 1 |
| oracle-db | Oracle container defaults | README recommends at least 4 GB Docker memory on the host | 1 |

## Startup Dependency Chain

1. `oracle-db` starts first and runs the initialization SQL scripts from `oracle-init/`.
2. Docker Compose health checks wait for `oracle-db` to report healthy.
3. `photoalbum-java-app` starts only after the database health condition passes because of `depends_on: condition: service_healthy`.
4. The Spring Boot app then opens port 8080 and begins handling HTTP requests.

## Secrets & Sensitive Configuration

| Secret Reference | Type | Storage (masked) |
| --- | --- | --- |
| `spring.datasource.username` | Database username | Spring properties / Docker env `[MASKED]` |
| `spring.datasource.password` | Database password | Spring properties / Docker env `[MASKED]` |
| `ORACLE_PASSWORD` | Database admin password | Docker Compose environment `[MASKED]` |
| `APP_USER_PASSWORD` | Database application password | Docker Compose environment `[MASKED]` |

### Secrets Provisioning Workflow

Secrets are provisioned inline through checked-in property files and Docker Compose environment variables rather than through a managed secret store. The Compose file injects Oracle container credentials and application datasource credentials, while the Spring property files provide the same values for local or default runtime execution. No managed identity, Key Vault, Vault, or secret rotation workflow was found.

## Feature Flags

| Flag Name | Default | Controlled By |
| --- | --- | --- |
| None detected | N/A | No conditional beans, feature flag framework, or property-driven feature toggles were found |

## Framework & Runtime Versions

| Component | Version | Source |
| --- | --- | --- |
| Java target | 8 | `pom.xml` properties |
| Spring Boot | 2.7.18 | `pom.xml` parent |
| Spring Framework | 5.3.31 | Maven dependency tree |
| Hibernate | 5.6.15.Final | Maven dependency tree |
| Thymeleaf | 3.0.15.RELEASE | Maven dependency tree |
| Oracle JDBC | 21.5.0.0 | `pom.xml` dependency |
| Maven build image | 3.9.6 with Eclipse Temurin 8 | `Dockerfile` |
| Runtime image | Eclipse Temurin 8 JRE | `Dockerfile` |
