# AmiraLearning/network-monitoring-service-analyzer

## At a glance
- **Role:** sole author. All 7 commits in the repo are his (`tory37` / "Tory Hebert" / tory37@gmail.com).
- **Lifespan:** 2023-08-15 → 2023-08-17 (private, org-owned, 3-day focused build).
- **Scale signals:** 0 stars, 0 forks, 0 PRs (direct-to-`main` internal tool). 100% JavaScript (~11 KB source). Input set grew to **57,882 activity IDs** in `fullActivityIds.csv` — the tool was pointed at a production-scale log corpus.
- **Stack:** Node.js, AWS SDK v3 (`@aws-sdk/client-s3`), `@supercharge/promise-pool`, `csvtojson`, `chartjs-node-canvas` / Chart.js, Node streams.

## What it is
An internal forensics/analytics tool built to answer a production question: how often does the student app's Network Monitoring Service (NMS) fire each network-health state, and is it firing at all, per learning activity. Raw NMS telemetry lands in the `amira-logging` S3 bucket as one JSON object per event, keyed by activity ID. This tool pulls that telemetry for tens of thousands of activities, aggregates the event counts, and renders a bar chart of the results.

## Technical work and problems solved

**S3 telemetry harvesting at scale.** `fetchAndWriteActivities.js` reads an activity-ID CSV, and for each ID lists every object under that ID's S3 prefix. `listAllContents` handles `ListObjectsV2` pagination explicitly via the `NextContinuationToken` loop, so activities with more events than one page's worth aren't silently truncated. Keys are then bucketed into the four NMS event families — `network_monitoring_service_initialized`, `network_status_changed`, `network_monitoring_service_cleanup`, `network_monitoring_service_audio_queue_dump` — and each matching object is fetched and parsed from a Node readable stream (`Body.on("data"/"end"/"error")` wrapped in a promise) rather than buffered by a convenience helper.

**Bounded concurrency instead of unbounded fan-out.** Fetching ~58k activities × N objects each would swamp S3 and the event loop with a naive `Promise.all`. He used `PromisePool.for(activityIds).withConcurrency(20)`, and collected `results.errors` so partial failures surface instead of rejecting the whole run.

**Memory pressure → streaming JSON writer (the most interesting fix).** The first working version accumulated every activity's parsed events into one in-memory `writeObject` map and did a single `fs.writeFileSync` at the end. That does not survive a 57k-activity input. The final commit (`9252685`) replaced it with an `fs.createWriteStream` that emits a JSON array incrementally as results land. To keep the output valid JSON without a trailing comma, he processes the *first* activity separately (writes it bare), `shift()`s it off the list, then prefixes every subsequent write with `,\n` — comma-before instead of comma-after. The reasoning is spelled out in the code comment. Result: constant-memory output regardless of input size.

**Deliberate two-phase split (fetch vs. parse).** Commit `6626cdc` restructured the tool from one monolithic script into two: `fetchAndWriteActivities.js` (expensive, network-bound S3 pull → `activities.json`) and `parseLogs.js` (cheap, local re-parse of that file). This meant iterating on the analysis logic no longer required re-hitting S3 for 58k activities — the pull becomes a cached artifact. Both scripts take file names from `process.argv`, so a small `testActivities.json` fixture can be swapped in for the full corpus during development.

**Aggregation and reporting.** `parseLogs.js` builds a per-activity counter object (init count, cleanup count, audio-queue-dump count, and a `Normal`/`Slow`/`Disconnected`/`Critical` breakdown of status-change events). `maxEventCount.js` reduces the whole corpus to the per-state maxima across all activities and renders them as a headless server-side bar chart (`chartjs-node-canvas` → `MaxEventCount.png`), including a custom `beforeDraw` Chart.js plugin to paint a white background so the PNG isn't transparent.

## Notable design decisions
- Cache the expensive S3 pull to disk as an intermediate artifact; keep analysis iteration local and free.
- Comma-before-element streaming write to produce valid JSON without holding the array in memory.
- Explicit `ListObjectsV2` continuation-token pagination rather than trusting a single page.
- Fixed concurrency ceiling (20) as the throttle, with error collection rather than fail-fast.
- Headless PNG chart output so results are shareable in a ticket/Slack without a UI.

## Resume-relevant framing
Built a Node.js/AWS-SDK data-forensics tool that harvested and aggregated client network-telemetry logs for ~58,000 production learning activities from S3, using bounded-concurrency worker pooling and a streaming JSON writer for constant-memory operation, and rendered the per-state event distribution as a server-side chart.

## Caveats
- Throwaway internal analysis tool, not a shipped service — no tests, no README, no CI, some commented-out exploratory code left in place.
- The final `parseLogs.js` iterates `activities.forEach` over what is now a JSON array; consistent with the streamed array format, but the repo was abandoned right after this change, so end-to-end run status on the full 57,882-ID input is unverified from the repo alone.
