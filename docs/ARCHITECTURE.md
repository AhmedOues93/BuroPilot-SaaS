# BuroPilot Architektur – Phase 1

## Sicherheitsgrenzen
E-Mail-Inhalte und Attachments sind untrusted input. AI-Ausgaben sind Vorschläge und werden mit Zod validiert. Nur der Action-/Policy-Layer darf Seiteneffekte auslösen. AI erhält keinen direkten Datenbankzugriff und keine unbeschränkten Tools.

## Tenant-Modell
Jede fachliche Tabelle trägt workspace_id. RLS prüft die Mitgliedschaft serverseitig. Provider-IDs und Idempotency-Keys besitzen tenant-sichere Unique Constraints.

## Phase-1 Ablauf
1. Provider-Event verifizieren und normalisieren.
2. provider_message_id deduplizieren.
3. Thread upserten.
4. Nachricht persistieren.
5. AI-Analyse über strukturiertes Schema.
6. Kontakt/Firma matchen oder anlegen.
7. Vorgang finden oder anlegen.
8. Antwortentwurf / nächste Aktion vorschlagen.
9. Business Rules prüfen.
10. AUTO ausführen oder Approval anlegen.
11. Audit Log schreiben.
12. Follow-up idempotent planen; bei Kundenantwort abbrechen.

## Noch externe Voraussetzungen
Gmail/Microsoft OAuth App-Credentials, produktiver AI-Provider, Token-Verschlüsselungs-Key und Supabase-Projektkonfiguration. Bis dahin darf UI keine Provider-Verbindung als produktiv fertig darstellen.
