
-- grant usage for schema dba
grant usage on schema dba to dodger ;

-- grant execute on the function change_my_password
grant execute on function dba.change_my_password(text) to dodger;
-- grant execute on the function change_valid_until
grant execute on function dba.change_valid_until(text) to dodger;

-- only insert is needed to allow audit trace
GRANT INSERT ON TABLE dba.pwdhistory TO dodger;

