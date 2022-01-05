
-- grant usage for schema dba
grant usage on schema dba to dodger ;

-- grant execute on the function that change_my_password the pass  but no on the one that change VALID UNTIL
grant execute on function dba.change_my_password(text) to dodger;

-- only insert is needed to allow audit trace
GRANT INSERT ON TABLE dba.pwdhistory TO dodger;

