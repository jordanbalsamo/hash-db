--SETUP TEST DATA
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
	customer_name varchar(500),
	customer_gender char(1),
	customer_dob datetime
)

INSERT INTO customers(customer_name, customer_gender, customer_dob)
VALUES ('Tester', 'M', '2020-03-02 17:21:58.450')

SELECT * FROM Customers;

--DEPLOY HASH SCRIPT FIRST;

--TEST

EXEC [dbo].[sp_HashDB_v4]

select * from customers


--REMOVE 0x prefix

SELECT
	LOWER(CONVERT(VARCHAR(500), customer_name, 2)),
	LOWER(CONVERT(VARCHAR(500), customer_gender, 2)),
	LOWER(CONVERT(VARCHAR(500), customer_dob, 2))
	
FROM customers


SELECT 
	customer_dob,
	DATEDIFF(SECOND, {d '1970-01-01'}, customer_dob) epochTime,
	HASHBYTES('SHA2_256', CONVERT(VARCHAR(500), customer_dob)) attemptToHashDateTime,
	LOWER(CONVERT(VARCHAR(500),HASHBYTES('SHA2_256', CONVERT(VARCHAR(500), DATEDIFF(SECOND, {d '1970-01-01'}, customer_dob))),2)) epochTimeHashed

FROM
	customers


