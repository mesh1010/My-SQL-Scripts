SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- DECLARE VARIABLES
DECLARE @DC INT
DECLARE @ZONE NVARCHAR(6)
DECLARE @ZONEAREA NVARCHAR(50)
DECLARE @SCENARIO_ID_CURRENT INT
DECLARE @SCENARIO_ID_FUTURE INT
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME

-- SET VARIABLE VALUES EVERY TIME FOR EACH SCENARIO
SET @DC = 3
SET @ZONE = 'RF'
SET @ZONEAREA = 'Refer'
SET @startDate = '12/6/2022'
SET @endDate = '3/6/2023'
SET @SCENARIO_ID_CURRENT = 0
SET @SCENARIO_ID_FUTURE = 3


 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- FINANCIAL ASSUMPTIONS FOR ALL ZONE AREAS
		DECLARE @annualBusinessDays INT ; DECLARE @daysOfTotesInInventory TINYINT ; 
		DECLARE @lifeOfTotes_yrs TINYINT ; DECLARE @lifeOfGelPanels_yrs TINYINT ; DECLARE @lifeOfToteLiners_yrs TINYINT ;
		DECLARE @costofLARTote FLOAT ; DECLARE @costOfREGTote FLOAT ; DECLARE @costOfSMLTote FLOAT ; DECLARE @costOfBAG FLOAT ; 
		DECLARE @bandinglengthLARTote INT ; DECLARE @bandinglengthREGTote INT ; DECLARE @bandinglengthSMLTote INT ; DECLARE @lengthofBandingRoll INT ; DECLARE @costOfBandingRoll FLOAT ;
		DECLARE @numOfLabelsRoll INT ; DECLARE @costOfLabelsRoll float
 
		--FINANCIAL ASSUMPTION SET VARIABLE VALUES - DO NOT CHANGE FOR EACH SCENARIO
		SET @annualBusinessDays = 255 ; SET @daysOfTotesInInventory = 5 ; SET @lifeOfTotes_yrs = 5 ; SET @lifeOfGelPanels_yrs = 5 ; SET @lifeOfToteLiners_yrs = 2
		SET @costofLARTote = 7.08 ; SET @costOfREGTote = 5.48 ; SET @costOfSMLTote = 6.70 ; SET @costOfBAG = 0.08 ;
		SET @bandinglengthLARTote = 131 ; SET @bandinglengthREGTote = 50 ; SET @bandinglengthSMLTote = 33 ; SET @lengthofBandingRoll = 144000 ; SET @costOfBandingRoll = 104.80
		SET @numOfLabelsRoll = 5000 ; SET @costOfLabelsRoll = 74.00
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE #temp_supplyimpact

--Outermost Query: This portion of the query makes sure to include all previous fields that have been calculated for or included as well as calculating some final totals
SELECT 

p4.DC, p4.DCName, p4.Zone, 
--CURRENT STATE FIELDS: REUSABLE AND DISPOSABLE SUPPLIES
	--tote
p4.currentDailyLARContainer, p4.currentInvOfLARContainer, p4.costOfCurrentInvOfLARContainer, p4.currentDailyREGContainer, p4.currentInvOfREGContainer, p4.costOfCurrentInvOfREGContainer, p4.currentDailySMLContainer, p4.currentInvOfSMLContainer, p4.costOfCurrentInvOfSMLContainers,
p4.totalCostOfCurrentInvOfContainers, p4.currentAnnualToteReplacementCost,
	--gel panels
p4.modeledCurrentDailyOrangePanels, p4.invCurrentOrangePanels, p4.costOfCurrentInvOrangePanels, p4.modeledCurrentDailyGreenPanels, p4.invCurrentGreenPanels, p4.costOfCurrentInvGreenPanels,
p4.totalCostCurrentInvOfGelPanels, p4.currentAnnualGelPanelReplacementCost,
	--tote liners
p4.modeledCurrentDailyLARToteLiners, p4.modeledCurrentDailyREGToteLiners, p4.costOfCurrentLARToteLiners, p4.invCurrentLARToteLiners, p4.invCurrentREGToteLiners, p4.costOfCurrentREGToteLiners,
p4.totalCostOfCurrentInvOfToteLiners, p4.currentAnnualToteLinerReplacementCost, 
	--reusable supplies total
p4.currentAnnualToteReplacementCost + p4.currentAnnualGelPanelReplacementCost + p4.currentAnnualToteLinerReplacementCost AS currentAnnualReplacementCost,
	--bags
p4.currentDailyBag, p4.currentAnnualInvOfBags, p4.currentAnnualCostOfBAG, 
	--banding & labels
p4.modeledCurrentDailyBandingRolls, p4.currentAnnualInvOfBandingRolls, p4.currentAnnualBandingCost, p4.modeledCurrentDailyLabelRolls, p4.currentAnnualInvOfLabelRolls, p4.currentAnnualLabelsCost, 
	--disposable supplies total
p4.currentAnnualDisposableSuppliesCost,
	-- reusable + disposable supplies annual total
p4.currentAnnualToteReplacementCost + p4.currentAnnualGelPanelReplacementCost + p4.currentAnnualToteLinerReplacementCost + p4.currentAnnualDisposableSuppliesCost as currentAnnualTotalSupplyCost,

--FUTURE STATE FIELDS: REUSABLE AND DISPOSABLE SUPPLIES
	--tote
p4.futureDailyLARContainer, p4.futureInvOfLARContainer, p4.costOfFutureInvOfLARContainer, p4.futureDailyREGContainer, p4.futureInvOfREGContainer, p4.costOfFutureInvOfREGContainer, p4.futureDailySMLContainer, p4.futureInvOfSMLContainer, p4.costOfFutureInvOfSMLContainers,
p4.totalCostOfFutureInvOfContainers, p4.futureAnnualToteReplacementCost, 
	--gel panels
p4.modeledFutureDailyOrangePanels, p4.invFutureOrangePanels, p4.costOfFutureInvOrangePanels, p4.modeledFutureDailyGreenPanels, p4.invFutureGreenPanels, p4.costOfFutureInvGreenPanels, 
p4.totalCostFutureInvOfGelPanels, p4.futureAnnualGelPanelReplacementCost, 
	--tote liners
p4.modeledFutureDailyLARToteLiners, p4.modeledFutureDailyREGToteLiners, p4.costOfFutureLARToteLiners, p4.invFutureLARToteLiners, p4.invFutureREGToteLiners, p4.costOfFutureREGToteLiners,
p4.totalCostOfFutureInvOfToteLiners, p4.futureAnnualToteLinerReplacementCost,
	--reusable supplies total
p4.futureAnnualToteReplacementCost + futureAnnualGelPanelReplacementCost + futureAnnualToteLinerReplacementCost AS futureAnnualReplacementCost, 
	--bags
p4.futureDailyBAG, p4.futureAnnualInvOfBags, p4.futureAnnualCostOfBAG, 
	--banding & labels
p4.modeledFutureDailyBandingRolls, p4.futureAnnualInvOfBandingRolls, p4.futureAnnualBandingCost, p4.modeledFutureDailyLabelRolls, p4.futureAnnualInvOfLabelRolls, p4.futureAnnualLabelsCost
	--disposabele supplies total
, p4.futureAnnualDisposableSuppliesCost,
	-- reusable + disposable supplies annual total
p4.futureAnnualToteReplacementCost + futureAnnualGelPanelReplacementCost + futureAnnualToteLinerReplacementCost + p4.futureAnnualDisposableSuppliesCost as futureAnnualTotalSupplyCost,

--ONE TIME TOTE PURCHASE QTY & COST
p4.initialLARTotePurchaseQty, p4.initialLARTotePurchaseCost, p4.initialREGTotePurchaseQty, p4.initialREGTotePurchaseCost, p4.initialSMLTotePurchaseQty, p4.initialSMLTotePurchaseCost,
p4.initialLARTotePurchaseQty + p4.initialREGTotePurchaseQty + p4.initialSMLTotePurchaseQty as totalInitialTotePurchaseQty,
p4.initialLARTotePurchaseCost + p4.initialREGTotePurchaseCost + p4.initialSMLTotePurchaseCost as totalInitialTotePurchaseCost,
--ONE TIME GEL PANEL QTY & COST
p4.initialOrangePanelPurchaseQty, p4.initialOrangePanelCost, p4.initialGreenPanelPurchaseQty, p4.initialGreenPanelCost,
p4.initialOrangePanelPurchaseQty + p4.initialGreenPanelPurchaseQty as totalInitialGelPanelPurchaseQty,
p4.initialOrangePanelCost + p4.initialGreenPanelCost as totalInitialGelPanelPurchaseCost,
--ONE TIME TOTE LINER QTY & COST
p4.initialLARToteLinerPurchaseQty, p4.initialLARToteLinerCost, p4.initialREGToteLinerPurchaseQty, p4.initialREGToteLinerCost,
p4.initialLARToteLinerPurchaseQty + p4.initialREGToteLinerPurchaseQty as totalInitialToteLinerPurchaseQty,
p4.initialLARToteLinerCost + p4.initialREGToteLinerCost as totalInitialToteLinerPurchaseCost,
--ONE TIME SUPPLIES COST TOTAL 
p4.initialLARTotePurchaseCost + p4.initialREGTotePurchaseCost + p4.initialSMLTotePurchaseCost + p4.initialOrangePanelCost + p4.initialGreenPanelCost + p4.initialLARToteLinerCost + p4.initialREGToteLinerCost as totalOneTimePurchaseCost


INTO #temp_supplyimpact

FROM
(
--Subquery 3: The purpose of this portion of the query is to continue solving for different calculations such as the annual replacement cost and the one-time purchase qty & cost. 
	SELECT p3.DC, p3.DCName, p3.ZoneArea, p3.Zone, 
	--CURRENT STATE FIELDS: REUSABLE AND DISPOSABLE SUPPLIES
		--totes
	p3.currentDailyLARContainer, p3.currentInvOfLARContainer, p3.costOfCurrentInvOfLARContainer, p3.currentDailyREGContainer, p3.currentInvOfREGContainer, p3.costOfCurrentInvOfREGContainer, p3.currentDailySMLContainer, p3.currentInvOfSMLContainer, p3.costOfCurrentInvOfSMLContainers
	, p3.totalCostOfCurrentInvOfContainers, p3.totalCostOfCurrentInvOfContainers/@lifeOfTotes_yrs as currentAnnualToteReplacementCost,
		--gel panels
	p3.modeledCurrentDailyOrangePanels, p3.invCurrentOrangePanels, p3.costOfCurrentInvOrangePanels, p3.modeledCurrentDailyGreenPanels, p3.invCurrentGreenPanels, p3.costOfCurrentInvGreenPanels
	, p3.totalCostCurrentInvOfGelPanels, p3.totalCostCurrentInvOfGelPanels/@lifeOfGelPanels_yrs as currentAnnualGelPanelReplacementCost,
		--toteliners
	p3.modeledCurrentDailyLARToteLiners, p3.modeledCurrentDailyREGToteLiners, p3.costOfCurrentLARToteLiners, p3.invCurrentLARToteLiners, p3.invCurrentREGToteLiners, p3.costOfCurrentREGToteLiners
	, p3.totalCostOfCurrentInvOfToteLiners, p3.totalCostOfCurrentInvOfToteLiners/@lifeOfToteLiners_yrs as currentAnnualToteLinerReplacementCost,
		--bags
	p3.currentDailyBag, p3.currentAnnualInvOfBags, p3.currentAnnualCostOfBAG, 
		--banding
	p3.modeledCurrentDailyBandingRolls, p3.currentAnnualInvOfBandingRolls, p3.currentAnnualBandingCost,
		--labels
	p3.modeledCurrentDailyLabelRolls, p3.currentAnnualInvOfLabelRolls, p3.currentAnnualLabelsCost,
		--disposabele supplies total
	 p3.currentAnnualCostOfBAG + p3.currentAnnualBandingCost +  p3.currentAnnualLabelsCost as currentAnnualDisposableSuppliesCost,
	
	--FUTURE STATE FIELDS: REUSABLE AND DISPOSABLE SUPPLIES
		--totes
	p3.futureDailyLARContainer, p3.futureInvOfLARContainer, p3.costOfFutureInvOfLARContainer, p3.futureDailyREGContainer, p3.futureInvOfREGContainer, p3.costOfFutureInvOfREGContainer, p3.futureDailySMLContainer, p3.futureInvOfSMLContainer, p3.costOfFutureInvOfSMLContainers
	, p3.totalCostOfFutureInvOfContainers, p3.totalCostOfFutureInvOfContainers/@lifeOfTotes_yrs as futureAnnualToteReplacementCost,
		--gel panels
	p3.modeledFutureDailyOrangePanels, p3.invFutureOrangePanels, p3.costOfFutureInvOrangePanels, p3.modeledFutureDailyGreenPanels, p3.invFutureGreenPanels, p3.costOfFutureInvGreenPanels
	, p3.totalCostFutureInvOfGelPanels, p3.totalCostFutureInvOfGelPanels/@lifeOfGelPanels_yrs as futureAnnualGelPanelReplacementCost,
		--toteliners
	p3.modeledFutureDailyLARToteLiners, p3.modeledFutureDailyREGToteLiners, p3.costOfFutureLARToteLiners, p3.invFutureLARToteLiners, p3.invFutureREGToteLiners, p3.costOfFutureREGToteLiners
	, p3.totalCostOfFutureInvOfToteLiners, p3.totalCostOfFutureInvOfToteLiners/@lifeOfToteLiners_yrs as futureAnnualToteLinerReplacementCost,
		--bags
	p3.futureDailyBAG, p3.futureAnnualInvOfBags, p3.futureAnnualCostOfBAG, 
		--banding
	p3.modeledFutureDailyBandingRolls, p3.futureAnnualInvOfBandingRolls, p3.futureAnnualBandingCost,
		--labels
	p3.modeledFutureDailyLabelRolls, p3.futureAnnualInvOfLabelRolls, p3.futureAnnualLabelsCost,
		--disposabele supplies total
	p3.futureAnnualCostOfBAG + p3.futureAnnualBandingCost + p3.futureAnnualLabelsCost as futureAnnualDisposableSuppliesCost,

	--ONE TIME TOTE PURCHASE QTY & COST
	CASE WHEN p3.changeInLARTOTECOST>0 THEN p3.changeInLARTOTECOST ELSE 0 END as initialLARTotePurchaseCost, 
	CASE WHEN p3.initialLARTotePurchaseQty >0 THEN p3.initialLARTotePurchaseQty ELSE 0 END AS initialLARTotePurchaseQty,
	CASE WHEN p3.changeInREGTOTECOST>0 THEN p3.changeInREGTOTECOST ELSE 0 END as initialREGTotePurchaseCost, 
	CASE WHEN p3.initialREGTotePurchaseQty >0 THEN p3.initialREGTotePurchaseQty ELSE 0 END AS initialREGTotePurchaseQty, 
	CASE WHEN p3.changeInSMLTOTECOST>0 THEN p3.changeInSMLTOTECOST ELSE 0 END as initialSMLTotePurchaseCost, 
	CASE WHEN p3.initialSMLTotePurchaseQty >0 THEN p3.initialSMLTotePurchaseQty ELSE 0 END AS initialSMLTotePurchaseQty,
	--ONE TIME GEL PANEL QTY & COST
	CASE WHEN (p3.invFutureOrangePanels - p3.invCurrentOrangePanels) >0 THEN (p3.invFutureOrangePanels - p3.invCurrentOrangePanels) ELSE 0 END AS initialOrangePanelPurchaseQty,
	CASE WHEN ((p3.invFutureOrangePanels - p3.invCurrentOrangePanels)*p3.costOfOrangeGelPanel) >0 THEN ((p3.invFutureOrangePanels - p3.invCurrentOrangePanels)*p3.costOfOrangeGelPanel) ELSE 0 END AS initialOrangePanelCost,
	CASE WHEN (p3.invFutureGreenPanels - p3.invCurrentGreenPanels) >0 THEN (p3.invFutureGreenPanels - p3.invCurrentGreenPanels) ELSE 0 END AS initialGreenPanelPurchaseQty,
	CASE WHEN ((p3.invFutureGreenPanels - p3.invCurrentGreenPanels)*p3.costOfGreenGelPanel) >0 THEN ((p3.invFutureGreenPanels - p3.invCurrentGreenPanels)*p3.costOfGreenGelPanel) ELSE 0 END AS initialGreenPanelCost,
	--ONE TIME TOTE LINER QTY & COST
	CASE WHEN (p3.invFutureLARToteLiners - p3.invCurrentLARToteLiners) >0 THEN (p3.invFutureLARToteLiners - p3.invCurrentLARToteLiners) ELSE 0 END AS initialLARToteLinerPurchaseQty,
	CASE WHEN ((p3.invFutureLARToteLiners - p3.invCurrentLARToteLiners)*p3.costOfToteLinerLARTote) >0 THEN ((p3.invFutureLARToteLiners - p3.invCurrentLARToteLiners)*p3.costOfToteLinerLARTote) ELSE 0 END AS initialLARToteLinerCost,
	CASE WHEN (p3.invFutureREGToteLiners - p3.invCurrentREGToteLiners) >0 THEN (p3.invFutureREGToteLiners - p3.invCurrentREGToteLiners) ELSE 0 END AS initialREGToteLinerPurchaseQty,
	CASE WHEN ((p3.invFutureREGToteLiners - p3.invCurrentREGToteLiners)*p3.costOfToteLinerREGTote) >0 THEN ((p3.invFutureREGToteLiners - p3.invCurrentREGToteLiners)*p3.costOfToteLinerREGTote) ELSE 0 END AS initialREGToteLinerCost


	FROM
	(	

-- Subquery 2: The purpose of this portion of the query is to calculate the inventory & cost of inventory of reusable supplies for totes, gel panels & tote liners. 
--We calculate the annual inventory & cost of annual inventory for disposable supplies (bags, banding & labels). We also begin process of calculating one-time tote purchase cost. 
			SELECT p2.DC, p2.DCName, p2.ZoneArea, p2.Zone,

			--CURRENT STATE FIELDS & CALCULATIONS
			--totes
			p2.currentDailyLARContainer, p2.currentDailyLARContainer*@daysOfTotesInInventory as currentInvOfLARContainer, 
			p2.currentDailyREGContainer, p2.currentDailyREGContainer*@daysOfTotesInInventory as currentInvOfREGContainer, 
			p2.currentDailySMLContainer, p2.currentDailySMLContainer*@daysOfTotesInInventory as currentInvOfSMLContainer
			,((p2.currentDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) as costOfCurrentInvOfLARContainer,
			 ((p2.currentDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) as costOfCurrentInvOfREGContainer,
			((p2.currentDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) as costOfCurrentInvOfSMLContainers,
			((p2.currentDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) + ((p2.currentDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) + ((p2.currentDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) as totalCostOfCurrentInvOfContainers,
			--gel panels
			--ISNULL function for gel panel & tote liner columns from rfa table-- 
			(p2.currentDailyLARContainer* ISNULL(rfa.numOfGelPanelsLARTote,0)) + (p2.currentDailyREGContainer*ISNULL(rfa.numOfGelPanelsREGTote,0)) as modeledCurrentDailyOrangePanels,
			(p2.currentDailyLARContainer*ISNULL(rfa.numOfGelPanelsLARTote,0)) + (p2.currentDailyREGContainer*ISNULL(rfa.numOfGelPanelsREGTote,0)) as modeledCurrentDailyGreenPanels,
			((p2.currentDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0)) + ((p2.currentDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0)) as invCurrentOrangePanels,
			((p2.currentDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0)) + ((p2.currentDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0)) as invCurrentGreenPanels,
			(((p2.currentDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*ISNULL(rfa.costOfOrangeGelPanel,0)) + (((p2.currentDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*ISNULL(rfa.costOfOrangeGelPanel,0)) as costOfCurrentInvOrangePanels,
			(((p2.currentDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*ISNULL(rfa.costOfGreenGelPanel,0)) + (((p2.currentDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*ISNULL(rfa.costOfGreenGelPanel,0)) as costOfCurrentInvGreenPanels,
			(((p2.currentDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*(ISNULL(rfa.costOfGreenGelPanel,0)+ISNULL(rfa.costOfOrangeGelPanel,0))) + (((p2.currentDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*(ISNULL(rfa.costOfGreenGelPanel,0) + ISNULL(rfa.costOfOrangeGelPanel,0))) as totalCostCurrentInvOfGelPanels,
			--tote liners
			(p2.currentDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0)) as modeledCurrentDailyLARToteLiners, (p2.currentDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0)) as modeledCurrentDailyREGToteLiners, ((p2.currentDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory) as invCurrentLARToteLiners, ((p2.currentDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory) as invCurrentREGToteLiners, 
			((p2.currentDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerLARTote,0) as costOfCurrentLARToteLiners, ((p2.currentDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerREGTote,0) as costOfCurrentREGToteLiners,
			(((p2.currentDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerLARTote,0)) + (((p2.currentDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerREGTote,0)) AS totalCostOfCurrentInvOfToteLiners,
			--bags
			p2.currentDailyBag, p2.currentDailyBag*@annualBusinessDays as currentAnnualInvOfBags, (p2.currentDailyBag*@costOfBAG)*@annualBusinessDays as currentAnnualCostOfBAG,
			--banding
			((p2.currentDailyLARContainer*@bandinglengthLARTote)+(p2.currentDailyREGContainer*@bandinglengthREGTote)+(p2.currentDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll as modeledCurrentDailyBandingRolls,
			(((p2.currentDailyLARContainer*@bandinglengthLARTote)+(p2.currentDailyREGContainer*@bandinglengthREGTote)+(p2.currentDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll)*@annualBusinessDays as currentAnnualInvOfBandingRolls,
			((((p2.currentDailyLARContainer*@bandinglengthLARTote)+(p2.currentDailyREGContainer*@bandinglengthREGTote)+(p2.currentDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll)*@annualBusinessDays)* @costOfBandingRoll as currentAnnualBandingCost,
			--labels
			((p2.currentDailyLARContainer + p2.currentDailyREGContainer + p2.currentDailySMLContainer + p2.currentDailyBag)/ @numOfLabelsRoll) as modeledCurrentDailyLabelRolls,
			(((p2.currentDailyLARContainer + p2.currentDailyREGContainer + p2.currentDailySMLContainer + p2.currentDailyBag)/ @numOfLabelsRoll)*@annualBusinessDays) as currentAnnualInvOfLabelRolls,
			(((p2.currentDailyLARContainer + p2.currentDailyREGContainer + p2.currentDailySMLContainer + p2.currentDailyBag)/ @numOfLabelsRoll)*@annualBusinessDays)*@costOfLabelsRoll as currentAnnualLabelsCost, 

			--FUTURE STATE FIELDS & CALCULATIONS
			--totes
			p2.futureDailyLARContainer, p2.futureDailyLARContainer*@daysOfTotesInInventory as futureInvOfLARContainer, 
			p2.futureDailyREGContainer, p2.futureDailyREGContainer*@daysOfTotesInInventory as futureInvOfREGContainer, 
			p2.futureDailySMLContainer, p2.futureDailySMLContainer*@daysOfTotesInInventory as futureInvOfSMLContainer
			,((p2.futureDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) as costOfFutureInvOfLARContainer,
			 ((p2.futureDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) as costOfFutureInvOfREGContainer,
			((p2.futureDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) as costOfFutureInvOfSMLContainers,
			((p2.futureDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) + ((p2.futureDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) + ((p2.futureDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) as totalCostOfFutureInvOfContainers,
			--gel panels
			(p2.futureDailyLARContainer*ISNULL(rfa.numOfGelPanelsLARTote,0)) + (p2.futureDailyREGContainer*ISNULL(rfa.numOfGelPanelsREGTote,0)) as modeledFutureDailyOrangePanels,
			(p2.futureDailyLARContainer*ISNULL(rfa.numOfGelPanelsLARTote,0)) + (p2.futureDailyREGContainer*ISNULL(rfa.numOfGelPanelsREGTote,0)) as modeledFutureDailyGreenPanels,
			((p2.futureDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0)) + ((p2.futureDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0)) as invFutureOrangePanels,
			((p2.futureDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0)) + ((p2.futureDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0)) as invFutureGreenPanels,
			(((p2.futureDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*ISNULL(rfa.costOfOrangeGelPanel,0)) + (((p2.futureDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*ISNULL(rfa.costOfOrangeGelPanel,0)) as costOfFutureInvOrangePanels,
			(((p2.futureDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*ISNULL(rfa.costOfGreenGelPanel,0)) + (((p2.futureDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*ISNULL(rfa.costOfGreenGelPanel,0)) as costOfFutureInvGreenPanels,
			(((p2.futureDailyLARContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsLARTote,0))*(ISNULL(rfa.costOfGreenGelPanel,0)+ISNULL(rfa.costOfOrangeGelPanel,0))) + (((p2.futureDailyREGContainer*@daysOfTotesInInventory)*ISNULL(rfa.numOfGelPanelsREGTote,0))*(ISNULL(rfa.costOfGreenGelPanel,0) + ISNULL(rfa.costOfOrangeGelPanel,0))) as totalCostFutureInvOfGelPanels,
			--tote liners
			(p2.futureDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0)) as modeledFutureDailyLARToteLiners, (p2.futureDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0)) as modeledFutureDailyREGToteLiners, ((p2.futureDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory) as invFutureLARToteLiners, ((p2.futureDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory) as invFutureREGToteLiners, 
			((p2.futureDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerLARTote,0) as costOfFutureLARToteLiners, ((p2.futureDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerREGTote,0) as costOfFutureREGToteLiners,
			(((p2.futureDailyLARContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerLARTote,0)) + (((p2.futureDailyREGContainer*ISNULL(rfa.numOfToteLinersAllTote,0))*@daysOfTotesInInventory)*ISNULL(rfa.costOfToteLinerREGTote,0)) as totalCostOfFutureInvOfToteLiners,
		    --bags
			p2.futureDailyBAG, p2.futureDailyBAG*@annualBusinessDays as futureAnnualInvOfBags ,(p2.futureDailyBAG*@costOfBAG)*@annualBusinessDays as futureAnnualCostOfBAG,
			--banding
			((p2.futureDailyLARContainer*@bandinglengthLARTote)+(p2.futureDailyREGContainer*@bandinglengthREGTote)+(p2.futureDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll as modeledFutureDailyBandingRolls,
			(((p2.futureDailyLARContainer*@bandinglengthLARTote)+(p2.futureDailyREGContainer*@bandinglengthREGTote)+(p2.futureDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll)*@annualBusinessDays as futureAnnualInvOfBandingRolls,
			((((p2.futureDailyLARContainer*@bandinglengthLARTote)+(p2.futureDailyREGContainer*@bandinglengthREGTote)+(p2.futureDailySMLContainer*@bandinglengthSMLTote)) / @lengthofBandingRoll)*@annualBusinessDays)* @costOfBandingRoll as futureAnnualBandingCost,
			--labels
			((p2.futureDailyLARContainer + p2.futureDailyREGContainer + p2.futureDailySMLContainer + p2.futureDailyBAG)/ @numOfLabelsRoll) as modeledFutureDailyLabelRolls,
			(((p2.futureDailyLARContainer + p2.futureDailyREGContainer + p2.futureDailySMLContainer + p2.futureDailyBAG)/ @numOfLabelsRoll)*@annualBusinessDays) as futureAnnualInvOfLabelRolls,
			(((p2.futureDailyLARContainer + p2.futureDailyREGContainer + p2.futureDailySMLContainer + p2.futureDailyBAG)/ @numOfLabelsRoll)*@annualBusinessDays)*@costOfLabelsRoll as futureAnnualLabelsCost, 

			--Initial One-Time Tote Purchase Cost
			(p2.futureDailyLARContainer*@daysOfTotesInInventory) - (p2.currentDailyLARContainer*@daysOfTotesInInventory) as initialLARTotePurchaseQty, ((p2.futureDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) - ((p2.currentDailyLARContainer*@daysOfTotesInInventory)*@costofLARTote) as changeInLARTOTECOST, 
			(p2.futureDailyREGContainer*@daysOfTotesInInventory) - (p2.currentDailyREGContainer*@daysOfTotesInInventory) as initialREGTotePurchaseQty, ((p2.futureDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) - ((p2.currentDailyREGContainer*@daysOfTotesInInventory)*@costOfREGTote) as changeInREGTOTECOST, 
			(p2.futureDailySMLContainer*@daysOfTotesInInventory) - (p2.currentDailySMLContainer*@daysOfTotesInInventory) as initialSMLTotePurchaseQty, ((p2.futureDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) - ((p2.currentDailySMLContainer*@daysOfTotesInInventory)*@costOfSMLTote) as changeInSMLTOTECOST,

		   -- assumption values for later calculations
		  rfa.[costOfOrangeGelPanel]
		  ,rfa.[costOfGreenGelPanel]
		  ,rfa.[costOfToteLinerLARTote]
		  ,rfa.[costOfToteLinerREGTote]

			FROM

			(

--Subquery 1: Inner Most Query-- The purpose of this portion of the query is to pull the necessary informational fields as well as get our daily container values for both current and future state by tote size.
-- Additionally, I joined on 2 tables the ToteSimOut Future & Picks Outbound tables. To get the daily value, we make sure the where clause includes the necessary DOWs and the desired date range for every daily container calculation. 
					SELECT toc.DC, p1.DCName, p1.ZoneArea, toc.Zone, p1.#ofDays, 
					CEILING(toc.LAR/p1.#ofDays) as currentDailyLARContainer, CEILING(toc.REG/p1.#ofDays) as currentDailyREGContainer, CEILING(toc.SML/p1.#ofDays) as currentDailySMLContainer, CEILING(toc.BAG/p1.#ofDays) as currentDailyBag, 
					CEILING(tof.LAR/p1.#ofDays) as futureDailyLARContainer, CEILING(tof.REG/p1.#ofDays) as futureDailyREGContainer, CEILING(tof.SML/p1.#ofDays) as futureDailySMLContainer, CEILING(tof.BAG/p1.#ofDays) as futureDailyBAG
					
					FROM [PDOpsSand].[dbo].[ToteSim_output_Summary_Current] as toc
					LEFT JOIN [PDOpsSand].[dbo].[ToteSim_output_Summary_Future] as tof
					ON tof.DC = toc.DC AND tof.Zone = toc.zone
					LEFT JOIN (SELECT DC, DCName, ZoneArea, Zone, COUNT(DISTINCT PlannedWaveDate) as #ofDays
					FROM [Manhattan].[D1].[Picks_Outbound] 
					WHERE  DC =@DC AND ZONE = @ZONE AND PlannedWaveDateDow IN (1,2,3,4,5) AND (PlannedWaveDate BETWEEN @startDate AND @endDate) AND LOCATIONCLASS IN ('A','C')
					GROUP BY DC, DCName, ZoneArea, Zone) as p1
					ON toc.DC = p1.DC AND toc.Zone = p1.Zone
					WHERE toc.DC = @DC AND toc.ZONE = @ZONE AND toc.ScenarioID = @SCENARIO_ID_CURRENT AND tof.ScenarioID = @SCENARIO_ID_FUTURE
				GROUP BY toc.DC, p1.DCName, p1.ZoneArea, toc.Zone, p1.#ofDays, toc.LAR, toc.REG, toc.SML, toc.BAG, tof.LAR, tof.REG, tof.SML, tof.BAG
				
				) as p2

			LEFT JOIN [PDOpsSand].[dbo].[ToteSim_ReferFinancialAssumptions] as rfa
			ON p2.ZoneArea = rfa.zoneArea
	
	) as p3

) as p4



-------------------------------------------------------------------------------------------------------------------------
-- ASSUMPTIONS QUERY
--SELECT 
--FROM [PDOpsSand].[dbo].[ToteSim_ToteFinancialAssumptions] 

-- after temporary table is created, run the below query separately from the above. 

SELECT DC, DCName, Zone
FROM #temp_supplyimpact

--CURRENT STATE--
--totes
SELECT 'Current Modeled Daily Containers',currentDailyLARContainer, currentDailyREGContainer, currentDailySMLContainer
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Containers', currentInvOfLARContainer, currentInvOfREGContainer, currentInvOfSMLContainer
FROM #temp_supplyimpact 
UNION ALL
SELECT 'Cost of Inventory of Containers', costOfCurrentInvOfLARContainer, costOfCurrentInvOfREGContainer, costOfCurrentInvOfSMLContainers
FROM #temp_supplyimpact
--tote totals
SELECT 'Total',totalCostOfCurrentInvOfContainers, currentAnnualToteReplacementCost
FROM #temp_supplyimpact

--gel panels
SELECT 'Modeled Daily Panels', modeledCurrentDailyOrangePanels, modeledCurrentDailyGreenPanels
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Panels', invCurrentOrangePanels, invCurrentGreenPanels
FROM .#temp_supplyimpact
UNION ALL
SELECT 'Cost of Inventory of Panels', costOfCurrentInvOrangePanels, costOfCurrentInvGreenPanels
FROM #temp_supplyimpact
-- gel panel totals
SELECT 'Total', totalCostCurrentInvOfGelPanels, currentAnnualGelPanelReplacementCost
FROM #temp_supplyimpact

--tote liners
SELECT 'Modeled Daily Tote Liners', modeledCurrentDailyLARToteLiners, modeledCurrentDailyREGToteLiners
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Tote Liners', invCurrentLARToteLiners, invCurrentREGToteLiners
FROM #temp_supplyimpact
UNION ALL
SELECT 'Cost of Inventory of Tote Liners', costOfCurrentLARToteLiners, costOfCurrentREGToteLiners
FROM #temp_supplyimpact
--tote liner totals
SELECT 'Total', totalCostOfCurrentInvOfToteLiners, currentAnnualToteLinerReplacementCost
FROM #temp_supplyimpact

--bags
SELECT 'Modeled Daily Bags', currentDailyBag
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Inventory of Bags', currentAnnualInvOfBags
FROM #temp_supplyimpact
UNION ALL 
SELECT 'Annual Cost of Inventory of Bags', currentAnnualCostOfBAG
FROM #temp_supplyimpact

--banding & labels
SELECT 'Modeled Daily Amount of Rolls', modeledCurrentDailyBandingRolls, modeledCurrentDailyLabelRolls
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Amount of Rolls', currentAnnualInvOfBandingRolls, currentAnnualInvOfLabelRolls
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Cost', currentAnnualBandingCost, currentAnnualLabelsCost
FROM #temp_supplyimpact

--FUTURE STATE--
--totes
SELECT 'Future Modeled Daily Containers',futureDailyLARContainer, futureDailyREGContainer, futureDailySMLContainer
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Containers', futureInvOfLARContainer, futureInvOfREGContainer, futureInvOfSMLContainer
FROM #temp_supplyimpact 
UNION ALL
SELECT 'Cost of Inventory of Containers', costOfFutureInvOfLARContainer, costOfFutureInvOfREGContainer, costOfFutureInvOfSMLContainers
FROM #temp_supplyimpact
--tote totals
SELECT 'Total',totalCostOfFutureInvOfContainers, futureAnnualToteReplacementCost
FROM #temp_supplyimpact

--gel panels
SELECT 'Modeled Daily Panels', modeledFutureDailyOrangePanels, modeledFutureDailyGreenPanels
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Panels', invFutureOrangePanels, invFutureGreenPanels
FROM #temp_supplyimpact
UNION ALL
SELECT 'Cost of Inventory of Panels', costOfFutureInvOrangePanels, costOfFutureInvGreenPanels
FROM #temp_supplyimpact
-- gel panel totals
SELECT 'Total', totalCostFutureInvOfGelPanels, futureAnnualGelPanelReplacementCost
FROM #temp_supplyimpact

--tote liners
SELECT 'Modeled Daily Tote Liners', modeledFutureDailyLARToteLiners, modeledFutureDailyREGToteLiners
FROM #temp_supplyimpact
UNION ALL
SELECT 'Inventory of Tote Liners', invFutureLARToteLiners, invFutureREGToteLiners
FROM #temp_supplyimpact
UNION ALL
SELECT 'Cost of Inventory of Tote Liners', costOfFutureLARToteLiners, costOfFutureREGToteLiners
FROM #temp_supplyimpact
--tote liner totals
SELECT 'Total', totalCostOfFutureInvOfToteLiners, futureAnnualToteLinerReplacementCost
FROM #temp_supplyimpact

--bags
SELECT 'Modeled Daily Bags', futureDailyBAG
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Inventory of Bags', futureAnnualInvOfBags
FROM #temp_supplyimpact
UNION ALL 
SELECT 'Annual Cost of Inventory of Bags', futureAnnualCostOfBAG
FROM #temp_supplyimpact

--banding & labels
SELECT 'Modeled Daily Amount of Rolls', modeledFutureDailyBandingRolls, modeledFutureDailyLabelRolls
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Amount of Rolls', futureAnnualInvOfBandingRolls, futureAnnualInvOfLabelRolls
FROM #temp_supplyimpact
UNION ALL
SELECT 'Annual Cost', futureAnnualBandingCost, futureAnnualLabelsCost
FROM #temp_supplyimpact

--ONE TIME PURCHASE COST--
--totes
SELECT 'Initial Purchase Quantity', initialLARTotePurchaseQty, initialREGTotePurchaseQty, initialSMLTotePurchaseQty, initialLARTotePurchaseQty + initialREGTotePurchaseQty + initialSMLTotePurchaseQty as Total
FROM #temp_supplyimpact
UNION ALL
SELECT 'Initial Purchase Cost', initialLARTotePurchaseCost, initialREGTotePurchaseCost, initialSMLTotePurchaseCost, initialLARTotePurchaseCost + initialREGTotePurchaseCost + initialSMLTotePurchaseCost as Total
FROM #temp_supplyimpact
--gel panels
SELECT 'Initial Purchase Quantity', initialOrangePanelPurchaseQty, initialGreenPanelPurchaseQty, initialOrangePanelPurchaseQty + initialGreenPanelPurchaseQty as Total
FROM #temp_supplyimpact
UNION ALL
SELECT 'Initial Purchase Cost', initialOrangePanelCost, initialGreenPanelCost,  initialOrangePanelCost + initialGreenPanelCost as Total
FROM #temp_supplyimpact
--tote liners
SELECT 'Initial Purchase Quantity', initialLARToteLinerPurchaseQty, initialREGToteLinerPurchaseQty, initialLARToteLinerPurchaseQty + initialREGToteLinerPurchaseQty as Total
FROM #temp_supplyimpact
UNION ALL
SELECT 'Initial Purchase Cost', initialLARToteLinerCost, initialREGToteLinerCost, initialLARToteLinerCost + initialREGToteLinerCost as Total
FROM #temp_supplyimpact 