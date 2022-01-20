# PostgreSQL expiration date management functions

## Description

This project tries to find a way to allow users the management of the `VALID UNTIL` expiration clause by themself.
All without granting `super` permissions and having a histoc of changes on a _pseudo-audit_ table

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


