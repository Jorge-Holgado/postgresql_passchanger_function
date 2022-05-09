# PostgreSQL expiration date management functions

## Description

This project tries to find a way to allow users the management of the `VALID UNTIL` expiration clause by themself.
All without granting `super` permissions and having a histoc of changes on a _pseudo-audit_ table

| :warning: WARNING          |
|:---------------------------|
| Amazon RDS has its own instructions on README_RDS.md |
|:---------------------------|
| :warning: WARNING          |

## Instructions

### First deploy
Deploy `passchanger.sql` on the desired cluster/database.

It will:
  * create a `dba` schema
  * create a `dba` role
  * create the `pwdhistory` table for audit purpouses
  * Grant the minimum permissions for this new role so the whole thing works
  * Create the 2 needed functions and grant permissions on them to `dba`


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
