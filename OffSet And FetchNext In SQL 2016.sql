/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [InspectionTypeID]
      ,[InspectionType]
      ,[IsActive]
      ,[TypeOfTier]
      ,[TierID]
      ,[CreatedBy]
      ,[CreatedOn]
      ,[ModifiedBy]
      ,[ModifiedOn]
      ,[ConcurrencyId]
  FROM [Genacis].[dbo].[InspectionType]

SELECT * FROM (
SELECT ROW_NUMBER() OVER(ORDER BY InspectionTypeID) AS number, *
FROM [InspectionType]) AS TempTable
WHERE number > 0 and number <= 4


Select * from [InspectionType] Order By InspectionTypeID OFFSET 0 ROWS Fetch next 10 Rows Only


