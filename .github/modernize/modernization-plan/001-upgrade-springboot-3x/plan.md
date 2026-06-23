# Upgrade Plan: Photo Album — Task 001 (Spring Boot 3.x / Java 21)

- **Generated**: autonomous run
- **HEAD Branch**: app-modernize-20260623131905

## Available Tools

**JDKs**
- JDK 1.8.0: not available (baseline will be skipped)
- JDK 21: /Users/edin/.local/jdks/jdk-21.0.11+10/Contents/Home (Temurin, installed for this upgrade)

**Build Tools**
- Maven 3.9.16: /opt/homebrew/bin/mvn (compatible with Java 21; no wrapper present)

## Options

- Working branch: app-modernize-20260623131905 (reused)
- Run tests before and after the upgrade: true

## Upgrade Goals

- Spring Boot 2.7.18 → 3.5.x
- Java 8 → Java 21
- Spring Framework 5.x → 6.x (derived)
- Jakarta EE migration: javax.* → jakarta.*

## Technology Stack

| Technology/Dependency | Current | Min Compatible | Why Incompatible |
| --------------------- | ------- | -------------- | ---------------- |
| Java | 1.8 | 21 | User requested |
| Spring Boot | 2.7.18 | 3.5.x | User requested |
| Spring Framework | 5.3.x | 6.x | Derived via Spring Boot 3 |
| javax.persistence ⚠️ EOL | 2.2 | N/A | Replaced by jakarta.persistence |
| javax.validation ⚠️ EOL | 2.0 | N/A | Replaced by jakarta.validation |
| Oracle JDBC (ojdbc8) | 8 | ojdbc11 | Java 21 alignment |

## Derived Upgrades

- Spring Boot 3.x → Java 17+ (target 21), Jakarta EE 10, Hibernate 6.x, Spring Framework 6.x
- javax.persistence/javax.validation → jakarta.*
- Dockerfile base images temurin-8 → temurin-21

## Impact Analysis

### Dependency Changes
| File | Dependency | Current | Action | Target | Reason |
|------|-----------|---------|--------|--------|--------|
| pom.xml | spring-boot-starter-parent | 2.7.18 | upgrade | 3.5.4 | User requested |
| pom.xml | java.version / release | 1.8 / 8 | upgrade | 21 | User requested |
| pom.xml | ojdbc8 | ojdbc8 | replace | ojdbc11 | Java 21 alignment |

### Source Code Changes
| File | Current | Required Change | Reason |
|------|---------|----------------|--------|
| Photo.java | javax.persistence.* | jakarta.persistence.* | Jakarta EE 10 |
| Photo.java | javax.validation.constraints.* | jakarta.validation.constraints.* | Jakarta EE 10 |
| PhotoServiceImpl.java | javax.imageio.ImageIO | unchanged (JDK package) | Not Jakarta |

### CI/CD Changes
| File | Current | Required Change |
|------|---------|----------------|
| Dockerfile | maven:3.9.6-eclipse-temurin-8 | maven:3.9.6-eclipse-temurin-21 |
| Dockerfile | eclipse-temurin:8-jre | eclipse-temurin:21-jre |

### Risks & Warnings
- Hibernate 5→6 dialects (OracleDialect/H2Dialect) class names remain valid; no change. Mitigation: context-load test covers H2.
- ojdbc8→ojdbc11 runtime-scoped; tests use H2, no test impact.

## Upgrade Steps
- Step 1: Setup Environment — verify JDK 21.
- Step 2: Setup Baseline — base JDK 1.8 unavailable → SKIPPED.
- Step 3: SB3 + Java 21 + Jakarta migration — apply all Impact Analysis changes; verify `mvn clean test-compile` on JDK 21.
- Step 4: Final Validation — `mvn clean test` on JDK 21; fix until 100% pass.
