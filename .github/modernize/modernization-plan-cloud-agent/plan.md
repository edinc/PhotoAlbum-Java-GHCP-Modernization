# Modernization Plan: Photo Album Azure Readiness Follow-up

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 21
- **Framework**: Spring Boot 3.5.15, Spring Framework 6.x
- **Build Tool**: Maven 3.9
- **Database**: PostgreSQL with Azure Database for PostgreSQL-ready configuration
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Spring Validation,
  Spring Cloud Azure JDBC PostgreSQL starter

---

## Overview

This follow-up modernization plan is based on the existing assessment report, but
only includes findings that still reproduce in the current repository. The
assessment originally reported Java 8 / Spring Boot 2.7 upgrade blockers, Oracle
database usage, and runtime plaintext datasource passwords; those issues no
longer exist in the current codebase. The remaining modernization work will:

- Align runtime configuration with Azure hosting expectations by removing or
  externalizing settings that can conflict with platform-managed behavior.
- Re-run dependency security validation and remediate any remaining CVEs before
  deployment.
- Preserve the current Spring Boot 3.5 / Java 21 / PostgreSQL application
  behavior while closing the remaining Azure-readiness gaps.

The work stays scoped to code and configuration changes only. No infrastructure
provisioning, containerization, or deployment task is included in this plan.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service | Authentication | Comments |
|-------------|------------------|-------------------|----------------|----------|
| Photo Album | Fixed runtime port / restricted app config | Azure hosting-compatible app config | n/a | Addresses remaining Azure hosting readiness findings |
| Photo Album | Current dependency baseline | Security-validated dependency baseline | n/a | Re-scan and remediate any remaining CVEs before deployment |

---

## Tasks

The detailed, machine-readable task breakdown is maintained in
`.metadata/tasks.json`. At a high level the plan contains:

1. **Azure runtime configuration cleanup** — Address the remaining assessment
   findings for fixed server port and restricted runtime configuration so the app
   is ready for Azure-managed hosting behavior.
2. **Security & CVE remediation** — Re-scan dependencies and remediate any
   vulnerabilities that remain after the earlier modernization work.

---

## Open Questions & Questionnaire

- [x] Q: Should the plan include environment/infrastructure provisioning? → A:
  No — focus on code and configuration migration only.
- [x] Q: Should the plan include integration testing? → A: No — not explicitly
  requested for this planning job.
- [x] Q: Should the plan include security/CVE remediation? → A: Yes — included
  by default in every modernization plan.
- [x] Q: Which Azure deployment target should the plan use? → A: No deployment
  — migration only, because no deployment target was requested.
- [x] Q: Should the plan include containerization? → A: No — a Dockerfile
  already exists and no deployment task was requested.
- [x] Q: Should the previously assessed upgrade, Oracle migration, and runtime
  credential findings be included? → A: No — they do not reproduce in the
  current repository state (Java 21, Spring Boot 3.5.15, PostgreSQL runtime
  configuration, and no runtime datasource password in the main application
  properties).
- [ ] If this plan should also produce Azure deployment assets, specify the
  target hosting service (Azure Container Apps, Azure App Service, AKS, etc.)
  so a deployment task can be added in a future revision.

---

## Notes & Considerations

- Baseline validation for this planning change succeeded with
  `JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64 mvn test`. The runner default JDK
  is 17, which cannot compile the project because the repository now targets
  Java 21.
- The remaining assessment findings that still reproduce are the fixed
  `server.port` settings in `src/main/resources/application.properties` and
  `src/main/resources/application-docker.properties`.
- Repository documentation such as `README.md` still describes the historical
  Oracle / Java 8 state, but documentation cleanup is intentionally not added as
  a modernization task here because it was not part of the verified assessment
  scope for this job.
