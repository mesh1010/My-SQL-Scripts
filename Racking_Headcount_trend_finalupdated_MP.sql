/****** Script for SelectTopNRows command from SSMS  ******/
SET
	TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Use Manhattan;

INSERT INTO [PDOpsSand].[dbo].[NM_CAP_RackingSqFt_SqFtPerPicker_MP] -- Joined on the outbound picker query, and calculated our sq ft per picker along with the calculations of racking sq ft, % of zone taken by racking and walking/process sq ft.
SELECT
	calc.DC,
	calc.dcName,
	calc.MonthYear,
	calc.ZoneArea,
	calc.MezzLevelZone,
	calc.LocationClass,
	calc.TotalAreaSquareFeet,
	calc.avgRackingSqFt,
	calc.[Walking/Process Sq Ft],
	calc.[Avg % of Zone Taken by Racking],
	calc.[% of Zone Walking/Process],
	headcount.[Avg Number of Pickers],
	calc.[Walking/Process Sq Ft] / headcount.[Avg Number of Pickers] AS 'Walking/Process Sq Ft per Picker'
FROM
	-- Subquery 6: We are looking at summarizing across a date range, so in order to get a clear picture of the date range, we will use AVG() of the snapshotdates to get our racking, % of zone taken by racking and walking/process sq ft.
	(
		SELECT
			trend.DC,
			trend.dcName,
			datename(MONTH, trend.SnapShotDate) + ' ' + CAST(
				DATEPART(YEAR, trend.SnapShotDate) AS VARCHAR
			) AS MonthYear,
			trend.ZoneArea,
			trend.MezzLevelZone,
			trend.LocationClass,
			AVG(trend.rackingSqFt) AS avgRackingSqFt,
			AVG(
				trend.[% of Zone Taken by Racking]
			) AS 'Avg % of Zone Taken by Racking',
			(
				trend.TotalAreaSquareFeet - AVG(trend.rackingSqFt)
			) AS 'Walking/Process Sq Ft',
			(
				trend.TotalAreaSquareFeet - AVG(trend.rackingSqFt)
			)/ NULLIF(trend.TotalAreaSquareFeet, 0) AS '% of Zone Walking/Process',
			trend.TotalAreaSquareFeet
		FROM
			(
				-- Subuery 5: Doing final comparisons by looking at snapshotdate trend ; calculating percentage of racking taken up by zone
				SELECT
					Summary.DC,
					Summary.dcName,
					Summary.SnapShotDate,
					Summary.ZoneArea,
					Summary.MezzLevelZone,
					Summary.LocationClass,
					Summary.rackingSqFt,
					bc.TotalAreaSquareFeet,
					Summary.rackingSqFt / NULLIF(bc.TotalAreaSquareFeet, 0) AS '% of Zone Taken by Racking',
					bc.PercentOfZoneCubeAvailableForRacking
				FROM
					(
						-- Subquery 4: This step is to aggregate the racking sq ft and also make sure locationclass for Mezz is converted to the value 'All'
						SELECT
							agg.DC,
							agg.dcName,
							agg.SnapShotDate,
							agg.ZoneArea,
							CASE WHEN agg.MezzLevelZone = 'Y' THEN 'Mezz' ELSE 'Main' END AS MezzLevelZone,
							CASE WHEN agg.MezzLevelZone = 'Y' THEN 'All' ELSE agg.LocationClass END AS LocationClass,
							SUM(agg.maxLocSqFt) AS rackingSqFt
						FROM
							(
								-- Subquery 3: join on the zone master table to define which zone is on the mezz and which is not. Lastly, get the max sq ft(will pull the LEVEL that has the highest area in each bay)
								SELECT
									rack.DC,
									rack.dcName,
									rack.SnapShotDate,
									CASE WHEN rack.DC = 27
									AND rack.zone = 'AD'
									AND rack.LocationClass = 'Reserve' THEN 'N' ELSE zonemaster.MezzLevelZone END AS MezzLevelZone,
									rack.LocationClass,
									rack.Zone,
									rack.Aisle,
									rack.Bay,
									rack.ZoneArea,
									MAX(rack.locSqFt) AS maxLocSqFt
								FROM
									(
										-- Subquery 2: calculate the area of the level (L x W) and then convert to sq ft.
										SELECT
											p1.DC,
											p1.PlantID,
											CASE WHEN p1.DC = 19 THEN 'Phoenix' ELSE p1.dcName END dcName,
											p1.SnapShotDate,
											p1.LocationClass,
											p1.Zone,
											p1.Aisle,
											p1.Bay,
											p1.Level,
											p1.ZoneArea,
											(
												(
													p1.LocationLength * p1.LocationWidth
												)/ 144
											) AS locSqFt
										FROM
											(
												-- Subquery 1: look at level detail and compare the loc length and width, do case when statements to ensure our values align with how DCName and Location Class is displayed in the building capacity table
												SELECT
													[DC],
													[PlantID],
													CASE WHEN [DC] = 99
													AND [ZoneArea] IN (
														'Cage', 'Vault', 'Refer', 'Frozen'
													) THEN 'NLC/BLC' ELSE [dcName] END AS dcName,
													[SnapShotDate],
													CASE WHEN [ZoneArea] IN (
														'Cage', 'Vault', 'Refer', 'Frozen'
													) THEN 'All' WHEN [dcName] = 'BLC' THEN 'All' ELSE (
														CASE WHEN [LocationClass] = 'A' THEN 'Active' WHEN [LocationClass] = 'R' THEN 'Reserve' WHEN [LocationClass] = 'C' THEN 'InnerPack' ELSE [LocationClass] END
													) END AS LocationClass,
													[Zone],
													[Aisle],
													[Bay],
													[Level],
													[ZoneArea],
													[LocationLength],
													SUM([LocationWidth]) AS LocationWidth
												FROM
													[Manhattan].[D1].[WhseLocationHistory]
												WHERE
													DC IN (99)
													AND (
														SnapShotDate BETWEEN '2024-03-01'
														AND '2024-04-30'
													)
													AND LocationClass IN ('A', 'R', 'C', '1', '0', '2')
													AND ZONE <> 'IO'
													AND Aisle <> 'RCV'
													AND LocationLength <> 0
													AND LocationWidth <> 0
													AND RackType <> 'Special Rack'
													AND LocationLength < 100
												GROUP BY
													[DC],
													[PlantID],
													CASE WHEN [DC] = 99
													AND [ZoneArea] IN (
														'Cage', 'Vault', 'Refer', 'Frozen'
													) THEN 'NLC/BLC' ELSE [dcName] END,
													[SnapShotDate],
													CASE WHEN [ZoneArea] IN (
														'Cage', 'Vault', 'Refer', 'Frozen'
													) THEN 'All' WHEN [dcName] = 'BLC' THEN 'All' ELSE (
														CASE WHEN [LocationClass] = 'A' THEN 'Active' WHEN [LocationClass] = 'R' THEN 'Reserve' WHEN [LocationClass] = 'C' THEN 'InnerPack' ELSE [LocationClass] END
													) END,
													[Zone],
													[Aisle],
													[Bay],
													[Level],
													[ZoneArea],
													[LocationLength] --ORDER BY DC, Zone, Aisle, Bay, Level
													) AS p1
										WHERE
											p1.LocationWidth < 300
										GROUP BY
											p1.DC,
											p1.PlantID,
											p1.dcName,
											p1.SnapShotDate,
											CASE WHEN p1.DC = 18 THEN 'St Louis' ELSE p1.dcName END,
											p1.SnapShotDate,
											p1.LocationClass,
											p1.Zone,
											p1.Aisle,
											p1.Bay,
											p1.Level,
											p1.ZoneArea,
											p1.LocationLength,
											p1.LocationWidth
									) AS rack
									LEFT JOIN [SCWeb].[dbo].[man_tbl_WhseZoneMaster] AS zonemaster ON rack.PlantID = zonemaster.PlantID
									AND rack.Zone = zonemaster.Zone
								GROUP BY
									rack.DC,
									rack.dcName,
									rack.PlantID,
									rack.SnapShotDate,
									CASE WHEN rack.DC = 27
									AND rack.zone = 'AD'
									AND rack.LocationClass = 'Reserve' THEN 'N' ELSE zonemaster.MezzLevelZone END,
									rack.LocationClass,
									rack.Zone,
									rack.Aisle,
									rack.Bay,
									rack.ZoneArea
							) AS agg
						GROUP BY
							agg.DC,
							agg.dcName,
							agg.SnapShotDate,
							CASE WHEN agg.MezzLevelZone = 'Y' THEN 'Mezz' ELSE 'Main' END,
							CASE WHEN agg.MezzLevelZone = 'Y' THEN 'All' ELSE agg.LocationClass END,
							agg.ZoneArea
					) AS Summary
					LEFT JOIN [PDOpsSand].[D1].[BuildingCapacity] AS bc ON Summary.dc = bc.dc
					AND Summary.zonearea = bc.[StorageArea]
					AND Summary.MezzLevelZone = bc.[Floor]
					AND Summary.LocationClass = bc.AreaType
				WHERE
					bc.DiscontinueDate = '2099-12-31' -- I was getting multiple records for 1 DC. Using this discontinue date will pull the numbers for the most recent CAD drawing
					) AS trend
		GROUP BY
			trend.DC,
			trend.dcName,
			datename(MONTH, trend.SnapShotDate) + ' ' + CAST(
				DATEPART(YEAR, trend.SnapShotDate) AS VARCHAR
			),
			trend.ZoneArea,
			trend.MezzLevelZone,
			trend.LocationClass,
			trend.TotalAreaSquareFeet
	) AS calc --JOINING TO THE OUTBOUND PICKER QUERY
	LEFT JOIN (
		--Subquery 3: Calculate average across date range
		SELECT
			trend.DC,
			trend.DCName,
			datename(MONTH, trend.PlannedWaveDate) + ' ' + CAST(
				DATEPART(YEAR, trend.PlannedWaveDate) AS VARCHAR
			) AS MonthYear,
			trend.ZoneArea,
			trend.MezzLevelZone,
			trend.LocationClass,
			AVG(trend.discpercentile) AS 'Avg Number of Pickers'
		FROM
			(
				--Subquery 2: calculate distinct percentile and get unique DC-ZoneArea-MezzLevelZone-LocationClass picker count
				SELECT
					DISTINCT maxpick.DC,
					maxpick.DCName,
					maxpick.PlannedWaveDate,
					maxpick.ZoneArea,
					maxpick.MezzLevelZone,
					maxpick.LocationClass,
					discpercentile = PERCENTILE_DISC(0.9) WITHIN GROUP(
						ORDER BY
							maxpick.Pickers
					) OVER(
						PARTITION BY maxpick.DC, maxpick.PlannedWaveDate,
						maxpick.ZoneArea, maxpick.MezzLevelZone,
						maxpick.LocationClass
					)
				FROM
					(
						--Subquery 1: get picker count by pick hour with count distinct, join on the zone master table, do case when statements to ensure our values align with how DCName and Location Class is displayed in the building capacity table
						SELECT
							Picks.[DC],
							CASE WHEN (
								Picks.DC = 99
								AND Picks.ZoneArea IN (
									'Cage', 'Vault', 'Refer', 'Frozen'
								)
							) THEN 'NLC/BLC' ELSE Picks.dcName END AS dcName,
							Picks.[PlantID],
							Picks.[PlannedWaveDate],
							Picks.[ZoneArea],
							CASE WHEN zonemaster.MezzLevelZone = 'Y' THEN 'Mezz' WHEN zonemaster.MezzLevelZone = 'N' THEN 'Main' ELSE 'Main' END AS MezzLevelZone,
							CASE WHEN Picks.ZoneArea IN (
								'Cage', 'Vault', 'Refer', 'Frozen'
							) THEN 'All' WHEN Picks.DCName = 'BLC' THEN 'All' WHEN zonemaster.MezzLevelZone = 'Y' THEN 'All' ELSE (
								CASE WHEN Picks.LocationClass = 'A' THEN 'Active' WHEN Picks.LocationClass = 'R' THEN 'Reserve' WHEN Picks.LocationClass = 'C' THEN 'InnerPack' ELSE Picks.LocationClass END
							) END AS LocationClass,
							DATEADD(
								mi,
								DATEDIFF(mi, 0, Picks.[PickTime])/ 60*60,
								0
							) AS PickHour,
							COUNT(DISTINCT Picks.Picker) AS Pickers
						FROM
							[Manhattan].[D1].[Picks_Outbound] Picks
							LEFT JOIN (
								SELECT
									[RecID],
									[PlantID],
									[Zone],
									[ZoneDescription],
									CASE WHEN PlantID = 'P027'
									AND ZONE = 'AD' THEN 'N' ELSE [MezzLevelZone] END AS MezzLevelZone
								FROM
									[SCWeb].[dbo].[man_tbl_WhseZoneMaster]
							) AS zonemaster ON Picks.PlantID = zonemaster.PlantID
							AND Picks.Zone = zonemaster.Zone
						WHERE
							(
								Picks.[PlannedWaveDate] BETWEEN '2024-03-01'
								AND '2024-04-30'
							)
							/* 4 weeks trend */
							AND Picks.[DC] IN (99) --AND Picks.InventoryType='P'
							AND Picks.[LocationClass] IN ('A', 'R', 'C', '1', '0', '2') --AND Picks.DeliveryTimeOfDay LIKE 'DSD_AM%'
							AND Picks.Zone <> 'IO'
							AND Picks.Aisle <> 'RCV'
						GROUP BY
							Picks.[DC],
							CASE WHEN (
								Picks.DC = 99
								AND Picks.ZoneArea IN (
									'Cage', 'Vault', 'Refer', 'Frozen'
								)
							) THEN 'NLC/BLC' ELSE Picks.dcName END,
							Picks.[PlantID],
							Picks.[PlannedWaveDate],
							Picks.[ZoneArea],
							CASE WHEN zonemaster.MezzLevelZone = 'Y' THEN 'Mezz' WHEN zonemaster.MezzLevelZone = 'N' THEN 'Main' ELSE 'Main' END,
							CASE WHEN Picks.ZoneArea IN (
								'Cage', 'Vault', 'Refer', 'Frozen'
							) THEN 'All' WHEN Picks.DCName = 'BLC' THEN 'All' WHEN zonemaster.MezzLevelZone = 'Y' THEN 'All' ELSE (
								CASE WHEN Picks.LocationClass = 'A' THEN 'Active' WHEN Picks.LocationClass = 'R' THEN 'Reserve' WHEN Picks.LocationClass = 'C' THEN 'InnerPack' ELSE Picks.LocationClass END
							) END,
							DATEADD(
								mi,
								DATEDIFF(mi, 0, Picks.[PickTime])/ 60*60,
								0
							) --ORDER BY Picks.Zone, PickHour
							) AS maxpick
			) AS trend
		GROUP BY
			trend.DC,
			trend.DCName,
			trend.ZoneArea,
			trend.MezzLevelZone,
			trend.LocationClass,
			datename(MONTH, trend.PlannedWaveDate) + ' ' + CAST(
				DATEPART(YEAR, trend.PlannedWaveDate) AS VARCHAR
			)
	) AS headcount ON calc.DC = headcount.DC
	AND calc.dcName = headcount.dcName
	AND calc.MezzLevelZone = headcount.MezzLevelZone
	AND calc.MonthYear = headcount.MonthYear
	AND calc.ZoneArea = headcount.ZoneArea;