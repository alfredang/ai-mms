# MySQL fixture readiness must use TCP

Use `mysqladmin ping -h 127.0.0.1` for the disposable handover fixture's health check. Do not use `localhost`, which can select a Unix socket.

On 2 November 2026 the fixture reported healthy during MySQL's socket-only bootstrap/seed phase. The immediately started PHP integration suite then failed its TCP PDO connection with `Connection refused`; retrying after bootstrap completed passed. A socket ping therefore does not establish that the API container can connect to the database.

Apply this rule when starting MySQL-backed test containers. The working configuration is in `scripts/tests/docker-compose.handover.yml` under `mysql.healthcheck`. It keeps integration tests from racing the temporary initialization server.
