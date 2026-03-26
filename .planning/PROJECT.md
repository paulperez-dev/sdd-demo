# SDD — URL Shortener Local

## What This Is

Un acortador de URLs que corre completamente en local como una aplicación Flutter de escritorio. Embebe un servidor HTTP en Dart que recibe URLs largas, genera versiones cortas, y redirige cuando se visita la URL corta. Almacena todo en SQLite local.

## Core Value

Acortar una URL y que la URL corta redirija correctamente a la original — todo sin depender de servicios externos.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] El usuario puede pegar una URL larga y obtener una URL corta generada
- [ ] Al visitar la URL corta en el navegador, redirige a la URL original
- [ ] El servidor HTTP embebido arranca junto con la app Flutter
- [ ] Las URLs se persisten en SQLite local (sobreviven reinicios)
- [ ] La app Flutter muestra la URL corta generada al usuario

### Out of Scope

- Historial de URLs acortadas — no necesario para v1
- Estadísticas de clics — complejidad innecesaria en v1
- URLs personalizadas (slugs custom) — v1 genera slugs automáticamente
- Deploy remoto / hosting — el proyecto es 100% local
- Autenticación — uso personal, sin multiusuario
- OAuth / integración con servicios externos — contradice el principio local

## Context

- Dart como lenguaje principal, Flutter para UI
- Arquitectura "todo en uno": Flutter lanza el servidor HTTP internamente
- El servidor escucha en localhost y maneja tanto la API de acortamiento como las redirecciones
- SQLite como base de datos local embebida
- Aplicación de escritorio (no móvil, no web)

## Constraints

- **Stack**: Dart + Flutter — decisión del usuario, no negociable
- **Runtime**: Ejecución 100% local, sin dependencias de red para funcionar
- **Persistencia**: SQLite — archivo local, sin servidor de base de datos
- **Arquitectura**: Servidor embebido en el proceso Flutter, no procesos separados

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter embebe el servidor Dart | Simplifica la experiencia: un solo proceso, un solo lanzamiento | — Pending |
| SQLite para persistencia | Persiste entre reinicios sin complejidad de un DBMS externo | — Pending |
| Solo desktop | El concepto de servidor local no aplica bien a móvil/web | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-26 after initialization*
