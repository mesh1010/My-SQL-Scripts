SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
Use Manhattan; 


SELECT DISTINCT po.[DC],
po.[DCName] as 'DC Name',
po.[Zone],
po.[Bay],
wlh.[SlotTypeDesc] as 'Slot Type Description',
po.[LocationName] as 'Location Name',
po.[ItemNumber] as 'Item Number',
po.[ItemDescription] as 'Item Description',
po.[QuantityPickedBaseUOM] as 'Item Case Pack',
po.[PickedUOMVolume] as 'Item Case Volume',
po.[PickedUOMWeight] as 'Item Case Weight',
po.[Truck],
po.[CustomerNumber] as 'Customer Number',
ord.[D_FACILITY_NAME] as 'Customer Name',
SUM(po.[taskLines]) as 'Task Lines',
SUM(po.[QuantityPickedBaseUOM]) as 'Qty (pieces)',
po.[oLPN],
po.PlannedWaveDate as 'Date'
	FROM [Manhattan].[D1].[Picks_Outbound] as po
	LEFT JOIN [Manhattan].[D1].[WhseLocationHistory] as wlh       /* [for slot type desc column] */
	ON po.instance = wlh.instance AND po.LocationName = wlh.LocationName AND wlh.snapShotDate>=dateadd(day,-1, cast(getdate() as date)) 
	LEFT JOIN [Manhattan].[WMS].[Orders] as ord             /* [for company name column] */
	ON po.instance = ord.instance AND po.CustomerNumber = ord.[D_FACILITY_ALIAS_ID] AND po.[OrderNumber] = ord.[TC_ORDER_ID] 
WHERE po.[taskLines] = 1 AND po.[LocationClass] = 'A' AND po.[oLPNType] = 'case'  AND po.[PlannedWaveDate]>=dateadd(day,-7, cast(getdate() as date))
GROUP BY
po.[DC],
po.[Instance],
po.[DCName],
po.[Zone],
po.[Bay],
wlh.[SlotTypeDesc],
po.[LocationName],
po.[ItemNumber],
po.[ItemDescription],
po.[QuantityPickedBaseUOM] ,
po.[PickedUOMVolume] ,
po.[PickedUOMWeight] ,
po.[Truck],
po.[CustomerNumber],
ord.[D_FACILITY_NAME],
po.[oLPN],
po.PlannedWaveDate

