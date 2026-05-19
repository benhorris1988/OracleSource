-- Runs once on first start, as SYS against the application PDB.
-- The APP_USER is already created by the container entrypoint from the
-- APP_USER / APP_USER_PASSWORD env vars; we just hand it the extra grants
-- needed to run the IFS seed (CREATE USER for any extra schemas the app
-- generates, plus unlimited tablespace so the INSERT bank actually fits).

GRANT CREATE USER TO IFSAPP;
GRANT UNLIMITED TABLESPACE TO IFSAPP;
GRANT CREATE ANY TABLE TO IFSAPP;
GRANT INSERT ANY TABLE TO IFSAPP;
GRANT SELECT ANY DICTIONARY TO IFSAPP;
