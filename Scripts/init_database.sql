/*
====================================================================
DATA WAREHOUSE INIT FILE 
--------------------------------------------------------------------
	THIS FILE GENERATES A DATABASE NAMED "DataWarehouse" WITH THREE 
	SCHEMAS "bronze", "silver" AND "gold". EACH SCHEMA CORESPONDS TO 
	A LAYER IN THE DATA WAREHOUSE. 
--------------------------------------------------------------------
WARNING: 
	THIS FILES CHECKS IF THE DATABASE "DataWarehouse" EXISTS FIRST 
	AND THEN DROPS IT TO GENERATE A NEW ONE. RUNNING THIS SCRIPT 
	WILL DROP ANY EXISTING DATABASE SO USE WITH CATUION.
====================================================================
*/

USE master
GO
--CHECKS IF THE "DataWarehouse" DATA BASE EXISTS, IF IT EXISTS DROPS IT 
IF EXISTS(SELECT name FROM sys.databases where name = N'DataWarehouse')
BEGIN 
ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE DataWarehouse;
END 
GO 

--CREATES THE "DataWarehouse" DATABASE 
CREATE DATABASE DataWarehouse;
GO 
--USES THE CREATED DATABASE TO GENERATE THE DATABASE SCHEMAS 
USE DataWarehouse;
GO

--CREATES THE BRONZE LAYER SCHEMA 
CREATE SCHEMA bronze;
GO 
--CREATES THE SILVER LAYER SCHEMA 
CREATE SCHEMA silver;
GO 
--CREATES THE GOLD LAYER SCHEMA 
CREATE SCHEMA gold; 
GO 
