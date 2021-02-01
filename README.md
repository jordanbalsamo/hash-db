# HashDB
A set of SQL SPs to recursively hash given columns throughout a given database.

## Inputs

The top-level SP (sp_hash_db) takes two arguments:

- **@targetTable**: this is an iterable that is generated in the SP itself. If you need to alter the scope of tables to be hashed, add your conditions to the WHERE clause.
- **@salt**: set this in the SP. This is the value that will be prepended to the column value, prior to hashing. If it is left blank - '' - there will be no salt added to the hash process. 
- **@targetFields**: a string of desired fields to hash. ***NOTE: it must not contain spaces***. For example:

        'name,address,telephone' will work;
        'name, address, telephone' will not work.

The bottom level SP (sp_hash_tables) should not require any further configuration prior to running.

## Outputs

The database will be hashed according to the inputs you provide above.

It is worth noting that target hash of type datetime will be converted to UNIX Epoch timestamps and then hashed with the given algorithm. If comparing or joining on hashes, any date times in the comparison dataset will need to be converted to UNIX Epoch timestamps first and then hashed with the same algorithm, to ensure hash equivalence.

## TODO:

1. Add support for passing in other hashing algorithms;
2. Unit testing of functionality to be added.

