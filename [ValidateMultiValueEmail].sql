
GO
/****** Object:  UserDefinedFunction [dbo].[ValidateMultiValueEmail]    Script Date: 25/09/2022 01:01:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alex Jackson
-- Create date: January 25, 2022
-- Description:	Validates multiple email addresses in a delimited string.
-- =============================================
ALTER FUNCTION [dbo].[ValidateMultiValueEmail]
(
	@InputMultiVal VARCHAR(8000), @Delimiter VARCHAR(10)
)
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE @NewMultiVal VARCHAR(8000) = ''
	
	/****************************** CLEANUP EMAILS ***********************************/
	SET @InputMultiVal = LTRIM(RTRIM(@InputMultiVal))
	IF @InputMultiVal LIKE '% /%' OR @InputMultiVal LIKE '%/ %' SET @InputMultiVal = REPLACE(@InputMultiVal, ' ', '')

	IF @InputMultiVal LIKE '%@%/%@%'	SET @InputMultiVal = REPLACE(@InputMultiVal, '/', '|')
	ELSE SET @InputMultiVal = REPLACE(@InputMultiVal, '/', '')

	SET @InputMultiVal = REPLACE(@InputMultiVal, ',', '.')
	IF @InputMultiVal LIKE '%..%' SET @InputMultiVal = REPLACE(@InputMultiVal, '..', '.')
	IF @InputMultiVal LIKE '%@%' SET @InputMultiVal = REPLACE(@InputMultiVal, '*', '')
	ELSE SET @InputMultiVal = REPLACE(@InputMultiVal, '*', '@')
	
	SET @InputMultiVal = REPLACE(@InputMultiVal, '?', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, ';', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '!', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '#', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '$', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '%', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '^', '')
	SET @InputMultiVal = REPLACE(@InputMultiVal, '&', '')
	/*********************************************************************************/
	--IF @InputMultiVal LIKE '%[*]%' --if email address contains *
	--	BEGIN
	--		SET @InputMultiVal = REPLACE(@InputMultiVal, '*' , '')
	--	END
	IF @InputMultiVal NOT LIKE '%'+@Delimiter+'%' --If string has no delimiters
	BEGIN
		IF @InputMultiVal LIKE '%_@__%.__%' AND PATINDEX('%[^a-z,0-9,@,.,_,\-]%', @InputMultiVal) = 0 --Validate email address.
			BEGIN
				IF @InputMultiVal LIKE '%[_]%' --if email address contains _
				BEGIN
					SET @InputMultiVal = REPLACE(@InputMultiVal, '_' , '''_''')
				END
			SET @NewMultiVal = @InputMultiVal
			END
	END
	ELSE
	BEGIN
		WHILE (@InputMultiVal LIKE '%'+@Delimiter+'%')
		BEGIN
			DECLARE @SubString VARCHAR(1000) = ''
	
			SET @SubString = (SELECT LEFT(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal) - 1))
			SET @InputMultiVal = REPLACE(SUBSTRING(@InputMultiVal, CHARINDEX(@Delimiter, @InputMultiVal)+1, LEN(@InputMultiVal)), '%'+@Delimiter, '')

			IF @SubString LIKE '%_@__%.__%' AND PATINDEX('%[^a-z,0-9,@,.,_,\-]%', @SubString) = 0 --Validate email address.
			BEGIN
				IF @SubString LIKE '%[_]%' --if email address contains _
				BEGIN
					SET @SubString = REPLACE(@SubString, '_' , '''_''')
				END
				IF @NewMultiVal LIKE '' --If first substring 
				BEGIN  
					SET @NewMultiVal = @SubString
				END
				ELSE
				BEGIN
					SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @SubString)
				END

				IF @InputMultiVal NOT LIKE '%'+@Delimiter+'%' AND (@InputMultiVal LIKE '%_@__%.__%' AND PATINDEX('%[^a-z,0-9,@,.,_,\-]%', @InputMultiVal) = 0) --If last value in input string.
				BEGIN
					IF @InputMultiVal LIKE '%[_]%' --if email address contains _.
					BEGIN 
						SET @InputMultiVal = REPLACE(@InputMultiVal, '_' , '''_''')
					END
						SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @InputMultiVal)
				END
			END
			--ELSE IF @InputMultiVal NOT LIKE'%'+@Delimiter+'%' AND (@InputMultiVal LIKE '%_@__%.__%' AND PATINDEX('%[^a-z,0-9,@,.,_,\-]%', @InputMultiVal) = 0) --
			--BEGIN
			--	IF @NewMultiVal <> '' 
			--		SET @NewMultiVal = CONCAT(@NewMultiVal, @Delimiter, @InputMultiVal)
			--	ELSE
			--		SET @NewMultiVal = CONCAT(@NewMultiVal, @InputMultiVal)
			--END
		END
	END
	
	RETURN NULLIF(@NewMultiVal, '')

END
