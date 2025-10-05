














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AIJobVehicle.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIVehicle, specializations)
       and SpecializationUtil.hasSpecialization(Drivable, specializations)
end


---
function AIJobVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIJobVehicle")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.steeringNode#node", "Steering node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.reverserNode#node", "Reverser node")
    schema:register(XMLValueType.FLOAT, "vehicle.ai.steeringSpeed", "Speed of steering" , 1)
    schema:register(XMLValueType.BOOL, "vehicle.ai#supportsAIJobs", "If true vehicle supports ai jobs", true)
    schema:register(XMLValueType.STRING_LIST, "vehicle.ai#supportedJobTypes", "List of job names that are supported (AIJobConveyor, AIJobDeliver, AIJobGoTo, AIJobLoadAndDeliver, AIJobFieldWork)", "all jobs if no names are given")
    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStartAllowed", "If ai start is allowed", true)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiJobVehicle#isAIStopAllowed", "If ai stop is allowed", true)
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).aiJobVehicle.lastJob#type", "Last job name", nil)
end



---
function AIJobVehicle.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIJobStarted")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobFinished")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleBlock")
    SpecializationUtil.registerEvent(vehicleType, "onAIJobVehicleContinue")
end

---
function AIJobVehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getShowAIToggleActionEvent", AIJobVehicle.getShowAIToggleActionEvent)
    SpecializationUtil.registerFunction(vehicleType, "stopCurrentAIJob",           AIJobVehicle.stopCurrentAIJob)
    SpecializationUtil.registerFunction(vehicleType, "skipCurrentTask",            AIJobVehicle.skipCurrentTask)
    SpecializationUtil.registerFunction(vehicleType, "aiJobStarted",               AIJobVehicle.aiJobStarted)
    SpecializationUtil.registerFunction(vehicleType, "aiJobFinished",              AIJobVehicle.aiJobFinished)
    SpecializationUtil.registerFunction(vehicleType, "toggleAIVehicle",            AIJobVehicle.toggleAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleAIVehicle",      AIJobVehicle.getCanToggleAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanStartAIVehicle",       AIJobVehicle.getCanStartAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanStopAIVehicle",        AIJobVehicle.getCanStopAIVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIJobSupported",        AIJobVehicle.getIsAIJobSupported)
    SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotBlinking",    AIJobVehicle.setAIMapHotspotBlinking)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentHelper",           AIJobVehicle.getCurrentHelper)
    SpecializationUtil.registerFunction(vehicleType, "aiBlock",                    AIJobVehicle.aiBlock)
    SpecializationUtil.registerFunction(vehicleType, "aiContinue",                 AIJobVehicle.aiContinue)
    SpecializationUtil.registerFunction(vehicleType, "getAIDirectionNode",         AIJobVehicle.getAIDirectionNode)
    SpecializationUtil.registerFunction(vehicleType, "getAISteeringNode",          AIJobVehicle.getAISteeringNode)
    SpecializationUtil.registerFunction(vehicleType, "getAIReverserNode",          AIJobVehicle.getAIReverserNode)
    SpecializationUtil.registerFunction(vehicleType, "getAISteeringSpeed",         AIJobVehicle.getAISteeringSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getAIJobFarmId",             AIJobVehicle.getAIJobFarmId)
    SpecializationUtil.registerFunction(vehicleType, "getStartableAIJob",          AIJobVehicle.getStartableAIJob)
    SpecializationUtil.registerFunction(vehicleType, "getHasStartableAIJob",       AIJobVehicle.getHasStartableAIJob)
    SpecializationUtil.registerFunction(vehicleType, "getStartAIJobText",          AIJobVehicle.getStartAIJobText)
    SpecializationUtil.registerFunction(vehicleType, "getJob",                     AIJobVehicle.getJob)
    SpecializationUtil.registerFunction(vehicleType, "getLastJob",                 AIJobVehicle.getLastJob)
    SpecializationUtil.registerFunction(vehicleType, "setIsAIStartAllowed",        AIJobVehicle.setIsAIStartAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setIsAIStopAllowed",         AIJobVehicle.setIsAIStopAllowed)
end


---
function AIJobVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer",    AIJobVehicle.getIsVehicleControlledByPlayer)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive",                       AIJobVehicle.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive",                     AIJobVehicle.getIsAIActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks",                AIJobVehicle.getAllowTireTracks)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave",              AIJobVehicle.getDeactivateOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave",               AIJobVehicle.getStopMotorOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDisableVehicleCharacterOnLeave", AIJobVehicle.getDisableVehicleCharacterOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName",                       AIJobVehicle.getFullName)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm",                     AIJobVehicle.getActiveFarm)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible",            AIJobVehicle.getIsMapHotspotVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspot",                     AIJobVehicle.getMapHotspot)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave",        AIJobVehicle.getDeactivateLightsOnLeave)
end


---
function AIJobVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIJobVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIJobVehicle)
end


---Called on loading
-- @param table savegame savegame
function AIJobVehicle:onLoad(savegame)
    local spec = self.spec_aiJobVehicle

    spec.actionEvents = {}
    spec.job = nil
    spec.lastJob = nil
    spec.startedFarmId = nil

    spec.aiSteeringSpeed = self.xmlFile:getValue("vehicle.ai.steeringSpeed", 1) * 0.001
    spec.steeringNode = self.xmlFile:getValue("vehicle.ai.steeringNode#node", nil, self.components, self.i3dMappings)
    spec.reverserNode = self.xmlFile:getValue("vehicle.ai.reverserNode#node", nil, self.components, self.i3dMappings)
    spec.supportsAIJobs = self.xmlFile:getValue("vehicle.ai#supportsAIJobs", true)
    spec.supportedJobTypes = self.xmlFile:getValue("vehicle.ai#supportedJobTypes", nil)
    spec.isAIStartAllowed = true
    spec.isAIStopAllowed = true

    spec.texts = {}
    spec.texts.dismissEmployee = g_i18n:getText("action_dismissEmployee")
    spec.texts.openHelperMenu = g_i18n:getText("action_openHelperMenu")
    spec.texts.hireEmployee = g_i18n:getText("action_hireEmployee")

    if savegame ~= nil then
        local aiJobTypeManager = g_currentMission.aiJobTypeManager
        local savegameKey = savegame.key .. ".aiJobVehicle"
        local jobKey = savegameKey .. ".lastJob"
        local jobTypeName = savegame.xmlFile:getString(jobKey .. "#type")

        local jobTypeIndex = aiJobTypeManager:getJobTypeIndexByName(jobTypeName)
        if jobTypeIndex ~= nil then
            local job = aiJobTypeManager:createJob(jobTypeIndex)
            if job ~= nil and job.loadFromXMLFile ~= nil then
                job:loadFromXMLFile(savegame.xmlFile, jobKey)
                spec.lastJob = job
            end
        end

        spec.isAIStartAllowed = savegame.xmlFile:getValue(savegameKey .. "#isAIStartAllowed", spec.isAIStartAllowed)
        spec.isAIStopAllowed = savegame.xmlFile:getValue(savegameKey .. "#isAIStopAllowed", spec.isAIStopAllowed)
    end
end















---Called on client side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function AIJobVehicle:onReadStream(streamId, connection)

    -- we only need to sync lastjob if no active job is running

    local hasJob = streamReadBool(streamId)
    if hasJob then
        local jobId = streamReadInt32(streamId)
        local startedFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        local helperIndex = streamReadUInt8(streamId)
        local job = g_currentMission.aiSystem:getJobById(jobId)

        self:aiJobStarted(job, helperIndex, startedFarmId)
    end

    local hasLastJob = streamReadBool(streamId)
    if hasLastJob then
        local jobTypeIndex = streamReadInt32(streamId)
        local spec = self.spec_aiJobVehicle
        spec.lastJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
        spec.lastJob:readStream(streamId, connection)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function AIJobVehicle:onWriteStream(streamId, connection)
    local spec = self.spec_aiJobVehicle

    -- we only need to sync lastjob if no active job is running
    if streamWriteBool(streamId, spec.job ~= nil) then
        streamWriteInt32(streamId, spec.job.jobId)
        streamWriteUIntN(streamId, spec.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteUInt8(streamId, spec.currentHelper.index)
    end

    if streamWriteBool(streamId, spec.lastJob ~= nil) then
        local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(spec.lastJob)
        streamWriteInt32(streamId, jobTypeIndex)
        spec.lastJob:writeStream(streamId, connection)
    end
end


---
function AIJobVehicle:onAIModeChanged(aiMode)
    if aiMode ~= AIModeSelection.MODE.WORKER then
        local spec = self.spec_aiJobVehicle
        if spec.job ~= nil then
            self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        end
    end
end








---Returns true if ai action event should be displayed
-- @return boolean active active
function AIJobVehicle:getShowAIToggleActionEvent()
    if self:getAIDirectionNode() == nil then
        return false
    end

    if g_currentMission.disableAIVehicle then
        return false
    end

    if not g_currentMission:getHasPlayerPermission("hireAssistant") then
        return false
    end

    if not self:getIsAIActive() and g_currentMission.aiSystem:getAILimitedReached() then
        return false
    end

--     if g_guidedTourManager:getIsTourRunning() then
--         if not g_currentMission.guidedTour:getCanStartAI(self) then
--             return false
--         end
--     end

    return true
end















































































































---
function AIJobVehicle:getIsInUse(superFunc, connection)
    if self:getIsAIActive() then
        return true
    end

    return superFunc(self, connection)
end


---
function AIJobVehicle:getIsActive(superFunc)
    if self:getIsAIActive() then
        return true
    end

    return superFunc(self)
end






---
function AIJobVehicle:getIsAIActive(superFunc)
    return superFunc(self) or self.spec_aiJobVehicle.job ~= nil
end





























---
function AIJobVehicle:toggleAIVehicle()
    if self:getIsAIActive() then
        self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    else
        local startableJob = self:getStartableAIJob()
        if startableJob ~= nil then
            g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(startableJob, self:getOwnerFarmId()))
            return
        end

        -- do not open menu while tour is running
        if g_guidedTourManager:getIsTourRunning() then
            return
        end

        if Platform.isMobile then
            g_gui:changeScreen(nil, InGameMenu)
            g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)

            --we look for the hotspot corresponding to the vehicle the player is in, and select it on the map
            local inGameMap = g_currentMission.hud:getIngameMap()
            inGameMap:updateHotspotSorting()
            local playerHotspot = g_inGameMenu.pageMapMobile.inGameMap:getPlayerHotspot(inGameMap.hotspotsSorted[true])

            g_inGameMenu.pageMapMobile:onClickHotspot(nil, playerHotspot)
            g_inGameMenu.pageMapMobile:onClickPagingAI()

            return
        else
            g_gui:showGui("InGameMenu")
        end

        g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
    end
end


---Returns if ai can be toggled
-- @return boolean canBeToggled can be toggled
function AIJobVehicle:getCanToggleAIVehicle()
    if self:getIsAIActive() then
        return self:getCanStopAIVehicle()
    end

    return self:getCanStartAIVehicle()
end











---Returns true if ai can start
-- @return boolean canStart can start ai
function AIJobVehicle:getCanStartAIVehicle()
    if g_currentMission.disableAIVehicle then
        return false
    end

    if self:getOwnerFarmId() == AccessHandler.EVERYONE then
        return false
    end

    local spec = self.spec_aiJobVehicle
    if not spec.supportsAIJobs then
        return false
    end

    if not spec.isAIStartAllowed then
        return false
    end

    if self:getAIDirectionNode() == nil then
        return false
    end

    if g_currentMission.aiSystem:getAILimitedReached() then
        return false
    end

    if self:getIsAIActive() then
        return false
    end

    if self.isBroken then
        return false
    end

    return true
end


---Returns true if the given AI job is supported
-- @return boolean canStart can start ai
function AIJobVehicle:getIsAIJobSupported(aiJobName)
    local spec = self.spec_aiJobVehicle
    if spec.supportedJobTypes == nil then
        return true
    end

    for _, supportedJobName in ipairs(spec.supportedJobTypes) do
        if string.lower(supportedJobName) == string.lower(aiJobName) then
            return true
        end
    end

    return false
end


























---Returns if vehicle deactivates lights on leave
-- @return boolean deactivate vehicle deactivates on leave
function AIJobVehicle:getDeactivateLightsOnLeave(superFunc)
    return superFunc(self) and not self:getIsAIActive()
end
