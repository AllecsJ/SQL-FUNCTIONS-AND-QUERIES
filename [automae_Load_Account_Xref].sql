
GO
/****** Object:  StoredProcedure [dbo].[update_Load_Account_Xref]    Script Date: 25/09/2022 01:05:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--==============================================================================
-- DBMS Name        :    TemenosMigration_BellBank
-- Procedure Name   :    update_stage_account
-- Description      :    Update table update_stage_account
-- Author           :    Alex Jackson
--==============================================================================
-- Notes / History

ALTER PROCEDURE [dbo].[update_Load_Account_Xref]

	@p_return_msg	VARCHAR(256) OUTPUT
	, @p_status		INTEGER      OUTPUT
	, @p_rowcount	INTEGER      OUTPUT

	AS 
	SET XACT_ABORT OFF  -- Turn off auto abort on errors
	SET NOCOUNT ON      -- Turn off row count messages

  --=====================================================
  -- Control variables used in most programs
  --=====================================================
	DECLARE
	@v_msgtext				VARCHAR(255)  -- Text for audit_trail
	, @v_sql				NVARCHAR(255) -- Text for SQL statements
	, @v_step				INTEGER       -- return code
	, @v_insert_count		INTEGER       -- no of records inserted
	, @v_return_status		INTEGER       -- Update result status
	, @v_current_datetime	DATETIME      -- Used for date insert

  --=====================================================
  -- General Variables
  --=====================================================

  --=====================================================
  -- MAIN
  --=====================================================
	SET @v_step = 100
	SET @v_insert_count = 0
	SET @v_current_datetime = GETDATE()

	BEGIN TRY

    --=====================================================
    -- Delete existing records
    --=====================================================
    SET @v_step = 200

	RAISERROR('Trucating table: load_account_xref', 0, 10) WITH NOWAIT;

    --=====================================================
    -- Insert new records
    --=====================================================
    SET @v_step = 300
    
    BEGIN TRANSACTION

	DECLARE @VM CHAR = CHAR(253)
	DECLARE @ABV CHAR = CHAR(3)
	DECLARE @TEMP CHAR = CHAR(253)
	DECLARE @LAST_WORKING_DAY DATE, @TODAY DATE, @NEXT_WORKING_DAY DATE, @SOURCE VARCHAR(2)
	SELECT @LAST_WORKING_DAY = LAST_WORKING_DAY FROM [dbo].[load_migration_config_date]
	SELECT @TODAY = TODAY FROM [dbo].[load_migration_config_date]
	SELECT @NEXT_WORKING_DAY = NEXT_WORKING_DAY FROM [dbo].[load_migration_config_date]
	SELECT @SOURCE = code FROM [dbo].[load_migration_source]
	SELECT @ABV = ABV FROM [dbo].[load_migration_source]

		TRUNCATE TABLE load_account_xref
	;WITH
	Primary_Customers  ---SELECT * THE PRIMARY CUSTOMERS
	AS 
	(
		SELECT
		LEGACY_REF [ACCOUNT]
		,CUSTOMER
		,'Primary' [RELATIONSHIP]
		FROM load_account 
	),
	Joint_Customers  (ACCOUNT, CUSTOMER, JOINT_HOLDER, RELATIONSHIP, RELATION_CODE) --RECURSIVLY ITERATE THROUGH JOINT HOLDER AND RELATION CODE
	AS 
	(
		SELECT
		LEGACY_REF [ACCOUNT]
		,CAST(LEFT(LA.JOINT_HOLDER, CHARINDEX('|', LA.JOINT_HOLDER + '|') - 1) AS VARCHAR(35)) [CUSTOMER]
        ,STUFF(LA.JOINT_HOLDER, 1, CHARINDEX('|', LA.JOINT_HOLDER + '|'), '') [JOINT_HOLDER]
		,CAST(LEFT(LA.RELATION_CODE, CHARINDEX('|', LA.RELATION_CODE + '|') - 1) AS VARCHAR(35)) [RELATIONSHIP]
		,STUFF(LA.RELATION_CODE, 1, CHARINDEX('|', LA.RELATION_CODE + '|'), '') [RELATION_CODE]
		FROM load_account LA

		UNION ALL 
		SELECT
		ACCOUNT [ACCOUNT]
		,CAST(LEFT(JOINT_HOLDER, CHARINDEX('|', JOINT_HOLDER + '|') - 1) AS VARCHAR(35)) [CUSTOMER]
        ,STUFF(JOINT_HOLDER, 1, CHARINDEX('|', JOINT_HOLDER + '|'), '') [JOINT_HOLDER]
		,CAST(LEFT(RELATION_CODE, CHARINDEX('|', RELATION_CODE + '|') - 1) AS VARCHAR(35)) [RELATIONSHIP]
		,STUFF(RELATION_CODE, 1, CHARINDEX('|', RELATION_CODE + '|'), '') [RELATION_CODE]
		
		FROM Joint_Customers  ---CALL BACK
		WHERE JOINT_HOLDER > '' --TERMINATION 
	) 

	INSERT INTO load_account_xref
				([ACCOUNT],
				 [CUSTOMER],
				 [RELATIONSHIP]
				)

	SELECT 
	ACCOUNT
	,CUSTOMER
	,RELATIONSHIP 
	FROM Primary_Customers

	UNION ALL
	SELECT
	ACCOUNT
	,CUSTOMER
	,'Joint ' + RELATIONSHIP [RELATIONSHIP]
	FROM Joint_Customers
	WHERE CUSTOMER <> '' OR CUSTOMER IS NULL


			
	


	SELECT @p_rowcount = @@ROWCOUNT,@v_insert_count = @@ROWCOUNT

    COMMIT

    --=====================================================
    -- All Done report the results
    --=====================================================

 SET @v_step = 400

    SET @p_status = 1
    SET @p_return_msg = 'update_stage_account. '
    + CONVERT(VARCHAR,@v_insert_count) + ' new records.'

	INSERT INTO migration_logs(process_name, output_message, log_status)
	VALUES(OBJECT_NAME(@@PROCID), @p_return_msg, 'SUCCESS')

    RETURN 0

	END TRY
	
	BEGIN CATCH

    SET @p_status = -2
    SET @p_return_msg = SUBSTRING('update_stage_account FAILED with error '
	+ CONVERT(VARCHAR,ISNULL(ERROR_NUMBER(),0))
	+ ' Step ' + CONVERT(VARCHAR,ISNULL(@v_step,0))
	+ '. Error Msg: ' + ERROR_MESSAGE(),1,255)
  
	IF XACT_STATE() <> 0
	BEGIN
	ROLLBACK TRANSACTION
	END

	INSERT INTO migration_logs(process_name, output_message, log_status)
	VALUES(OBJECT_NAME(@@PROCID), @p_return_msg, 'ERROR')
	
	END CATCH

	
	RETURN 0