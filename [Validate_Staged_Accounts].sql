
GO
/****** Object:  StoredProcedure [dbo].[Validate_Staged_Accounts]    Script Date: 25/09/2022 01:04:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Validate_Staged_Accounts]
@Source CHAR(2)
AS
BEGIN

DECLARE @p_return_msg VARCHAR(2000), @p_rowcount VARCHAR(2000), @p_status TINYINT = 0
SELECT @SOURCE = code FROM [dbo].[load_migration_source]

	DELETE FROM [dbo].[Migration_Validation_Failure] where table_name = 'stage_account'
	RAISERROR('Deleting stage_account validation errors from table: migration_validation_failure ', 0 , 10) WITH NOWAIT;

	RAISERROR('Validating code mappings...', 0 , 10) WITH NOWAIT;


	/*--------------------------------------------------RELATION_CODE--------------------------------------------------*/
	--/****     Validate Relation Code mapping     ****/
	TRUNCATE TABLE [dbo].[load_account_relation_code_xref]
	;WITH Multi_Relations (RELATIONSHIP, RELATION_CODE) AS 
	(
		SELECT DISTINCT
		CAST(LEFT(LC.RELATION_CODE, CHARINDEX('|', LC.RELATION_CODE + '|') - 1) AS VARCHAR(35)) [RELATIONSHIP]
		,STUFF(LC.RELATION_CODE, 1, CHARINDEX('|', LC.RELATION_CODE + '|'), '') [RELATION_CODE]
		FROM [dbo].[load_loan] LC WHERE LC.RELATION_CODE LIKE '%|%'

		UNION ALL 
		SELECT
		CAST(LEFT(RELATION_CODE, CHARINDEX('|', RELATION_CODE + '|') - 1) AS VARCHAR(35)) [RELATIONSHIP]
		,STUFF(RELATION_CODE, 1, CHARINDEX('|', RELATION_CODE + '|'), '') [RELATION_CODE]
		
		FROM Multi_Relations  
		WHERE RELATION_CODE > ''  
	) 
	,Loan_Relations As
	(
		SELECT DISTINCT
		RELATION_CODE [RELATION_CODE]
		FROM [dbo].[load_loan] WHERE RELATION_CODE NOT LIKE '%|%'

		UNION ALL
		SELECT DISTINCT
		RELATIONSHIP [RELATION_CODE]
		FROM Multi_Relations
	)
	INSERT INTO [dbo].[load_loan_relation_code_xref]	
	SELECT DISTINCT RELATION_CODE FROM Loan_Relations WHERE RELATION_CODE <> ''

	IF EXISTS 
	(
		SELECT LC.RELATION_CODE
		FROM [dbo].[load_loan_relation_code_xref] LC
		LEFT JOIN [dbo].[map_t24_relation_code] MT
			ON MT.LEGACY_CODE = LC.RELATION_CODE
		WHERE MT.T24_CODE IS NULL
	)
	BEGIN 
		;WITH UNMAPPED AS (
			SELECT LC.RELATION_CODE FROM [dbo].[load_loan_relation_code_xref] LC
			LEFT JOIN [dbo].[map_t24_relation_code] MT ON MT.LEGACY_CODE = LC.RELATION_CODE
			WHERE MT.T24_CODE IS NULL
		)
		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
		SELECT 
			'stage_customer' [Table_Name],
			@SOURCE [Source],
			CONCAT('Mapping issue: RELATION_CODE ',(RELATION_CODE),' is unmapped') [Error_Message] 
		FROM UNMAPPED
		SET @p_status = 1
	END

	Set @p_return_msg = STUFF((SELECT CHAR(10)+ [Error_Message]
	FROM [dbo].[Migration_Validation_Failure] WHERE [Table_Name] = 'stage_ld_loans_and_deposits'
	FOR XML PATH('')), 1, 1, '')
			
	IF @p_status = 0 RAISERROR('Code mapping validation successful.', 0 , 10) WITH NOWAIT;
	IF @p_status = 1 RAISERROR('Code mapping validation failed.', 0 , 10) WITH NOWAIT;
	RAISERROR(@p_return_msg, 0, 10) WITH NOWAIT;




	/*--------------------------------------------------CNTRL_BK_CODE--------------------------------------------------*/
	IF EXISTS 
	(
		SELECT DISTINCT LA.CNTRL_BK_CODE
		FROM [dbo].[load_account] LA
		LEFT JOIN [dbo].[map_t24_account_cntrl_bk_code] MT
			ON MT.LEGACY_CODE = LA.CNTRL_BK_CODE
		WHERE MT.T24_CODE IS NULL
	)
	BEGIN
		;WITH UNMAPPED AS (
			SELECT DISTINCT LA.CNTRL_BK_CODE FROM [dbo].[load_account] LA 
			LEFT JOIN [dbo].[map_t24_account_cntrl_bk_code] MT 
			ON MT.LEGACY_CODE = LA.CNTRL_BK_CODE WHERE MT.T24_CODE IS NULL)

		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
			SELECT 
				'stage_account' [Table_Name],
				@SOURCE [Source],
				CONCAT('Mapping issue: CNTRL_BK_CODE ',(CNTRL_BK_CODE),' is unmapped') [Error_Message] 
				FROM UNMAPPED
				SET @p_status = 1
	END

	/**--------------------------------------------------REG_PROD_SECTOR--------------------------------------------------**/
	IF EXISTS 
	(	
		SELECT DISTINCT LA.REG_PROD_SECTOR FROM [dbo].[load_account] LA
		LEFT JOIN [dbo].map_t24_account_reg_prod_sector MT
			ON MT.LEGACY_CODE = LA.REG_PROD_SECTOR
	    WHERE MT.T24_CODE IS  NULL
	)
	BEGIN

		;WITH UNMAPPED AS (
			SELECT DISTINCT LA.REG_PROD_SECTOR FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].map_t24_account_reg_prod_sector MT
				ON MT.LEGACY_CODE = LA.REG_PROD_SECTOR
			WHERE MT.T24_CODE IS  NULL)

		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
			SELECT 
				'stage_account' [Table_Name],
				@SOURCE [Source],
				CONCAT('Mapping issue: REG_PROD_SECTOR ',(REG_PROD_SECTOR),' is unmapped') [Error_Message] 
				FROM UNMAPPED
				SET @p_status = 1

	END


	/**--------------------------------------------------MEANS_OF_PAYMNT--------------------------------------------------**/
	IF EXISTS 
	(	
			SELECT DISTINCT LA.MEANS_OF_PAYMNT FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].map_t24_account_means_of_paymnt MT
				ON MT.LEGACY_CODE = LA.MEANS_OF_PAYMNT
			WHERE MT.T24_CODE IS NULL AND LA.MEANS_OF_PAYMNT <> ''
	)
	BEGIN

		;WITH UNMAPPED AS (
			SELECT DISTINCT LA.MEANS_OF_PAYMNT FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].map_t24_account_means_of_paymnt MT
				ON MT.LEGACY_CODE = LA.MEANS_OF_PAYMNT
			WHERE MT.T24_CODE IS NULL  AND LA.MEANS_OF_PAYMNT <> '' )

		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
			SELECT 
				'stage_account' [Table_Name],
				@SOURCE [Source],
				CONCAT('Mapping issue: MEANS_OF_PAYMNT ',(MEANS_OF_PAYMNT),' is unmapped') [Error_Message] 
				FROM UNMAPPED
				SET @p_status = 1
	END

		/**--------------------------------------------------Category--------------------------------------------------**/
	IF EXISTS 
	(	
			SELECT DISTINCT LA.CATEGORY FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].[map_t24_account_category] MT
					ON MT.LEGACY_CODE = LA.CATEGORY
			WHERE MT.T24_CODE IS NULL  
	)
	BEGIN

		;WITH UNMAPPED AS (
			SELECT DISTINCT LA.CATEGORY FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].[map_t24_account_category] MT
					ON MT.LEGACY_CODE = LA.CATEGORY
			WHERE MT.T24_CODE IS NULL   )

		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
			SELECT 
				'stage_account' [Table_Name],
				@SOURCE [Source],
				CONCAT('Mapping issue: CATEGORY ',(CATEGORY),' is unmapped') [Error_Message] 
				FROM UNMAPPED
				SET @p_status = 1
	END

		/**--------------------------------------------------POSTING RESTRICT--------------------------------------------------**/
	IF EXISTS 
	(	
			SELECT DISTINCT LA.POSTING_RESTRICT FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].[map_t24_account_posting_restrict] MT
					ON MT.LEGACY_CODE = LA.POSTING_RESTRICT
			WHERE MT.T24_CODE IS NULL AND LA.POSTING_RESTRICT <> ''
	)
	BEGIN

		;WITH UNMAPPED AS (
			SELECT DISTINCT LA.POSTING_RESTRICT FROM [dbo].[load_account] LA
			LEFT JOIN [dbo].[map_t24_account_posting_restrict] MT
					ON MT.LEGACY_CODE = LA.POSTING_RESTRICT
			WHERE MT.T24_CODE IS NULL AND LA.POSTING_RESTRICT <> '')

		INSERT INTO [dbo].[Migration_Validation_Failure]([Table_Name],[Source],[Error_Message])
			SELECT 
				'stage_account' [Table_Name],
				@SOURCE [Source],
				CONCAT('Mapping issue: POSTING_RESTRICT ',(POSTING_RESTRICT),' is unmapped') [Error_Message] 
				FROM UNMAPPED
				SET @p_status = 1
	END

	Set @p_return_msg = STUFF((SELECT CHAR(10)+ [Error_Message]
	FROM [dbo].[Migration_Validation_Failure] WHERE [Table_Name] = 'stage_account'
	FOR XML PATH('')), 1, 1, '')
			
	IF @p_status = 0 RAISERROR('Code mapping validation successful.', 0 , 10) WITH NOWAIT;
	IF @p_status = 1 RAISERROR('Code mapping validation failed.', 0 , 10) WITH NOWAIT;

	RAISERROR(@p_return_msg, 0, 10) WITH NOWAIT;
	RAISERROR('Validation checks completed.', 0 , 10) WITH NOWAIT;

END
