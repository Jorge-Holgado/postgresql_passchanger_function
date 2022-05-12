# PostgreSQL expiration date management functions

## Description

This project tries to find a way to allow users the management of the `VALID UNTIL` expiration clause by themself.
Everyghin without granting `super` permissions and having a histoc of changes on a _pseudo-audit_ table.

You can easly combine this functions with the [passwordcheck extra](https://github.com/michaelpq/pg_plugins/tree/main/passwordcheck_extra) extension, the regex inside `dba.change_valid_until` match the _default_ requirements in the extension for special characters and you can change the variable `_min_password_length` to match your requirements (in the case you changed it, of course).


| :warning: WARNING          |
|:---------------------------|
| Amazon RDS has some notes at the end... |
| :warning: WARNING          |

## Instructions

### First deploy

Modify `passchanger.sql` according your needings:
  * Change `_min_password_length` on `change_my_password` function
  * Change `_password_lifetime` on `change_valid_until` function

Deploy `passchanger.sql` on the desired cluster/database.

It will:
  * create a `dba` schema
  * create a `dba` role
  * create the `pwdhistory` table for audit purpouses
  * Grant the minimum permissions for this new role so the whole thing works
  * Create the 2 needed functions and grant permissions on them to `dba`


### Updates

Just execute the `CREATE OR REPLACE FUNCTION` part of the `passchanger.sql` file.

| :warning: WARNING          |
|:---------------------------|
| Amazon RDS has some notes at the end... |
| :warning: WARNING          |



### Allowing users to use that functions
Take the file `grants_to_grant.sql` and modify the username _dodger_ so it match the username that should have the permissions.
Execute the grants on the cluster/database you have deployed `passchanger.sql`


### Changing password & extending expiration date

The user should just execute:
```
select dba.change_my_password('YOUR_NEW_GENERATED_PASSWORD_NOT_THIS_ONE') ;
```

## Helper script

I've generated a helper script to make the process easier for users:
```
dodger@ciberterminal.net $ bash password_creator.sh 
-- CHECK: password check
-- <Wl}TxqRPBQaV_N<rU#A 
-- /CHECK: password check

-- ##############################################
select dba.change_my_password('<Wl}TxqRPBQaV_N<rU#A') ;
-- ##############################################
```


## RDS considerations

As Amazon has modified Postgresql so you don't have access as a *real* superuser and the _dangerous_ function
`change_valid_until` should run as the owner of the database (the user created when you deploy the database through AWS)

There's a `passchanger_rds.sql` file which should be used instead of the normal one.

For updates you should change the owner of the `change_valid_until` to the database _owner_:
```
ALTER FUNCTION dba.change_valid_until(text) OWNER TO _DATABASEOWNER;
```
Modify `_DATABASEOWNER` according your admin username...


## Security considerations

  * Non-RDS `change_valid_until` function does not uses `ALTER USER` to modify `VALID UNTIL`, it makes an `update pg_catalog.pg_authid set rolvaliduntil` instead, so the `dba` user has only grant over that table/column instead of granting additional permissions to him.
  * RDS `change_valid_until` should run as the database owner, is the only way to make this work as you can't access `pg_catalog.pg_authid` on rds, it uses `ALTER USER ... VALID UNTIL` instead.



