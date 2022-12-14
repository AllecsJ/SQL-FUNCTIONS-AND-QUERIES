
GO
/****** Object:  UserDefinedFunction [dbo].[ConsolidatePDLoanCharges]    Script Date: 25/09/2022 00:58:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alex Jackson
-- Create date: November 12, 2021
-- Description:	Consolidates all charges (Payment Type 'CH')
--				within a multivalue string into one value 
--				(Assuming the format PR|IN|CH|CH...).
-- =============================================
ALTER FUNCTION [dbo].[ConsolidatePDLoanCharges] 
(
	@PAY_TYPE VARCHAR(35),
	@PAY_AMNT VARCHAR(65),
	@DELIMITER VARCHAR(2)
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @Payment_Amt VARCHAR(100) = ''-- RETURN
	DECLARE @TypeSubString VARCHAR(35) = '', @AmntSubString VARCHAR(65) = ''
	DECLARE @CH_sum DECIMAL(38,2) = 0, @CH_flag BIT = 0

	SET @PAY_TYPE = LTRIM(RTRIM(@PAY_TYPE))
	SET @PAY_AMNT = LTRIM(RTRIM(@PAY_AMNT))     

	IF @PAY_TYPE NOT LIKE '%'+@Delimiter+'%'
	BEGIN
		SET @Payment_Amt = @PAY_AMNT
	END
	ELSE
	BEGIN
		WHILE (@PAY_TYPE LIKE '%'+@Delimiter+'%')
		BEGIN
			--Search both at the same time
			SET @TypeSubString = (SELECT LEFT(@PAY_TYPE, CHARINDEX(@Delimiter, @PAY_TYPE) - 1))
			SET @PAY_TYPE = REPLACE(SUBSTRING(@PAY_TYPE, CHARINDEX(@Delimiter, @PAY_TYPE)+1, LEN(@PAY_TYPE)), '%'+@Delimiter, '')

			SET @AmntSubString = (SELECT LEFT(@PAY_AMNT, CHARINDEX(@Delimiter, @PAY_AMNT) - 1))
			SET @PAY_AMNT = REPLACE(SUBSTRING(@PAY_AMNT, CHARINDEX(@Delimiter, @PAY_AMNT)+1, LEN(@PAY_AMNT)), '%'+@Delimiter, '')

			IF @TypeSubString = 'CH' 
			BEGIN--Sum Charges
				IF @CH_flag = 0
					SET @CH_flag = 1
				SET @CH_sum = @CH_sum + CAST(@AmntSubString AS DECIMAL(38,2))

				IF @PAY_TYPE NOT LIKE '%'+@Delimiter+'%' AND @PAY_TYPE = 'CH'
					SET @CH_sum = @CH_sum + CAST(@PAY_AMNT AS DECIMAL(38,2))
			END
			ELSE	
			BEGIN	--Rebuild multivalue string
				IF @Payment_Amt <> '' 
					SET @Payment_Amt = CONCAT(@Payment_Amt, @Delimiter, @AmntSubString)
				ELSE
					SET @Payment_Amt = CONCAT(@Payment_Amt, @AmntSubString)
			END
		END
		IF @CH_flag = 1  --Re-attach total charges found to mutivalue string
			IF @Payment_Amt <> '' 
				SET @Payment_Amt = CONCAT(@Payment_Amt, @Delimiter, @CH_sum)
			ELSE
				SET @Payment_Amt = CONCAT(@Payment_Amt, @CH_sum)
		ELSE 
		BEGIN
			SET @Payment_Amt = CONCAT(@Payment_Amt, @Delimiter, @PAY_AMNT)
		END
	END
	
	RETURN @Payment_Amt

END
