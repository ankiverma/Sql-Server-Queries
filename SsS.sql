USE [Genacis]
GO
/****** Object:  StoredProcedure [dbo].[GetWorkOrderReportForMap]    Script Date: 01/16/2017 16:18:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/*---------------------------------------------------------------------------------------          
Stored Proc Name : GetWorkOrderReportForMap          
Description      : SP defined to retreive workorders for Leakage Map    
Input Parameters : CustomerID,LeakType,IsAssigned,startdate,enddate        
Authors          : Hem Upreti       
Date             : July 9, 2009     

      
		Modification History              
-----------------------------------------------------------------------------------------------
Date					Modified By                     Details            
-----------------------------------------------------------------------------------------------
17-01-2011				Manuj Sharma				Add another case for technicianName in case statement of OrderBy        
04-02-2011				Manuj Sharma				Get community and communityunit name         
12-05-2013				Manuj Sharma				Get device frequency     
20-01-2014				Hari Om Singh				Left Join with table [ProblemCode] and [ResolutionCode] removed and used    
													GetMultipleCodes function to get semi-colon separated Problem Codes and Resolution Codes.    
02-03-2015				Manuj Sharma				Get Floor Level and Apartment Number     
04-21-2015				Manuj Sharma				Get correct distance setting value  
11-08-2015				Manuj Sharma				Solve a typecast issue in order by clause.     
18-08-2015				Manuj Sharma				Get the leak type and set them in IsDigitalLeak
21-09-2015				Manuj Sharma				Add filter of Community,CommunityUnit,SupervisorArea and TechnicianArea,MDUOnly,Normal and M3 Leak
09-10-2015				Manuj Sharma				Add new filter HighFrequencyBand and Add DeviceFrequency in result and modify the way isdigital
													leak parameter was handled
09-10-2015				Manuj Sharma				Optimize the script
16-01-2016				Ankit verma                 Add PSID Filer and get PSID AND ISpanding in Result
-----------------------------------------------------------------------------------------------------													

EXEC GetWorkOrderReportForMap @customerID=N'1',@technicianID=0,@leakType=N'RAT_KILLER,HIGH_PEAKS,MED_PEAKS,LOW_PEAKS',@isAssigned=2,@startDate='2015-04-12 00:00:00',
@endDate='2015-10-09 00:00:00',@sortID=0,@workOrderIDs=NULL,@IsDigitalLeak=N'0,1,2',@CommunityID=NULL,@CommunityUnitID=N'2,12,3,1',
@SupervisorAreaID=NULL,@TechnicianAreaID=NULL,@MDUOnly=1,@M3LeakOnly=0,@NormalLeak=1,@HighFrequencyBand=N'600,700' 
----------------------------------------------------------------------------------------*/          
ALTER PROCEDURE [dbo].[GetWorkOrderReportForMap] 
(   
	 @customerID VARCHAR(800),      
	 @technicianID INT,      
	 @leakType VARCHAR(400)=NULL,      
	 @isAssigned INT = NULL,      
	 @startDate DATETIME =NULL,      
	 @endDate DATETIME =NULL,      
	 @sortID INT = NULL ,    
	 @workOrderIDs VARCHAR(8000) =NULL,  
	 @isDigitalLeak VARCHAR(10)=NULL,
	 @CommunityID VARCHAR(MAX)=NULL,  
	 @CommunityUnitID VARCHAR(MAX)=NULL,  
	 @SupervisorAreaID VARCHAR(MAX)=NULL,  
	 @TechnicianAreaID VARCHAR(MAX)=NULL,
	 @MDUOnly BIT=0,        
	 @M3LeakOnly BIT=0,
	 @NormalLeak BIT=0,
	 @HighFrequencyBand VARCHAR(2000)=NULL
	 ,@SelectedPSID VARCHAR(8000) = NULL
 )
   
AS         
 BEGIN                    
 SET NOCOUNT ON      
    
 --To get the customer timezone(hour offset and minute offset)        
 DECLARE @TimeZoneHourOffset INT, 
		 @TimeZoneMinuteOffset INT,
		 @MessageTypeID INT,
		 @MessageTypeIDForM3TypeLeak INT
 
 DECLARE @CommunityTable TABLE(ID INT)  
 DECLARE @SupervisorTable TABLE(ID INT)  
 DECLARE @TechnicianTable TABLE(ID INT)  
 DECLARE @CommunityUnitTable TABLE(ID INT)
 DECLARE @tblWorkOrderId TABLE(ID INT)
 DECLARE @tblCustomerTable TABLE(CustomerID INT)
 DECLARE @tblPeakType TABLE(PeakType VARCHAR(200))
 
 DECLARE @PSIDTable TABLE (PhysicalSystemID INT, PSID VARCHAR(8000), CommunityID INT, CommunityName VARCHAR(500), CustomerID INT)		
      	DECLARE @PSIDCommunityMappedTable TABLE (CommunityID INT, CommunityName VARCHAR(500),PhysicalSystemID INT, PSID VARCHAR(8000))	
		 
    INSERT INTO @tblCustomerTable(CustomerID)
    SELECT ITEMS FROM dbo.Split(@customerID,',')
    
    INSERT INTO @tblPeakType(PeakType)
    SELECT ITEMS FROM dbo.Split(@leakType,',')
    		 
		 ----Get messageTypeID for MDU Leak 
	SELECT @MessageTypeID=DBO.fn_GetMessageTypeID('MessageType','MDULeak')
	
	----Get messageTypeID for M3 Type Leak
	SELECT @MessageTypeIDForM3TypeLeak=DBO.fn_GetMessageTypeID('MessageType','M3Leak')
	
	INSERT INTO @tblWorkOrderId(ID)
	SELECT Items FROM DBO.Split(@workOrderIDs,',') 
	
	IF ISNULL(@CommunityID,'')<>''
	BEGIN 
		INSERT INTO @CommunityTable   
		SELECT Items FROM dbo.split(@CommunityID ,',')  
	END

	INSERT INTO @SupervisorTable   
	SELECT Items FROM dbo.split(@SupervisorAreaID ,',')  

	INSERT INTO @TechnicianTable   
	SELECT Items FROM dbo.split(@TechnicianAreaID ,',')  

	INSERT INTO @CommunityUnitTable   
	SELECT Items FROM dbo.split(@CommunityUnitID ,',') 
	
		--select All Communities with respect to Physical System ID and CustomerID values ------
			INSERT INTO @PSIDTable(CommunityID,CommunityName,PhysicalSystemID,PSID)
			SELECT CommunityID,CommunityName,PhysicalSystemID,PSID FROM [dbo].[GetAllCommunityByPSID](@CustomerId,@SelectedPSID)

			INSERT INTO @PSIDCommunityMappedTable
				SELECT Distinct CommunityID, CommunityName,PhysicalSystemID,
				 STUFF(  
						(  
						SELECT ',' + T2.PSID  
						FROM @PSIDTable T2
						WHERE T2.CommunityID = T1.CommunityID 
						FOR XML PATH ('')  
						),1,1,'') 
						FROM @PSIDTable T1
						GROUP BY T1.CommunityName,T1.CommunityID,T1.PSID,T1.PhysicalSystemID
		-- ----------- Select PSID ----------------------------------------------------- 
         IF ISNULL(@CommunityUnitID,'')<>''  
			 BEGIN  
			  INSERT INTO @CommunityUnitTable     
			  SELECT Items FROM dbo.split(@CommunityUnitID ,',')    
			   
			  INSERT INTO @CommunityTable    
			  SELECT COMMUNITYID FROM COMMUNITYMAPPING WHERE COMMUNITYUNITID IN(SELECT ID FROM @CommunityUnitTable)    
			  AND IsActive=1    
			 END  
			 ELSE IF ISNULL(@CommunityID,'')<>''
			 BEGIN  
			   INSERT INTO @CommunityTable       
				SELECT Items FROM dbo.split(@CommunityID ,',')    
			 END
			 ELSE IF ISNULL(@SelectedPSID,'')<>''
			 BEGIN
					INSERT INTO @CommunityTable   
					SELECT CommunityID FROM @PSIDCommunityMappedTable
			END
			ELSE
			BEGIN	
				INSERT INTO @CommunityTable       
			   VALUES(0) 
			   
				  INSERT INTO @CommunityTable       
			   SELECT   
				COMMUNITYID   
			   FROM   
				CustomerCommunity   
			   WHERE IsActive=1   
				AND CustomerID IN (SELECT Items FROM dbo.split(@CustomerId,';'))  
			END
		
		
	/*
	
	 SELECT * FROM        
		 (        
			  SELECT           
				  LeakLatitude AS Latitude,LeakLongitude AS Longitude,WO.WorkOrderID,WO.WorkOrderNo,        
				  RIGHT(REPLICATE('0',10) + Wo.WorkOrderNo,10) AS SortWorkOrderNO,        
				  LeakSignalStrength,IsWorkOrderCreated, 
				  WorkOrderStatus,
				  ISRatKiller, T.FirstName, T.LastName,          
				  T.FirstName + ' '+  T.LastName TechnicianName,DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)) AS EventTime,        
				  CONVERT(VARCHAR(10),DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)),101) + ' ' + CONVERT(VARCHAR(10),DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)),108) AS LeakTime ,        
				  FaultLocation,Convert(Varchar,WO.DateRepair,101) As RepairedOn,RepairTime,LevelAfterRepair,          
				  ISNULL(L.Address,LeakLatitude + ','+ LeakLongitude) [Address],
				  dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') AS 'Description', -- changed PC.[Description] to dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  Comments,  
				  TechnicianReportedLeak,
				  dbo.GetCustomerMultipleCodes(WO.ProblemCodeID,'P',@customerID) AS Code,	-- changed PC.Code to dbo.GetMultipleCodes(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  dbo.GetCustomerMultipleCodes(WO.ResolutionCodeID,'R',@customerID) AS 'ResolutionCode',-- changed RC.Code to dbo.GetMultipleCodes(WO.ResolutionCodeID,'R') by Hari on 17/1/2014
				  dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') AS 'ResolutionDescription', -- changed RC.Description to dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') by Hari on 17/1/2014       
				  L.CustomerID,        
				  (          
					   SELECT LookupKey FROM CustomerLookUp CLU           
					   INNER JOIN Lookup L ON CLU.LookupID=L.LookupID AND CustomerID=tbl.CustomerID          
					   INNER JOIN LookupType LT ON L.LookupTypeID=LT.LookupTypeID          
					   AND LookupTypeKey='LeakSignalRangeName'           
					   AND StartValue<= LeakSignalStrength  AND EndValue>=LeakSignalStrength          
				  )PeakType,
				  WO.TechnicianID,          
				  CONVERT(VARCHAR,Wo.CreatedOn,101) CreatedOn,L.LeakageID,        
				  WO.CreatedOn AS SortCreatedOn,        
				  WO.DateRepair AS SortRepairedOn,        
				  ISNULL(GE.COMMUNITYNAME,'') [CommunityName],
				  ISNULL(GE.COMMUNITYUNITNAME,'') [CommunityUnitName],  
				  CASE 
						WHEN @MessageTypeID=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog MDU'
						WHEN @MessageTypeID=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital MDU'
						WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog M3'
						WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital M3'
						WHEN ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog'
						WHEN L.IsDigitalLeak = 1 THEN 'Digital'
				   END [IsDigitalLeak] ,
				  ISNULL(DeviceFrequency,0) DeviceFrequency,
				   ----Added by Manuj on April 21,2015
				  CASE WHEN CS.DistanceUnitID=1 
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=1 AND DISTANCEVALUE=L.DistanceSetting)
					  WHEN CS.DistanceUnitID=2
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=2 AND DISTANCEVALUE=L.DistanceSetting)
				  END [DistanceSetting],
				  CS.DistanceUnitID,
				  ISNULL(FloorLevel,'') [FloorLevel],
				  ISNULL(AptNum,'') [AptNumber],
				  CASE WHEN ISNULL(FloorLevel,'')='' AND ISNULL(AptNum,'')=''  THEN ''
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')=''  THEN ISNULL(FloorLevel,'')
									 WHEN ISNULL(FloorLevel,'')=''  AND ISNULL(AptNum,'')<>'' THEN ISNULL(AptNum,'')
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')<>'' THEN ISNULL(FloorLevel,'') +'<br />' + ISNULL(AptNum,'')
				  END [AptFloorLevel],
				  L.CommunityID,L.SupervisorAreaID,L.TechnicianAreaID,
				  CASE WHEN UDP.MessageTypeID=@MessageTypeID THEN 1  
						ELSE 0  
					END [IsMDULeak],
				 
					CASE 
						WHEN UDP.MessageTypeID=@MessageTypeIDForM3TypeLeak THEN 1 
						ELSE 0
					END [IsM3TypeLeak],
					CASE WHEN CAST(L.DeviceFrequency AS FLOAT)>550 AND ISNULL(@HighFrequencyBand,'')<>'' THEN
								dbo.fn_CheckDeviceFrequencyRange(L.DeviceFrequency,@HighFrequencyBand) 
						ELSE 1
					END	[IsFrequencyExistInGivenRange],
					TZ.TimeZoneHourOffset,
					TZ.TimeZoneMinuteOffset  
			  FROM           
				  Leakage L WITH(NOLOCK)           
				  INNER JOIN UDPMaster UDP WITH(NOLOCK) ON L.UDPMasterID=UDP.UDPMasterID
				  INNER JOIN Workorders WO ON WO.LeakageID=L.LeakageID           
				  AND           
				  (          
				   ISNULL(@IsAssigned,2) =2           
				   OR (@IsAssigned =1 AND ISNULL(WO.TechnicianID,0)<>0)           
				   OR (@IsAssigned =0 AND ISNULL(WO.TechnicianID,0)=0)          
				  )        
				   --AND (@isDigitalLeak=2 OR ISNULL(L.isDigitalLeak,0)=ISNULL(@isDigitalLeak,0)) ----Added by Manuj     
				  INNER JOIN CustomerSetUp CS ON L.CustomerID = CS.CustomerID        
				  INNER JOIN (       
								SELECT TimeZoneID,CAST(TimeZoneOffsetOperator+ CAST(TimeZoneHourOffset AS VARCHAR) AS SMALLINT) AS TimeZoneHourOffset,             
									CAST(TimeZoneOffsetOperator + CAST(TimeZoneMinuteOffset AS VARCHAR) AS SMALLINT) AS TimeZoneMinuteOffset           
								FROM 
									TimeZones     
							) AS TZ ON CS.TimeZoneID = TZ.TimeZoneID       
				  INNER JOIN @tblCustomerTable tbl ON CS.CustomerID=tbl.CustomerID    
				  LEFT JOIN Technicians T ON WO.TechnicianID=T.TechnicianID           
				  LEFT JOIN vwCommunityDetail GE ON L.COMMUNITYID=GE.COMMUNITYID        
			  WHERE
					(   
						(ISNULL(@isDigitalLeak,'') LIKE '%0%' AND ISNULL(L.isDigitalLeak,0)=0)  
						OR  
						(ISNULL(@isDigitalLeak,'') LIKE '%2%')  
						OR  
						((ISNULL(@isDigitalLeak,'') LIKE '1%' OR ISNULL(@isDigitalLeak,'') LIKE '%,1%') AND L.isDigitalLeak=1 AND CAST(L.DeviceFrequency AS FLOAT)<=550)  
					)  
					AND         
				   (          
					   ( ISNULL(@startDate,'') = '' OR DATEDIFF(dd,DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)),@startDate) <= 0)          
						AND (ISNULL(@endDate,'') = '' OR DATEDIFF(dd,@endDate,DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)))<=0)          
				   )
		  )TempTable        
		  WHERE        
				  (@leakType IS NULL OR PeakType IN (SELECT PeakType FROM @tblPeakType))
				  AND (ISNULL(@technicianID,'')= '' OR TechnicianID= @technicianID)        
				  AND        
				  (        
						ISNULL(@workOrderIDs,'') = ''         
						OR WorkOrderID IN (SELECT ID FROM @tblWorkOrderId)   
				  )      
				  --AND CustomerID= @CustomerID     
				  AND (@CommunityID IS NULL OR  ISNULL(TempTable.CommunityID,0) IN (SELECT ISNULL(ID,0) FROM @CommunityTable)) 
				  AND (@SupervisorAreaID IS NULL OR SupervisorAreaID IN (SELECT ID FROM @SupervisorTable))  
				  AND (@TechnicianAreaID IS NULL OR TechnicianAreaID IN (SELECT ID FROM @TechnicianTable))  
				  AND WorkOrderStatus=1  
				  AND (
					((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsMDULeak end =0)
					AND 
					(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsMDULeak end =1)
					OR 
					(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsMDULeak end =0)
					OR 
					(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak  end =0)
					OR
					(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak  end =0 ))
					OR
					((case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak end =1)
					OR 
					(case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
					)				 
				 AND IsFrequencyExistInGivenRange=1 
		  ORDER BY         
			CASE @sortID WHEN 0 THEN CAST(SortWorkOrderNO AS VARCHAR)
						 WHEN 1 THEN CAST(LeakSignalStrength AS VARCHAR)
						 WHEN 3 THEN CAST(SortWorkOrderNO AS VARCHAR)
			END,            
			CASE WHEN @sortID = 2 THEN CAST(TechnicianName AS VARCHAR)
			END  
		*/
		
			
  
		IF(CHARINDEX(',',@customerID) > 0) -- For multiple customer        
		BEGIN        
		 SELECT * FROM        
		 (        
			  SELECT           
				  LeakLatitude as Latitude,LeakLongitude AS Longitude,WO.WorkOrderID,WO.WorkOrderNo,        
				  RIGHT(REPLICATE('0',10) + Wo.WorkOrderNo,10) AS SortWorkOrderNO,        
				  LeakSignalStrength,IsWorkOrderCreated, WorkOrderStatus,ISRatKiller, T.FirstName, T.LastName,          
				  T.FirstName + ' '+  T.LastName TechnicianName,DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)) AS EventTime,        
				  CONVERT(VARCHAR(10),DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)),101) + ' ' + CONVERT(VARCHAR(10),DATEADD(mi,TimeZoneMinuteOffset,DATEADD(hh,TimeZoneHourOffset,L.EventTime)),108) AS LeakTime ,        
				  FaultLocation,Convert(Varchar,WO.DateRepair,101) As RepairedOn,RepairTime,LevelAfterRepair,          
				  ISNULL(L.Address,LeakLatitude + ','+ LeakLongitude) [Address],
				  dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') AS 'Description', -- changed PC.[Description] to dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  Comments,  TechnicianReportedLeak,
				  dbo.GetCustomerMultipleCodes(WO.ProblemCodeID,'P',@customerID) AS Code,	-- changed PC.Code to dbo.GetMultipleCodes(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  dbo.GetCustomerMultipleCodes(WO.ResolutionCodeID,'R',@customerID) AS 'ResolutionCode',-- changed RC.Code to dbo.GetMultipleCodes(WO.ResolutionCodeID,'R') by Hari on 17/1/2014
				  dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') AS 'ResolutionDescription',-- changed RC.Description to dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') by Hari on 17/1/2014       
				  L.CustomerID,
				  WO.TechnicianID,          
				  CONVERT(VARCHAR,Wo.CreatedOn,101) CreatedOn,L.LeakageID,        
				  WO.CreatedOn AS SortCreatedOn,        
				  WO.DateRepair AS SortRepairedOn,
				  ISNULL(GE.COMMUNITYNAME,'') [CommunityName],ISNULL(GE.COMMUNITYUNITNAME,'') [CommunityUnitName],  
				CASE 
					WHEN @MessageTypeID=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog MDU'
					WHEN @MessageTypeID=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital MDU'
					WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog M3'
					WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital M3'
					WHEN ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog'
					WHEN L.IsDigitalLeak = 1 THEN 'Digital'
					END [IsDigitalLeak] ,
				  ISNULL(DeviceFrequency,0) DeviceFrequency,

					 ----Added by Manuj on April 21,2015
				  CASE WHEN CS.DistanceUnitID=1 
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=1 AND DISTANCEVALUE=L.DistanceSetting)
					  WHEN CS.DistanceUnitID=2
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=2 AND DISTANCEVALUE=L.DistanceSetting)
				  END [DistanceSetting],
				  CS.DistanceUnitID,
				  ISNULL(FloorLevel,'') [FloorLevel],
				  ISNULL(AptNum,'') [AptNumber],
				  CASE WHEN ISNULL(FloorLevel,'')='' AND ISNULL(AptNum,'')=''  THEN ''
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')=''  THEN ISNULL(FloorLevel,'')
									 WHEN ISNULL(FloorLevel,'')=''  AND ISNULL(AptNum,'')<>'' THEN ISNULL(AptNum,'')
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')<>'' THEN ISNULL(FloorLevel,'') +'<br />' + ISNULL(AptNum,'')
									END [AptFloorLevel],
				  L.CommunityID,L.TechnicianAreaID,L.SupervisorAreaID,
					CASE WHEN UDP.MessageTypeID=@MessageTypeID THEN 1  
						ELSE 0  
					END [IsMDULeak],
				 
					CASE 
						WHEN UDP.MessageTypeID=@MessageTypeIDForM3TypeLeak THEN 1 
						ELSE 0
					END [IsM3TypeLeak],
					CASE WHEN CAST(L.DeviceFrequency AS FLOAT)>550 AND ISNULL(@HighFrequencyBand,'')<>'' THEN
								dbo.fn_CheckDeviceFrequencyRange(L.DeviceFrequency,@HighFrequencyBand) 
						ELSE 1
						END	[IsFrequencyExistInGivenRange] ,
							CASE
							WHEN wo.WorkOrderstatus=0 THEN 'NO' 
							WHEN wo.IsPending=1 THEN 'YES'
							 ELSE 'NO'
						END [IsPending],
						SelectPSID.PSID
			  From           
				  Leakage L           
				  INNER JOIN UDPMaster UDP ON L.UDPMasterID=UDP.UDPMasterID
				  INNER JOIN Workorders WO ON WO.LeakageID=L.LeakageID           
				  AND           
				  (          
				   ISNULL(@IsAssigned,2) =2           
				   OR (@IsAssigned =1 AND ISNULL(WO.TechnicianID,0)<>0)           
				   OR (@IsAssigned =0 AND ISNULL(WO.TechnicianID,0)=0)          
				  )        
				   --AND (@isDigitalLeak=2 OR ISNULL(L.isDigitalLeak,0)=ISNULL(@isDigitalLeak,0)) ----Added by Manuj     
				 
				
				  INNER JOIN CustomerSetUp CS ON L.CustomerID = CS.CustomerID        
				  INNER JOIN (       SELECT        TimeZoneID,        CAST(TimeZoneOffsetOperator+ CAST(TimeZoneHourOffset AS VARCHAR) AS SMALLINT) AS TimeZoneHourOffset,             
				 CAST(TimeZoneOffsetOperator + CAST(TimeZoneMinuteOffset AS VARCHAR) AS SMALLINT) AS TimeZoneMinuteOffset           
				 FROM        TimeZones     ) AS TZ      ON CS.TimeZoneID = TZ.TimeZoneID           
				  LEFT JOIN Technicians T ON WO.TechnicianID=T.TechnicianID           
				  LEFT JOIN vwCommunityDetail GE ON L.COMMUNITYID=GE.COMMUNITYID     
				  	-- Added to map PSID
						LEFT OUTER JOIN @PSIDCommunityMappedTable SelectPSID ON GE.COMMUNITYID  = SelectPSID.CommunityID	   
			  WHERE
				 
					(   
						(ISNULL(@isDigitalLeak,'') LIKE '%0%' AND ISNULL(L.isDigitalLeak,0)=0)  
						OR  
						(ISNULL(@isDigitalLeak,'') LIKE '%2%')  
						OR  
						((ISNULL(@isDigitalLeak,'') LIKE '1%' OR ISNULL(@isDigitalLeak,'') LIKE '%,1%') AND L.isDigitalLeak=1 AND CAST(L.DeviceFrequency AS FLOAT)<=550)  
					)  
		  )TempTable        
		  WHERE        
		   (        
			CustomerID IN        
			 (        
			  SELECT         
			   CAST(LTRIM(RTRIM(SUBSTRING(ID, Number+1, CHARINDEX(',', ID, Number+1)-Number - 1))) AS INT) AS CustomerID        
			  FROM           
			   (SELECT ','+ ISNULL(@customerID,'') + ','  AS ID ) AS InnerQuery        
				JOIN Numbers N ON N.Number < LEN(InnerQuery.ID)        
			   WHERE         
			  SUBSTRING(ID, Number, 1) = ','        
			 )        
		  ) AND        
		  (        
		   ISNULL(@workOrderIDs,'') = ''         
		   OR WorkOrderID IN (SELECT ID FROM @tblWorkOrderId)       
		  )        
		  AND WorkOrderStatus=1     
		    AND (@CommunityID IS NULL OR ISNULL(TempTable.CommunityID,0) IN (SELECT ISNULL(ID,0) FROM @CommunityTable)) 
			AND (@SupervisorAreaID IS NULL OR SupervisorAreaID IN (SELECT ID FROM @SupervisorTable))  
			AND (@TechnicianAreaID IS NULL OR TechnicianAreaID IN (SELECT ID FROM @TechnicianTable))  
			
			AND (
			((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsMDULeak end =0)
			AND 
			(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
			OR
			((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsMDULeak end =1)
			OR 
			(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
			OR
			((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsMDULeak end =0)
			OR 
			(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
			OR
			((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak  end =0)
			OR
			(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak  end =0 ))
			OR
			((case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak end =1)
			OR 
			(case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
		  )
		  AND IsFrequencyExistInGivenRange=1
		  ORDER BY         
			CASE @sortID WHEN 0 THEN CAST(SortWorkOrderNO AS VARCHAR)
						 WHEN 1 THEN CAST(LeakSignalStrength AS VARCHAR)
						 WHEN 3 THEN CAST(SortWorkOrderNO AS VARCHAR)
			END,            
			CASE WHEN @sortID = 2 THEN CAST(TechnicianName AS VARCHAR)
			END         
	END        
	ELSE -- For single customer        
	BEGIN        
         
		 SELECT          
		  @TimeZoneHourOffset=CAST(TimeZoneOffsetOperator + CAST(TimeZoneHourOffset AS VARCHAR) AS SMALLINT),        
		  @TimeZoneMinuteOffset= CAST(TimeZoneOffsetOperator + CAST(TimeZoneMinuteOffset AS VARCHAR) AS SMALLINT)         
		 FROM          
		  TimeZones         
		  INNER JOIN CustomerSetUp CSU ON TimeZones.TimeZoneID = CSU.TimeZoneID AND CSU.CustomerID = @customerID        
		         
		 SELECT * FROM        
		 (        
			  SELECT           
				  LeakLatitude AS Latitude,LeakLongitude AS Longitude,WO.WorkOrderID,WO.WorkOrderNo,        
				  RIGHT(REPLICATE('0',10) + Wo.WorkOrderNo,10) AS SortWorkOrderNO,        
				  LeakSignalStrength,IsWorkOrderCreated, WorkOrderStatus,ISRatKiller, T.FirstName, T.LastName,          
				  T.FirstName + ' '+  T.LastName TechnicianName,DATEADD(mi,@TimeZoneMinuteOffset,DATEADD(hh,@TimeZoneHourOffset,L.EventTime)) AS EventTime,        
				  CONVERT(VARCHAR(10),DATEADD(mi,@TimeZoneMinuteOffset,DATEADD(hh,@TimeZoneHourOffset,L.EventTime)),101) + ' ' + CONVERT(VARCHAR(10),DATEADD(mi,@TimeZoneMinuteOffset,DATEADD(hh,@TimeZoneHourOffset,L.EventTime)),108) AS LeakTime ,        
				  FaultLocation,Convert(Varchar,WO.DateRepair,101) As RepairedOn,RepairTime,LevelAfterRepair,          
				  ISNULL(L.Address,LeakLatitude + ','+ LeakLongitude) [Address],
				  dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') AS 'Description', -- changed PC.[Description] to dbo.GetMultipleCodeDescriptions(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  Comments,  TechnicianReportedLeak,
				  dbo.GetCustomerMultipleCodes(WO.ProblemCodeID,'P',@customerID) AS Code,	-- changed PC.Code to dbo.GetMultipleCodes(WO.ProblemCodeID,'P') by Hari on 17/1/2014
				  dbo.GetCustomerMultipleCodes(WO.ResolutionCodeID,'R',@customerID) AS 'ResolutionCode',-- changed RC.Code to dbo.GetMultipleCodes(WO.ResolutionCodeID,'R') by Hari on 17/1/2014
				  dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') AS 'ResolutionDescription', -- changed RC.Description to dbo.GetMultipleCodeDescriptions(WO.ResolutionCodeID,'R') by Hari on 17/1/2014       
				  L.CustomerID,        
				  (          
				   SELECT LookupKey FROM CustomerLookUp CLU           
				   INNER JOIN Lookup L ON CLU.LookupID=L.LookupID AND CustomerID=@customerID           
				   INNER JOIN LookupType LT ON L.LookupTypeID=LT.LookupTypeID          
				   AND LookupTypeKey='LeakSignalRangeName'           
				   AND StartValue<= LeakSignalStrength  AND EndValue>=LeakSignalStrength          
				  )         
				  PeakType,WO.TechnicianID,          
				  CONVERT(VARCHAR,Wo.CreatedOn,101) CreatedOn,L.LeakageID,        
				  WO.CreatedOn AS SortCreatedOn,        
				  WO.DateRepair AS SortRepairedOn        
				  ,ISNULL(GE.COMMUNITYNAME,'') [CommunityName],ISNULL(GE.COMMUNITYUNITNAME,'') [CommunityUnitName],  
				  --CASE WHEN ISNULL(L.IsDigitalLeak,0)=0 THEN 'No' ELSE 'Yes' END IsDigitalLeak ,-- Added By Manuj on 25-03-2013 
				  CASE 
											WHEN @MessageTypeID=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog MDU'
											WHEN @MessageTypeID=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital MDU'
											WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog M3'
											WHEN @MessageTypeIDForM3TypeLeak=UDP.MessageTypeID AND L.IsDigitalLeak=1 THEN 'Digital M3'
											WHEN ISNULL(L.IsDigitalLeak, 0) = 0 THEN 'Analog'
											WHEN L.IsDigitalLeak = 1 THEN 'Digital'
											END [IsDigitalLeak] ,
				  ISNULL(DeviceFrequency,0) DeviceFrequency,
				   ----Added by Manuj on April 21,2015
				  CASE WHEN CS.DistanceUnitID=1 
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=1 AND DISTANCEVALUE=L.DistanceSetting)
					  WHEN CS.DistanceUnitID=2
							THEN (SELECT DISTANCE FROM DistanceMaster WHERE UNITID=2 AND DISTANCEVALUE=L.DistanceSetting)
				  END [DistanceSetting],
				  CS.DistanceUnitID,
				  ISNULL(FloorLevel,'') [FloorLevel],
				  ISNULL(AptNum,'') [AptNumber],
				  CASE WHEN ISNULL(FloorLevel,'')='' AND ISNULL(AptNum,'')=''  THEN ''
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')=''  THEN ISNULL(FloorLevel,'')
									 WHEN ISNULL(FloorLevel,'')=''  AND ISNULL(AptNum,'')<>'' THEN ISNULL(AptNum,'')
									 WHEN ISNULL(FloorLevel,'')<>'' AND ISNULL(AptNum,'')<>'' THEN ISNULL(FloorLevel,'') +'<br />' + ISNULL(AptNum,'')
									END [AptFloorLevel],
				  L.CommunityID,L.SupervisorAreaID,L.TechnicianAreaID,
				  CASE WHEN UDP.MessageTypeID=@MessageTypeID THEN 1  
						ELSE 0  
					END [IsMDULeak],
				 
					CASE 
						WHEN UDP.MessageTypeID=@MessageTypeIDForM3TypeLeak THEN 1 
						ELSE 0
					END [IsM3TypeLeak],
				CASE WHEN CAST(L.DeviceFrequency AS FLOAT)>550 AND ISNULL(@HighFrequencyBand,'')<>'' THEN
								dbo.fn_CheckDeviceFrequencyRange(L.DeviceFrequency,@HighFrequencyBand) 
						ELSE 1
						END	[IsFrequencyExistInGivenRange] ,
						CASE
							WHEN wo.WorkOrderstatus=0 THEN 'NO' 
							WHEN wo.IsPending=1 THEN 'YES'
							 ELSE 'NO'
						END [IsPending],
						SelectPSID.PSID
			  From           
				  Leakage L           
				  INNER JOIN UDPMaster UDP ON L.UDPMasterID=UDP.UDPMasterID
				  INNER JOIN Workorders WO ON WO.LeakageID=L.LeakageID 
				  INNER JOIN CustomerSetUp CS ON L.CustomerID = CS.CustomerID          
				  AND           
				  (          
				   ISNULL(@IsAssigned,2) =2           
				   OR (@IsAssigned =1 AND ISNULL(WO.TechnicianID,0)<>0)           
				   OR (@IsAssigned =0 AND ISNULL(WO.TechnicianID,0)=0)          
				  )   
				  ----Commented by Manuj on 09-10-2015   
				  ---- AND (@isDigitalLeak=2 OR ISNULL(L.isDigitalLeak,0)=ISNULL(@isDigitalLeak,0)) ----Added by Manuj     
				  LEFT JOIN Technicians T ON WO.TechnicianID=T.TechnicianID           
				  LEFT JOIN vwCommunityDetail GE ON L.COMMUNITYID=GE.COMMUNITYID     
				  	-- Added to map PSID
						LEFT OUTER JOIN @PSIDCommunityMappedTable SelectPSID ON GE.COMMUNITYID  = SelectPSID.CommunityID	
			 WHERE
					(   
						(ISNULL(@isDigitalLeak,'') LIKE '%0%' AND ISNULL(L.isDigitalLeak,0)=0)  
						OR  
						(ISNULL(@isDigitalLeak,'') LIKE '%2%')  
						OR  
						((ISNULL(@isDigitalLeak,'') LIKE '1%' OR ISNULL(@isDigitalLeak,'') LIKE '%,1%') AND L.isDigitalLeak=1 AND CAST(L.DeviceFrequency AS FLOAT)<=550)  
					)  
					     
		  )TempTable        
		  WHERE           
				   (@leakType IS NULL OR PeakType IN        
					(        
					 SELECT         
					 LTRIM(RTRIM(SUBSTRING(ID, Number+1, CHARINDEX(',', ID, Number+1)-Number - 1))) AS PeakType        
					 FROM           
					 (SELECT ','+ ISNULL(@leakType,'') + ','  AS ID ) AS InnerQuery        
					 JOIN Numbers N ON N.Number < LEN(InnerQuery.ID)        
					 WHERE         
					 SUBSTRING(ID, Number, 1) = ','        
					)        
				   )        
				   AND         
				   (          
					   ( ISNULL(@startDate,'') = '' OR DATEDIFF(dd,DATEADD(mi,@TimeZoneMinuteOffset,DATEADD(hh,@TimeZoneHourOffset,EventTime)),@startDate) <= 0)          
						AND (ISNULL(@endDate,'') = '' OR DATEDIFF(dd,@endDate,DATEADD(mi,@TimeZoneMinuteOffset,DATEADD(hh,@TimeZoneHourOffset,EventTime)))<=0)          
				   )
				  AND (ISNULL(@technicianID,'')= '' OR TechnicianID= @technicianID)        
				  AND        
				  (        
				   ISNULL(@workOrderIDs,'') = ''         
				   OR WorkOrderID IN (SELECT ID FROM @tblWorkOrderId)   
				  )      
				  AND CustomerID= @CustomerID     
				  AND (@CommunityID IS NULL OR  ISNULL(TempTable.CommunityID,0) IN (SELECT ISNULL(ID,0) FROM @CommunityTable)) 
				  AND (@SupervisorAreaID IS NULL OR SupervisorAreaID IN (SELECT ID FROM @SupervisorTable))  
				  AND (@TechnicianAreaID IS NULL OR TechnicianAreaID IN (SELECT ID FROM @TechnicianTable))  
				  AND WorkOrderStatus=1  
				  AND (
					((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsMDULeak end =0)
					AND 
					(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsMDULeak end =1)
					OR 
					(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=0) then IsM3TypeLeak end =0))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsMDULeak end =0)
					OR 
					(case when (@NormalLeak=1 and @MDUOnly=0 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
					OR
					((case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak  end =0)
					OR
					(case when (@NormalLeak=1 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak  end =0 ))
					OR
					((case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsMDULeak end =1)
					OR 
					(case when (@NormalLeak=0 and @MDUOnly=1 and @M3LeakOnly=1) then IsM3TypeLeak end =1))
					)				 
				 AND IsFrequencyExistInGivenRange=1    
		  ORDER BY         
		   CASE @sortID WHEN 0 THEN CAST(SortWorkOrderNO AS VARCHAR)
						 WHEN 1 THEN CAST(LeakSignalStrength AS VARCHAR)
						 WHEN 3 THEN CAST(SortWorkOrderNO AS VARCHAR)
			END,            
			CASE WHEN @sortID = 2 THEN CAST(TechnicianName AS VARCHAR)
			END     
END         
 
        
END 