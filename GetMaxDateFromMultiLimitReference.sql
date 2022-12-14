
GO
/****** Object:  UserDefinedFunction [dbo].[GetMaxDateFromMultiLimitReference]    Script Date: 23/09/2022 21:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- DBMS:		TemenosMigration_BellBank
-- Author:		Alex Jackson
-- Create date: November 2, 2021
-- Description:	Takes multivalue field and replaces 
--				values with corresponding T24 values. 
-- =============================================
ALTER FUNCTION [dbo].[GetMaxDateFromMultiLimitReference] 
(
	@InputMultiVal VARCHAR(1000), @Delimiter VARCHAR(10)
)
RETURNS VARCHAR(1000)
AS
BEGIN
	DECLARE @NewMultiVal VARCHAR(1000)=''
	SET @InputMultiVal = LTRIM(RTRIM(@InputMultiVal))

	IF @InputMultiVal NOT LIKE '%'+@Delimiter+'%' 
	BEGIN
		IF @InputMultiVal <> '' or @InputMultiVal IS NULL
			SET @NewMultiVal = (SELECT FIN_MAT_DATE FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref =  @InputMultiVal)
		ELSE
			SET @NewMultiVal = ''
	END
	ELSE
	BEGIN
		WHILE (@InputMultiVal LIKE '%'+@Delimiter+'%')
		BEGIN
			DECLARE @SubString VARCHAR(1000)= ''
			DECLARE @NewValue VARCHAR(1000) = ''
	
	IF (@InputMultiVal LIKE '%'+@Delimiter+'%')
	BEGIN
			-- GET NEXT SUBSTRING VALUE
			Set @SubString = (SELECT LEFT(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal) - 1))

			--DO LOOK UP
			SET @NewValue = (SELECT FIN_MAT_DATE FROM [dbo].[stage_ld_loans_and_deposits] WHERE T24_ID = @SubString)

			--SET INPUT STRING TO REMAINING SUBSTRING 
			SET @InputMultiVal = REPLACE(SUBSTRING(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal)+1, LEN(@InputMultiVal)), '%'+@Delimiter, '')

			--COMPARE LEGACY_REF OF THE TWO
			SET @NewMultiVal = (SELECT MAX(FIN_MAT_DATE) FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @SubString OR Legacy_ref = @InputMultiVal)
	 
	--BEGIN 

	--SET @NewMultiVal = (SELECT FIN_MAT_DATE FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @SubString OR Legacy_ref = @InputMultiVal)

	
	--END
	END
	--		--BUILD NEW DELIMITED STRING
	--		IF @NewMultiVal LIKE ''
	--		BEGIN  
	--			SET @NewMultiVal = CONCAT(@NewMultiVal, @NewValue)
	--		END
	--		ELSE
	--		BEGIN
	--			SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @NewValue)
	--		END

	--		IF @InputMultiVal NOT LIKE '%'+@Delimiter+'%'
	--		BEGIN
	--			SET @NewValue = (SELECT T24_ID FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @InputMultiVal)
	--			SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @NewValue)
	--		END
		END
	END
	
	RETURN @NewMultiVal --Returns the comparison of the max fin date of the 2 limit references'. 
END


