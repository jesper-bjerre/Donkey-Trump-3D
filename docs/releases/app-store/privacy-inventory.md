# Privacy inventory — implementation in progress

2026-09-27, base 94dc44d89929137c4ff02649da58ba8fefa29f1e plus current uncommitted changes. No Apple declaration submitted. Public pages are local files, not a verified PROD deployment.

| Information | Scope / linkage / use | Retention |
|---|---|---|
| Personal best, sound, haptics | App-private UserDefaults; local only | Until reset/uninstall |
| Random 32-byte secret | Protected atomic Application Support file; excluded from backup; HTTPS Authorization only | Installation lifetime; corruption fails writes closed |
| Chosen name/run ID/score/level | Optional explicit publication; public name/score; private level/timestamp/sequence | While ranked |
| Installation SHA-256 | Links submissions and reports within an installation; abuse prevention, not hardware attestation | While attributed data/active block is retained |
| Report reason/private entry snapshot | Operator-only investigation; reporter-only generic receipt | Pending until resolved, ordinary closed30d, spam snapshot removed immediately/receipt24h |
| Removed IDs / active blocks | Prevent resurrection or publication bypass | Service retirement / explicit unblock for block only |
| Operator audit | Action/time/count, no offending name or raw credential | <=30d, <=500 records |
| Local receipt | ID/time/status only; <=20; no payload queue, backup excluded | Receipt expiry/404 check or uninstall |
| Pre-migration backup | One private prefix Blob per aggregate; MI only | Success deletion or24h; hourly/startup recovery |
| App diagnostics | Method/status/time/count only | Live configuration/provider audit still BLOCKED; release target<=7d |

Current iOS source uses only Apple platform frameworks; no third-party iOS SDK dependency was found. UserDefaults accesses are app-private settings/best; manifest declares CA92.1. Debug-only fixture defaults/performance instrumentation are not shipping features. Inspect final archive/privacy report before claiming full required-reason compliance. Standard URLSession HTTPS and platform randomness are used; export questionnaire remains unsubmitted pending actual Apple questions.

No tracking, advertising, account, location, contacts or payments feature was added. No-login does not mean no data collection: public submissions and installation-linked moderation must be disclosed. Provider IP/diagnostic retention, storage history/versioning/soft delete, seven-day app logging configuration and archive privacy report remain release gates. Static pages explicitly retain this operational limitation until verified; replace internal readiness wording with verified actual retention before publication.

Owner supplied public name Jesper Bjerre. General contact uses verified public owner repository Issues, requiring GitHub account; no invented email/phone. Private Apple review contact/trader facts remain unavailable until account discovery. GitHub issues must not solicit private player/report information.
