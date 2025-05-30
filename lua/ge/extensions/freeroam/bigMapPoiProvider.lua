-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.dependencies = {'gameplay_missions_missions','freeroam_bigMapMode', 'gameplay_rawPois'}


local sendToMinimap = true
local function forceSend() sendToMinimap = true end
M.onClientStartMission = forceSend
M.requestMissionLocationsForMinimap = forceSend

local function sendMissionLocationsToMinimap()
  --[[
  local send = true
  if not gameplay_markerInteraction.isStateFreeroam() or gameplay_missions_missionManager.getForegroundMissionId() then
    send = false
  end
  if send then
    local data = {
      key = 'missions',
      items = {}
    }
    local level = getCurrentLevelIdentifier()
    local i = 1
    for _, cluster in ipairs(gameplay_rawPois.getAllClusters({mergeRadius = 20, levelIdentifier = level})) do
      if cluster.hasType['mission'] then
        data.items[i] = cluster.pos.x
        data.items[i+1] = cluster.pos.y
        data.items[i+2] = cluster.containedIds
        data.items[i+3] = gameplay_rawPois.getIconNamesForCluster(cluster)
        i = i+4
      end
    end
    guihooks.trigger("NavigationStaticMarkers", data)
  else
    M.clearMissionsFromMinimap()
  end
  ]]
  sendToMinimap = false
end

M.sendMissionLocationsToMinimap = sendMissionLocationsToMinimap
M.clearMissionsFromMinimap = function()
  if getCurrentLevelIdentifier() then
    guihooks.trigger("NavigationStaticMarkers", {key = 'missions', items = {}})
  end
end

M.formatPoiForBigmap = function(poi)
  local bmi = poi.markerInfo.bigmapMarker
  local qtEnabled = (not career_career.isActive()) or (career_modules_linearTutorial.getTutorialFlag('quickTravelEnabled'))
  return {
    id = poi.id,
    --idInCluster = poi.idInCluster,
    name = bmi.name,
    description = bmi.description,
    thumbnailFile = bmi.thumbnail,
    previewFiles = bmi.previews,
    type = poi.data.type,
    label = '',
    quickTravelAvailable = bmi.quickTravelPosRotFunction and qtEnabled or false,
    quickTravelUnlocked = bmi.quickTravelPosRotFunction and qtEnabled or false,
    canSetRoute = bmi.pos,
  }
end

M.formatMissionForBigmap = function(elemData)
  local mission = gameplay_missions_missions.getMissionById(elemData.missionId)
  local qtEnabled = (not career_career.isActive()) or (career_modules_linearTutorial.getTutorialFlag('quickTravelEnabled'))
  if mission then
    local ret = {
      id = elemData.missionId,
      --clusterId = elemData.clusterId,
      idInCluster = elemData.idInCluster,
      name = mission.name,
      label = mission.missionTypeLabel or mission.missionType,
      description = mission.description,
      thumbnailFile = mission.thumbnailFile,
      previewFiles = {mission.previewFile},
      type = "mission",
      difficulty = mission.additionalAttributes.difficulty,
      bigmapCycleProgressKeys = mission.bigmapCycleProgressKeys,
      unlocks = mission.unlocks,
      quickTravelAvailable = qtEnabled and true,
      quickTravelUnlocked = qtEnabled and gameplay_missions_progress.missionHasQuickTravelUnlocked(elemData.missionId),
      branchTagsSorted = tableKeysSorted(mission.unlocks.branchTags),
      -- these two will show below the mission and will be a context translation.
      aggregatePrimary = {
        --label = {txt = 'Test', context = {}},
        --value = {txt = 'general.onlyValue', context = {value = '99m'}}
      },
      aggregateSecondary = {
        --label = {txt = 'ui.apps.gears.name', context = {}},
        --value = {txt = 'general.onlyValue', context = {value = '12345'}}
      },
      devMission = mission.devMission or false,

      --[[ rating can have different types: attempts, done, new, stars, with context data.
      rating = {type = 'attempts', attempts = 12345}, -- show attempts: 12345 in this case
      --rating = {type = 'stars', stars = 2}, -- show stars: 2 in this case
      --rating = {type = 'done'}, -- show done
      --rating = {type = 'new'}, -- show new
      ]]
      canSetRoute = true,
    }
    ret.formattedProgress =  gameplay_missions_progress.formatSaveDataForUi(elemData.missionId)
    ret.leaderboardKey = mission.defaultLeaderboardKey or 'recent'


    for key, val in pairs(gameplay_missions_progress.formatSaveDataForBigmap(mission.id) or {}) do
      ret[key] = val
    end
    return ret
  end
  return nil
end

local function getBranchIcons()
  local icons = {money = 'beamCurrency', beamXP = 'beamXP', vouchers = 'voucherHorizontal3'}
  for _, branch in ipairs(career_branches.getSortedBranches()) do
    icons[branch.id] = branch.icon
  end
  return icons
end

local noBranch = "branch_noBranch"
M.sendCurrentLevelMissionsToBigmap = function()
  local data = {poiData = {}, levelData = {}, branchIcons = getBranchIcons()}
  local level = getCurrentLevelIdentifier()
  local missionData = {}
  local playerPos = core_camera.getPosition()
  local distanceFilter = {
    {25,'close'},
    {100,'medium'},
    {250,'far'},
    {1000,'veryFar'}
  }
  local difficultyValues = {veryLow=0, low=1, medium=2, high=3, veryHigh=4}
  local groupData = {
    rating_new = {label = "Rating: New"},
    rating_locked = {label = "Rating: Locked"},
    rating_attempts = {label = "Rating: Attempted"},
    rating_done = {label = "Rating: Done"},
    type_mission = {label = "Mission"},
    type_driftSpots = {label = "Drift Spots"},
    type_dragstrip = {label = "Dragstrips"},
    type_spawnPoint = {label = "Quicktravel Points"},
    type_garage = {label = "Garages"},
    type_gasStation = {label = "Gas Stations"},
    type_dealership = {label = "Dealerships"},
    type_playerVehicle = {label = "Player Vehicles"},
    type_events = {label = "Free-Roam Events"}, -- Create a type for sections
    type_travel = {label = "Travel Points"},
    type_assignRole = {label = "Role Assignment"},
    type_other = {label = "Other"},

    delivery_facility = {label = "Logistics: Delivery Facility"},
    delivery_dropoff = {label = "Logistics: Delivery Dropoff"},

    distance_veryClose = {label = "Distance: Very Close"},
    distance_close = {label = "Distance: Close"},
    distance_medium = {label = "Distance: Medium"},
    distance_far = {label = "Distance: Far"},
    distance_veryFar = {label = "Distance: Very Far"},
  }

  for _, branch in ipairs(career_branches.getSortedBranches()) do
    if branch and not branch.isDomain then
      local domain = career_branches.getBranchById(branch.parentDomain)
      groupData["branch_"..branch.id] = {label = {txt = "ui.career.domainSlashBranch", context={domain=domain.name, branch=branch.name}}}
    end
  end
  groupData[noBranch] = {label = "Branchless Missions"}

  for _, diff in pairs(gameplay_missions_missions.getAdditionalAttributes().difficulty.valuesByKey) do
    groupData["difficulty_"..diff.key] = {label = "Difficulty: " ..diff.translationKey}
  end
  for _, v in pairs(gameplay_missions_missions.getAdditionalAttributes().vehicle.valuesByKey) do
    groupData["vehicleUsed_"..v.key] = {label = "Vehicle Used: " .. v.translationKey}
  end
  for _, gr in pairs(groupData) do
    gr.elements = {}
  end


  gameplay_rawPois.clear()
  for _, poi in ipairs(gameplay_rawPois.getRawPoiListByLevel(level)) do
    if poi.markerInfo.bigmapMarker then
      local filterData = {
        groupTags = {},
        sortingValues = {}
      }
          -- distance
      filterData.sortingValues['distance'] = 10--math.max(0,(poi.pos - playerPos):length() - (poi.radius or 0))
      local distLabel = 'veryClose'
      for _, filter in ipairs(distanceFilter) do
        if filterData.sortingValues['distance'] >= filter[1] then
          distLabel = filter[2]
        end
      end
      filterData.groupTags['distance_'..distLabel] = true
      filterData.sortingValues['id'] = poi.id

      if poi.data.type == 'mission' then
        local formatted = M.formatMissionForBigmap(poi.data)
        data.poiData[poi.id] = formatted
        filterData.groupTags['type_mission'] = true

        local mission = gameplay_missions_missions.getMissionById(poi.data.missionId)
        -- general data
        filterData.groupTags['missionType_'..mission.missionTypeLabel] = true
        if not groupData['missionType_'..mission.missionTypeLabel] then
          groupData['missionType_'..mission.missionTypeLabel] = {label = mission.missionTypeLabel, elements = {}}
        end
        if mission.additionalAttributes.difficulty then
          filterData.groupTags['difficulty_'..mission.additionalAttributes.difficulty] = true
          filterData.sortingValues['difficulty'] = difficultyValues[mission.additionalAttributes.difficulty]
        end
        if mission.additionalAttributes.vehicle then
          filterData.groupTags['vehicleUsed_'..mission.additionalAttributes.vehicle] = true
        end
        filterData.sortingValues['depth'] = mission.unlocks.depth

        -- branch data
        --for branchKey, _ in pairs(mission.unlocks.branchTags) do
        --  filterData.groupTags['branch_'..branchKey] = true
        --end
        --if not next(mission.unlocks.branchTags) then
        --  filterData.groupTags[noBranch] = true
        --end

        if career_career.isActive() and mission.careerSetup.skill then
          local skill = career_branches.getBranchById(mission.careerSetup.skill)
          if skill then
            filterData.groupTags['branch_'..skill.id] = true
          end
        end

        filterData.sortingValues['maxBranchTier'] = mission.unlocks.maxBranchlevel
        filterData.groupTags['maxBranchTier_'..mission.unlocks.maxBranchlevel] = true
        groupData['maxBranchTier_'..mission.unlocks.maxBranchlevel] = {label = 'Tier ' .. mission.unlocks.maxBranchlevel, elements = {}}

        -- custom groups/tags
        if mission.grouping.id ~= "" then
          local gId = 'missionGroup_'..mission.grouping.id
          if not groupData[gId] then groupData[gId] = {elements = {}} end
          if mission.grouping.label ~= "" and groupData[gId].label == nil then
            groupData[gId].label = mission.grouping.label
          end
          filterData.groupTags[gId] = true
        end

        -- progress
        if formatted.rating then
          filterData.groupTags['rating_'..formatted.rating.type] = true
        end
        filterData.sortingValues['starCount'] = formatted.rating.totalStars
        filterData.sortingValues['defaultUnlockedStarCount'] = formatted.rating.defaultUnlockedStarCount
        filterData.sortingValues['totalUnlockedStarCount'] = formatted.rating.totalUnlockedStarCount

      elseif poi.data.type == 'spawnPoint' then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_spawnPoint'] = true
      elseif poi.data.type == 'computer' then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_garage'] = true
      elseif poi.data.type == 'gasStation' then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_gasStation'] = true
      elseif poi.data.type == 'dealership' then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_dealership'] = true
      elseif poi.data.type == "events" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_events'] = true
      elseif poi.data.type == "travel" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_travel'] = true
      elseif poi.data.type == "logisticsParking" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['delivery_dropoff'] = true
      elseif poi.data.type == "assignRole" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_assignRole'] = true
      elseif poi.data.type == 'logisticsOffice' then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['delivery_facility'] = true
      elseif poi.data.type == "driftSpot" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_driftSpots'] = true
      elseif poi.data.type == "dragstrip" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_dragstrip'] = true
      elseif poi.data.type == "playerVehicle" then
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_playerVehicle'] = true
      else -- other
        data.poiData[poi.id] = M.formatPoiForBigmap(poi)
        filterData.groupTags['type_other'] = true
      end

      data.poiData[poi.id].filterData = filterData

      for tag, act in pairs(filterData.groupTags) do
        if act then
          if not groupData[tag] then
            log("W","","Unknown group tag: " .. dumps(tag) .. " for poi " .. dumps(poi.id))
            groupData[tag] = {label = tag, elements = {}}
          end
          table.insert(groupData[tag].elements, poi.id)
        end
      end
    end
  end

  for key, gr in pairs(groupData) do
    local elementsAsPois = {}
    for i, id in ipairs(gr.elements) do elementsAsPois[i] = data.poiData[id] end
    table.sort(elementsAsPois,gameplay_missions_unlocks.depthIdSort)
    for i, poi in ipairs(elementsAsPois) do gr.elements[i] = elementsAsPois[i].id end
  end



  -- build premade filters
  local filterFreeroamPois = {
    key = 'freeroamPois',
    icon = 'mapPoint',
    groups = {
      groupData['type_spawnPoint'],
      groupData['type_gasStation'],
      groupData['type_driftSpots'],
      groupData['type_dragstrip'],
      groupData['type_other'],
    }
  }
  local filterCareerPois = {
    key = 'careerPois',
    icon = 'mapPoint',
    groups = {
      groupData['type_playerVehicle'],
      groupData['type_dealership'],
      groupData['type_garage'],
      groupData['type_gasStation'],
      groupData['type_dragstrip'],
      groupData['type_events'], -- Added types here for sections
      groupData['type_travel'],
      groupData['type_assignRole'],
      groupData['type_other'],
    }
  }
  local filterMissionsByType = {
    key = 'missionsByType',
    icon = 'flag',
    groups = {},
  }
  for _, groupKey in ipairs(tableKeysSorted(groupData)) do
    if string.startswith(groupKey,'missionType_') then
      table.insert(filterMissionsByType.groups, groupData[groupKey])
    end
  end


  local branchOrdered = career_branches.orderBranchNamesKeysByBranchOrder()
  local domainFilters = {}
  for _, domainId in ipairs(branchOrdered) do
    local domain = career_branches.getBranchById(domainId)
    if domain.isDomain then
      local hasContent = false
      local filter = {
        key = 'domain_'..domainId,
        icon = domain.icon,
        groups = {}
      }
      if domain.id == "logistics" then
        table.insert(filter.groups, groupData['delivery_dropoff'])
        table.insert(filter.groups, groupData['delivery_facility'])
        hasContent = true
      end

      if domain.id == "apm" then
        data.poiData["apmChallengeInfo"] = {
          id = "apmChallengeInfo",
          type = "apmChallengeInfo",
          name = "APM Challenges",
          description = "APM Challenges and progress can be found in the Career Paths Menu.",
          thumbnailFile = domain.thumbnail,
          previewFiles = {domain.progressCover},
        }
        table.insert(filter.groups, {
          label = "APM Challenges",
          elements = { "apmChallengeInfo" }
        })
        hasContent = true
      end

      for _, branchId in ipairs(branchOrdered) do
        local branch = career_branches.getBranchById(branchId)
        if branch.parentDomain == domainId then
          if groupData['branch_'..branchId] and next(groupData['branch_'..branchId].elements) then
            table.insert(filter.groups, groupData['branch_'..branchId])
            hasContent = true
          end
          if branch.id == "bmra-drift" then
            table.insert(filter.groups, groupData['type_driftSpots'])
            hasContent = true
          end
        end
      end
      if hasContent then
        table.insert(domainFilters, filter)
      end
    end
  end

  local filterDelivery = {
    key = 'delivery',
    icon = 'boxTruckFast',
    groups = {
      groupData['delivery_dropoff']
    }
  }

  for _, lvl in ipairs(core_levels.getList()) do
    if string.lower(lvl.levelName) == getCurrentLevelIdentifier() then
      data.levelData = lvl
    end
  end
  data.gameMode = "freeroam"
  if career_career and career_career.isActive() then
    data.gameMode = "career"
  end
  if gameplay_missions_missionManager.getForegroundMissionId() then
    data.gameMode = "mission"
  end



  local allGroupsFilter = {
    key = 'allGroupsTest',
    icon = 'star',
    groups = {}
  }
  for _, grKey in ipairs(tableKeysSorted(groupData)) do
    table.insert(allGroupsFilter.groups, groupData[grKey])
  end
  if career_career and career_career.isActive() then

    data.rules = {
      canSetRoute = not career_modules_testDrive.isActive()
    }

    data.filterData = {filterCareerPois}

    for _, filter in ipairs(domainFilters) do table.insert(data.filterData, filter) end
    --table.insert(data.filterData, allGroupsFilter)

    if career_modules_delivery_general.isDeliveryModeActive() then
      data.selectedFilterKey = "delivery"
      table.insert(data.filterData, filterDelivery)
    end
  else
    data.filterData = {filterMissionsByType, filterFreeroamPois}

    data.rules = {
      canSetRoute = true
    }
  end

  guihooks.trigger("BigmapMissionData", data)
end


-- gets called only while career mode is enabled
local function onPreRender(dtReal, dtSim)
  if not gameplay_markerInteraction.isStateFreeroam() then
    return
  end
  -- check if we've switched level
  local level = getCurrentLevelIdentifier()
  if level then
    if sendToMinimap then
      M.sendMissionLocationsToMinimap()
    end
  end
end

M.onPreRender = onPreRender
M.forceSend = forceSend
return M