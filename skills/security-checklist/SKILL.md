---
name: security-checklist
description: Stack-independent security checklist for a code change - input handling, authentication and authorization, secrets, data exposure, dependencies - with a severity rule. Use when reviewing a diff for security or self-checking code before handing it over.
---

# Security checklist

Start from the trust boundaries: every place where data enters from a user,
another system, a file or the network, and every place where the change
grants access to something. Most findings are there.

## Input

- Is every value from outside validated where it enters: type, length, range,
  format, allowed set?
- Is it used in a query, a shell command, a file path, a template, a regular
  expression or a redirect? Then it must be parameterized, escaped for that
  context or checked against an allow-list. String concatenation into any of
  these is a finding.
- File uploads: type, size, name and destination checked; never executed or
  served from where they were written.
- Deserialization of untrusted data into objects; parsers given unbounded
  input.

## Authentication and authorization

- Does every new or changed entry point require authentication, unless it is
  meant to be public?
- Is authorization checked on the server, for this user and this specific
  object, not only for the route? Changing an id in the request must not
  reach another user's data.
- Are roles and permissions checked at the point of the action, not only in
  the interface?
- Session and token handling: expiry, rotation, invalidation on logout and
  on password change.

## Secrets and sensitive data

- No credentials, keys or tokens in code, configuration committed to the
  repository, tests, fixtures or comments.
- Secrets and personal data kept out of logs, error messages, URLs, analytics
  and responses.
- Sensitive data encrypted in transit, and at rest where the project requires
  it.
- Responses return only the fields the caller needs.

## Output and errors

- Data rendered into HTML, attributes, scripts or URLs is encoded for that
  context.
- Errors shown to a caller say what went wrong for them, without stack
  traces, queries, paths or versions.
- A failure in a security check denies access. It never falls through to
  allow.

## State-changing requests

- Protected against cross-site request forgery where cookies authenticate.
- Rate limited where abuse is cheap: login, password reset, sign-up, search,
  anything that sends a message or costs money.
- Safe to receive twice.

## Cryptography

- Standard, current algorithms from the platform library; nothing home-made.
- Passwords stored with a slow, salted password hash.
- Random values for security purposes come from a cryptographic source.

## Dependencies and configuration

- Each new or upgraded dependency: is it needed, is it maintained, what does
  it bring in?
- No debug modes, default credentials, permissive cross-origin settings or
  disabled certificate checks.
- Outbound requests to addresses a user can influence are restricted, so the
  server cannot be made to call internal systems.

## Severity

| Severity | Use when |
|---|---|
| `blocking` | a realistic way to exploit, expose or lose data, or a violated security requirement |
| `warning` | hardening, defense in depth, or a risk that needs unusual conditions |

Each finding: `file:line`, what the code does, how it goes wrong, the fix
direction. If you cannot tell whether something is exploitable, say so and
rate it `warning`.
