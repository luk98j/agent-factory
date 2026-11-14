---
name: performance-checklist
description: Stack-independent performance checklist for a code change - data access, algorithmic cost, blocking calls, memory, caching, concurrency - judged against real load, with a severity rule. Use when reviewing a diff for performance.
---

# Performance checklist

First establish the load: how often does this path run, with how much data,
and how many at once? A finding only exists relative to that. If the load is
unknown, say what you assumed.

## Data access

- A query or remote call inside a loop, where one batched call would do.
- A query that reads more rows or columns than it uses; a missing limit or
  pagination on a result that can grow.
- Filtering, sorting or joining in application code that the data store
  could do.
- A filter or sort on a column that has no index, on a table that is or will
  be large.
- Transactions held open across slow work such as remote calls.

## Cost of the work

- Work that grows faster than its input: nested loops over the same
  collection, repeated linear searches, repeated sorting.
- The same result computed more than once in a request or a loop.
- Expensive work done eagerly that most callers never use.
- Synchronous work in a request that could be deferred to a background job.

## Waiting

- Blocking calls on a path that must stay responsive: an event loop, a
  request thread, a user interface thread.
- Outbound calls without a timeout, or with retries that have no limit or
  backoff.
- Calls made one after another that are independent and could run together.

## Memory

- A whole file, result set or response loaded into memory when it could be
  streamed or paged.
- Collections that grow without a bound: caches without eviction, listeners
  never removed, buffers never drained.
- Large objects copied where a reference would do, inside a hot path.

## Caching

- An expensive result that is reused but not cached.
- A cache with no invalidation or expiry, or keyed so that one user can
  receive another's data.
- A cache in front of something cheap: complexity without a gain.

## Concurrency

- Shared state changed without coordination; locks taken in different orders.
- A pool (connections, threads, workers) that can be exhausted by slow
  requests.
- Many requests rebuilding the same expired cache entry at once.

## Front end, when it applies

- Work repeated on every render; large lists rendered whole.
- Assets larger than needed; code loaded before it is used.
- Layout that shifts after load.

## Severity

| Severity | Use when |
|---|---|
| `blocking` | breaks a stated performance requirement, or will fail or time out at the expected load |
| `warning` | a measurable but tolerable cost, or a risk at loads beyond the expected |

Each finding: `file:line`, what the code does, at what load it goes wrong,
the fix direction. Do not ask for an optimization without naming its cost. An
inefficiency on a path that runs rarely with little data is not a finding.
