













---
function PowerConsumer.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("powerConsumer", g_i18n:getText("configuration_powerConsumer"), "powerConsumer", VehicleConfigurationItem)

    g_storeManager:addSpecType("neededPower", "shopListAttributeIconPowerReq", PowerConsumer.loadSpecValueNeededPower, PowerConsumer.getSpecValueNeededPower, StoreSpecies.VEHICLE)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PowerConsumer")

    PowerConsumer.registerPowerConsumerXMLPaths(schema, "vehicle.powerConsumer")
    PowerConsumer.registerPowerConsumerXMLPaths(schema, "vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(?)")

    schema:register(XMLValueType.INT, "vehicle.storeData.specs.neededPower", "Needed power")
    schema:register(XMLValueType.INT, "vehicle.storeData.specs.neededPower#maxPower", "Max. recommended power")
    schema:register(XMLValueType.INT, "vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(?)#neededPower", "Needed power")

    schema:addDelayedRegistrationFunc("WorkMode:workMode", function(cSchema, cKey)
        cSchema:register(XMLValueType.FLOAT, cKey .. "#forceScale", "Scale the powerConsumer force up or down", 1)
        cSchema:register(XMLValueType.FLOAT, cKey .. "#ptoPowerScale", "Scale the powerConsumer pto power up or down", 1)
    end)

    schema:setXMLSpecializationType()
end


---
function PowerConsumer.registerPowerConsumerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#forceNode", "Force node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#forceDirNode", "Force node", "Force node")
    schema:register(XMLValueType.FLOAT, basePath .. "#forceFactor", "Force factor", 1)

    schema:register(XMLValueType.FLOAT, basePath .. "#maxForce", "Max. force (kN)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#forceDir", "Force direction", 1)

    schema:register(XMLValueType.BOOL, basePath .. "#useTurnOnState", "While vehicle is turned on the vehicle consumes the pto power", true)

    schema:register(XMLValueType.FLOAT, basePath .. "#turnOnPeakPowerMultiplier", "While turning the tool on a short peak power with this multiplier is consumed", 3)
    schema:register(XMLValueType.TIME, basePath .. "#turnOnPeakPowerDuration", "Duration for peak power while turning on (sec)", 2)

    schema:register(XMLValueType.L10N_STRING, basePath .. "#turnOnNotAllowedWarning", "Turn on not allowed text", "warning_insufficientPowerOutput")

    schema:register(XMLValueType.FLOAT, basePath .. "#neededMaxPtoPower", "Needed max. pto power", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#neededMinPtoPower", "Needed min. pto power", "neededMaxPtoPower")
    schema:register(XMLValueType.FLOAT, basePath .. "#ptoRpm", "Pto rpm", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#virtualPowerMultiplicator", "Virtual multiplicator for pto power to increased the motor load without reducing the available power for driving", 1)

    schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#offset", "Speed limit offset to apply")
    schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#minPowerHp", "Min. power in HP of root motor", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#maxPowerHp", "Max. power in HP of root motor", 0)
end



---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PowerConsumer.prerequisitesPresent(specializations)
    return true
end


---
function PowerConsumer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadPowerSetup", PowerConsumer.loadPowerSetup)
    SpecializationUtil.registerFunction(vehicleType, "getPtoRpm", PowerConsumer.getPtoRpm)
    SpecializationUtil.registerFunction(vehicleType, "getDoConsumePtoPower", PowerConsumer.getDoConsumePtoPower)
    SpecializationUtil.registerFunction(vehicleType, "getPowerMultiplier", PowerConsumer.getPowerMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "getConsumedPtoTorque", PowerConsumer.getConsumedPtoTorque)
    SpecializationUtil.registerFunction(vehicleType, "getConsumingLoad", PowerConsumer.getConsumingLoad)
end


---
function PowerConsumer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", PowerConsumer.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOnAll", PowerConsumer.getCanBeTurnedOnAll)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", PowerConsumer.getTurnedOnNotAllowedWarning)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRawSpeedLimit", PowerConsumer.getRawSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkModeFromXML", PowerConsumer.loadWorkModeFromXML)
end


---
function PowerConsumer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerConsumer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PowerConsumer)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", PowerConsumer)
    SpecializationUtil.registerEventListener(vehicleType, "onWorkModeChanged", PowerConsumer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", PowerConsumer)
end


---Called on loading
-- @param table savegame savegame
function PowerConsumer:onLoad(savegame)
    local spec = self.spec_powerConsumer

    local foldingConfigurationId = Utils.getNoNil(self.configurations["powerConsumer"], 1)
    local configKey = string.format("vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(%d)", foldingConfigurationId - 1)

    if not self.xmlFile:hasProperty(configKey) then
        configKey = "vehicle.powerConsumer"
    end

    spec.forceNode = self.xmlFile:getValue(configKey .. "#forceNode", nil, self.components, self.i3dMappings)
    spec.forceDirNode = self.xmlFile:getValue(configKey .. "#forceDirNode", spec.forceNode, self.components, self.i3dMappings)
    spec.forceFactor = self.xmlFile:getValue(configKey .. "#forceFactor", 1.0)

    spec.maxForce = self.xmlFile:getValue(configKey .. "#maxForce", 0) -- kN
    spec.forceDir = self.xmlFile:getValue(configKey .. "#forceDir", 1)

    spec.useTurnOnState = self.xmlFile:getValue(configKey .. "#useTurnOnState", true)

    spec.turnOnNotAllowedWarning = string.format(self.xmlFile:getValue(configKey .. "#turnOnNotAllowedWarning", "warning_insufficientPowerOutput", self.customEnvironment), self.typeDesc)

    self:loadPowerSetup(self.xmlFile, configKey)

    spec.speedLimitModifier = {}
    spec.sourceMotorPeakPower = math.huge

    spec.turnOnPeakPowerMultiplier = self.xmlFile:getValue(configKey .. "#turnOnPeakPowerMultiplier", 3)
    spec.turnOnPeakPowerDuration = self.xmlFile:getValue(configKey .. "#turnOnPeakPowerDuration", 2.5)
    spec.turnOnPeakPowerTimer = -1

    self.xmlFile:iterate(configKey .. ".speedLimitModifier", function(index, key)
        local entry = {}
        entry.offset = self.xmlFile:getValue(key .. "#offset")

        if entry.offset ~= nil then
            entry.minPowerKw = self.xmlFile:getValue(key .. "#minPowerHp", 0) * 0.735499
            entry.maxPowerKw = self.xmlFile:getValue(key .. "#maxPowerHp", 0) * 0.735499
            table.insert(spec.speedLimitModifier, entry)
        else
            Logging.xmlWarning(self.xmlFile, "Invalid offset found for '%s'", key)
        end
    end)

    if #spec.speedLimitModifier == 0 then
        SpecializationUtil.removeEventListener(self, "onPostDetach", PowerConsumer)
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function PowerConsumer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isActive then
        local spec = self.spec_powerConsumer

        if spec.forceNode ~= nil and self.movingDirection == spec.forceDir and self.lastSpeedReal > 0.0001 then
            local multiplier = self:getPowerMultiplier()
            if multiplier ~= 0 then
                local frictionForce = spec.forceFactor * self.lastSpeedReal * 1000 * self:getTotalMass(false) / (dt/1000)

                local force = -math.min(frictionForce, spec.maxForce) * self.movingDirection * multiplier
                local dx,dy,dz = localDirectionToWorld(spec.forceDirNode, 0, 0, force)
                local px,py,pz = getCenterOfMass(spec.forceNode)

                addForce(spec.forceNode, dx,dy,dz, px,py,pz, true)

                if (VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS or VehicleDebug.state == VehicleDebug.DEBUG_TUNING) and self.isActiveForInputIgnoreSelectionIgnoreAI then
                    local str = string.format("frictionForce=%.2f maxForce=%.2f -> force=%.2f", frictionForce, spec.maxForce, force)
                    renderText(0.7, 0.85, getCorrectTextSize(0.02), str)
                end
            end
        end

        if spec.turnOnPeakPowerTimer > 0 then
            spec.turnOnPeakPowerTimer = spec.turnOnPeakPowerTimer - dt
        end
    end
end


---Called on loading
-- @param table savegame savegame
function PowerConsumer:loadPowerSetup(xmlFile, baseKey)
    local spec = self.spec_powerConsumer

    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#neededPtoPower", string.format("%s#neededMinPtoPower and %s#neededMaxPtoPower", baseKey, baseKey))

    spec.neededMaxPtoPower = xmlFile:getValue(baseKey .. "#neededMaxPtoPower", 0)
    spec.neededMinPtoPower = xmlFile:getValue(baseKey .. "#neededMinPtoPower", spec.neededMaxPtoPower) -- in kW at ptoRpm
    if spec.neededMaxPtoPower < spec.neededMinPtoPower then
        Logging.xmlWarning(self.xmlFile, "'%s#neededMaxPtoPower' is smaller than '%s#neededMinPtoPower'", baseKey, baseKey)
    end

    spec.ptoRpm = xmlFile:getValue(baseKey .. "#ptoRpm", 0)
    spec.virtualPowerMultiplicator = xmlFile:getValue(baseKey .. "#virtualPowerMultiplicator", 1)
end


---Returns rpm of pto
-- @return float rpm rpm of pto
function PowerConsumer:getPtoRpm()
    if self:getDoConsumePtoPower() then
        return self.spec_powerConsumer.ptoRpm
    end

    return 0
end


---Returns if should consume pto power
-- @return boolean consume consumePtoPower
function PowerConsumer:getDoConsumePtoPower()
    return self.spec_powerConsumer.useTurnOnState and self.getIsTurnedOn ~= nil and self:getIsTurnedOn()
end


---Returns power multiplier
-- @return float powerMultiplier current power multiplier
function PowerConsumer:getPowerMultiplier()
    return 1
end



---Returns consumed pto torque
-- @return float torque consumed pto torque in kNm
function PowerConsumer:getConsumedPtoTorque(expected, ignoreTurnOnPeak)
    if self:getDoConsumePtoPower() or (expected ~= nil and expected) then
        local spec = self.spec_powerConsumer

        local rpm = spec.ptoRpm
        if rpm > 0.001 then
            local consumingLoad, count = self:getConsumingLoad()
            if count > 0 then
                consumingLoad = consumingLoad / count
            else
                consumingLoad = 1
            end

            local turnOnPeakPowerMultiplier = math.max(math.max(math.min(spec.turnOnPeakPowerTimer / spec.turnOnPeakPowerDuration, 1), 0) * spec.turnOnPeakPowerMultiplier, 1)
            if ignoreTurnOnPeak == true then
                turnOnPeakPowerMultiplier = 1
            end

            local neededPtoPower = spec.neededMinPtoPower + (consumingLoad * (spec.neededMaxPtoPower - spec.neededMinPtoPower))
            return neededPtoPower / (rpm*math.pi/30), spec.virtualPowerMultiplicator * turnOnPeakPowerMultiplier
        end
    end

    return 0, 1
end


---
function PowerConsumer:getConsumingLoad()
    return 0, 0
end


---Returns if turn on is allowed
-- @return boolean allow allow turn on
function PowerConsumer:getCanBeTurnedOn(superFunc)
    local rootVehicle = self.rootVehicle
    if rootVehicle ~= nil and rootVehicle.getMotor ~= nil then
        local rootMotor = rootVehicle:getMotor()

        local torqueRequested, _ = self:getConsumedPtoTorque(true)
        local totalTorque, _ = PowerConsumer.getTotalConsumedPtoTorque(rootVehicle, self)
        torqueRequested = torqueRequested + totalTorque
        torqueRequested = torqueRequested / rootMotor:getPtoMotorRpmRatio()

        -- 90% of motor torque should be more than requested torque, because we need some torque to accelerate the vehicle
        if torqueRequested > 0 and torqueRequested > 0.9 * rootMotor:getPeakTorque() then
            if not self:getIsTurnedOn() then
                return false, true
            end
        end
    end

    if superFunc ~= nil then
        return superFunc(self)
    else
        return true, false
    end
end


---Returns if all vehicles can be turned on
-- @return boolean canBeTurnedOn all vehicles can be turned on
function PowerConsumer:getCanBeTurnedOnAll(superFunc)
    if not superFunc(self) then
        return false
    end

    local rootVehicle = self.rootVehicle
    if rootVehicle ~= nil and rootVehicle.getMotor ~= nil then
        local rootMotor = rootVehicle:getMotor()

        local torqueRequested, _ = PowerConsumer.getTotalConsumedPtoTorque(rootVehicle, nil, true)
        torqueRequested = torqueRequested / rootMotor:getPtoMotorRpmRatio()

        -- 90% of motor torque should be more than requested torque, because we need some torque to accelerate the vehicle
        if torqueRequested > 0 and torqueRequested > 0.9 * rootMotor:getPeakTorque() then
            if not self:getIsTurnedOn() then
                return false, self.spec_powerConsumer.turnOnNotAllowedWarning
            end
        end
    end

    return true, false
end


---Returns turn on not allowed warning text
-- @return string warningText turn on not allowed warning text
function PowerConsumer:getTurnedOnNotAllowedWarning(superFunc)
    local spec = self.spec_powerConsumer
    local _, notEnoughPower = PowerConsumer.getCanBeTurnedOn(self)
    if notEnoughPower then
        return spec.turnOnNotAllowedWarning
    else
        return superFunc(self)
    end
end


---
function PowerConsumer:getRawSpeedLimit(superFunc)
    local rawSpeedLimit = superFunc(self)

    local spec = self.spec_powerConsumer
    for i = #spec.speedLimitModifier, 1, -1 do
        local modifier = spec.speedLimitModifier[i]
        if spec.sourceMotorPeakPower >= modifier.minPowerKw and spec.sourceMotorPeakPower <= modifier.maxPowerKw then
            return rawSpeedLimit + modifier.offset
        end
    end

    return rawSpeedLimit
end


---
function PowerConsumer:loadWorkModeFromXML(superFunc, xmlFile, key, workMode)
    if not superFunc(self, xmlFile, key, workMode) then
        return false
    end

    workMode.forceScale = xmlFile:getValue(key .. "#forceScale", 1)
    workMode.ptoPowerScale = xmlFile:getValue(key .. "#ptoPowerScale", 1)

    return true
end


---
function PowerConsumer:onStateChange(state, data)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        local spec = self.spec_powerConsumer
        local rootVehicle = self.rootVehicle
        if rootVehicle ~= nil and rootVehicle.getMotor ~= nil then
            local rootMotor = rootVehicle:getMotor()
            spec.sourceMotorPeakPower = rootMotor.peakMotorPower
        else
            spec.sourceMotorPeakPower = math.huge
        end
    end
end


---
function PowerConsumer:onWorkModeChanged(workMode, oldWorkMode)
    if workMode.forceScale ~= nil then
        local spec = self.spec_powerConsumer
        if spec.maxForceOrig == nil then
            spec.maxForceOrig = spec.maxForce
            spec.neededMinPtoPowerOrig = spec.neededMinPtoPower
            spec.neededMaxPtoPowerOrig = spec.neededMaxPtoPower
        end

        spec.maxForce = spec.maxForceOrig * workMode.forceScale
        spec.neededMinPtoPower = spec.neededMinPtoPowerOrig * workMode.forceScale
        spec.neededMaxPtoPower = spec.neededMaxPtoPowerOrig * workMode.forceScale
    end
end


---
function PowerConsumer:onTurnedOn()
    self.spec_powerConsumer.turnOnPeakPowerTimer = self.spec_powerConsumer.turnOnPeakPowerDuration * 1.5
end


---Get total amount of consumed pto torque (from every attached vehicle)
-- @param table? excludeVehicle exluded vehicle
-- @param boolean? expected expected torque
-- @param boolean? ignoreTurnOnPeak
-- @return float torque total amount of consumed pto torque in kNm
-- @return float virtualMultiplicator virtual multiplicator
function PowerConsumer.getTotalConsumedPtoTorque(self, excludeVehicle, expected, ignoreTurnOnPeak)
    local torque, virtualMultiplicator = 0, 1
    if self ~= excludeVehicle then
        if self.getConsumedPtoTorque ~= nil then
            torque, virtualMultiplicator = self:getConsumedPtoTorque(expected, ignoreTurnOnPeak)
        end
    end

    if self.getAttachedImplements ~= nil then
        local attachedImplements = self:getAttachedImplements()
        for _, implement in pairs(attachedImplements) do
            local implementTorque, implementMultiplicator = PowerConsumer.getTotalConsumedPtoTorque(implement.object, excludeVehicle, expected, ignoreTurnOnPeak)
            torque = torque + implementTorque

            if torque == 0 then
                virtualMultiplicator = implementMultiplicator
            else
                local ratio = implementTorque / torque
                virtualMultiplicator = virtualMultiplicator * (1 - ratio) + implementMultiplicator * ratio
            end
        end
    end

    return torque, virtualMultiplicator
end


---Returns max pto rpm
-- @return float maxPtoRpm max pto rpm
function PowerConsumer.getMaxPtoRpm(self)
    local rpm = 0

    if self.getPtoRpm ~= nil then
        rpm = self:getPtoRpm()
    end

    if self.getAttachedImplements ~= nil then
        local attachedImplements = self:getAttachedImplements()
        for _, implement in pairs(attachedImplements) do
            rpm = math.max(rpm, PowerConsumer.getMaxPtoRpm(implement.object))
        end
    end

    return rpm
end



---
function PowerConsumer:consoleSetPowerConsumer(neededMinPtoPower, neededMaxPtoPower, forceFactor, maxForce, forceDir, ptoRpm)
    if neededMinPtoPower == nil then
        return "No arguments given! Usage: gsPowerConsumerSet <neededMinPtoPower> <neededMaxPtoPower> <forceFactor> <maxForce> <forceDir> <ptoRpm>"
    end
    local object
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        if g_localPlayer:getCurrentVehicle():getSelectedImplement() ~= nil and g_localPlayer:getCurrentVehicle():getSelectedImplement().object.spec_powerConsumer ~= nil then
            object = g_localPlayer:getCurrentVehicle():getSelectedImplement().object
        end
    end
    if object == nil then
        return "No vehicle with powerConsumer specialization selected"
    end

    object.spec_powerConsumer.neededMinPtoPower = Utils.getNoNil(neededMinPtoPower, object.spec_powerConsumer.neededMinPtoPower)
    object.spec_powerConsumer.neededMaxPtoPower = Utils.getNoNil(neededMaxPtoPower, object.spec_powerConsumer.neededMaxPtoPower)
    object.spec_powerConsumer.forceFactor = Utils.getNoNil(forceFactor, object.spec_powerConsumer.forceFactor)
    object.spec_powerConsumer.maxForce = Utils.getNoNil(maxForce, object.spec_powerConsumer.maxForce)
    object.spec_powerConsumer.forceDir = Utils.getNoNil(forceDir, object.spec_powerConsumer.forceDir)
    object.spec_powerConsumer.ptoRpm = Utils.getNoNil(ptoRpm, object.spec_powerConsumer.ptoRpm)

    for _, veh in pairs(g_currentMission.vehicleSystem.vehicles) do
        if veh.configFileName == object.configFileName then
            veh.spec_powerConsumer.neededMinPtoPower = object.spec_powerConsumer.neededMinPtoPower
            veh.spec_powerConsumer.neededMaxPtoPower = object.spec_powerConsumer.neededMaxPtoPower
            veh.spec_powerConsumer.forceFactor = object.spec_powerConsumer.forceFactor
            veh.spec_powerConsumer.maxForce = object.spec_powerConsumer.maxForce
            veh.spec_powerConsumer.forceDir = object.spec_powerConsumer.forceDir
            veh.spec_powerConsumer.ptoRpm = object.spec_powerConsumer.ptoRpm
        end
    end

    return string.format("Updated power consumer for '%s'", object.configFileName)
end




---Loads needed power spec value
-- @param XMLFile xmlFile XMLFile instance
-- @param string customEnvironment custom environment
-- @return float neededPower needed power
function PowerConsumer.loadSpecValueNeededPower(xmlFile, customEnvironment, baseDir)
    local neededPower = {}
    neededPower.base = xmlFile:getValue("vehicle.storeData.specs.neededPower")
    neededPower.maxPower = xmlFile:getValue("vehicle.storeData.specs.neededPower#maxPower")
    neededPower.config = {}

    local i = 0
    while true do
        local baseKey = string.format("vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(%d)", i)
        if not xmlFile:hasProperty(baseKey) then
            break
        end

        neededPower.config[i+1] = xmlFile:getValue(baseKey .. "#neededPower")

        i = i + 1
    end


    return neededPower
end


---Returns needed power spec value
-- @param table storeItem store item
-- @param table realItem real item
-- @return string l10n l10n text
-- @return float neededPower needed power in kw
-- @return float neededPower needed power in hp
function PowerConsumer.getSpecValueNeededPower(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.neededPower ~= nil then
        local minPower, maxPower = math.huge, -math.huge
        for _, value in pairs(storeItem.specs.neededPower.config) do
            minPower = math.min(minPower, value)
            maxPower = math.max(maxPower, value)
        end

        if minPower == math.huge then
            minPower = storeItem.specs.neededPower.base or 0
            maxPower = storeItem.specs.neededPower.maxPower
        end

        if minPower == 0 then
            return nil
        end

        if maxPower == nil or minPower == maxPower then
            local hp, kw = g_i18n:getPower(minPower)
            return string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(kw), MathUtil.round(hp))
        else
            local minHP, _ = g_i18n:getPower(minPower)
            local maxHP, _ = g_i18n:getPower(maxPower)
            return string.format(g_i18n:getText("shop_neededPowerValueMinMax"), MathUtil.round(minHP), MathUtil.round(maxHP))
        end
    end
    return nil
end
