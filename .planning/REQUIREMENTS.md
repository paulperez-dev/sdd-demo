# Requirements: SDD — URL Shortener Local

**Defined:** 2026-03-26
**Core Value:** Acortar una URL y que la URL corta redirija correctamente a la original — todo sin depender de servicios externos.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Foundation

- [x] **FOUND-01**: Flutter desktop app arranca y muestra una ventana funcional
- [x] **FOUND-02**: Servidor HTTP embebido arranca automáticamente con la app en un puerto local
- [x] **FOUND-03**: Servidor se detiene limpiamente al cerrar la app
- [x] **FOUND-04**: Si el puerto por defecto está ocupado, el servidor usa un puerto alternativo
- [x] **FOUND-05**: Base de datos SQLite se crea en una ubicación estable (no CWD)

### URL Shortening

- [x] **SHORT-01**: Usuario puede pegar una URL larga en un campo de texto y enviarla
- [x] **SHORT-02**: El sistema genera un slug corto único para la URL
- [ ] **SHORT-03**: La URL original y el slug se persisten en SQLite
- [x] **SHORT-04**: La app muestra la URL corta completa (localhost:puerto/slug) al usuario
- [ ] **SHORT-05**: Las URLs persisten entre reinicios de la app

### Redirect

- [ ] **REDIR-01**: Al visitar la URL corta en un navegador, redirige a la URL original
- [ ] **REDIR-02**: La redirección usa HTTP 302 (no 301) para evitar caching permanente del navegador
- [ ] **REDIR-03**: Si el slug no existe, el servidor responde con 404

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Link Management

- **LINKS-01**: Usuario puede ver historial de URLs acortadas
- **LINKS-02**: Usuario puede eliminar un link del historial
- **LINKS-03**: Usuario puede copiar URL corta al clipboard con un botón
- **LINKS-04**: Usuario puede buscar/filtrar en el historial

### Enhanced Features

- **ENHC-01**: Usuario puede especificar un slug personalizado
- **ENHC-02**: Contador de clics por URL
- **ENHC-03**: Generación de código QR para una URL corta

## Out of Scope

| Feature | Reason |
|---------|--------|
| Analytics detallado (geo, device, referrer) | Complejidad de SaaS sin valor para uso personal |
| Acceso público / sharing | Contradice el principio 100% local |
| Dominio custom (no localhost) | Requiere DNS, TLS, reverse proxy — fuera del alcance |
| OAuth / autenticación | App de un solo usuario, sin multiusuario |
| API REST para consumidores externos | El servidor es para redirecciones, no es un API |
| Browser extension | Scope grande, platform-specific, no v1 |
| Import/export desde otros shorteners | Caso nicho, parsing de formatos |
| App móvil / web | Desktop-first por diseño |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| FOUND-04 | Phase 1 | Complete |
| FOUND-05 | Phase 1 | Complete |
| SHORT-01 | Phase 2 | Complete |
| SHORT-02 | Phase 2 | Complete |
| SHORT-03 | Phase 2 | Pending |
| SHORT-04 | Phase 2 | Complete |
| SHORT-05 | Phase 2 | Pending |
| REDIR-01 | Phase 2 | Pending |
| REDIR-02 | Phase 2 | Pending |
| REDIR-03 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-26*
*Last updated: 2026-03-26 after roadmap creation*
