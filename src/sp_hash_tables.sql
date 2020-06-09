CREATE OR ALTER PROCEDURE [sp_hash_tables] @targetTable VARCHAR(100), @saltValue VARCHAR(512), @targetFields VARCHAR(MAX) AS


--------------------------------------------------
--Author: Jordan Balsamo
--Version: v4
--Changelog: updated hashing process to fix padding and data type issues
--------------------------------------------------

---------------------------------------------------------
--CONFIGURE TARGET TABLE HERE
---------------------------------------------------------
DECLARE @tableName VARCHAR(100)
SET @tableName = @targetTable

---------------------------------------------------------
--COLLECT META DATA/COLUMN NAMES
---------------------------------------------------------

DROP TABLE IF EXISTS #TEMP_COLS

PRINT @tableName
SELECT
	Id = ROW_NUMBER() OVER(ORDER BY(SELECT NULL)),
	COLUMN_NAME as ColumnName,
	CONCAT(COLUMN_NAME, 'Salted') as ColumnNameSalted,
	CONCAT(COLUMN_NAME, 'Hashed') as ColumnNameHashed,
	DATA_TYPE as DataType
INTO
	#TEMP_COLS
FROM
(
	SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @tableName
) schemaLookup

------------------------------------------------------------
--CONFIGURE TARGET COLUMNS HERE
------------------------------------------------------------
WHERE COLUMN_NAME IN (SELECT value as COLUMN_NAME from STRING_SPLIT(@targetFields, ','))
--WHERE COLUMN_NAME IN ('customer_name', 'customer_gender', 'customer_dob')

SELECT * FROM #TEMP_COLS

--------------------------------------------------------------
--LOOP THROUGH META TABLE & PERFORM HASH
--------------------------------------------------------------

DECLARE @rowId INT
DECLARE @column VARCHAR(MAX)
DECLARE @columnSalted VARCHAR (MAX)
DECLARE @columnHashed VARCHAR(MAX)
DECLARE @dataType VARCHAR(250)

WHILE (SELECT COUNT(*) FROM #TEMP_COLS) > 0
BEGIN

	SELECT TOP 1 @rowId = Id, @column = ColumnName, @columnSalted = ColumnNameSalted, @columnHashed = ColumnNameHashed, @dataType = DataType FROM #TEMP_COLS
	
	PRINT @tableName
	PRINT @column
	PRINT @columnSalted
	PRINT @columnHashed
	PRINT @dataType

	PRINT CONCAT( 'RowId: {', @rowId, '} Col: {', @column, '} ColSalted: {', @columnSalted, '} ColHashed: {', @columnHashed, '}')

	
	BEGIN TRY
		BEGIN TRANSACTION hashColumn
		--------------------------------------------------------
		--SHARED CMDS
		--------------------------------------------------------

		DECLARE @addSaltColCMD  VARCHAR(MAX)
		SET @addSaltColCMD = 'ALTER TABLE ' + QUOTENAME(@tableName) + ' ADD ' + QUOTENAME(@columnSalted) + ' VARCHAR(MAX)'
		PRINT @addSaltColCMD

		DECLARE @addVarBinaryColCMD VARCHAR(MAX)
		SET @addVarBinaryColCMD = 'ALTER TABLE ' + QUOTENAME(@tableName) + ' ADD ' + QUOTENAME(@columnHashed) + ' VARBINARY(MAX)'
		PRINT @addVarBinaryColCMD

		DECLARE @preSaltCMD VARCHAR(MAX)
		SET @preSaltCMD = 'UPDATE ' + QUOTENAME(@tableName) + ' SET ' + QUOTENAME(@columnSalted) + ' = CONVERT(VARCHAR(MAX), REPLACE(' + QUOTENAME(@column) + ', '' '', ''''))'
		PRINT @preSaltCMD

		DECLARE @preSaltDateCMD VARCHAR(MAX)
		SET @preSaltDateCMD = 'UPDATE ' + QUOTENAME(@tableName) + ' SET ' + QUOTENAME(@columnSalted) + ' = CONVERT(VARCHAR(MAX), DATEDIFF(SECOND, {d ''1970-01-01''}, ' + QUOTENAME(@column) + '))'
		PRINT @preSaltDateCMD

		DECLARE @saltCMD VARCHAR(MAX)       
		SET @saltCMD = 'UPDATE ' + QUOTENAME(@tableName) + ' SET ' + QUOTENAME(@columnSalted) + ' = CONCAT(''' + @saltValue + ''', ' + QUOTENAME(@columnSalted) + ')'
		PRINT @saltCMD

		DECLARE @hashCMD VARCHAR(MAX)
		SET @hashCMD = 'UPDATE ' + QUOTENAME(@tableName) + ' SET ' + QUOTENAME(@columnHashed) + ' = HASHBYTES(''SHA2_256'', ' + QUOTENAME(@columnSalted) + ')'
		PRINT @hashCMD

		DECLARE @dropOriginalColumnCMD VARCHAR(MAX)
		SET @dropOriginalColumnCMD = 'ALTER TABLE ' + QUOTENAME(@tableName) + ' DROP COLUMN ' + QUOTENAME(@column)
		PRINT @dropOriginalColumnCMD

		DECLARE @dropSaltedColumnCMD VARCHAR(MAX)
		SET @dropSaltedColumnCMD = 'ALTER TABLE ' + QUOTENAME(@tableName) + ' DROP COLUMN ' + QUOTENAME(@columnSalted)
		PRINT @dropSaltedColumnCMD

		DECLARE @renameColumnBuilderCMD VARCHAR(MAX)
		SET @renameColumnBuilderCMD = @tableName + '.' + @columnHashed 
		PRINT @renameColumnBuilderCMD

		DECLARE @alreadyHashedLOG VARCHAR(MAX)
		SET @alreadyHashedLOG = (SELECT CONCAT('Likely that ', QUOTENAME(@tableName), '.', QUOTENAME(@column), ' is already hashed. Skipping...'))
	

		--------------------------------------------------------------
		--CHECK DATATYPE AND EXEC SQL
		--------------------------------------------------------------
		IF (@dataType = 'varbinary')
			BEGIN
				PRINT @alreadyHashedLOG
			END

		ELSE IF (@dataType = 'nvarchar' or @dataType = 'varchar' or @dataType = 'bit' or @dataType = 'char' or @dataType = 'nchar' or @dataType = 'datetime')
			BEGIN

				--Add salt column
				EXEC(@addSaltColCMD)

				--Add VARBINARY column
				EXEC(@addVarBinaryColCMD)

				--Prepare salt
				IF (@dataType = 'datetime')
					BEGIN
						EXEC(@preSaltDateCMD)
					END
				ELSE
					BEGIN
						EXEC(@preSaltCMD)
					END
				--Begin salt
				EXEC(@saltCMD)

				--Set new VARBINARY column to hash of old data
				EXEC(@hashCMD)
			
				PRINT CONCAT('Hash output: ', @column, ' => ', @columnHashed)
			
				--Drop raw column
				EXEC(@dropOriginalColumnCMD)

				--Drop salt column
				EXEC(@dropSaltedColumnCMD)

				--Rename new hashed column to old name
				EXEC sp_rename @renameColumnBuilderCMD, @column, 'COLUMN'
				PRINT 'SUCCESS: review results to verify.'
				COMMIT
			END

		ELSE
			BEGIN;
				THROW 51000, 'ERROR: transaction rolled back.', 1;
			END
		
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION hashColumn
		RAISERROR( 'ERROR: transaction rolled back.', 1, 1)
	END CATCH

	DELETE FROM #TEMP_COLS WHERE Id = @rowId
END
GO