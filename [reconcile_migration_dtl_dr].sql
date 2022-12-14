
GO
/****** Object:  StoredProcedure [dbo].[reconcile_migration_dtl_dr]    Script Date: 25/09/2022 01:02:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[reconcile_migration_dtl_dr]

AS
BEGIN
	
DECLARE @SYSDATE DATE
DECLARE @DATE DATE
SELECT @SYSDATE = T24_Date FROM [dbo].[stage_system_date]
SELECT @DATE = @SYSDATE
DECLARE @TODAY DATE
SELECT @TODAY = TODAY FROM [dbo].[load_migration_config_date]
DECLARE @VM CHAR(1) = '|'
DECLARE @T24Date DATE = dbo.Get_t24_date()
DECLARE @EOM VARCHAR(8) =  CONVERT(VARCHAR,EOMONTH(@t24Date),112) 
DECLARE @SOURCE VARCHAR(2), @ABV VARCHAR(3)
SELECT @SOURCE = code FROM [dbo].[load_migration_source]
SELECT @ABV = ABV FROM [dbo].[load_migration_source]



---------------------------------------------------------------------------------------------
                                  -- MODULE FIN DETAILS | DR --
---------------------------------------------------------------------------------------------


--SELECT 'UPDATING DR DETAILS...'
DELETE FROM [recon].[RECON_DTL_CUSTOMER] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_ACCOUNT] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_MM_MONEY_MARKET] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_LD_LOANS_AND_DEPOSIT] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_COLLATERALS] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_PAST_DUE] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_AC_LOCKED_EVENTS] WHERE SOURCE = @SOURCE
----DELETE FROM [recon].[RECON_DTL_STANDING_ORDERS] WHERE SOURCE = @SOURCE
----DELETE FROM [recon].[RECON_DTL_SAFE_DEPOSIT_BOX]  WHERE SOURCE = @SOURCE
----DELETE FROM [recon].[RECON_DTL_LIMIT]  WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_CCMB_LMM_CUST_BLOCK] WHERE SOURCE = @SOURCE
DELETE FROM [recon].[RECON_DTL_FUNDS_TRANSFER] WHERE SOURCE = @SOURCE
----DELETE FROM [RECON].[RECON_DTL_SECUIRTY_MASTER]  WHERE SOURCE = @SOURCE
DELETE FROM [RECON].[RECON_DTL_ACCRUED_INTEREST] WHERE SOURCE = @SOURCE
DELETE FROM  [recon].[RECON_DTL_PD_CAPTURE] WHERE SOURCE = @SOURCE
--DELETE FROM  [recon].[RECON_DTL_CLAIMS] WHERE SOURCE = @SOURCE
--DELETE FROM  [recon].[RECON_DTL_CHEQUE_ISSUE] WHERE SOURCE = @SOURCE
--DELETE FROM  [recon].[RECON_DTL_CHEQUE_REGISTER_SUPPLEMENT] WHERE SOURCE = @SOURCE




/********************************************************************************************************************		
									 CUSTOMERS
selects from the load/source table along with the t24_extract/customer extract table and insert into recon_dtl table
*********************************************************************************************************************/
INSERT INTO [recon].[RECON_DTL_CUSTOMER]
(
	[Source],
	[ID],
	[Legacy_Ref],
	[Name],
	[Src_Name],
	[Mailing_Address],
	[Src_MailingAddr],
	[Dob],
	[Src_Dob],
	[Telephone],
	[Src_telephone],
	[Email_Address],
	[Src_Email_Address],
	[Firstname_1],
	[Src_Firstname_1],
	[FirstName_2],
	[Src_Firstname_2],
	[Surname_1],
	[Src_Surname_1],
	[Surname_2],
	[Src_Surname_2],
	[Company],
	[Src_Company],
	[Street_Address],
	[Src_Street_Address]
	--,[EXCEPTIONS]
	--,[EXCEPTIONS_COUNT]
)
SELECT
	@SOURCE [Source],
    CE.RECORD_ID [ID]
    ,CE.LEGACY_REF [Legacy_Ref]
    ,(SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'NAME_1') [Name]
    ,LC.NAME_1 [Src_Name]
    ,CONCAT((CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_STREET') = '' THEN NULL 
				ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_STREET')+', ' END)
		,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_TOWN_CNTRY') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_TOWN_CNTRY')+', ' END)
		,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_PARISH_ST') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_PARISH_ST')+', ' END)
      ,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_POST_CODE') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_POST_CODE')+', ' END)
      ,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_COUNTRY') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'MAIL_COUNTRY') END)) [Mailing_Address]
    ,CONCAT((CASE WHEN LC.MAIL_STREET = '' THEN NULL ELSE LC.MAIL_STREET+', ' END)
		,(CASE WHEN LC.MAIL_TOWN_CNTRY = '' THEN NULL ELSE LC.MAIL_TOWN_CNTRY+', ' END)
		,(CASE WHEN LC.MAIL_PARISH_ST = '' THEN NULL ELSE LC.MAIL_PARISH_ST+', ' END)
      ,(CASE WHEN LC.MAIL_POST_CODE = '' THEN NULL ELSE LC.MAIL_POST_CODE+', ' END)
      ,(CASE WHEN LC.MAIL_COUNTRY = '' THEN NULL ELSE LC.MAIL_COUNTRY END)) [Src_MailingAddr]
    ,ISNULL(CE.DATE_OF_BIRTH,'') [Dob]
    ,ISNULL(CONVERT(VARCHAR(8),LC.DATE_OF_BIRTH,112),'') [Src_Dob]
    ,ISNULL(STUFF((SELECT '|' + CV.Data
		FROM [recon].[CUSTOMER.MV.EXTRACT] CV
		WHERE CE.RECORD_ID = CV.ID AND CV.Field = 'PHONE_1'
		ORDER BY CV.MV
		FOR XML PATH('')), 1, 1, ''),'') [Telephone]
    ,LC.PHONE [Src_telephone]
    ,ISNULL(STUFF((SELECT '|' + CV.Data
		FROM [recon].[CUSTOMER.MV.EXTRACT] CV
		WHERE CE.RECORD_ID = CV.ID AND CV.Field = 'EMAIL_1'
		ORDER BY CV.MV
		FOR XML PATH('')), 1, 1, ''),'') [Email_Address] 
    ,LC.EMAIL [Src_Email_Address]
    ,ISNULL(CE.FIRST_NAME_1,'') [Firstname_1]
    ,LC.FIRST_NAME_1 [Src_Firstname_1]
    ,ISNULL(CE.FIRST_NAME_2,'') [FirstName_2]
    ,LC.FIRST_NAME_2 [Src_Firstname_2]
    ,ISNULL(CE.SURNAME_1,'') [Surname_1]
    ,LC.SURNAME_1 [Src_Surname_1]
    ,ISNULL(CE.SURNAME_2,'') [Surname_2]
    ,LC.SURNAME_2 [Src_Surname_2]
    ,CASE WHEN CE.FIRST_NAME_1 IS NULL THEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'NAME_1') 
		ELSE '' END [Company] 
    ,LC.COMPANY_NAME [Src_Company]
	,CONCAT((CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'STREET') = '' THEN NULL 
				ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'STREET')+', ' END)
		,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'ADDRESS') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'ADDRESS')+', ' END)
		,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'TOWN_CNTRY') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'TOWN_CNTRY')+', ' END)
      ,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'POST_CODE') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'POST_CODE')+', ' END)
      ,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'COUNTRY') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'COUNTRY')+', ' END)
		,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'PARISH_STATE') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'PARISH_STATE')+', ' END)
      ,(CASE WHEN (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'ZIP_CODE') = '' THEN NULL 
			ELSE (SELECT CV.Data FROM [recon].[CUSTOMER.MV.EXTRACT] CV WHERE CE.RECORD_ID = CV.ID AND Field = 'ZIP_CODE') END)) [Street_Address]
    ,CONCAT((CASE WHEN LC.STREET = '' THEN NULL ELSE LC.STREET+', ' END)
		,(CASE WHEN LC.ADDRESS = '' THEN NULL ELSE LC.ADDRESS+', ' END)
		,(CASE WHEN LC.TOWN_COUNTRY = '' THEN NULL ELSE LC.TOWN_COUNTRY+', ' END)
      ,(CASE WHEN LC.POST_CODE = '' THEN NULL ELSE LC.POST_CODE+', ' END)
      ,(CASE WHEN LC.COUNTRY = '' THEN NULL ELSE LC.COUNTRY END)
	  ,(CASE WHEN LC.PARISH_STATE = '' THEN NULL ELSE LC.PARISH_STATE END)
	  --,(CASE WHEN LC.MUNICIPALITY = '' THEN NULL ELSE LC.MUNICIPALITY END)
	  ,(CASE WHEN LC.ZIP_CODE = '' THEN NULL ELSE LC.ZIP_CODE END)) [Src_Street_Address]
FROM [dbo].[load_customer] LC
LEFT JOIN [recon].[CUSTOMER.EXTRACT] CE ON CE.LEGACY_REF = LC.LEGACY_REF ;
	
/***********************************************************************************************************
									 ACCOUNTS
***********************************************************************************************************/
INSERT INTO [recon].[RECON_DTL_ACCOUNT]
(	
	[Source] ,
	[ID] ,
	[Legacy_Ref] ,
	[Ccy] ,
	[Src_Ccy] ,
	[Balance] ,
	[Src_Balance] ,
	[Customer] ,
	[Src_Customer] ,
	[Joint_Holders] ,
	[Src_Jnt_Holders] ,
	[Title] ,
	[Src_title] ,
	[Category] ,
	[Src_Category] ,
	[Out_Main_fee] ,
	[Src_Out_Main_Fee] ,
	[Signing_Mandate] ,
	[Src_Signing_Mandate] ,
	[Posting_Restriction] ,
	[Src_Post_Restriction] ,
	[Status] ,
	[Src_Status] ,
	[Jnt_Relation_Code] ,
	[Src_Relation_Code] ,
	[Interest_Rate] ,
	[SrcInterest_Rate] ,
	[Company] ,
	[Src_Company] ,
	[Ovedraft_Amt] ,
	[Src_Overdraft_Amount]
)
SELECT  
	@SOURCE [Source] ,
	AE.RECORD_ID [ID] ,
	LA.Legacy_Ref [Legacy_Ref] ,
	AE.CURRENCY [Ccy] ,
	LA.CURRENCY [SRC_Ccy] ,
	ISNULL(AE.ONLINE_ACTUAL_BAL,'0.00') [Balance] ,
	LA.BALANCE [SRC_Balance] ,
	AE.CUSTOMER [Customer] ,
	(SELECT SA.CUSTOMER FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = LA.LEGACY_REF) [SRC_Customer] ,
	ISNULL(STUFF((SELECT '|' + AV.Data
		FROM [recon].[ACCOUNT.MV.EXTRACT] AV
		WHERE AE.RECORD_ID = AV.ID AND AV.Field = 'JOINT_HOLDER'
		ORDER BY AV.MV
		FOR XML PATH('')), 1, 1, ''), '') [Joint_Holders] ,
	REPLACE((SELECT SA.JOINT_HOLDER FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = LA.LEGACY_REF), 'ý','|') [SRC_Jnt_Holders] ,
	AE.ACCOUNT_TITLE_1 [Title] ,
	LA.ACCOUNT_TITLE_1 [SRC_title] ,
	AE.CATEGORY [Category] ,
	(SELECT SA.CATEGORY FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = LA.LEGACY_REF) [SRC_Category] ,
	ISNULL(AE.OUT_MAIN_FEE, '') [Out_Main_fee] ,
	'' [SRC_Out_Main_Fee] ,
	ISNULL(STUFF((SELECT '|' + AV.Data
		FROM [recon].[ACCOUNT.MV.EXTRACT] AV
		WHERE AE.RECORD_ID = AV.ID AND [Field] = 'ACCT_SIGN_MAND'
		ORDER BY AV.MV
		FOR XML PATH('')), 1, 1, ''), '') [Signing_Mandate] ,
	LA.ACCT_SIGN_MAND [SRC_Signing_Mandate] ,
	ISNULL(STUFF((SELECT '|' + AV.Data
		FROM [recon].[ACCOUNT.MV.EXTRACT] AV
		WHERE AE.RECORD_ID = AV.ID AND [Field] = 'POSTING_RESTRICT'
		ORDER BY AV.MV
		FOR XML PATH('')), 1, 1, ''), '') [Posting_Restriction] ,
	ISNULL((SELECT SA.POSTING_RESTRICT FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = LA.LEGACY_REF), '') [SRC_Post_Restriction] ,
	ISNULL(STUFF((SELECT '|' + AV.Data
		FROM [recon].[ACCOUNT.MV.EXTRACT] AV
		WHERE AE.RECORD_ID = AV.ID AND [Field] = 'MIGRATE_STATUS'
		ORDER BY AV.MV
		FOR XML PATH('')), 1, 1, ''), '') [Status] ,
	'' [SRC_Status] ,
	ISNULL(STUFF((SELECT '|' + AV.Data
		FROM [recon].[ACCOUNT.MV.EXTRACT] AV
		WHERE AE.RECORD_ID = AV.ID AND [Field] = 'RELATION_CODE'
		ORDER BY AV.MV
		FOR XML PATH('')), 1, 1, ''), '') [Jnt_Relation_Code] ,
	REPLACE((SELECT SA.RELATION_CODE FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = LA.LEGACY_REF), 'ý','|') [SRC_Relation_Code] ,
	AE.ORIG_INT_PAID [Interest_Rate] ,
	LA.ORIG_INT_PAID [SRCInterest_Rate] ,
	AE.COMPANY_ID [Company] ,
	LA.LEGACY_CO [SRC_Company] ,
	'' [Ovedraft_Amt] ,
	''  [SRC_Overdraft_Amount]  
FROM [dbo].[LOAD_ACCOUNT] LA
LEFT JOIN [recon].[ACCOUNT.EXTRACT] AE ON AE.LEGACY_REF = LA.LEGACY_REF ;

/****************************************************************************************
								MM MONEY MARKET
****************************************************************************************/
INSERT INTO [recon].[RECON_DTL_MM_MONEY_MARKET]
(
	[source],
	[@id],
	[legacy_ref],
	[ccy],
	[src_ccy],
	[customer],
	[src_customer],
	[principal],
	[src_principal],
	[interest_rt],
	[src_int_rate],
	[joint_holders],
	[src_jnt_holders]
)
SELECT
	@SOURCE [source],
	ME.RECORD_ID [@id],
	ME.LEGACY_REF [legacy_ref],
	ME.[CURRENCY] [ccy],
	LC.CURRENCY [src_ccy],
	ME.CUSTOMER_ID [customer],
	(SELECT SC.T24_ID FROM [dbo].[stage_customer] SC WHERE SC.LEGACY_REF = LC.CUSTOMER_ID) [src_customer],
	ME.PRINCIPAL [principal],
	LC.PRINCIPAL [src_principal],
	ME.INTEREST_RATE [interest_rt],
	LC.INTEREST_RATE [src_int_rate],
	ISNULL(STUFF((SELECT '|' + MV.Data 
		FROM [recon].[MM.MONEY.MARKET.MV.EXTRACT] MV 
		WHERE ME.RECORD_ID = MV.ID AND Field = 'MM_JOINT_CUST'
		ORDER BY MV.MV
		FOR XML PATH('')), 1, 1, ''), '') [joint_holders],
	LC.MM_JOINT_CUST [src_jnt_holders]
FROM [dbo].[load_cd] LC
LEFT JOIN [recon].[MM.MONEY.MARKET.EXTRACT] ME ON ME.LEGACY_REF = LC.LEGACY_REF ;

/***********************************************************************************************************
									 LOANS
***********************************************************************************************************/
INSERT INTO [recon].[RECON_DTL_LD_LOANS_AND_DEPOSIT]
(
	[SOURCE], 
	[@ID], 
	[LEGACY_REF], 
	[CURRENCY], 
	[SRC CURRENCY], 
	[CUSTOMER], 
	[SRC CUSTOMER], 
	[AMOUNT], 
	[Src_AMOUNT], 
	[INTEREST_RATE], 
	[SRC INT RATE], 
	[JOINT HOLDER], 
	[SRC JNT HOLDER], 
	[MATURITY DATE], 
	[SRC MATURITY DATE], 
	[ANNUITY PYMT], 
	[SRC ANNUITY PYMT], 
	[Fee],
	[Srcfee],
	[t24category], 
	[CATEGORY], 
	[LOANAMOUNT], 
	[Src_AMOUNT_src], 
	[Monthly_payments], 
	[SRCmonthly_payments]
)
SELECT
	@SOURCE [SOURCE], 
	LE.RECORD_ID [@ID], 
	LE.LEGACY_REF [LEGACY_REF], 
	LE.CURRENCY [CURRENCY], 
	LL.CURRENCY [SRC CURRENCY], 
	LE.CUSTOMER_ID [CUSTOMER], 
	(SELECT SL.CUSTOMER_ID FROM [dbo].[stage_ld_loans_and_deposits] SL WHERE SL.LEGACY_REF = LL.LEGACY_REF) [SRC CUSTOMER], 
	STUFF((SELECT '|' + RTRIM(LV.Data)
             FROM [recon].[LD.LOANS.AND.DEPOSITS.MV.EXTRACT] LV
             WHERE LE.RECORD_ID = LV.ID and LV.Field = 'AMOUNT'
             ORDER BY LV.MV
             FOR XML PATH('')), 1, 1, '') [AMOUNT], 
	LL.AMOUNT [Src_AMOUNT], 
	STUFF((SELECT '|' + RTRIM(LV.Data)
             FROM [recon].[LD.LOANS.AND.DEPOSITS.MV.EXTRACT] LV
             WHERE LE.RECORD_ID = LV.ID and LV.Field = 'INTEREST_RATE'
             ORDER BY LV.MV
             FOR XML PATH('')), 1, 1, '') [INTEREST_RATE], 
	LL.INTEREST_RATE [SRC INT RATE], 
	ISNULL(STUFF((SELECT '|' + RTRIM(LV.Data)
             FROM [recon].[LD.LOANS.AND.DEPOSITS.MV.EXTRACT] LV
             WHERE LE.RECORD_ID = LV.ID and LV.Field = 'JOINT_HOLDER'
             ORDER BY LV.MV
             FOR XML PATH('')), 1, 1, ''), '') [JOINT HOLDER], 
	LL.JOINT_HOLDER [SRC JNT HOLDER], 
	LE.FIN_MAT_DATE [MATURITY DATE], 
	CONVERT(VARCHAR(8), LL.FIN_MAT_DATE, 112) [SRC MATURITY DATE], 
	LE.ANNUITY_REPAY_AMT [ANNUITY PYMT], 
	'' [SRC ANNUITY PYMT], 
	''[Fee],
	'' [Srcfee],
	LE.CATEGORY [t24category], 
	(SELECT SL.CATEGORY FROM [dbo].[stage_ld_loans_and_deposits] SL WHERE SL.LEGACY_REF = LL.LEGACY_REF) [CATEGORY], 
	STUFF((SELECT '|' + RTRIM(LV.Data)
             FROM [recon].[LD.LOANS.AND.DEPOSITS.MV.EXTRACT] LV
             WHERE LE.RECORD_ID = LV.ID and LV.Field = 'AMOUNT'
             ORDER BY LV.MV
             FOR XML PATH('')), 1, 1, '') [LOANAMOUNT], 
	LL.AMOUNT [Src_AMOUNT_src], 
	--REPLACE((SELECT SCH_AMOUNT FROM [dbo].[stage_ld_loans_and_deposits] WHERE LEGACY_REF = LL.LEGACY_REF), 'ý','|') [Monthly_payments], 
	'' [Monthly_payments],
	--ISNULL(STUFF((SELECT '|' + RTRIM(CASE WHEN SCH_TYPE = 'A' THEN '' ELSE CAST(LS.AMOUNT AS VARCHAR) END)
 --            FROM [dbo].[load_loan_schedule] LS
 --            WHERE LS.LEGACY_REF = LL.LEGACY_REF 
 --            ORDER BY LS.DATE
 --            FOR XML PATH('')), 1, 1, ''), '') [SRCmonthly_payments]
	'' [SRCmonthly_payments]
FROM [dbo].[LOAD_LOAN] LL
INNER JOIN [recon].[LD.LOANS.AND.DEPOSITS.EXTRACT] LE ON LE.LEGACY_REF = LL.LEGACY_REF ;

/****************************************************************************************
								   COLLATERALS
****************************************************************************************/
INSERT INTO [recon].[RECON_DTL_COLLATERALS]
(
	[source],
	[@id],
	[legacy_ref],
	[description],
	[src_desc],
	[customers],
	[src_customers],
	[loans],
	[src_loans],
	[Currency],
	[Src_Currency],
	[Nominal_Value],
	[Src_Nominal_Value],
	[Company],
	[Src_Company],
	[Expiry_Date],
	[Src_Expiry_Date],
	[Collateral_Address],
	[Src_Collateral_Address],
	[Maximum_Value],
	[SrcMaximum_Value]
)
SELECT
	@SOURCE [source],
	CRE.RECORD_ID [@id],
	CRE.LEGACY_REF [legacy_ref],
	ISNULL(STUFF((SELECT '' +CRV.Data
             FROM [recon].[COLLATERAL.MV.EXTRACT] CRV
             WHERE CRE.RECORD_ID = CRV.ID
             and CRV.Field = 'DESCRIPTION'
             ORDER BY CRV.MV
             FOR XML PATH('')), 1, 0, ''),'') [description],
	LCD.[DESCRIPTION] [src_desc],
	(SELECT CUSTOMER FROM [recon].[COLLATERAL.RIGHT.EXTRACT] CLE WHERE CLE.RECORD_ID = CRE.RECORD_ID) [customers],
	(SELECT SC.T24_ID FROM [dbo].[load_customer] LC INNER JOIN [dbo].[stage_customer] SC ON SC.LEGACY_REF = LC.LEGACY_REF WHERE LC.LEGACY_REF = LCD.CUSTOMER_ID) [src_customers],
	(SELECT LIMIT_REFERENCE FROM [recon].[COLLATERAL.RIGHT.EXTRACT] CLE WHERE CLE.RECORD_ID = CRE.RECORD_ID) [loans],
	(SELECT [LIMIT_REFERENCE] FROM [dbo].[load_collateral] LC WHERE LC.LEGACY_REF = LCD.LEGACY_REF) [src_loans],
	CRE.CURRENCY [Currency],
	LCD.CURRENCY [Src_Currency],
	CRE.NOMINAL_VALUE [Nominal_Value],
	LCD.NOMINAL_VALUE [Src_Nominal_Value],
	CRE.COMPANY_NAME [Company],
	(SELECT CO_CODE FROM [dbo].[stage_collateral_right] WHERE LEGACY_REF = LCD.LEGACY_REF) [Src_Company],
	CRE.EXPIRY_DATE [Expiry_Date],
	CONVERT(VARCHAR(8),LCD.EXPIRY_DATE,112) [Src_Expiry_Date],
	ISNULL(STUFF((SELECT '' +CRV.Data
             FROM [recon].[COLLATERAL.MV.EXTRACT] CRV
             WHERE CRE.RECORD_ID = CRV.ID
             and CRV.Field = 'ADDRESS'
             ORDER BY CRV.MV
             FOR XML PATH('')), 1, 0, ''),'') [Collateral_Address],
	LCD.ADDRESS [Src_Collateral_Address],
	CRE.MAXIMUM_VALUE [Maximum_Value],
	LCD.MAXIMUM_VALUE [SrcMaximum_Value]
FROM [dbo].[load_collateral_detail] LCD
LEFT JOIN [recon].[COLLATERAL.EXTRACT] CRE ON CRE.LEGACY_REF = LCD.LEGACY_REF ;

/****************************************************************************************
								   PAST DUE
****************************************************************************************/
;WITH 
/************************PAYMENT DUE EXTRACT DATA***********************/
pd_types AS (SELECT * FROM recon.[PD.PAYMENT.DUE.MV.EXTRACT] WHERE field = 'TOT_OVRDUE_TYPE'),
pd_amts AS (SELECT * FROM recon.[PD.PAYMENT.DUE.MV.EXTRACT] WHERE field = 'TOT_OD_TYPE_AMT'),
pymts AS (SELECT ISNULL(pt.id,pa.Id)  [ID],pt.[Data] [TOT_OVRDUE_TYPE],pa.[Data] TOT_OD_TYPE_AMT,pt.MV FROM pd_types pt FULL OUTER JOIN pd_amts pa ON pt.Id = pa.Id AND pt.MV = pa.MV),
pd_pymt_due AS
(select ID,SUM(CASE WHEN TOT_OVRDUE_TYPE = 'IN' THEN CONVERT(MONEY,TOT_OD_TYPE_AMT) ELSE 0 END) [TOT_INT_ARREARS], SUM(CASE WHEN TOT_OVRDUE_TYPE = 'PR' THEN CONVERT(MONEY,TOT_OD_TYPE_AMT) ELSE 0 END) [TOT_PRIN_ARREARS],SUM(CASE WHEN TOT_OVRDUE_TYPE = 'CH' THEN CONVERT(MONEY,TOT_OD_TYPE_AMT) ELSE 0 END) [TOT_CHRG_ARREARS] FROM pymts GROUP BY ID),	
/************************PAYMENT DUE SOURCE DATA***********************/
Past_Due AS 
(
	SELECT
	LP.LEGACY_REF [LEGACY_REF]
	,CAST(LEFT(LP.PAYMENT_TYPE, CHARINDEX('|', LP.PAYMENT_TYPE + '|') - 1) AS VARCHAR(35)) [OVERDUE_TYPE]
    ,STUFF(LP.PAYMENT_TYPE, 1, CHARINDEX('|', LP.PAYMENT_TYPE + '|'), '') [PAYMENT_TYPE]
	,CAST(LEFT(LP.PAYMENT_AMT, CHARINDEX('|', LP.PAYMENT_AMT + '|') - 1) AS VARCHAR(35)) [OVERDUE_AMT]
	,STUFF(LP.PAYMENT_AMT, 1, CHARINDEX('|', LP.PAYMENT_AMT + '|'), '') [PAYMENT_AMT]

	FROM [dbo].[load_past_due_loan] LP

	UNION ALL 
	SELECT
	LEGACY_REF [LEGACY_REF]
	,CAST(LEFT(PAYMENT_TYPE, CHARINDEX('|', PAYMENT_TYPE + '|') - 1) AS VARCHAR(35)) [OVERDUE_TYPE]
    ,STUFF(PAYMENT_TYPE, 1, CHARINDEX('|', PAYMENT_TYPE + '|'), '') [PAYMENT_TYPE]
	,CAST(LEFT(PAYMENT_AMT, CHARINDEX('|', PAYMENT_AMT + '|') - 1) AS VARCHAR(35)) [OVERDUE_AMT]
	,STUFF(PAYMENT_AMT, 1, CHARINDEX('|', PAYMENT_AMT + '|'), '') [PAYMENT_AMT]
		
	FROM Past_Due 
	WHERE PAYMENT_TYPE > ''
),
src_pymt_due AS
(select LEGACY_REF,SUM(CASE WHEN OVERDUE_TYPE = 'IN' THEN CONVERT(MONEY,OVERDUE_AMT) ELSE 0 END) [INT_ARREARS], SUM(CASE WHEN OVERDUE_TYPE = 'PR' THEN CONVERT(MONEY,OVERDUE_AMT) ELSE 0 END) [PRIN_ARREARS],SUM(CASE WHEN OVERDUE_TYPE = 'CH' THEN CONVERT(MONEY,OVERDUE_AMT) ELSE 0 END) [CHRG_ARREARS] FROM Past_Due GROUP BY LEGACY_REF)

INSERT INTO [recon].[RECON_DTL_PAST_DUE]
(
	[Source],
	[ID],
	[Legacy_Ref],
	[Ccy],
	[Src_Ccy],
	[Customer],
	[Src_Customer],
	[Principal_arrears],
	[Src_Principal_Arrears],
	[Interest_Arrears],
	[Src_Interest_Arrears],
	[Chg_Arrears],
    [Src_Chg_Arrears]
)
SELECT
	@SOURCE [Source],
    PDE.RECORD_ID [ID]
    ,PDE.LEGACY_REF [Legacy_Ref]
    ,PDE.CURRENCY [Ccy]
    ,(SELECT TOP 1 LP.CURRENCY FROM [dbo].[load_past_due_loan] LP WHERE LP.LEGACY_REF = SRC.LEGACY_REF) [Src_Ccy]
    ,PDE.CUSTOMER [Customer]
    ,(SELECT TOP 1 LP.CUSTOMER FROM [dbo].[load_past_due_loan] LP WHERE LP.LEGACY_REF = SRC.LEGACY_REF) [Src_Customer]
    ,(SELECT PD.TOT_PRIN_ARREARS FROM pd_pymt_due PD WHERE PD.ID = PDE.RECORD_ID) [Principal_arrears]
    ,SRC.PRIN_ARREARS [Src_Principal_Arrears]
    ,(SELECT PD.TOT_INT_ARREARS FROM pd_pymt_due PD WHERE PD.ID = PDE.RECORD_ID) [Interest_Arrears]
    ,SRC.INT_ARREARS [Src_Interest_Arrears]
    ,(SELECT PD.TOT_CHRG_ARREARS FROM pd_pymt_due PD WHERE PD.ID = PDE.RECORD_ID) [Chg_Arrears]
    ,SRC.CHRG_ARREARS [Src_Chg_Arrears]
FROM src_pymt_due SRC
LEFT JOIN [recon].[PD.PAYMENT.DUE.EXTRACT] PDE ON PDE.LEGACY_REF = SRC.LEGACY_REF ;

/***************************************************************************************
								AC LOCKED EVENTS
****************************************************************************************/
INSERT INTO [recon].[RECON_DTL_AC_LOCKED_EVENTS]
(
	[Source],
	[Account_number],
	[Src_AccountNo],
	[From_Date],
	[Src_From_Date],
	[To_Date],
	[Src_To_Date],
	[Locked_Amt],
	[Src_Lock_Amt],
	[Description],
	[Src_Description]
)
SELECT 
	@SOURCE [Source],
    ACE.ACCOUNT_NUMBER [Account_number],
    (SELECT T24_ID FROM [dbo].[stage_account] WHERE LEGACY_REF = LH.ACCOUNT_NUMBER) [Src_AccountNo],
    ACE.FROM_DATE [From_Date],
    CONVERT(VARCHAR(8),LH.FROM_DATE,112) [Src_From_Date],
    ACE.TO_DATE [To_Date],
    CONVERT(VARCHAR(8),LH.TO_DATE,112) [Src_To_Date],
    ACE.LOCKED_AMOUNT [Locked_Amt],
    LH.LOCKED_AMOUNT [Src_Lock_Amt],
    ACE.DESCRIPTION [Description],
    LH.DESCRIPTION [Src_Description]
FROM [dbo].[load_hold_funds] LH
LEFT JOIN [RECON].[AC.LOCKED.EVENTS.EXTRACT] ACE ON ACE.LEGACY_REF = LH.LEGACY_REF ;

/***********************************************************************************************************
									 CCMB LMM CUST BLOCK
***********************************************************************************************************/
INSERT INTO [recon].[RECON_DTL_CCMB_LMM_CUST_BLOCK]
(
	[SOURCE]
	,[ID]
	,[t24EXPIRATION_DATE]
	,[SrcEXPIRATION_DATE]
	,[BLOCKED_AMOUNT]
	,[SrcBLOCKEDY_Amt]
	,[NOTES]
	,[SrcNOTES]
	,[t24Co_Code]
	,[SrcCompCode]
)
SELECT DISTINCT
	@SOURCE [SOURCE],
	BE.RECORD_ID [ID]
	,ISNULL(STUFF((SELECT '|' + RTRIM(BV.Data)
             FROM [recon].[CCMB.LMM.CUST.BLOCK.MV.EXTRACT] BV
             WHERE BE.RECORD_ID = BV.ID and BV.Field = 'EXPIRATION_DATE'
             ORDER BY BV.MV
             FOR XML PATH('')), 1, 1, ''), '') [t24EXPIRATION_DATE]
	,STUFF((SELECT '|' + CONVERT(VARCHAR(8),BC.EXPIRATION_DATE,112)
		FROM load_blocked_cd BC 
		WHERE BC.CUSTOMER_ID = LB.CUSTOMER_ID 
		FOR XML PATH('')), 1, 1, '') [SrcEXPIRATION_DATE]
	,ISNULL(STUFF((SELECT '|' + RTRIM(BV.Data)
             FROM [recon].[CCMB.LMM.CUST.BLOCK.MV.EXTRACT] BV
             WHERE BE.RECORD_ID = BV.ID and BV.Field = 'BLOCKED_AMOUNT'
             ORDER BY BV.MV
             FOR XML PATH('')), 1, 1, ''), '') [BLOCKED_AMOUNT]
	,STUFF((SELECT '|' + CAST(BC.BLOCKED_AMOUNT AS VARCHAR)
		FROM load_blocked_cd BC 
		WHERE BC.CUSTOMER_ID = LB.CUSTOMER_ID 
		FOR XML PATH('')), 1, 1, '') [SrcBLOCKEDY_Amt]
	,ISNULL(STUFF((SELECT '|' + RTRIM(BV.Data)
             FROM [recon].[CCMB.LMM.CUST.BLOCK.MV.EXTRACT] BV
             WHERE BE.RECORD_ID = BV.ID and BV.Field = 'NOTES'
             ORDER BY BV.MV
             FOR XML PATH('')), 1, 1, ''), '') [NOTES]
	,STUFF((SELECT '|' + BC.NOTES
		FROM load_blocked_cd BC 
		WHERE BC.CUSTOMER_ID = LB.CUSTOMER_ID 
		FOR XML PATH('')), 1, 1, '') [SrcNOTES]
	,BE.COMPANY_ID [t24Co_Code]
	,LB.LEGACY_CO [SrcCompCode]
FROM [dbo].[load_blocked_cd] LB
LEFT JOIN [recon].[CCMB.LMM.CUST.BLOCK.EXTRACT] BE ON BE.RECORD_ID = (SELECT T24_ID FROM stage_customer WHERE LEGACY_REF = CAST(LB.CUSTOMER_ID AS VARCHAR(10))) ;

/***********************************************************************************************************
									 FUNDS TRANSFER
***********************************************************************************************************/
;WITH SRC_FT AS
(
/***************CLIENT ACCOUNTS****************/
	SELECT
		SA.CO_CODE [CO_CODE]
		,LA.LEGACY_REF [LEGACY_REF]
		,'ACTO' [TRANSACTION_TYPE]
		,CASE 
			WHEN LA.BALANCE > 0 THEN MT.TAKE_ON_ACCOUNT
			WHEN LA.BALANCE < 0 THEN SA.T24_ID
		END [DEBIT_ACCT_NO]
		,CASE 
			WHEN LA.BALANCE > 0 THEN SA.T24_ID
			WHEN LA.BALANCE < 0 THEN MT.TAKE_ON_ACCOUNT
		END [CREDIT_ACCT_NO]
		,ABS(LA.BALANCE) [DEBIT_AMOUNT]
		,CONVERT(VARCHAR(8), @TODAY, 112) [DEBIT_VALUE_DATE]
		,SA.CURRENCY [CREDIT_CURRENCY]
		,SA.CURRENCY [DEBIT_CURRENCY]
		,'JMMB' [ORDERING_CUST]
		,'DATA MIGRATION' [CREDIT_THEIR_REF]
		,'DATA MIGRATION' [DEBIT_THEIR_REF]
		,NULL [PROFIT_CENTRE_DEPT]
		,'DATA MIGRATION TRANSFER AC' [USR_TXN_NARR]
	FROM [dbo].[load_account] LA
	INNER JOIN [dbo].[stage_account] SA ON LEFT(SA.LEGACY_REF, REPLACE(CHARINDEX('-', SA.LEGACY_REF) - 1,-1,LEN(SA.LEGACY_REF))) = LA.LEGACY_REF
	LEFT JOIN [dbo].[map_t24_takeon_account] MT ON MT.CURRENCY = SA.CURRENCY AND MT.COMPANY = SA.CO_CODE
	WHERE LA.BALANCE <> 0

	UNION ALL
/***************PROFIT AND LOSS****************/
	SELECT
		MC.COMPANY [CO_CODE]
		,CONCAT(MG.LEGACY_REF,'-',MG.CURRENCY,'-',MG.LEGACY_CO) [LEGACY_REF]
		,'ACTO' [TRANSACTION_TYPE]
		,CASE 
			WHEN MG.BALANCE > 0 THEN MT.TAKE_ON_ACCOUNT
			WHEN MG.BALANCE < 0 THEN MG.T24ACCOUNT
		END [DEBIT_ACCT_NO]
		,CASE 
			WHEN MG.BALANCE > 0 THEN MG.T24ACCOUNT
			WHEN MG.BALANCE < 0 THEN MT.TAKE_ON_ACCOUNT
		END [CREDIT_ACCT_NO]
		,ABS(MG.BALANCE) [DEBIT_AMOUNT]
		,CONVERT(VARCHAR(8), @TODAY, 112) [DEBIT_VALUE_DATE]
		,MG.CURRENCY [CREDIT_CURRENCY]
		,MG.CURRENCY [DEBIT_CURRENCY]
		,'JMMB' [ORDERING_CUST]
		,'DATA MIGRATION' [CREDIT_THEIR_REF]
		,'DATA MIGRATION' [DEBIT_THEIR_REF]
		,CASE WHEN MG.T24ACCOUNT LIKE '%PL%' AND LEN(MG.T24ACCOUNT) = 7 THEN MC.OFFICER ELSE NULL END [PROFIT_CENTRE_DEPT]
		,'DATA MIGRATION TRANSFER P&L' [USR_TXN_NARR]
	FROM [dbo].[map_t24_gl_category] MG
	LEFT JOIN [dbo].[map_t24_company] MC ON MC.LEGACY_CODE = MG.LEGACY_CO
	LEFT JOIN [dbo].[map_t24_takeon_account] MT ON MT.CURRENCY = MG.CURRENCY AND MT.COMPANY = MC.COMPANY
	WHERE MG.BALANCE <> 0
	AND MG.SYSTEM = 'T24'
	AND MG.JMMB_GL_TYPE = 'P&L'

	UNION ALL
/***************INTERNAL ACCOUNTS****************/
SELECT
		MC.COMPANY [CO_CODE]
		,CONCAT(MG.LEGACY_REF,'-',MG.CURRENCY,'-',MG.LEGACY_CO) [LEGACY_REF]
		,'ACTO' [TRANSACTION_TYPE]
		,CASE 
			WHEN MG.BALANCE > 0 THEN MT.TAKE_ON_ACCOUNT
			WHEN MG.BALANCE < 0 THEN MG.T24ACCOUNT
		END [DEBIT_ACCT_NO]
		,CASE 
			WHEN MG.BALANCE > 0 THEN MG.T24ACCOUNT
			WHEN MG.BALANCE < 0 THEN MT.TAKE_ON_ACCOUNT
		END [CREDIT_ACCT_NO]
		,ABS(MG.BALANCE) [DEBIT_AMOUNT]
		,CONVERT(VARCHAR(8), @TODAY, 112) [DEBIT_VALUE_DATE]
		,MG.CURRENCY [CREDIT_CURRENCY]
		,MG.CURRENCY [DEBIT_CURRENCY]
		,'JMMB' [ORDERING_CUST]
		,'DATA MIGRATION' [CREDIT_THEIR_REF]
		,'DATA MIGRATION' [DEBIT_THEIR_REF]
		,NULL [PROFIT_CENTRE_DEPT]
		,'DATA MIGRATION TRANSFER GL' [USR_TXN_NARR]
	FROM [dbo].[map_t24_gl_category] MG
	LEFT JOIN [dbo].[map_t24_company] MC ON MC.LEGACY_CODE = MG.LEGACY_CO
	LEFT JOIN [dbo].[map_t24_takeon_account] MT ON MT.CURRENCY = MG.CURRENCY AND MT.COMPANY = MC.COMPANY
	WHERE MG.BALANCE <> 0
	AND MG.SYSTEM = 'T24'
	AND MG.JMMB_GL_TYPE = 'INTERNAL AC'

	UNION ALL
/***************NOSTRO ACCOUNTS****************/
	SELECT
		SA.CO_CODE [CO_CODE]
		,SA.LEGACY_REF [LEGACY_REF]
		,'ACTO' [TRANSACTION_TYPE]
		,CASE 
			WHEN LG.BALANCE > 0 THEN MT.TAKE_ON_ACCOUNT
			WHEN LG.BALANCE < 0 THEN SA.T24_ID
		END [DEBIT_ACCT_NO]
		,CASE 
			WHEN LG.BALANCE > 0 THEN SA.T24_ID
			WHEN LG.BALANCE < 0 THEN MT.TAKE_ON_ACCOUNT
		END [CREDIT_ACCT_NO]
		,ABS(LG.BALANCE) [DEBIT_AMOUNT]
		,CONVERT(VARCHAR(8), @TODAY, 112) [DEBIT_VALUE_DATE]
		,SA.CURRENCY [CREDIT_CURRENCY]
		,SA.CURRENCY [DEBIT_CURRENCY]
		,'JMMB' [ORDERING_CUST]
		,'DATA MIGRATION' [CREDIT_THEIR_REF]
		,'DATA MIGRATION' [DEBIT_THEIR_REF]
		,NULL [PROFIT_CENTRE_DEPT]
		,'DATA MIGRATION TRANSFER NOSTRO' [USR_TXN_NARR]
	FROM [dbo].[load_gl_account] LG
	INNER JOIN [dbo].[map_t24_gl_category] MG ON LG.LEGACY_REF = MG.LEGACY_REF AND LG.LEGACY_CO = MG.LEGACY_CO AND LG.CURRENCY = MG.CURRENCY
	INNER JOIN [dbo].[stage_account] SA ON LEFT(SA.LEGACY_REF, REPLACE(CHARINDEX('-', SA.LEGACY_REF) - 1,-1,LEN(SA.LEGACY_REF))) = LG.LEGACY_REF 
	AND SA.LEGACY_CO = LG.LEGACY_CO AND SA.CURRENCY = LG.CURRENCY
	LEFT JOIN [dbo].[map_t24_takeon_account] MT ON MT.CURRENCY = MG.CURRENCY AND MT.COMPANY = SA.CO_CODE
	WHERE LG.BALANCE <> 0
	AND MG.SYSTEM = 'T24'
	AND MG.JMMB_GL_TYPE = 'NOSTRO'

	UNION ALL
/***************SETTLEMENT ACCOUNTS****************/
	SELECT
		SA.CO_CODE [CO_CODE]
		,CONCAT(MG.LEGACY_REF,'-',MG.CURRENCY,'-',MG.LEGACY_CO) [LEGACY_REF]
		,'ACTO' [TRANSACTION_TYPE]
		,CASE 
			WHEN LG.BALANCE > 0 THEN MT.TAKE_ON_ACCOUNT
			WHEN LG.BALANCE < 0 THEN SA.T24_ID
		END [DEBIT_ACCT_NO]
		,CASE 
			WHEN LG.BALANCE > 0 THEN SA.T24_ID
			WHEN LG.BALANCE < 0 THEN MT.TAKE_ON_ACCOUNT
		END [CREDIT_ACCT_NO]
		,ABS(LG.BALANCE) [DEBIT_AMOUNT]
		,CONVERT(VARCHAR(8), @TODAY, 112) [DEBIT_VALUE_DATE]
		,SA.CURRENCY [CREDIT_CURRENCY]
		,SA.CURRENCY [DEBIT_CURRENCY]
		,'JMMB' [ORDERING_CUST]
		,'DATA MIGRATION' [CREDIT_THEIR_REF]
		,'DATA MIGRATION' [DEBIT_THEIR_REF]
		,NULL [PROFIT_CENTRE_DEPT]
		,'DATA MIGRATION TRANSFER GL' [USR_TXN_NARR]
	FROM [dbo].[load_gl_account] LG
	INNER JOIN [dbo].[map_t24_gl_category] MG ON LG.LEGACY_REF = MG.LEGACY_REF AND LG.LEGACY_CO = MG.LEGACY_CO AND LG.CURRENCY = MG.CURRENCY
	INNER JOIN [dbo].[stage_account] SA ON LEFT(SA.LEGACY_REF, REPLACE(CHARINDEX('-', SA.LEGACY_REF) - 1,-1,LEN(SA.LEGACY_REF))) = LG.LEGACY_REF 
	AND SA.LEGACY_CO = LG.LEGACY_CO AND SA.CURRENCY = LG.CURRENCY
	LEFT JOIN [dbo].[map_t24_takeon_account] MT ON MT.CURRENCY = MG.CURRENCY AND MT.COMPANY = SA.CO_CODE
	WHERE LG.BALANCE <> 0
	AND MG.SYSTEM = 'T24'
	AND MG.JMMB_GL_TYPE = 'SETTLEMENT AC'
)
INSERT INTO [recon].[RECON_DTL_FUNDS_TRANSFER]
(
	[Source],
	[ID],
	[debit_acc_no],
	[src_debit_acc_no],
	[debit_amount],
	[src_debit_amount],
	[debit_currency],
	[src_debit_currency],
	[credit_acc_no],
	[src_credit_acc_no],
	[debit_value_date],
	[src_debit_value_date],
	[LEGACY_REF],
	[SRC_LEGACY_REF]
)
SELECT
	@SOURCE [Source],
	FT.RECORD_ID [ID],
	FT.DEBIT_ACCT_NO [debit_acc_no],
	SRC.DEBIT_ACCT_NO [src_debit_acc_no],
	FT.DEBIT_AMOUNT [debit_amount],
	SRC.DEBIT_AMOUNT [src_debit_amount],
	FT.DEBIT_CURRENCY [debit_currency],
	SRC.DEBIT_CURRENCY [src_debit_currency],
	FT.CREDIT_ACCT_NO [credit_acc_no],
	SRC.CREDIT_ACCT_NO [src_credit_acc_no],
	FT.DEBIT_VALUE_DATE [debit_value_date],
	SRC.DEBIT_VALUE_DATE [src_debit_value_date],
	FT.LEGACY_REF [LEGACY_REF],
	SRC.LEGACY_REF [SRC_LEGACY_REF]
FROM SRC_FT SRC 
LEFT JOIN [recon].[FUNDS.TRANSFER.EXTRACT] FT ON FT.LEGACY_REF = SRC.LEGACY_REF ;

/***********************************************************************************************************		
									    ACCRUED INTEREST
***********************************************************************************************************/ 
INSERT INTO [recon].[RECON_DTL_ACCRUED_INTEREST]
(
	[Source],
	[ID],
	[Legacy_Ref],
	[Account_Number],
	[Src_Account_Number],
	[Interest_Accrued],
	[Src_Interest_Accrued],
	[Due_Date],
	[Src_Due_Date],
	[Company],
	[Src_Company]
)	
SELECT 
	@SOURCE [SOURCE],
	AIE.RECORD_ID [ID]
	,AIE.LEGACY_REF [Legacy_Ref]
	,AIE.PAYABLE_ACCOUNT [Account_Number]
	,(SELECT SA.T24_ID FROM [dbo].[stage_account] SA WHERE SA.LEGACY_REF = AI.ACCOUNT_NUMBER) [Src_Account_Number] --?
	,AIE.INTEREST_ACCRUED [Interest_Accrued]
	,AI.INTEREST_ACCRUED [Src_Interest_Accrued]
	,AIE.DUE_DATE [Due_Date]
	,CONVERT(VARCHAR(8),AI.DUE_DATE,112) [Src_Due_Date]
	,AIE.COMPANY_ID [Company]
	,(SELECT MC.COMPANY FROM [dbo].[map_t24_company] MC WHERE MC.LEGACY_CODE = AI.LEGACY_CO) [SrcCompany] --?
FROM [dbo].[load_accrued_interest] AI
INNER JOIN [recon].[JMMB.ACCRUED.INTEREST.EXTRACT] AIE ON AI.LEGACY_REF = AIE.LEGACY_REF
WHERE AI.INTEREST_ACCRUED > 0 ;	

/****************************************************************************************
								   PD CAPTURE
****************************************************************************************/	
INSERT INTO [recon].[RECON_DTL_PD_CAPTURE]
(
	[SOURCE],
	[RECORD_ID],
	[LEGACY_REF],
	[PAYMENT_AMT],
	[SRC_PAYMENT_AMT],
	[OUTSTANDING_BAL],
	[SRC_OUTSTANDING_BAL],
	[CURRENCY],
	[SRC_CURRENCY],
	[CUSTOMER],
	[SRC_CUSTOMER]
)
SELECT
	@SOURCE [SOURCE],
	PCE.RECORD_ID [RECORD_ID],
	PCE.LEGACY_REF [LEGACY_REF],
	ISNULL(STUFF((SELECT '|' + RTRIM(PCV.Data)
             FROM [recon].[PD.CAPTURE.MV.EXTRACT] PCV
             WHERE PCE.RECORD_ID = PCV.ID and PCV.Field = 'PAYMENT_AMT'
             ORDER BY PCV.MV
             FOR XML PATH('')), 1, 1, ''), '') [PAYMENT_AMT],
	LP.PAYMENT_AMT [SRC_PAYMENT_AMT],
	PCE.OUTSTANDING_BAL [OUTSTANDING_BAL],
	LP.OUTSTANDING_BAL [SRC_OUTSTANDING_BAL],
	PCE.CURRENCY [CURRENCY],
	LP.CURRENCY [SRC_CURRENCY],
	PCE.CUSTOMER [CUSTOMER],
	LP.CUSTOMER [SRC_CUSTOMER]
FROM [dbo].[load_past_due_loan] LP
LEFT JOIN [recon].[PD.CAPTURE.EXTRACT] PCE ON PCE.LEGACY_REF = LP.LEGACY_REF ;

/****************************************************************************************
								   OFFICER
****************************************************************************************/
--INSERT INTO [recon].[RECON_DTL_DEPT_ACCT_OFFICER]
--(

--)
--SELECT
	
--FROM [dbo].[load_officer] LO
--LEFT JOIN [recon].[DEPT.ACCT.OFFICER.EXTRACT] AO ON AO.LEGACY_REF = LO.LEGACY_REF ;

/****************************************************************************************
								   CHEQUE ISSUE
****************************************************************************************/
--INSERT INTO [recon].[RECON_DTL_CHEQUE_ISSUE]
--(
	
--)
--SELECT * FROM [dbo].[load_cheque_book_series] CB
--LEFT JOIN [recon].[CHEQUE.ISSUE.EXTRACT] CI ON CI.LEGACY_REF = C.LEGACY_REF ;

/****************************************************************************************
								   CHEQUE REGISTER SUPPLEMENT
****************************************************************************************/
--INSERT INTO [recon].[RECON_DTL_CHEQUE_REGISTER_SUPPLEMENT]
--(
	
--)
--SELECT
	
--FROM [dbo].[load_managers_cheque] LM
--LEFT JOIN [recon].[CHEQUE.REGISTER.SUPPLEMENT.EXTRACT] CR ON CR.LEGACY_REF = LM.LEGACY_REF ;


/****************************************************************************************
								   STOPPED CHEQUE
****************************************************************************************/
--INSERT INTO 
--(

--)
--SELECT

--FROM [dbo].[load_stopped_cheque] LS
--LEFT JOIN  

/****************************************************************************************
								   JMMB CLAIMS
****************************************************************************************/
--INSERT INTO [recon].[RECON_DTL_CLAIMS]
--(

--)
--SELECT

--FROM [dbo].[load_customer_complaint] CC
--LEFT JOIN [recon].[JMMB.CLAIMS.EXTRACT] JC ON JC.LEGACY_REF = CC.LEGACY_REF ;
END