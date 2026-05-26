# Oracle Source — local Oracle service

Spins up a real Oracle Database Free 23c container so external consumers
(BI tools, ETL jobs, the ConnectorExpenses operator console, …) can
extract data from the IFS source you designed in the Flutter app.

## Quick start

```bash
cd docker
cp .env.example .env          # adjust credentials if you like
docker compose up -d          # first start: ~5 min while Oracle provisions
docker compose logs -f oracle # watch progress
```

When you see `DATABASE IS READY TO USE!` you can connect:

| Setting       | Value                                      |
|---------------|--------------------------------------------|
| Host          | `localhost`                                |
| Port          | `1521`                                     |
| Service name  | `IFSPRD` (set via `ORACLE_PDB` in `.env`)  |
| Username      | `IFSAPP` (set via `APP_USER`)              |
| Password      | `ifs_dev_password` (set via `APP_USER_PASSWORD`) |

JDBC: `jdbc:oracle:thin:IFSAPP/ifs_dev_password@//localhost:1521/IFSPRD`

The Flutter app's **Source settings → Credentials** card shows the same
values and a copy-able JDBC URL.

## Loading IFS seed data

The container's init scripts in `docker/init/` run once on first start:

| File              | Runs as | Purpose                                     |
|-------------------|---------|---------------------------------------------|
| `00_grants.sql`   | SYS     | Extra privileges on IFSAPP                  |
| `01_seed.sql`     | IFSAPP  | DDL + INSERTs for the IFS schema (you fill) |

`01_seed.sql` ships as a placeholder. To populate Oracle with the IFS
sample data from the Flutter app:

1. Run the app (`flutter run -d chrome` from the project root).
2. **Source settings → "Copy seed SQL (DDL + INSERTs)"**.
3. Replace `docker/init/01_seed.sql` with the clipboard contents.
4. From `docker/`: `docker compose down -v && docker compose up -d`.

The `-v` flag wipes the `oracle_data` volume, which is what makes Oracle
re-run the init scripts on the next start.

## Keeping config in sync

`config/source.json` is the project's source of truth for connection
metadata. The Flutter app reads it for defaults; this Docker setup reads
the same values from `docker/.env`. If you change the password in the
app, also update both files:

- `docker/.env` — `APP_USER_PASSWORD=…`
- `config/source.json` — `"password": "…"`

(or use **Source settings → "Copy config/source.json"** which dumps the
current state in the exact shape `config/source.json` expects.)

## Tearing down

```bash
docker compose down       # stops the container, keeps data
docker compose down -v    # also removes the oracle_data volume → next
                          # `up` does a fresh provision and re-runs init
```
