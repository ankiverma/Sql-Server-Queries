Select * from CustomerCommunity where CommunityName = 'UK Test 2'
--Select * from DrivePathCommunityMapping Where CommunityID = 182568

Select * from spatialCustomerCommunity where CommunityID = 182568
--Select * from  spatialDrivePathCommunityMapping Where CommunityID = 182568

Update CustomerCommunity Set isactive = 1 where CommunityID = 182568
Update spatialCustomerCommunity Set isactive = 1 where CommunityID = 182568


SELECT communityid FROM json_to_recordset('[{"communityid":182568,"CustomerID":162,"ZoneName":"UK Test 2","Description":"","ZoneLatLong":"51.92883652956803, -4.71008304040879;51.61953244207647, -3.69384768884629;51.65362561575941, -2.83691409509629;51.77274997042664, -2.29309085290879;51.328704828187895, -2.44689944665879;51.20994251835242, -1.0375977214425802;51.0198983225267, 0.385742224752903;51.78747701501922, 0.781250037252903;52.542212850677494, 1.154785193502903;52.7953810777308, -0.053710900247097015;53.40225490314969, 0.056152381002902985;53.81939133092867, -0.405273400247097;53.961831454447236, -2.844238243997097;51.92883652956803, -4.71008304040879;","CenterLat":"52.477214265147","CenterLong":"-1.6194400223025","CommunityUnitID":0,"CreatedBy":312,"CreatedOn":"2015-04-29T10:35:51.05","IsActive":true,"ModifiedBy":null,"ModifiedOn":null}]')
                                          as jsondata(communityid int)
               Select * from  public."PostGISCustomerCommunity"  
    where "CommunityID" in       (182568)  
    
    Update public."PostGISCustomerCommunity"  set  isactive = 1
    where "CommunityID" in ( 182568)
    
    SELECT Count(0)  FROM json_to_recordset('[{"communityid":182568,"CustomerID":162,"ZoneName":"UK Test 2","Description":"","ZoneLatLong":"51.92883652956803, -4.71008304040879;51.61953244207647, -3.69384768884629;51.65362561575941, -2.83691409509629;51.77274997042664, -2.29309085290879;51.328704828187895, -2.44689944665879;51.20994251835242, -1.0375977214425802;51.0198983225267, 0.385742224752903;51.78747701501922, 0.781250037252903;52.542212850677494, 1.154785193502903;52.7953810777308, -0.053710900247097015;53.40225490314969, 0.056152381002902985;53.81939133092867, -0.405273400247097;53.961831454447236, -2.844238243997097;51.92883652956803, -4.71008304040879;","CenterLat":"52.477214265147","CenterLong":"-1.6194400223025","CommunityUnitID":0,"CreatedBy":312,"CreatedOn":"2015-04-29T10:35:51.05","IsActive":true,"ModifiedBy":null,"ModifiedOn":null}]')
                                          as jsondata(communityid int)
 Select utility.fn_UpdateDeletedCommunityData('[{"communityid":182568,"CustomerID":162,"ZoneName":"UK Test 2","Description":"","ZoneLatLong":"51.92883652956803, -4.71008304040879;51.61953244207647, -3.69384768884629;51.65362561575941, -2.83691409509629;51.77274997042664, -2.29309085290879;51.328704828187895, -2.44689944665879;51.20994251835242, -1.0375977214425802;51.0198983225267, 0.385742224752903;51.78747701501922, 0.781250037252903;52.542212850677494, 1.154785193502903;52.7953810777308, -0.053710900247097015;53.40225490314969, 0.056152381002902985;53.81939133092867, -0.405273400247097;53.961831454447236, -2.844238243997097;51.92883652956803, -4.71008304040879;","CenterLat":"52.477214265147","CenterLong":"-1.6194400223025","CommunityUnitID":0,"CreatedBy":312,"CreatedOn":"2015-04-29T10:35:51.05","IsActive":true,"ModifiedBy":null,"ModifiedOn":null}]')

