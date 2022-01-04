
-- Schema creation
create schema dba ;

-- password history table
CREATE TABLE IF NOT EXISTS dba.pwdhistory
(
    usename character varying COLLATE pg_catalog."default",
    password character varying COLLATE pg_catalog."default",
    changed_on timestamp without time zone
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS dba.pwdhistory
    OWNER to postgres;


-- the function
CREATE OR REPLACE FUNCTION dba.passchanger(_password text)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
   _min_password_length int := 8;  -- specify min length here
   _usename text := '';
begin
   select user into _usename;
   if length(_password) >= _min_password_length then
      EXECUTE format('ALTER USER %I WITH PASSWORD %L', _usename, _password);
   else  -- also catches NULL
      -- raise custom error
      raise exception 'Password too short!'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please check your password.'
          , hint = 'Password must be at least ' || _min_password_length || ' characters.';
   end if;
   
   insert into dba.pwdhistory
          (usename, password, changed_on)
   values (_usename, md5(_password),now());
   EXECUTE format('update pg_catalog.pg_authid set rolvaliduntil=now() + interval ''120 days'' where rolname=''%I'' ', _usename);
--   update pg_catalog.pg_authid 
--         set rolvaliduntil='2021-12-30 00:00:00+01' where rolname='dodger' ;
   return 0;
exception
   -- trap existing error and re-raise with added detail
   when unique_violation then  -- = error code 23505   
      raise unique_violation
      using detail = 'Password already used earlier. Please try again with a different password.';
end
$BODY$;

