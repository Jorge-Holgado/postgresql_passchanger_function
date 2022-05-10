# PostgreSQL expiration date management functions

## Description

This project tries to find a way to allow users the management of the `VALID UNTIL` expiration clause by themself.
All without granting `super` permissions and having a histoc of changes on a _pseudo-audit_ table

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
ALTER FUNCTION dba.change_my_password(text) OWNER TO _DATABASEOWNER;
```
Modify `_DATABASEOWNER` according your admin username...


