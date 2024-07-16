SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- DECLARE VARIABLES
DECLARE @DC INT
DECLARE @ZONE NVARCHAR(6)
DECLARE @ZONEAREA NVARCHAR(50)
DECLARE @SCENARIO_ID_CURRENT INT
DECLARE @SCENARIO_ID_FUTURE INT
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME
DECLARE @annualBusinessDays INT 
-- SET VARIABLE VALUES
SET @DC = 3
SET @ZONE = 'RF'
SET @ZONEAREA = 'Refer'
SET @startDate = '12/6/2022'
SET @endDate = '3/6/2023'
SET @SCENARIO_ID_CURRENT = 0
SET @SCENARIO_ID_FUTURE = 3
SET @annualBusinessDays = 255 

DROP TABLE #temp_laborimpact

--Outermost Query: The purpose of this portion of the query is to solve for the remaining fields which are the differences between future and current - count & percentage, as well as the $ cost associated with this change at both daily and annual level (labor cost).
--Organized by tote, batchcart, pickingprocesshours, labor cost
SELECT p3.DC, p3.DCName, p3.Zone, 
--tote
p3.totalCurrentModeledDailyContainers, p3.totalFutureModeledDailyContainers, p3.totalFutureModeledDailyContainers - p3.totalCurrentModeledDailyContainers as changeInDailyContainers, (p3.totalFutureModeledDailyContainers - p3.totalCurrentModeledDailyContainers)/p3.totalCurrentModeledDailyContainers as pctchangeInDailyContainers,
--batch cart
p3.currentDailyBatchCart, p3.futureDailyBatchCart, p3.futureDailyBatchCart - p3.currentDailyBatchCart as changeInDailyBatchCart, (p3.futureDailyBatchCart - p3.currentDailyBatchCart)/p3.currentDailyBatchCart as pctchangeInDailyBatchCart,
--picking process hours
p3.currentDailyPickingProcessHours, p3.futureDailyPickingProcessHours , p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours as changeInDailyPickProcessHours, (p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours)/p3.currentDailyPickingProcessHours as pctchangeInDailyPickingProcessHours, 
--labor cost
p3.currentDailyPickingProcessHours*p3.hourlyLaborRate as currentDailyLaborCost, (p3.currentDailyPickingProcessHours*p3.hourlyLaborRate)*@annualBusinessDays as currentAnnualLaborCost, p3.futureDailyPickingProcessHours*p3.hourlyLaborRate as futureDailyLaborCost, (p3.futureDailyPickingProcessHours*p3.hourlyLaborRate)*@annualBusinessDays as futureAnnualLaborCost,
(p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours)*p3.hourlyLaborRate as changeInDailyLaborCost, ((p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours)*p3.hourlyLaborRate)/(p3.currentDailyPickingProcessHours*p3.hourlyLaborRate) as pctChangeInDailyLaborCost,
((p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours)*p3.hourlyLaborRate)*@annualBusinessDays as changeInAnnualLaborCost, (((p3.futureDailyPickingProcessHours - p3.currentDailyPickingProcessHours)*p3.hourlyLaborRate)*@annualBusinessDays)/((p3.currentDailyPickingProcessHours*p3.hourlyLaborRate)*@annualBusinessDays) as pctChangeInAnnualLaborCost,
--Below columns will be used for assumptions select statement in the temp table
p3.hourlyLaborRate, @annualBusinessDays as annualBusinessDays, p3.batchSize, p3.REGToteInSeconds, p3.LARToteInSeconds, p3.toteInSeconds, p3.batchInSeconds       

INTO #temp_laborimpact
       
FROM 
(
--Subquery 2: The purpose of this portion of the query is to calculate the MAX batch size for a specific zone based on the unqiue oLPNcount from query 1. Then, continue solving for different calculations such as the picking process hours and the batch cart. 
--We also join on 2 new tables: ToteSim_HourlyLaborRatesFDC and ToteSim_ToteFinancialAssumptions. They're both in the PDOpsSand database. We use the assumptions to solve for picking process hours.
		SELECT p2.DC, p2.DCName, p2.ZoneArea, p2.Zone, 
		--daily containers
		 p2.totalCurrentModeledDailyContainers, p2.totalFutureModeledDailyContainers, 
		--daily batch cart
		p2.batchSize, p2.currentDailyBatchCart, p2.futureDailyBatchCart, 
		-- time in seconds: totes, batch & the refer specific tote in seconds
		 ppt.REGToteInSeconds, ppt.LARToteInSeconds, ppt.ToteInSeconds, ppt.BatchInSeconds,
		--current picking process hours
		CASE WHEN p2.ZoneArea = 'Refer' THEN (((p2.currentDailyLARBatchCart+currentDailyREGBatchCart)*ppt.BatchInSeconds)+((p2.currentDailyREGTote*ppt.REGToteInSeconds)+(p2.currentDailyLARTote*ppt.LARToteInSeconds)))/3600
		ELSE ((p2.currentDailyBatchCart*ppt.BatchInSeconds)+(p2.totalCurrentModeledDailyContainers*ppt.ToteInSeconds))/3600 END as currentDailyPickingProcessHours,
		
		--future picking process hours
		CASE WHEN p2.ZoneArea = 'Refer' THEN (((p2.futureDailyLARBatchCart+p2.futureDailyREGBatchCart)*ppt.BatchInSeconds)+((p2.futureDailyREGTote*ppt.REGToteInSeconds)+(p2.futureDailyLARTote*ppt.LARToteInSeconds)))/3600
		ELSE ((p2.futureDailyBatchCart*ppt.BatchInSeconds)+(p2.totalFutureModeledDailyContainers*ppt.ToteInSeconds))/3600 END as futureDailyPickingProcessHours,		
		
		--assumptions to be used to calculate daily/annual labor cost in outer query
		hlr.hourlyLaborRate    
		
		FROM
		(

--Subquery 1: Inner Most Query-- The purpose of this portion of the query is to pull the necessary informational fields as well as get our batch size by first doing a COUNT DISTINCT of the oLPN count by TaskID.
-- Additionally, I joined on 2 tables from the ToteSimOut Current & Future tables. In the excel analysis, the current & future modeled totes by size and its sum play a crucial role in the foundation of the analysis, so I introduced the numbers in subquery 1. 
--I also calculate the daily container values for the total current & future containers as well as by tote size type. We join on the picks outbound table to pull the # of days to divide our simulated totes by to get the daily totes by tote size.    
				-- Make the TOC query our main FROM query and join on TOF & the picks outbound table (number of Business Days & oLPNCount by TaskID calculation included)
				SELECT toc.DC, p1.DCName, p1.ZoneArea, toc.Zone, p1.#ofDays,CEILING((toc.LAR + toc.REG + toc.SML + toc.BAG)/p1.#ofDays) as totalCurrentModeledDailyContainers, CEILING(tof.futureModeledTotes/p1.#ofDays) as totalFutureModeledDailyContainers,
					toc.LAR/p1.#ofDays as currentDailyLARTote, toc.REG/p1.#ofDays as currentDailyREGTote, toc.SML/p1.#ofDays as currentDailySMLTote, toc.BAG/p1.#ofDays as currentDailyBag, 
					tof.f_LAR/p1.#ofDays as futureDailyLARTote, tof.f_REG/p1.#ofDays as futureDailyREGTote, tof.f_SML/p1.#ofDays as futureDailySMLTote, tof.f_BAG/p1.#ofDays as futureDailyBAG, 
					p1.batchSize,  CEILING(((toc.LAR + toc.REG + toc.SML + toc.BAG)/p1.#ofDays)/p1.batchSize) as currentDailyBatchCart, CEILING(((tof.futureModeledTotes/p1.#ofDays))/p1.batchSize) as futureDailyBatchCart,
					CEILING((toc.LAR/p1.#ofDays)/p1.batchSize) as currentDailyLARBatchCart , CEILING((toc.REG/p1.#ofDays)/p1.batchSize) as currentDailyREGBatchCart, CEILING((tof.f_LAR/p1.#ofDays)/p1.batchSize) as futureDailyLARBatchCart , CEILING((tof.f_REG/p1.#ofDays)/p1.batchSize) as futureDailyREGBatchCart
					FROM [PDOpsSand].[dbo].[ToteSim_output_Summary_Current] as toc
					LEFT JOIN (SELECT DC, Zone, ScenarioID as futureScenarioID, LAR + REG + SML + BAG as futureModeledTotes,  LAR as f_LAR, REG as f_REG, SML as f_SML, BAG as f_BAG
					FROM [PDOpsSand].[dbo].[ToteSim_output_Summary_Future]
					WHERE DC = @DC AND ZONE = @ZONE AND ScenarioID = @SCENARIO_ID_FUTURE) as tof
					ON tof.DC = toc.DC AND tof.Zone = toc.zone
					LEFT JOIN (SELECT po.DC, po.DCName, po.ZoneArea, po.Zone, MAX(po.oLPNCount) as batchSize, COUNT(DISTINCT po.PlannedWaveDate) as #ofDays
						 FROM  
								(SELECT DC, DCName, ZoneArea, Zone, PlannedWaveDate, TaskID, COUNT(DISTINCT oLPN) as oLPNCount 
								FROM [Manhattan].[D1].[Picks_Outbound] 
								WHERE  DC =@DC AND ZONE = @ZONE AND PlannedWaveDateDow IN (1,2,3,4,5) AND (PlannedWaveDate BETWEEN @startDate AND @endDate)
								AND LOCATIONCLASS IN ('A','C') and oLPNType = 'container' AND ContainerSize IN ('MED','REG','SML','LAR','BAG')
								GROUP BY DC, DCName, ZoneArea, Zone, PlannedWaveDate, TaskID) as po
						 GROUP BY po.DC, po.DCName, po.ZoneArea, po.Zone) as p1
						 ON p1.DC = p1.DC AND p1.Zone = p1.Zone
					WHERE toc.DC = @DC AND toc.ZONE = @ZONE AND toc.ScenarioID = @SCENARIO_ID_CURRENT
					GROUP BY toc.DC, p1.DCName, p1.ZoneArea, toc.Zone, tof.futureModeledTotes, toc.LAR, toc.REG, toc.SML, toc.BAG, tof.f_LAR, tof.f_REG, tof.f_SML, tof.f_BAG, p1.#ofDays, p1.batchSize		
				) as p2
				--can update the tote financial table into 2 ; explore by tote size and zone area tables
	LEFT JOIN (SELECT * FROM [PDOpsSand].[dbo].[ToteSim_PickingProcessTime] WHERE ZoneArea = @ZONEAREA) as ppt
	ON p2.ZoneArea = ppt.[zoneArea]
	LEFT JOIN (SELECT * FROM [PDOpsSand].[dbo].[ToteSim_HourlyLaborRatesFDC] WHERE DC = @DC)hlr
	ON p2.DC = hlr.DC
	GROUP BY hlr.hourlyLaborRate, p2.DC, p2.DCName, p2.ZoneArea, p2.Zone, p2.batchSize, p2.totalCurrentModeledDailyContainers, p2.totalFutureModeledDailyContainers, p2.currentDailyBatchCart, p2.futureDailyBatchCart, ppt.REGToteInSeconds, ppt.LARToteInSeconds, ppt.ToteInSeconds, ppt.BatchInSeconds, 
	p2.currentDailyLARBatchCart, p2.currentDailyLARTote, currentDailyREGBatchCart, p2.currentDailyREGTote, p2.futureDailyLARBatchCart, p2.futureDailyLARTote, p2.futureDailyREGBatchCart, p2.futureDailyREGTote
) as p3




-- after temporary table is created, run the below query separately from the above. 

--ASSUMPTIONS
-- WHEN ZONE AREA = 'REFER' REG REGToteInSeconds, LARToteInSeconds will values and toteinSeconds will be NULL and vice versa.
SELECT 'Assumptions - Labor Hours', batchSize, REGToteInSeconds, LARToteInSeconds, toteinSeconds, batchInSeconds
FROM #temp_laborimpact
--ASSUMPTIONS
SELECT 'Assumptions - Labor Cost', hourlyLaborRate, annualBusinessDays
FROM #temp_laborimpact
-- CURRENT STATE
SELECT DC, DCName, Zone, totalCurrentModeledDailyContainers, currentDailyBatchCart, currentDailyPickingProcessHours
FROM #temp_laborimpact

SELECT currentDailyLaborCost, currentAnnualLaborCost
FROM #temp_laborimpact
-- FUTURE STATE
SELECT DC, DCName, Zone, totalFutureModeledDailyContainers, futureDailyBatchCart, futureDailyPickingProcessHours
FROM #temp_laborimpact

SELECT futureDailyLaborCost, futureAnnualLaborCost
FROM #temp_laborimpact
-- DIFFERENCE
SELECT 'Change',changeInDailyContainers, changeInDailyBatchCart, changeInDailyPickProcessHours
FROM #temp_laborimpact
UNION ALL
SELECT 'Change (%)', pctchangeInDailyContainers, pctchangeInDailyBatchCart, pctchangeInDailyPickingProcessHours
FROM #temp_laborimpact
--FINANCIAL
SELECT changeInDailyLaborCost, changeInAnnualLaborCost
FROM #temp_laborimpact
UNION ALL
SELECT pctChangeInDailyLaborCost, pctChangeInAnnualLaborCost
FROM #temp_laborimpact

