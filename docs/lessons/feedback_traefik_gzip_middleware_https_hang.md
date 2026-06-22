---
name: Traefik gzip compress middleware can silently hang the HTTPS router only
description: A Coolify/Traefik resource can gateway-timeout on HTTPS while HTTP works perfectly — the gzip compress middleware on the https router can hang indefinitely with zero bytes returned, no errors logged anywhere
type: feedback
---

When a country's storefront gateway-times out on `https://` (curl/browser hang
for the full timeout window, 0 bytes received) while the app, database, and
even plain `http://` on the same domain work perfectly, suspect the **Traefik
`gzip`/`compress` middleware on the HTTPS router specifically** before
anything else. This produced an hours-long false trail through application,
database, and network-layer debugging before the actual cause was found.

**Why:** On Ghana's server (2026-06-22 incident), `https://www.tertiarycourses.com.gh/`
gateway-timed out for every client (real browsers, curl, from multiple
networks) while `http://www.tertiarycourses.com.gh/` (which redirects to
HTTPS) returned its 302 instantly. Every layer checked out individually:

- App container: Apache responded in <150ms via `localhost`, and even via
  direct container-to-container `wget` on **port 80** — full correct 302
  response in ~120ms, captured at the packet level with `tcpdump -A`.
- Database: no locks, no slow queries (`SHOW PROCESSLIST` clean).
- Network: TCP handshake completed every time (`nc -zv` open, full 3-way
  handshake visible in every packet capture); ICMP large-packet tests passed
  between every hop (host↔host, container↔container).
- TLS: the *correct* Let's Encrypt cert was served, full TLS 1.3 handshake
  completed (including a real `subjectAltName` match and "SSL certificate
  verify ok"), HTTP/2 **and** HTTP/1.1 client negotiation both completed,
  the `GET` request was sent successfully — and then **zero bytes ever came
  back**, even hitting Traefik via pure loopback (`--resolve
  host:443:127.0.0.1`), completely independent of any external network path.
- Two full restarts (`docker restart coolify-proxy`, then a full Coolify
  redeploy of the app container, getting a brand-new container ID) did not
  fix it — ruling out "stuck process" theories.

The actual differentiator, found by diffing the Traefik Docker labels Coolify
generates: the working `http` routers carry middleware
`redirect-to-https`; the broken `https` routers carry middleware `gzip`
(`traefik.http.middlewares.gzip.compress=true`). Disabling gzip/compression
for the resource in Coolify's UI and redeploying fixed it immediately —
confirmed via `curl -w "HTTP=%{http_code} time=%{time_total}s"` going from a
20s timeout to `HTTP=200 time=2.4s`.

**How to apply:**

1. **Fast diagnostic**: if `http://` works but `https://` hangs with 0 bytes
   on the exact same domain/backend, suspect a middleware difference between
   the two routers before chasing app/DB/network causes. Compare:
   ```bash
   docker inspect <container> --format '{{json .Config.Labels}}' | tr ',' '\n' | grep -i traefik
   ```
   and diff the `middlewares` value between the `http-*` and `https-*`
   routers for the same service.
2. **Decisive isolation test** (skips the entire app/network stack): from the
   Coolify host, hit Traefik directly via loopback with the real domain
   forced as SNI/Host, bypassing DNS/external network entirely:
   ```bash
   curl -v --max-time 15 --resolve <domain>:443:127.0.0.1 "https://<domain>/"
   ```
   If TLS completes (cert verifies, handshake finishes) and the request is
   sent but no response ever returns — even over loopback — the problem is
   inside Traefik's HTTPS router pipeline, not the app, DB, or external
   network. Don't spend more time on `tcpdump`/MTU/firewall theories at that
   point; go straight to the middleware chain.
3. **Fix**: disable gzip/compression for the resource in Coolify's dashboard
   (resource settings, not a label you can safely hand-edit on a running
   container) and redeploy. This is low-cost — slightly larger response
   payloads, no functional downside — so it's reasonable to disable
   preemptively on sibling country instances (MY/NG/BT/IN) running the same
   Traefik version, rather than waiting for each one to independently
   gateway-timeout before discovering the same cause.
4. This is a **Traefik v3.6 behavior** (confirmed via `docker ps` showing
   `traefik:v3.6` as the proxy image), not anything specific to this repo's
   code — a version bump may resolve it upstream, but until then, leave gzip
   off on every country resource sharing this Coolify/Traefik setup.

**What this is NOT** (false leads burned hours on, don't re-chase these next
time the same symptom appears):
- Database locks/long queries — `SHOW PROCESSLIST` was clean throughout.
- App-level slowness or worker exhaustion — Apache workers were idle, fast,
  and `MaxRequestWorkers` had huge headroom.
- `mod_evasive`/`mod_security`/fail2ban blocking the proxy's internal IP —
  none of these were installed/active.
- `HostnameLookups On` causing slow reverse-DNS per request — confirmed
  `Off` in `apache2.conf`.
- Path-MTU/fragmentation blackhole on the external network — large ICMP
  packets passed cleanly on every hop tested, and the failure reproduced
  identically over pure loopback where MTU is irrelevant.
- Stale/corrupted container state — a full redeploy (brand-new container ID)
  did not fix it, because the bug lives in the **proxy's** middleware chain,
  not the app container at all.
- Wrong backend port auto-detection by Traefik — the container only exposes
  port 80, so there was never more than one port for Traefik to guess.

See also [[feedback_country_seed_drift_menu_and_guest_pricing.md]] for an
unrelated but adjacent incident on the same Ghana instance, three days
earlier — that one was a data/seed-drift bug inside the app's own database,
not a proxy/infra issue. Worth distinguishing: "empty page, no errors" was
the seed-drift bug; "gateway timeout, 0 bytes, every layer below Traefik
checks out fine in isolation" is this one.
