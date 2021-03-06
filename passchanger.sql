
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

-- alter if you come from a previous version of the table:
-- alter table dba.pwdhistory add column usename_addres character varying ;
-- alter table dba.pwdhistory add column application_name character varying ;

ALTER TABLE IF EXISTS dba.pwdhistory
    OWNER to dba;



-- ######################################
-- ######################################

-- real functions

-- ######################################
-- ######################################

drop function if exists dba.change_valid_until ;

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
    _password_lifetime integer := 120 ;  -- specify password lifetime in days
    _retval  INTEGER;
    _expiration_date numeric ;
begin
    select extract(epoch from localtimestamp) into _expiration_date;
    select _expiration_date+(_password_lifetime*24*60*60) into _expiration_date;

    select query into _invokingfunction from pg_stat_activity where pid = pg_backend_pid() ;
    -- first, checking the invoking function
    _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\(.*\\)[[:space:]]{0,};' , 'i');
    if _matches IS NOT NULL then
      -- then checking the regex for the password
        _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\([[:space:]]{0,}''([[:alnum:]]|@|\\$|#|%|\\^|&|\\*|\\(|\\)|\\_|\\+|\\{|\\}|\\||<|>|\\?|=|!){11,100}''[[:space:]]{0,}\\)[[:space:]]{0,};' , 'i');
        if _matches IS NOT NULL then
            EXECUTE format('update pg_catalog.pg_authid set rolvaliduntil=to_timestamp(%L) where rolname=%L ', _expiration_date, _usename);
            -- INTO _retval;
            RETURN 0;
        else
            raise exception 'Regular expresion for password check failed'
            using errcode = '22023'  -- 22023 = "invalid_parameter_value'
            , detail = 'Check your generated password an try again'
            , hint = 'Read the official documentation' ;
            RETURN 1;
        end if;
    else  
      -- also catches NULL
      -- raise custom error
      raise exception 'You''re not allowed to run this function directly'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please call dba.change_my_password function.'
          , hint = 'Invoked function: ' || _invokingfunction ;
      RETURN 1;
    end if;
end
$BODY$;

ALTER FUNCTION dba.change_valid_until(text) OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_valid_until(text) From PUBLIC;

CREATE OR REPLACE FUNCTION dba.change_my_password(_password text)
    RETURNS integer
    SECURITY INVOKER
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    _min_password_length int := 12;  -- specify min length here
    _usename text := '';
    _useraddress text := '';
    _userapp text := '';
    _retval integer ;
begin
   select user into _usename;
   if user = 'postgres' then
      raise exception 'This function should not be run by user postgres'
      using errcode = '22024'  -- 22023 = "invalid_parameter_value'
          , detail = 'Use a named user only.' ;
      return 1;
   end if;

   if length(_password) < _min_password_length then
      -- also catches NULL
      -- raise custom error
      raise exception 'Password too short!'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please check your password.'
          , hint = 'Password must be at least ' || _min_password_length || ' characters.';
      return 1;
   end if;

   select client_addr into _useraddress from pg_stat_activity where pid = pg_backend_pid() ;
   select application_name into _userapp from pg_stat_activity where pid = pg_backend_pid() ;

    --PERFORM dba.change_valid_until(_usename) ;
    SELECT dba.change_valid_until(_usename)
        INTO _retval;
    -- this will be executed by the username invoking this function
    if _retval = 0 then
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', _usename, _password);
        insert into dba.pwdhistory
               (usename, usename_addres, application_name, password, changed_on)
        values (_usename, _useraddress, _userapp, md5(_password),now());

        raise notice 'Password changed' ;
    else
        raise exception 'Could not change expiration date, please check'
        using errcode = '22023'  -- 22023 = "invalid_parameter_value'
            , detail = 'contact the dba' ;
        return 1;
    end if;

    return 0;
end
$BODY$;

ALTER FUNCTION dba.change_my_password(text) OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_my_password(text) From PUBLIC;

