-- grant execution on the function
grant execute on function dba.passchanger(_password text) to dodger;

-- only insert is needed to allow audit trace
GRANT INSERT ON TABLE dba.pwdhistory TO dodger;

-- the following permissions are necessary to change the 'VALID UNTIL' date
grant select on pg_catalog.pg_authid to dodger ;
grant update (rolvaliduntil) on pg_catalog.pg_authid to dodger ;
