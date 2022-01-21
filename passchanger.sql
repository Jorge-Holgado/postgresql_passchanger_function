
-- Schema creation
create schema dba ;

-- role creation
create role dba with NOLOGIN NOINHERIT ;

-- grants for dba
grant select on pg_catalog.pg_authid to dba ;
grant update (rolvaliduntil) on pg_catalog.pg_authid to dba ;
grant pg_read_all_stats to dba ;


-- password history table
CREATE TABLE IF NOT EXISTS dba.pwdhistory
(
    usename character varying COLLATE pg_catalog."default",
    usename_addres character varying COLLATE pg_catalog."default",
    application_name character varying COLLATE pg_catalog."default",
    password character varying COLLATE pg_catalog."default",
    changed_on timestamp without time zone
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS dba.pwdhistory
    OWNER to dba;



-- ######################################
-- ######################################

-- real functions

-- ######################################
-- ######################################

CREATE OR REPLACE FUNCTION dba.change_valid_until(_usename text)
    RETURNS integer
    SECURITY DEFINER
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
   _invokingfunction text := '';
   _matches text;
begin
    select query into _invokingfunction from pg_stat_activity where pid = pg_backend_pid() ;
--     raise notice 'Invoking function: %', _invokingfunction;
    _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\(''([[:alnum:]]|@|\\$|#|%|\\^|&|\\*|\\(|\\)|\\_|\\+|\\{|\\}|\\||<|>|\\?|=){1,100}''\\)[[:space:]]{0,};' , 'i');
--     raise notice 'Matches: %', _matches;
    if _matches IS NOT NULL then
      EXECUTE format('update pg_catalog.pg_authid set rolvaliduntil=now() + interval ''120 days'' where rolname=''%I'' ', _usename);
      return 0;
    else  -- also catches NULL
      -- raise custom error
      raise exception 'You''re not allowed to run this function directly'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please call dba.change_my_password function.'
          , hint = 'Invoked function: ' || _invokingfunction ;
    end if;
end
$BODY$;

ALTER FUNCTION dba.change_valid_until(text)
    OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_valid_until(text) From PUBLIC;


CREATE OR REPLACE FUNCTION dba.change_my_password(_password text)
    RETURNS integer
    SECURITY INVOKER
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
   _min_password_length int := 8;  -- specify min length here
   _usename text := '';
   _useraddress text := '';
   _userapp text := '';
begin
   select user into _usename;
   select client_addr user into _useraddress from pg_stat_activity where pid = pg_backend_pid() ;
   select application_name user into _userapp from pg_stat_activity where pid = pg_backend_pid() ;
   if length(_password) >= _min_password_length then
      EXECUTE format('ALTER USER %I WITH PASSWORD %L', _usename, _password);
   else  -- also catches NULL
      -- raise custom error
      raise exception 'Password too short!'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please check your password.'
          , hint = 'Password must be at least ' || _min_password_length || ' characters.';
   end if;
   if user = 'postgres' then
      raise exception 'This function should not be run by user postgres'
      using errcode = '22024'  -- 22023 = "invalid_parameter_value'
          , detail = 'Use a named user only.' ;
   else 
       insert into dba.pwdhistory
              (usename, usename_addres, application_name, password, changed_on)
       values (_usename, _useraddress, _userapp, md5(_password),now());
       PERFORM dba.change_valid_until(_usename) ;
   end if;

   return 0;
end
$BODY$;

ALTER FUNCTION dba.change_my_password(text)
    OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_my_password(text) From PUBLIC;

