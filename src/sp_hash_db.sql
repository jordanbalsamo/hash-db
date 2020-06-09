CREATE OR ALTER PROCEDURE [dbo].[sp_hash_db]
AS

--THIS SCRIPT DEPENDS ON sp_hash_tables
---------------------------------------------------
--Author: Jordan Balsamo						 --
--Version: v4									 --
--Changelog: added compatability for v4 script	 --
---------------------------------------------------

-- Check extant data types for hashfields.
 --SELECT DISTINCT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
 --WHERE COLUMN_NAME IN ( SELECT VALUE FROM string_split('customer_name,customer_gender,customer_dob', ','))


DROP TABLE IF EXISTS #TEMP_TABLES

SELECT Id = ROW_NUMBER() OVER(ORDER BY(SELECT NULL)), TABLE_NAME as TableName INTO #TEMP_TABLES FROM
(
	SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_TYPE = 'BASE TABLE'
	--CHANGE SCHEMA SCOPE HERE:
	AND TABLE_SCHEMA = 'dbo'
	--AND TABLE_NAME  != <INSERT EXCLUSIONS HERE>
) schemaLookup

SELECT * FROM #TEMP_TABLES

DECLARE @rowId INT
DECLARE @table NVARCHAR(MAX)
DECLARE @salt NVARCHAR(512) = '' -- OR NEWID()

IF(@salt !=  '')
	BEGIN
		PRINT 'The SALT for this transaction is: ' + @salt + '. Please note this down.' 
	END
	
WHILE (SELECT COUNT(*) FROM #TEMP_TABLES) > 0
BEGIN

	SELECT TOP 1 @rowId = Id, @table = TableName FROM #TEMP_TABLES

	PRINT @rowId
	PRINT @table
	

	PRINT CONCAT( 'RowId: {', @rowId, '} Table: {', @table, '}')

	
	BEGIN TRY
		BEGIN TRANSACTION

		EXEC [sp_hash_tables] @targetTable = @table, @saltValue = @salt, @targetFields = 'customer_name,customer_gender,customer_dob'

		COMMIT

		PRINT 'SUCCESS: check results to verify.'
		
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW 51000, 'Error occured in sp_hash_db', 1;
	END CATCH

	DELETE FROM #TEMP_TABLES WHERE Id = @rowId
END

------------------------------------------------------
--REVIEW RESULTS
------------------------------------------------------
--Underlying script will emit result sets
GO