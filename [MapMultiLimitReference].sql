
GO
/****** Object:  UserDefinedFunction [dbo].[MapMultiLimitReference]    Script Date: 25/09/2022 00:56:51 ******/
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
ALTER FUNCTION [dbo].[MapMultiLimitReference] 
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
		IF @InputMultiVal <> ''
			SET @NewMultiVal = (SELECT T24_ID FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @InputMultiVal and T24_ID Is not null )
		ELSE
			SET @NewMultiVal = NULL
	END
	ELSE
	BEGIN
		WHILE (@InputMultiVal LIKE '%'+@Delimiter+'%')
		BEGIN
			DECLARE @SubString VARCHAR(1000)= ''
			DECLARE @NewValue VARCHAR(1000) = ''
	
			-- GET NEXT SUBSTRING VALUE
			Set @SubString = (SELECT LEFT(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal) - 1))

			--DO LOOK UP
			SET @NewValue = (SELECT T24_ID FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @SubString and T24_ID Is not null)

			--SET INPUT STRING TO REMAINING SUBSTRING 
			SET @InputMultiVal = REPLACE(SUBSTRING(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal)+1, LEN(@InputMultiVal)), '%'+@Delimiter, '')

			--BUILD NEW DELIMITED STRING
			IF @NewMultiVal LIKE ''
			BEGIN  
				SET @NewMultiVal = CONCAT(@NewMultiVal, @NewValue)
			END
			ELSE
			BEGIN
				--IF @NewValue IS NOT NULL
					SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @NewValue)
			END

			IF @InputMultiVal NOT LIKE '%'+@Delimiter+'%'
			BEGIN
				SET @NewValue = (SELECT T24_ID FROM [dbo].[stage_ld_loans_and_deposits] WHERE Legacy_ref = @InputMultiVal and T24_ID Is not null)
				--IF @NewValue IS NOT NULL
					SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @NewValue)
			END
		END
	END
	
	RETURN @NewMultiVal --A return value with a single (ý), traling (%ý) or consecutive deliminters (%ýý%), means one or more values were not found in referenced table.
						--Returns NULL if input string is ''. 
END


