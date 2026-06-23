# Assessment Overview

This document serves as the navigation entry point for all supplementary analysis documents generated as part of the application assessment for the **Photo Album** Java Spring Boot application.

## Supplementary Documents

The following documents have been generated and are available in this `facts/` directory:

| Document | Description |
|----------|-------------|
| [Architecture Diagram](./architecture-diagram.md) | Two-layer architecture visualization: high-level application layer diagram (Spring Boot, Thymeleaf, Oracle DB) and detailed component relationship diagram (controllers, services, repositories) |
| [Dependency Map](./dependency-map.md) | Visual map of all declared external dependencies grouped by functional category (Web Frameworks, Database/ORM, Validation, Utilities), with version/compatibility risks and notable observations |
| [API & Service Communication Contracts](./api-service-contracts.md) | Complete inventory of all 5 HTTP endpoints, service catalog (app + Oracle DB), DTOs and contracts, communication patterns, and service technology matrix with sequence diagram |
| [Data Architecture & Persistence Layer](./data-architecture.md) | Database configuration per profile, `Photo` entity model with ER diagram, key repository methods (including Oracle-specific native queries), caching strategy, and data classification/sensitivity analysis |
| [Configuration & Externalized Settings Inventory](./configuration-inventory.md) | All configuration sources, runtime profiles (default and docker), properties inventory, startup dependency chain (Docker Compose healthcheck), secrets inventory, and framework/runtime versions |
| [Core Business Workflows](./business-workflows.md) | End-to-end documentation of the 4 core workflows (browse gallery, upload photo, view/navigate photo, delete photo), business rules & decision logic, validation rules, and transaction boundaries |

## Key Findings Summary

- **Application type**: Monolithic Spring Boot 2.7.18 (EOL) web application with a single Oracle Database backend
- **Java version**: Java 8 — two LTS releases behind Java 21
- **Oracle dependency**: All 6 custom repository queries use Oracle-specific SQL (`ROWNUM`, `NVL`, `TO_CHAR`, analytic functions) — not portable to other databases
- **Security gaps**: No authentication/authorization, hardcoded database credentials in source control, MIME type validation relies on client-supplied header (spoofable)
- **No observability**: No Spring Actuator, metrics, health checks, or tracing configured
- **Schema management risk**: `ddl-auto=create` drops and recreates the schema on every startup
