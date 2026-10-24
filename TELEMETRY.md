# Telemetry

## Event ID convention
Use `GMSOFT-XXXX`.

Suggested ranges:
- GMSOFT-0001..0099 General
- GMSOFT-0100..0199 Setup
- GMSOFT-0200..0299 Sales
- GMSOFT-0300..0399 Purchasing
- GMSOFT-0400..0499 Integrations
- GMSOFT-0500..0599 Background jobs
- GMSOFT-0900..0999 Install / Upgrade

## Rules
- Prefer structured custom dimensions.
- Never log secrets or personal data.
- Keep stable event IDs once released.
