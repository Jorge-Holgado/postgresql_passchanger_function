
-- grant usage for schema dba
grant usage on schema dba to dodger ;

-- grant execute on the function change_my_password
grant execute on function dba.change_my_password(text) to dodger;
-- grant execute on the function change_valid_until
grant execute on function dba.change_valid_until(text, text) to dodger;

-- only insert is needed to allow audit trace
GRANT INSERT ON TABLE dba.pwdhistory TO dodger;



-- SET SESSION AUTORIZATION dodger ;



'tV4{A#&x|P%hKM9*}4a0'

select dba.change_my_password( 'XFF{O>%|<e%_#F$pHqaB' ) ;


XFF{O>%|<e%_#F$pHqaB
