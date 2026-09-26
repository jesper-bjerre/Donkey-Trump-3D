# Research: Global Top 100 Highscores

Date: 2026-09-26. Phase 0 complete. Decisions resolve the implementation questions in [spec.md](spec.md) and refine the earlier [technical proposal](technical-proposal.md). Backend and iOS research were performed independently and checked against the repository. No product clarification remains open.

## 1. Runtime, dependencies and project size

**Decision:** Extend the existing `src/backend/DonkeyTrump.Highscores.Api.csproj` as one ASP.NET Core Minimal API targeting `net10.0`; use C# 14 defaults, nullable references and built-in dependency injection. Add one sibling xUnit test project under `src/backend.tests` to avoid the web project's recursive source glob including tests. Use Azure.Storage.Blobs 12.29.2, Azure.Identity 1.21.0 and Microsoft.AspNetCore.Mvc.Testing 10.0.12 as the researched stable baseline. Pin package versions during implementation; update the SDK/runtime to a serviced .NET 10 release before release validation.

**Rationale:** Microsoft recommends Minimal APIs for new APIs. .NET 10 is LTS. The original local SDK was 10.0.302/runtime 10.0.10. Implementation on 2026-09-26 selects SDK 10.0.401/runtime 10.0.12 from Microsoft release metadata, pinned at the repository root with latestPatch and previews disabled. Azure packages remain at the researched versions; test packages are Microsoft.NET.Test.Sdk 18.10.1, xUnit 2.9.3 and runner 4.0.0.

**Alternatives considered:** Controllers, multiple architecture projects, EF Core, MediatR and a message bus add responsibilities this feature does not require. Native AOT is unnecessary for the first version.

Sources: [Microsoft API guidance](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis?view=aspnetcore-10.0), [.NET support](https://dotnet.microsoft.com/en-us/platform/support/policy), official package metadata for [Blob Storage](https://api.nuget.org/v3-flatcontainer/azure.storage.blobs/index.json), [Identity](https://api.nuget.org/v3-flatcontainer/azure.identity/index.json) and [API testing](https://api.nuget.org/v3-flatcontainer/microsoft.aspnetcore.mvc.testing/index.json).

## 2. Storage and successful-save ordering

**Decision:** Use one private block blob, `global-v1.json`, in a deployment-provisioned `highscores` container on a Standard GPv2 Hot/LRS account. Its document contains schema version, next sequence and at most 100 entries. Sort by score descending, then ascending sequence. Assign sequences only within candidate documents, so only a winning write commits a tie position.

**Rationale:** Read content and ETag from the same response; conditionally upload the whole bounded document with `If-Match`. On first creation use `If-None-Match: *`. Only recognized condition failures trigger a new read and recomputation. A local lock cannot protect different server instances. Hot suits frequent reads/updates of very little data.

**Alternatives considered:** Table Storage is useful for a history or many rankings, but a single conditional document update is simpler here. Blob leases introduce acquisition/release and expiry handling. Neither queues nor local files provide the required immediate shared ranking with this scope.

Sources: [Blob concurrency](https://learn.microsoft.com/en-us/azure/storage/blobs/concurrency-manage), [conditional headers](https://learn.microsoft.com/en-us/rest/api/storageservices/specifying-conditional-headers-for-blob-service-operations), [access tiers](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview).

## 3. Bounded retries and an uncertain save

**Decision:** Disable Azure SDK automatic retries for this store (`Retry.MaxRetries = 0`), set a two-second network-operation timeout, and propagate one linked six-second operation deadline. Permit five total conditional-write attempts, rereading between them with random 25–100 ms backoff, only after a confirmed expected condition conflict. Do not retry a write after a timeout, transport error or other ambiguous failure. Return `submission_unconfirmed`; the app never replays it.

**Rationale:** SDK defaults would exceed the UI's eight-second limit. A write can commit and lose its acknowledgement; replaying that request could produce a later precondition error that obscures the original success. This unknown-outcome conclusion follows from combining the documented retry and conditional-write semantics. Cancellation or an error does not roll back a completed storage operation.

**Alternatives considered:** Default retry policies, unbounded retries and an offline queue conflict with the selected latency/failure behaviour. A durable receipt archive would add storage and lifecycle obligations the user did not request.

Source: [Azure Storage retry configuration](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-retry-policy).

## 4. Empty, corrupt and unavailable storage

**Decision:** Treat only `404 BlobNotFound` as an empty ranking. `ContainerNotFound`, malformed/oversized JSON, an unknown schema version and authorization failures become operational errors. Retry `ConditionNotMet` from the intended condition and recognized first-create `BlobAlreadyExists` races; other 409/412 errors are not ranking conflicts. Never auto-create a production container or overwrite corrupt state in the request path.

**Rationale:** Treating every missing resource as an empty list could hide a deployment problem or destroy evidence of corruption. Reads are bounded to 256 KiB and writes are serialized and size-checked before upload. Use one small Put Blob operation, not a staged multi-block upload.

**Alternatives considered:** Auto-healing to an empty list and unconditional overwrite are rejected because they can erase scores.

Source: [Blob service error codes](https://learn.microsoft.com/en-us/rest/api/storageservices/blob-service-error-codes).

## 5. Identity, validation and public data

**Decision:** No player accounts or embedded app secrets. A random UUID identifies a completed run, not a person. Validate a score in 0–2,147,483,600 in multiples of 100, a one-based level within signed 32-bit range, a non-zero UUID, and a single-line name after NFC normalization and surrounding-space trimming. Names have 1–20 grapheme clusters and at most 256 UTF-8 bytes; reject controls and line/paragraph separators. Names need not be unique. The backend is authoritative for validation.

**Rationale:** Current scoring uses +100/+1000. Bounds protect arithmetic and resource usage; they do not authenticate gameplay. Grapheme counts avoid treating Danish letters or composed emoji as multiple visible characters. Use .NET `StringInfo` and Swift `Character` with shared boundary fixtures. Reject a name consisting only of whitespace/formatting marks. No profanity filter or moderation interface is added.

**Alternatives considered:** Name-based identity, one score per device, login, replays and signed client secrets would change the agreed product scope. A .NET `string.Length` limit does not count perceived characters correctly.

Source: [Microsoft character encoding guidance](https://learn.microsoft.com/en-us/dotnet/standard/base-types/character-encoding-introduction).

## 6. Limits, errors and observability

**Decision:** Adopt configurable process-wide token buckets with no wait queue: GET capacity 40/refill 20 per second; POST capacity 10/refill 2 per second. Exceeding limits returns 429 with an integer `Retry-After`. Limit POST bodies to 4 KiB. Emit Problem Details with stable application error codes and trace IDs. Record route, outcome, duration, CAS attempt count and error class, without names, bodies, score payloads, credentials or client IPs.

**Rationale:** Initial performance validation targets 10 reads/second plus one submission/second over five minutes on a warm deployment, plus a short burst of ten submissions. Rate limits are per replica and do not establish global fairness or DDoS protection. They avoid unreliable client-IP interpretation behind proxies. The independent 100-writer correctness test raises test-fixture limits and reports explicit contention failures rather than promising all writes succeed.

**Alternatives considered:** Per-user quotas require identity; per-IP limits require trusted-proxy configuration and can group shared networks unfairly. Redis/shared ingress enforcement is deferred until observed abuse or traffic requires it.

Sources: [ASP.NET rate limiting](https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit?view=aspnetcore-10.0), [Problem Details](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling-api?view=aspnetcore-10.0), [Container Apps forwarding headers](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview).

## 7. Azure identity, hosting and cost boundary

**Decision:** Target Azure Container Apps Consumption, HTTPS ingress, minimum zero/maximum two replicas, colocated with storage. Start with the smallest suitable CPU/memory allocation and tune only from load evidence. Use a reused `ManagedIdentityCredential` and Blob client, with Storage Blob Data Contributor scoped to the container. Configure a modest log-retention policy and a cost alert during deployment. Keep connection strings restricted to local Azurite mode.

**Rationale:** Scale-to-zero avoids idle compute usage, but a cold start can exceed the eight-second UI deadline and cause an unsubmitted result; this is the agreed unavailable-service behaviour. The warm-service performance target does not cover cold starts. If cold-start measurements are unacceptable, one warm replica is an operational cost tradeoff, not a new storage design. Region, resource names, subscription and DNS are deployment inputs; no Azure resources are created in planning.

**Alternatives considered:** Reuse of an already paid App Service plan can be cheaper incrementally; there is no such plan established in this repository. A dedicated VM, mandatory warm capacity or a new database would add baseline cost. No fixed monthly price or uptime SLA is promised.

Sources: [Identity best practices](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/best-practices), [storage role definitions](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage), [Container Apps scaling](https://learn.microsoft.com/en-us/azure/container-apps/scale-app).

## 8. iOS run identity and thread ownership

**Decision:** Add an immutable `CompletedRun` to the framework-independent core. Assign a new ID in both `startNewGame()` and `restart()` and freeze score/level only on the final-life Game Over transition. Carry the optional completion persistently in `HUDState`, clear it on new run/title and include it in equality. A separate main-actor highscore coordinator receives immutable snapshots and owns networking/presentation state.

**Rationale:** `GameEngine` renders and steps the simulation off the main actor, then dispatches changed HUD snapshots to the main queue. One-frame completion events can be lost or incorrectly overwritten. Controller inputs start/restart directly, so observed phase/run changes must invalidate network work as well as SwiftUI button wrappers. Title attract mode steps a separate simulation and does not finish a session. Disable publication for development automation (`-autopilot`) and test/demo modes.

**Alternatives considered:** Inferring completion from score changes, networking inside the renderer, and identifying a run by its name or score are unsafe. New Swift source/test files belong in the existing filesystem-synchronized Xcode groups; only a new UI-test target needs explicit target/scheme registration.

Repository evidence: [Simulation.swift](../../src/DonkeyTrump3D/Core/Simulation.swift), [GameEngine.swift](../../src/DonkeyTrump3D/App/GameEngine.swift), [GameModel](../../src/DonkeyTrump3D/App/DonkeyTrump3DApp.swift), [Xcode project](../../src/DonkeyTrump3D.xcodeproj/project.pbxproj).

## 9. Networking deadline and no later publication

**Decision:** Use a foreground ephemeral `URLSession`, `waitsForConnectivity = false`, request/resource timeouts of eight seconds and no app-level HTTP retries. Independently expire the coordinator's operation at eight seconds: invalidate its generation, show the terminal error and cancel work. Do not await an uncooperative task before updating the UI. Exit/background/start/restart invalidates pending publication. Failed qualification or publication permanently retires that run's submission opportunity; later list refresh is browse-only.

**Rationale:** The request timeout measures inactivity; it can restart as bytes arrive. The resource timeout and independent UI deadline cover the total wait. A background session can retry uploads later, conflicting with the user's choice. Every completion must match the active presentation, generation and run ID. Store cached rankings only in session memory; there is no payload queue or reconnect handler.

**Alternatives considered:** Background URLSession, connectivity waiting and a timeout implemented only by awaiting a cancellation-ignoring task are rejected. Missing/invalid API configuration yields an unavailable list, never a gameplay gate.

Sources: Apple [request timeout](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/timeoutintervalforrequest), [resource timeout](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/timeoutintervalforresource), [connectivity waiting](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/waitsforconnectivity).

## 10. Positioning and validation tooling

**Decision:** Scroll by returned entry UUID: centre after keyboard dismissal for a ranked run, bottom for non-qualification, top for title browsing. Clamp naturally at content boundaries. Use scalable row text and VoiceOver rank/name/score/selection labels. Validate the HTTP contract with OpenAPI 3.1; use Azurite 3.37.0, xUnit/WebApplicationFactory, existing Swift Testing and a small new XCUITest target.

**Rationale:** Existing arcade fonts have fixed sizes and cannot be copied unchanged into the new accessible list. API/runtime tests cannot prove row visibility. Local Node/npm and Azure CLI are available; Docker is not, so the quickstart runs the emulator through pinned `npx`. Physical-device and development-Azure checks remain release evidence, not claims made by this plan.

**Alternatives considered:** Matching rows by nickname breaks repeated names. Docker-only setup would add an unnecessary local prerequisite. A manual-only test strategy does not establish the requested concurrency and late-response guarantees.

Sources: Apple [ScrollViewReader](https://developer.apple.com/documentation/swiftui/scrollviewreader), [accessibility focus](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate), [official Azurite instructions](https://github.com/Azure/Azurite), [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0.html).
