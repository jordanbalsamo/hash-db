DECLARE @algo NVARCHAR(100) = 'SHA2_256'
DECLARE @testCase NVARCHAR(500) = 'test'
DECLARE @pyHash NVARCHAR(500) = 'cd6357efdd966de8c0cb2f876cc89ec74ce35f0968e11743987084bd42fb8944';

DECLARE @testTable TABLE (
nvarchar_test NVARCHAR(500),
varchar_test VARCHAR(500),
char_test CHAR(500)
)

INSERT INTO @testTable
VALUES ('test', 'test', 'test')

SELECT 
	HASHBYTES(@algo, nvarchar_test) AS rawNvarcharHash,
	LOWER(CONVERT(VARCHAR(500), HASHBYTES(@algo, nvarchar_test),2)) AS cleanNvarcharHash,
	HASHBYTES(@algo, varchar_test) AS rawVarcharHash,
	LOWER(CONVERT(VARCHAR(500), HASHBYTES(@algo, varchar_test),2)) AS clesnVarcharHash,
	HASHBYTES(@algo, char_test) AS rawCharHash,
	LOWER(CONVERT(VARCHAR(500), HASHBYTES(@algo, char_test),2)) AS cleanCharHash,
	
	'|' as [|],
	
	--

	--THIS FIXES NVARCHAR / CHAR DATA TYPE BY: (1) removing whitespace with replace, (2) converting to varchar and then hashing, (3) taking SQL hash with '0x' prefix and converting to string representation', (4) lowering for use globally.
	LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(nvarchar_test, ' ', ''))),2)) fixHashNvarchar,
	LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(nvarchar_test, ' ', ''))),2)) fixHashVarchar,
	LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(char_test, ' ', ''))),2)) fixHashChar,
	--CHECK HASH IS CONSISTENT WITH VARCHAR DATA TYPE:
	CASE WHEN
		LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(nvarchar_test, ' ', ''))),2)) = @pyHash AND LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(varchar_test, ' ', ''))),2)) = @pyHash AND LOWER(CONVERT(VARCHAR(500),HASHBYTES(@algo, CONVERT(VARCHAR(500), REPLACE(char_test, ' ', ''))),2)) = @pyHash THEN 'TRUE'
		ELSE 'FALSE'
	END AS isConsistent

		
FROM @testTable