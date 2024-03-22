IF EXISTS (SELECT name FROM sysobjects WHERE name = N'EntitiesImporter_ImportDataDirectContractsRegister' AND type = 'P')
  DROP PROCEDURE CUS.EntitiesImporter_ImportDataDirectContractsRegister
GO
-----------------------------------------------------
---   (c) ПАО "Красноярсэнергосбыт" 1994-2024     ---
-----------------------------------------------------
/****f* CUS.EntitiesImporter_ImportDataDirectContractsRegister
*	NAME 
*	CUS.EntitiesImporter_ImportDataDirectContractsRegister
*	USAGE 
* Импорт данных о потребителях для расчёта по прямым договорам
*	DESCRIPTION
*	
*	AUTHOR 
*	Денега Анатолий Остапович
*	CREATION DATE 
*	23.03.2024
*	INPUTS
*	
*	OUTPUT
*
******  
*/
CREATE PROCEDURE CUS.EntitiesImporter_ImportDataDirectContractsRegister
@DocString    VARCHAR(4096) = '',
@Function     INT = 4,
@MessageDiag  VARCHAR(2048) = '' OUTPUT
AS


DECLARE @nCount INT = 0, @ErrorNumber VARCHAR(20) = '00', @DivisionId INT,
        @PeriodNumber INT,
        @System_User VARCHAR(200) = ABS(dbo.Kernel_GetPerformer())
                                    ------------------------------
CREATE TABLE #Result (Result INT)
DECLARE @Protocol TABLE (Id INT IDENTITY, DocString VARCHAR(300))

DECLARE @cmd VARCHAR(8000), @DtCreate DATETIME,
        @TableName VARCHAR(100) = '##ImportDataDirectContractsRegister' + '_' + @System_User + '_' + DB_Name() + '_' + CAST(@@SPID AS VARCHAR(20))

IF @Function = 4 BEGIN
  SELECT DocString FROM @Protocol ORDER BY Id
  RETURN
END

IF @Function IN(0, 3) BEGIN
  SET @cmd = 'INSERT INTO #Result SELECT OBJECT_ID(' + '''' + 'tempdb..' + @TableName + '''' + ')'
  EXECUTE (@cmd)
  IF EXISTS(SELECT * FROM #Result WHERE Result IS NOT NULL) BEGIN
    SET @cmd = 'DROP TABLE ' + @TableName
    EXECUTE (@cmd)
  END
END

IF @Function = 0 BEGIN
  SET @cmd = 'CREATE TABLE ' + @TableName + ' (' +
             'nn INT, AbonNumber VARCHAR(20), FamilyMemberId INT, SNP VARCHAR(200), TransferPensFundAmount MONEY, ' +
             'SatisfiedCaseNumber VARCHAR(50), DocumentId VARCHAR(50), F8 VARCHAR(200), F9 VARCHAR(200), F10 VARCHAR(200), F11 VARCHAR(200), ' +
             'F12 VARCHAR(200), F13 VARCHAR(200), F14 VARCHAR(200), F15 VARCHAR(200), F16 VARCHAR(200), F17 VARCHAR(200), F18 VARCHAR(200), ' +
             'Empty VARCHAR(20) NULL)'
  EXECUTE (@cmd)
  RETURN
END

IF @Function = 1 BEGIN
  IF LEFT(@DocString, LEN('№ п/п;ЛС;Ид члена члена семьи;')) = '№ п/п;ЛС;Ид члена члена семьи;' BEGIN
    RETURN
  END
  SET @DocString = REPLACE(@DocString, '''', '"')
  SET @DocString = '''' + REPLACE(@DocString, ';', ''',''') + ''''
  SET @cmd = 'INSERT INTO ' + @TableName + ' (nn, AbonNumber, FamilyMemberId, SNP, TransferPensFundAmount, SatisfiedCaseNumber, DocumentId, ' +
                                           'F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18, Empty) ' +
                'SELECT ' + @DocString
  BEGIN TRY
    EXECUTE (@cmd)
  END TRY
  BEGIN CATCH
    SET @MessageDiag = ERROR_MESSAGE() + ' в строке: ' + @DocString
  END CATCH
  RETURN
END

IF @Function = 2 BEGIN
  CREATE TABLE #TempTableLoadData (nn INT, AbonNumber VARCHAR(20), FamilyMemberId INT, SNP VARCHAR(200), TransferPensFundAmount MONEY,
                                   SatisfiedCaseNumber VARCHAR(50), DocumentId INT, DocNumber VARCHAR(50))
  SET @cmd =
  '
    INSERT INTO #TempTableLoadData (nn, AbonNumber, FamilyMemberId, SNP, TransferPensFundAmount, SatisfiedCaseNumber,
                                    DocumentId, DocNumber)
      SELECT t.nn, ISNULL(LTRIM(RTRIM(t.AbonNumber)), ''''), ISNULL(t.FamilyMemberId, 0), t.SNP, t.TransferPensFundAmount,
             ISNULL(LTRIM(RTRIM(t.SatisfiedCaseNumber)), ''''), CAST(SUBSTRING(ISNULL(LTRIM(RTRIM(t.DocumentId)), ''''), 5, 10) AS INT),
             ISNULL(LTRIM(RTRIM(t.DocumentId)), '''')
      FROM ' + @TableName + ' t'
  EXECUTE (@cmd)
  /*
  INSERT INTO @Protocol (DocString)
    SELECT 'Уже загружен: ' + t.AbonNumber + '. ' + t.SNP + '. Судебный документ с Ид ' + t.DocNumber
    FROM #TempTableLoadData t
    INNER JOIN EnforceProceedingsRegisterCourtDocuments r ON r.DocumentId = t.DocumentId AND r.FamilyMemberId = t.FamilyMemberId AND
                                                             r.DivisionId = CAST(LEFT(t.DocNumber, 3) AS INT)
  DELETE #TempTableLoadData
  FROM #TempTableLoadData t
  INNER JOIN EnforceProceedingsRegisterCourtDocuments r ON r.DocumentId = t.DocumentId AND
                                                           r.DivisionId = CAST(LEFT(t.DocNumber, 3) AS INT) AND r.FamilyMemberId = t.FamilyMemberId
  WHERE r.DivisionId = @DivisionId
  SELECT @nCount = COUNT(*) FROM #TempTableLoadData

  SET @ErrorNumber = '01'
  INSERT INTO @Protocol (DocString)
    SELECT @ErrorNumber + '. Абонент ' + t.AbonNumber + ' не найден'
    FROM #TempTableLoadData t
    LEFT JOIN vAbonents a ON a.AbonNumber = t.AbonNumber
    WHERE a.AbonentId IS NULL
  DELETE #TempTableLoadData
  FROM #TempTableLoadData t
  LEFT JOIN vAbonents a ON a.AbonNumber = t.AbonNumber
  WHERE a.AbonentId IS NULL
  SET @nCount = @nCount - @@ROWCOUNT

  SET @ErrorNumber = '02'
  INSERT INTO @Protocol (DocString)
    SELECT @ErrorNumber + '. Абонент ' + t.AbonNumber + ', судебный документ ' + t.DocNumber + ' не найден или не принадлежит этому абоненту'
    FROM #TempTableLoadData t
    INNER JOIN vAbonents a ON a.AbonNumber = t.AbonNumber
    LEFT JOIN LitigationHoldRegisterCourtDocuments r ON r.AbonentId = a.AbonentId AND r.DocumentId = t.DocumentId AND
                                                        r.DivisionId = CAST(LEFT(t.DocNumber, 3) AS INT)
    WHERE r.AbonentId IS NULL
  DELETE #TempTableLoadData
  FROM #TempTableLoadData t
  INNER JOIN vAbonents a ON a.AbonNumber = t.AbonNumber
  LEFT JOIN LitigationHoldRegisterCourtDocuments r ON r.AbonentId = a.AbonentId AND r.DocumentId = t.DocumentId AND
                                                      r.DivisionId = CAST(LEFT(t.DocNumber, 3) AS INT)
  WHERE r.AbonentId IS NULL
  SET @nCount = @nCount - @@ROWCOUNT

  SET @ErrorNumber = '03'
  INSERT INTO @Protocol (DocString)
    SELECT @ErrorNumber + '. ' + t.AbonNumber + '. Ид участника СП ' + ISNULL(CAST(t.FamilyMemberId AS VARCHAR(20)), '"пусто"') +
           ' не принадлежит этому абоненту'
    FROM #TempTableLoadData t
    LEFT JOIN vFamilyMembers f ON f.AbonNumber = t.AbonNumber AND f.FamilyMemberId = t.FamilyMemberId
    WHERE f.FamilyMemberId IS NULL OR t.FamilyMemberId = 0
  DELETE #TempTableLoadData
  FROM #TempTableLoadData t
  LEFT JOIN vFamilyMembers f ON f.AbonNumber = t.AbonNumber AND f.FamilyMemberId = t.FamilyMemberId
  WHERE f.FamilyMemberId IS NULL OR t.FamilyMemberId = 0
  SET @nCount = @nCount - @@ROWCOUNT

  SET @ErrorNumber = '04'
  INSERT INTO @Protocol (DocString)
    SELECT @ErrorNumber + '. ' + t.AbonNumber + '. ФИО участника СП ' + ISNULL(t.SNP, '?') + ' не найдены или его нет в СД'
    FROM #TempTableLoadData t
    LEFT JOIN vFamilyMembers f ON f.AbonNumber = t.AbonNumber AND f.FullName = t.SNP
    WHERE f.FamilyMemberId IS NULL OR t.FamilyMemberId = 0
  DELETE #TempTableLoadData
  FROM #TempTableLoadData t
  LEFT JOIN vFamilyMembers f ON f.AbonNumber = t.AbonNumber AND f.FullName = t.SNP
  WHERE f.FamilyMemberId IS NULL OR t.FamilyMemberId = 0
  SET @nCount = @nCount - @@ROWCOUNT
---
INSERT INTO EnforceProceedingsRegisterCourtDocuments
(
  DivisionId, DocumentId, FamilyMemberId, DocumentStatusId, StatusInstallationDate, BailiffsDepartmentId,
  ExcitationDate1, ExcitationAmount1, EndingDate1, EndingReason1Id, ExcitationDate2, ExcitationAmount2,
  EndingDate2, EndingReason2Id, TransferPensFundDate, TransferPensFundAmount, ClaimDuplicateDate,
  WriteoffDate, WriteoffAmount, Notes, CancelEDDate, DocumentSourceId, DtUpdate, PerformerId, PeriodNumber
)
  SELECT @DivisionId, t.DocumentId, t.FamilyMemberId, 1, GETDATE() AS StatusInstallationDate,
         NULL AS BailiffsDepartmentId,
         NULL AS ExcitationDate1, NULL AS ExcitationAmount1, NULL AS EndingDate1, NULL AS EndingReason1Id,
         NULL AS ExcitationDate2, NULL AS ExcitationAmount2, NULL AS EndingDate2, NULL AS EndingReason2Id,
         NULL AS TransferPensFundDate, t.TransferPensFundAmount, NULL AS ClaimDuplicateDate,
         NULL AS WriteoffDate, 0 AS WriteoffAmount, NULL AS Notes, NULL AS CancelEDDate, 2 AS DocumentSourceId,
         GETDATE(), dbo.Kernel_GetPerformer(), @PeriodNumber
  FROM #TempTableLoadData t
  INNER JOIN vAbonents a ON a.AbonNumber = t.AbonNumber
*/
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION
  SELECT DocString FROM @Protocol ORDER BY Id
  IF EXISTS(SELECT DocString FROM @Protocol) BEGIN
    SET @MessageDiag = 'Реестр загружен не в полном объёме (записей ' + CAST(@nCount AS VARCHAR(20)) + '). Подробности в Протоколе загрузки'
  END
  ELSE BEGIN
    SET @MessageDiag = 'Из реестра загружено записей ' + CAST(@nCount AS VARCHAR(20))
  END
  RETURN
END

RETURN 0
GO 
