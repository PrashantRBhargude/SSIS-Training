USE [AdventureWorks2014]
GO

/****** Object:  StoredProcedure [dbo].[PRC_TMP_DATA_LOAD]    Script Date: 3/6/2019 3:08:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PRC_TMP_DATA_LOAD] (@no_of_col int) 
AS 
DECLARE @YourText NVARCHAR(MAX)=N'    12/02/2015 09:47:44:745 SecureHARTPort version: 1.1.12.0.

    12/02/2015 09:47:44:745 Connecting and initialing Session to 
    67.40.65.181 Port:5094 Tcp
DeviceId:76w8r7
    12/02/2015 09:47:44:745 Tx: Message Header: Ver: 1, MsgType: 0, MsgId: 0 
    Status: 0x00
   TranId: 1, Data ByteCount: 5
   Data: 01 00 09 27 C0 

DeviceId:798Q6R0
    12/02/2015 09:47:44:761 Rx: Message Header: Ver: 1, MsgType: 1, MsgId: 0 
   Status: 0x00
  TranId: 1, Data ByteCount: 5
  Data: 01 00 09 27 C0 
  
DeviceId:121Q9DH
  12/02/2015 09:47:44:855 Tx: Message Header: Ver: 1, MsgType: 0, MsgId: 3 
  Status: 0x00
 TranId: 2, Data ByteCount: 5
 Data: 02 80 00 00 82 
DeviceId:7WHSA7E8Q
 12/02/2015 09:47:44:855 Rx: Message Header: Ver: 1, MsgType: 1, MsgId: 3 
 Status: 0x00
 TranId: 2, Data ByteCount: 29
 Data: 06 80 00 18 00 50 FE 26 4E 05 07 05 02 0E 0C 0B 6A 64 05 04 00 01 50 
 00 26 00 26 84 8E 

 Rx Cmd=0, Rsp code=0x00, Device Status=0x50
 Expansion Code=254
 Expanded Device Type=9806
 # Request Preambles=5
 Universal Comand Revision Level=7
 Transmitter HART Revision Level=5
 Software Revision=2
 Hardware Revision Level / Physical Signaling Code=14
 Flags=0C
 Device ID=748132
 Minimum # Response Preambles=5
 Max # of device variables=4
 Configuration Change Counter=1
 Extended Field Device Status=50
 Manufacturer''s ID=38
 Private Label Distributor=38
 Device Profile=132

DeviceId:HDB7661
 12/02/2015 09:47:44:855 Tx: Message Header: Ver: 1, MsgType: 0, MsgId: 3 
 Status: 0x00
 TranId: 3, Data ByteCount: 9
  Data: 82 A6 4E 0B 6A 64 14 00 7B 

DeviceId:97721HY
  12/02/2015 09:47:44:870 Rx: Message Header: Ver: 1, MsgType: 1, MsgId: 3 
  Status: 0x00
  TranId: 3, Data ByteCount: 43
  Data: 86 A6 4E 0B 6A 64 14 22 00 50 77 69 68 61 72 74 67 77 00 00 00 00 00 
 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0C 

 Rx Cmd=20, Rsp code=0x00, Device Status=0x50
 Long Tag=wihartgw
DeviceId:981S0EHB
  12/02/2015 09:47:44:870 Tx: Message Header: Ver: 1, MsgType: 0, MsgId: 3 
 Status: 0x00
 TranId: 4, Data ByteCount: 9
 Data: 82 A6 4E 0B 6A 64 4A 00 25 
DeviceId:102HUC8
 12/02/2015 09:47:44:886 Rx: Message Header: Ver: 1, MsgType: 1, MsgId: 3 
 Status: 0x00
 TranId: 4, Data ByteCount: 19
  Data: 86 A6 4E 0B 6A 64 4A 0A 00 50 01 01 65 00 05 02 01 03 1B 

  Rx Cmd=74, Rsp code=0x00, Device Status=0x50
 Max Num IO Cards=1
 Max Num Channels per IO Card=1
 Max Num Sub-Devices per Channel=101
  Num Devices Detected=5
  Max Num DR Supported=2
  Master Mode for Comm=1
   Retry Count for Sub-Device=3

   Rx Cmd=9, Rsp code=0x00, Device Status=0x50
   Extended Device Status=0
   Slot0 Var Code=246
   Slot0 Var Classification=0
   Slot0 Var Units=251
   Slot0 Var Value=4
   Slot0 Var Status=C0
   Slot1 Var Code=116
  Slot1 Var Units=70
 Slot1 Var Value=0'; 

 WITH LineByLine AS
 (
    SELECT  ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS LineNr
           ,LTRIM(RTRIM(x.value(N'(text())[1]',N'nvarchar(max)'))) AS Line
    FROM
    (
    SELECT CAST(N'<x>' + REPLACE((SELECT REPLACE(REPLACE(REPLACE(REPLACE(@YourText,',',NCHAR(13)+NCHAR(10)),NCHAR(10),NCHAR(13)),NCHAR(13)+NCHAR(13),NCHAR(13)),NCHAR(13),N'\nl') 
	AS [*] FOR XML PATH('')),N'\nl',N'</x><x>')  + N'</x>'AS XML) AS Casted
    ) AS t
    CROSS APPLY Casted.nodes(N'/x[text()]') AS A(x)
 ),

  CTE_TMP AS (
 SELECT LineNr,Line
 FROM LineByLine
 WHERE  CHARINDEX('Data:',Line)>0
	OR CHARINDEX('MsgId',Line)>0
	OR CHARINDEX('DeviceId',Line)>0)
SELECT * INTO TMP_DATA_LOAD
FROM CTE_TMP;

ALTER TABLE TMP_DATA_LOAD ADD ROW_NUM INT;

DECLARE @line varchar(max) 
DECLARE @LineNr int
DECLARE @X INT = @no_of_col
DECLARE @Y INT = 0;

DECLARE unstr CURSOR
STATIC FOR 
SELECT LineNr,line FROM TMP_DATA_LOAD
	  order by LineNr;
OPEN unstr
IF @@CURSOR_ROWS > 0
BEGIN 
FETCH NEXT FROM unstr INTO @LineNr,@line
WHILE @@Fetch_status = 0
BEGIN
IF @X%@no_of_col = 0    
BEGIN
--PRINT  CAST(@X AS VARCHAR(10)) + @line+ CAST(@LineNr AS VARCHAR(10))

UPDATE TMP_DATA_LOAD SET ROW_NUM= CAST(@X AS VARCHAR(10))
WHERE LineNr = CAST(@LineNr AS VARCHAR(10));

/*UPDATE TMP_DATA_LOAD SET ROW_NUM=CAST(@X-1 AS VARCHAR(10))
WHERE LineNr = CAST(@LineNr AS VARCHAR(10));*/
END
ELSE
BEGIN
WHILE (@X%@no_of_col<@no_of_col AND @X%@no_of_col>0)
BEGIN
/*UPDATE TMP_DATA_LOAD SET ROW_NUM=CAST(@X-2 AS VARCHAR(10))
WHERE LineNr = CAST(@LineNr AS VARCHAR(10));*/
--PRINT  CAST(@X-(@X%@no_of_col) AS VARCHAR(10)) + @line+ CAST(@LineNr AS VARCHAR(10))

UPDATE TMP_DATA_LOAD SET ROW_NUM= CAST(@X-(@X%@no_of_col) AS VARCHAR(10))
WHERE LineNr = CAST(@LineNr AS VARCHAR(10));

IF @X%@no_of_col <= @no_of_col-1
BEGIN
FETCH NEXT FROM unstr INTO @LineNr,@line
SET  @X = @X+1;
SET @Y=1;
END
END
END
IF (@X % @no_of_col = 0 AND @Y!=1)
BEGIN
FETCH NEXT FROM unstr INTO @LineNr,@line
SET @X = @X + 1;
END
SET @Y = 0;
END
END
CLOSE unstr
DEALLOCATE unstr;
GO


