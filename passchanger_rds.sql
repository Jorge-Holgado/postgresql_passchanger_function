
-- Schema creation
create schema dba ;

-- role creation
create role dba with NOLOGIN NOINHERIT ;

-- grants for dba
GRANT rds_superuser TO dba ;

-- grant select on pg_catalog.pg_authid to dba ;
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

drop function dba.change_valid_until ;

CREATE OR REPLACE FUNCTION dba.change_valid_until(_usename text, _thepassword text)
    RETURNS integer
    SECURITY DEFINER
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    _invokingfunction text := '';
    _matches text;
    --_password_lifetime text := '120 days';  -- specify password lifetime
    _retval  INTEGER;
    _expiration_date text;
begin
    select now() + interval '120 days' into _expiration_date ;
    select query into _invokingfunction from pg_stat_activity where pid = pg_backend_pid() ;
    -- first, checking the invoking function
    _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\(.*\\)[[:space:]]{0,};' , 'i');
--     raise notice 'Matches: %', _matches;
    if _matches IS NOT NULL then
        -- then checking the regex for the password
        _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\([[:space:]]{0,}''([[:alnum:]]|@|\\$|#|%|\\^|&|\\*|\\(|\\)|\\_|\\+|\\{|\\}|\\||<|>|\\?|=|!){11,100}''[[:space:]]{0,}\\)[[:space:]]{0,};' , 'i');
        -- catch-all regexp, avoid using it
        -- _matches := regexp_matches(_invokingfunction, E'select dba\.change_my_password\\(.*\\)[[:space:]]{0,};' , 'i');
        if _matches IS NOT NULL then
            --EXECUTE format('ALTER ROLE %I WITH PASSWORD %L VALID UNTIL now() + interval %L days ;', _usename, _thepassword, _password_lifetime);
            EXECUTE format('ALTER ROLE %I WITH PASSWORD %L VALID UNTIL %L ;', _usename, _thepassword, _expiration_date);
            -- INTO _retval;
            RETURN 0;
        else
            raise exception 'Regular expresion for password check failed'
            using errcode = '22023'  -- 22023 = "invalid_parameter_value'
            , detail = 'Check your generated password (' || _thepassword || ') an try again'
            , hint = 'Read the official documentation' ;
        end if;
    else  
      -- also catches NULL
      -- raise custom error
      raise exception 'You''re not allowed to run this function directly'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please call dba.change_my_password function.'
          , hint = 'Invoked function: ' || _invokingfunction ;
    end if;
end
$BODY$;

ALTER FUNCTION dba.change_valid_until(text, text) OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_valid_until(text, text) From PUBLIC;

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
begin
    select user into _usename;
    if user = 'postgres' then
        raise exception 'This function should not be run by user postgres'
        using errcode = '22024'  -- 22023 = "invalid_parameter_value'
          , detail = 'Use a named user only.' ;
    end if;

    if length(_password) < _min_password_length then
      -- also catches NULL
      -- raise custom error
      raise exception 'Password too short!'
      using errcode = '22023'  -- 22023 = "invalid_parameter_value'
          , detail = 'Please check your password.'
          , hint = 'Password must be at least ' || _min_password_length || ' characters.';
    end if;

    select client_addr into _useraddress from pg_stat_activity where pid = pg_backend_pid() ;
    select application_name into _userapp from pg_stat_activity where pid = pg_backend_pid() ;

    PERFORM dba.change_valid_until(_usename, _password) ;
    insert into dba.pwdhistory
          (usename, usename_addres, application_name, password, changed_on)
    values (_usename, _useraddress, _userapp, md5(_password),now());

    return 0;
end
$BODY$;

ALTER FUNCTION dba.change_my_password(text) OWNER TO dba;
REVOKE EXECUTE ON FUNCTION dba.change_my_password(text) From PUBLIC;

