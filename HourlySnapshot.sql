SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

SELECT DISTINCT hrlysnap.DC, hrlysnap.DCName, hrlysnap.ZoneArea, 
hrlysnap.PlannedWaveDate, hrlysnap.PlannedWaveDateDow, hrlysnap.pickDate, hrlysnap.pickingHour, hrlysnap.departDate, hrlysnap.departHour
,hrlysnap.pieces, hrlysnap.lines, hrlysnap.salesDollars
FROM
(
SELECT DC, DCName,
[ZoneArea]
,plannedwavedate
,[PlannedWaveDateDow]
,CAST(DATEADD(dd, 0, DATEDIFF(dd, 0,[PickTime])) AS date) as pickDate
,DATEPART(hour,[PickTime]) as pickingHour
,CAST(DATEADD(dd, 0, DATEDIFF(dd, 0,[TruckDepartureActual])) AS date) as departDate
,DATEPART(hour,[TruckDepartureActual]) as departHour
,SUM([QuantityPickedBaseUOM]) as pieces
,SUM([TaskLines]) as lines
,SUM([TotalNIFO]) as salesDollars
FROM [Manhattan].[D1].[Picks_Outbound]
WHERE PlannedWaveDate BETWEEN '06-02-2024' AND '06-08-2024'
GROUP BY 
DC, DCName,
[ZoneArea]
,DATEPART(hour,[PickTime])
,plannedwavedate
,[PlannedWaveDateDow]
,CAST(DATEADD(dd, 0, DATEDIFF(dd, 0,[PickTime])) AS date)
,CAST(DATEADD(dd, 0, DATEDIFF(dd, 0,[TruckDepartureActual])) AS date)
,DATEPART(hour,[TruckDepartureActual])
) as hrlysnap

