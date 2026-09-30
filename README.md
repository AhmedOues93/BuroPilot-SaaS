# BuroPilot

BuroPilot automatisiert konkrete Büroarbeit für kleine und mittlere deutsche B2B-Dienstleister. Das Produkt ist bewusst **kein** Node-/Workflow-Builder.

## Phase 1
Der erste produktionsnahe End-to-End-Flow ist eine neue Kundenanfrage per E-Mail: deduplizieren, Thread zuordnen, strukturiert analysieren, Kontakt/Firma und Vorgang zuordnen, fehlende Informationen erkennen, Antwort vorbereiten, Regeln/Freigabe prüfen und Follow-up sicher planen.

## Architektur
- Next.js App Router + TypeScript
- PostgreSQL/Supabase mit RLS für Tenant-Isolation
- Zod an allen untrusted Grenzen
- serverseitige Workflow-Engine mit idempotenten Events/Steps
- AI Provider hinter einer Abstraktion; AI schlägt vor, Policy/Action-Layer entscheidet
- Human-in-the-loop: AUTO, APPROVAL_REQUIRED, MANUAL

Externe Gmail/Microsoft- und AI-Credentials werden nicht simuliert. Development-Adapter müssen als solche sichtbar bleiben.
