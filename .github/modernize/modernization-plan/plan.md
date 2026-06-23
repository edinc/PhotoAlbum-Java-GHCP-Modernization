# Modernization Plan: Photo Album Java to Azure

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 8 (1.8)
- **Framework**: Spring Boot 2.7.18 (EOL), Spring Framework 5.x
- **Build Tool**: Maven
- **Database**: Oracle Database (ojdbc8, OracleDialect)
- **Key Dependencies**: Spring Data JPA / Hibernate, Spring MVC, Thymeleaf, Spring Validation, Oracle JDBC Driver

---

## Overview

This migration modernizes the Photo Album application so it can run securely on
Azure. The application currently runs on an end-of-life Spring Boot 2.7.18 / Java 8
stack, stores photos in an Oracle database using Oracle-specific SQL, and keeps
database credentials hard-coded in configuration files. The new architecture will:

- Move to a supported runtime (Spring Boot 3.x / Java 21) so the application stays
  on a maintained, security-patched foundation.
- Replace the Oracle backend with Azure Database for PostgreSQL to remove
  proprietary database licensing and enable a managed cloud data service.
- Remove hard-coded credentials from source control by storing secrets in Azure
  Key Vault, closing a key security gap.
- Remediate all known CVEs in third-party dependencies before the application is
  considered ready for deployment.

The migration follows a phased approach: first the runtime is upgraded, then the
data and configuration layers are migrated to Azure services, and finally
security vulnerabilities are remediated.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service | Authentication | Comments |
|-------------|------------------|-------------------|----------------|----------|
| Photo Album | Oracle Database | Azure Database for PostgreSQL | Managed Identity | Migrate Oracle-specific SQL to PostgreSQL |
| Photo Album | Hard-coded credentials | Azure Key Vault | Managed Identity | Remove plaintext secrets from config |
| Photo Album | Spring Boot 2.7.18 / Java 8 | Spring Boot 3.x / Java 21 | n/a | Upgrade EOL runtime (mandatory blocker) |

---

## Tasks

The detailed, machine-readable task breakdown is maintained in
`.metadata/tasks.json`. At a high level the plan contains:

1. **Upgrade runtime** — Upgrade from Spring Boot 2.7.18 / Java 8 to Spring Boot
   3.x / Java 21 (includes Spring Framework 6.x and the javax → jakarta
   migration). Addresses the mandatory upgrade blockers in the assessment.
2. **Migrate Oracle to Azure Database for PostgreSQL** — Replace the Oracle JDBC
   driver, dialect, and all Oracle-specific SQL (ROWNUM, NVL, TO_CHAR, analytic
   functions) with PostgreSQL equivalents.
3. **Migrate plaintext credentials to Azure Key Vault** — Remove hard-coded
   database credentials from configuration and source code.
4. **Security & CVE remediation** — Scan all dependencies and remediate known
   CVEs identified in the assessment (Tomcat, Spring, Thymeleaf, logback,
   snakeyaml, jackson, Hibernate, commons-io, H2, and others).

---

## Open Questions & Questionnaire

The `ask_user` tool was not available, so the following questionnaire items were
resolved using best-effort defaults based on the assessment report and repository
contents. Adjust if any assumption is incorrect.

- [x] Q: Should the plan include environment/infrastructure provisioning? → A: No — focus on code migration only (no IaC provisioning requested).
- [x] Q: Should the plan include integration testing? → A: No — not explicitly requested.
- [x] Q: Should the plan include security/CVE remediation? → A: Yes — included (default; assessment lists 40+ mandatory CVEs).
- [x] Q: Which Azure deployment target should be used? → A: No deployment — migration only (deployment not explicitly requested).
- [x] Q: Should the plan include containerization? → A: No — not explicitly requested (a Dockerfile already exists in the repo).
- [ ] The assessment lists mandatory EOL upgrade blockers but the request did not specify a target version. This plan assumes **Spring Boot 3.x / Java 21**. Confirm whether Spring Boot 4.x / Java 25 is preferred instead.

---

## Notes & Considerations

- The Oracle→PostgreSQL task uses project-specific guidance found at
  `.github/postgres-migrations/results/application_guidance/coding_notes.md`.
- The schema currently uses `spring.jpa.hibernate.ddl-auto=create`, which drops
  and recreates the schema on every startup — review this as part of the database
  migration.
- All migration tasks depend on the runtime upgrade completing first, since the
  Azure SDKs and Spring Cloud Azure starters require Spring Boot 3.x / Java 17+.
