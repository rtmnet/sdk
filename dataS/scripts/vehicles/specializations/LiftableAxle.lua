















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function LiftableAxle.prerequisitesPresent(specializations)
    return true
end


---Called while initializing the specialization
function LiftableAxle.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("liftableAxle", g_i18n:getText("shop_configuration"), "liftableAxle", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("LiftableAxle")

    LiftableAxle.registerXMLPaths(schema, "vehicle.liftableAxle")
    LiftableAxle.registerXMLPaths(schema, "vehicle.liftableAxle.liftableAxleConfigurations.liftableAxleConfiguration(?)")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).liftableAxle#state", "Liftable axle state", false)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).liftableAxle#height", "Current height of the liftable axle")
end


---
function LiftableAxle.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#inputAction", "Input action name if manual control is allowed")

    schema:register(XMLValueType.STRING, basePath .. "#animationName", "Name of the animation")
    schema:register(XMLValueType.FLOAT, basePath .. "#animationSpeed", "Speed of animation", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#defaultState", "Default state of the animation [0-1]", 0)

    schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Index of fill unit to check")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelThreshold", "Fill level at which the lift axle is toggled [0-1]", 0)

    schema:register(XMLValueType.NODE_INDICES, basePath .. ".dependentAttacherJoint(?)#nodes", "List of attacher joint nodes to adjust height based on attacher joint height")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentAttacherJoint(?)#minJointHeight", "Joint height from ground when axle is lowered", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentAttacherJoint(?)#maxJointHeight", "Joint height from ground when axle is lifted", 1.5)

    schema:register(XMLValueType.NODE_INDICES, basePath .. ".dependentInputAttacherJoint(?)#nodes", "List of input attacher joint nodes to adjust height based on the parent attacher joint height or the height of the parent vehicle chassis")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentInputAttacherJoint(?)#minJointHeight", "Joint height from ground when axle is lowered", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentInputAttacherJoint(?)#maxJointHeight", "Joint height from ground when axle is lifted", 1.5)

    schema:register(XMLValueType.L10N_STRING, basePath .. ".texts#lift", "Text for lifting", "$l10n_action_liftableAxleLift")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".texts#lower", "Text for lowering", "$l10n_action_liftableAxleLower")
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function LiftableAxle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setLiftableAxleState", LiftableAxle.setLiftableAxleState)
    SpecializationUtil.registerFunction(vehicleType, "getLiftableAxleAttacherJointHeight", LiftableAxle.getLiftableAxleAttacherJointHeight)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function LiftableAxle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSmoothAttachUpdateAllowed", LiftableAxle.getIsSmoothAttachUpdateAllowed)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function LiftableAxle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", LiftableAxle)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", LiftableAxle)
end


---Called on load
-- @param table savegame savegame
function LiftableAxle:onLoad(savegame)
    local spec = self.spec_liftableAxle

    local configurationId = Utils.getNoNil(self.configurations["liftableAxle"], 1)
    local configKey = string.format("vehicle.liftableAxle.liftableAxleConfigurations.liftableAxleConfiguration(%d)", configurationId - 1)
    if not self.xmlFile:hasProperty(configKey) then
        configKey = "vehicle.liftableAxle"
    end

    spec.animationName = self.xmlFile:getValue(configKey .. "#animationName")
    if spec.animationName ~= nil then
        local inputActionName = self.xmlFile:getValue(configKey .. "#inputAction")
        spec.inputAction = InputAction[inputActionName]

        spec.animationSpeed = self.xmlFile:getValue(configKey .. "#animationSpeed", 1)
        spec.defaultState = self.xmlFile:getValue(configKey .. "#defaultState")

        spec.fillUnitIndex = self.xmlFile:getValue(configKey .. "#fillUnitIndex")
        spec.fillLevelThreshold = self.xmlFile:getValue(configKey .. "#fillLevelThreshold", 0)

        spec.attacherJointData = {}
        for _, key in self.xmlFile:iterator(configKey .. ".dependentAttacherJoint") do
            local data = {}
            data.nodes = self.xmlFile:getValue(key .. "#nodes", nil, self.components, self.i3dMappings, true)
            if data.nodes ~= nil and #data.nodes > 0 then
                data.minJointHeight = self.xmlFile:getValue(key .. "#minJointHeight", 1)
                data.maxJointHeight = self.xmlFile:getValue(key .. "#maxJointHeight", 1.5)

                data.isActive = false
                data.currentHeight = data.minJointHeight

                table.insert(spec.attacherJointData, data)
            end
        end

        spec.inputAttacherJointData = {}
        for _, key in self.xmlFile:iterator(configKey .. ".dependentInputAttacherJoint") do
            local data = {}
            data.nodes = self.xmlFile:getValue(key .. "#nodes", nil, self.components, self.i3dMappings, true)
            if data.nodes ~= nil and #data.nodes > 0 then
                data.minJointHeight = self.xmlFile:getValue(key .. "#minJointHeight", 1)
                data.maxJointHeight = self.xmlFile:getValue(key .. "#maxJointHeight", 1.5)

                data.isActive = false
                data.currentHeight = data.minJointHeight

                table.insert(spec.inputAttacherJointData, data)
            end
        end

        spec.texts = {}
        spec.texts.lift = self.xmlFile:getValue(configKey .. ".texts#lift", "action_liftableAxleLift", self.customEnvironment)
        spec.texts.lower = self.xmlFile:getValue(configKey .. ".texts#lower", "action_liftableAxleLower", self.customEnvironment)

        spec.state = false
        spec.fixedHeight = nil

        if spec.defaultState == 0 or spec.defaultState == 1 then
            spec.state = spec.defaultState == 1
        else
            spec.fixedHeight = spec.defaultState
        end

        if not self.isServer or spec.fillUnitIndex == nil then
            SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", LiftableAxle)
        end

        if not self.isServer or #spec.attacherJointData == 0 then
            SpecializationUtil.removeEventListener(self, "onPreAttachImplement", LiftableAxle)
            SpecializationUtil.removeEventListener(self, "onPreDetachImplement", LiftableAxle)
        end

        if not self.isServer or #spec.inputAttacherJointData == 0 then
            SpecializationUtil.removeEventListener(self, "onPreAttach", LiftableAxle)
            SpecializationUtil.removeEventListener(self, "onPreDetach", LiftableAxle)
        end

        if not self.isClient or spec.inputAction == nil then
            SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LiftableAxle)
        end
    else
        SpecializationUtil.removeEventListener(self, "onPostLoad", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onReadStream", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onWriteStream", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onPreAttachImplement", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onPreDetachImplement", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onPreAttach", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onPreDetach", LiftableAxle)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LiftableAxle)
    end
end


---
function LiftableAxle:onPostLoad(savegame)
    local spec = self.spec_liftableAxle

    local state = spec.state
    local height = spec.fixedHeight
    if savegame ~= nil and not savegame.resetVehicles then
        state = savegame.xmlFile:getValue(savegame.key .. ".liftableAxle#state", state)
        height = savegame.xmlFile:getValue(savegame.key .. ".liftableAxle#height")
    end

    spec.state = nil -- force update
    self:setLiftableAxleState(state, height, true, true)
end


---
function LiftableAxle:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_liftableAxle
    if spec.animationName ~= nil then
        xmlFile:setValue(key .. "#state", spec.state)

        if spec.fixedHeight ~= nil then
            xmlFile:setValue(key .. "#height", spec.fixedHeight)
        end
    end
end


---
function LiftableAxle:onReadStream(streamId, connection)
    local state = streamReadBool(streamId)

    local fixedHeight = nil
    if streamReadBool(streamId) then
        fixedHeight = streamReadFloat32(streamId)
    end

    self:setLiftableAxleState(state, fixedHeight, true, true)
end


---
function LiftableAxle:onWriteStream(streamId, connection)
    local spec = self.spec_liftableAxle
    streamWriteBool(streamId, spec.state)

    if streamWriteBool(streamId, spec.fixedHeight ~= nil) then
        streamWriteFloat32(streamId, spec.fixedHeight or 0)
    end
end


---
function LiftableAxle:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
    if self:getIsSynchronized() then -- during loading we use the state that we saved ourselfs in the savegame
        local spec = self.spec_liftableAxle

        if fillUnitIndex == spec.fillUnitIndex and fillLevelDelta ~= 0 then
            local fillLevel = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
            local state = fillLevel > spec.fillLevelThreshold
            if state ~= spec.state then
                self:setLiftableAxleState(state)
            end
        end
    end
end


---
function LiftableAxle:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
    local spec = self.spec_liftableAxle

    local jointDesc = self:getAttacherJointByJointDescIndex(jointDescIndex)
    for _, data in ipairs(spec.attacherJointData) do
        local isActive = false
        for _, node in ipairs(data.nodes) do
            if node == jointDesc.jointTransform then
                isActive = true
                break
            end
        end

        if isActive ~= data.isActive then
            data.isActive = isActive

            if isActive then
                local inputAttacherJoint = object:getInputAttacherJointByJointDescIndex(inputJointDescIndex)
                local alpha = 1 - MathUtil.inverseLerp(data.minJointHeight, data.maxJointHeight, inputAttacherJoint.attacherHeight)

                -- the closest height we could reach
                data.currentHeight = MathUtil.lerp(data.minJointHeight, data.maxJointHeight, 1 - alpha)

                self:setLiftableAxleState(spec.state, alpha)
            end
        end
    end
end


---
function LiftableAxle:onPreDetachImplement(implement)
    local spec = self.spec_liftableAxle

    local jointDesc = self:getAttacherJointByJointDescIndex(implement.jointDescIndex)
    for _, data in ipairs(spec.attacherJointData) do
        for _, node in ipairs(data.nodes) do
            if node == jointDesc.jointTransform then
                if data.isActive then
                    data.isActive = false
                    self:setLiftableAxleState(spec.state, nil)
                end
            end
        end
    end

    if spec.defaultState ~= nil then
        local isAnyAttacherJointActive = false
        for _, data in ipairs(spec.attacherJointData) do
            if data.isActive then
                isAnyAttacherJointActive = true
                break
            end
        end

        if not isAnyAttacherJointActive then
            if spec.defaultState == 0 or spec.defaultState == 1 then
                self:setLiftableAxleState(spec.defaultState == 1, nil)
            else
                self:setLiftableAxleState(spec.state, spec.defaultState)
            end
        end
    else
        self:setLiftableAxleState(spec.state, nil)
    end
end


---
function LiftableAxle:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
    local spec = self.spec_liftableAxle

    local inputAttacherJoint = self:getInputAttacherJointByJointDescIndex(inputJointDescIndex)
    for _, data in ipairs(spec.inputAttacherJointData) do
        local isActive = false
        for _, node in ipairs(data.nodes) do
            if node == inputAttacherJoint.node then
                isActive = true
                break
            end
        end

        if isActive ~= data.isActive then
            data.isActive = isActive

            if isActive then
                local height
                if attacherVehicle.getLiftableAxleAttacherJointHeight ~= nil then
                    height = attacherVehicle:getLiftableAxleAttacherJointHeight(jointDescIndex)
                end

                if height == nil then
                    local attacherJoint = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
                    if attacherJoint ~= nil then
                        height = (attacherJoint.upperDistanceToGround + attacherJoint.lowerDistanceToGround) * 0.5
                    end
                end

                if height ~= nil then
                    local alpha = 1 - MathUtil.inverseLerp(data.minJointHeight, data.maxJointHeight, height)
                    data.currentHeight = MathUtil.lerp(data.minJointHeight, data.maxJointHeight, alpha)

                    self:setLiftableAxleState(spec.state, alpha)
                end
            end
        end
    end
end


---
function LiftableAxle:onPreDetach(attacherVehicle, implement)
    local spec = self.spec_liftableAxle

    local inputAttacherJoint = self:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
    for _, data in ipairs(spec.inputAttacherJointData) do
        for _, node in ipairs(data.nodes) do
            if node == inputAttacherJoint.node then
                if data.isActive then
                    data.isActive = false
                    self:setLiftableAxleState(spec.state, nil)
                end
            end
        end
    end

    if spec.defaultState ~= nil then
        local isAnyAttacherJointActive = false
        for _, data in ipairs(spec.inputAttacherJointData) do
            if data.isActive then
                isAnyAttacherJointActive = true
                break
            end
        end

        if not isAnyAttacherJointActive then
            if spec.defaultState == 0 or spec.defaultState == 1 then
                self:setLiftableAxleState(spec.defaultState == 1, nil)
            else
                self:setLiftableAxleState(spec.state, spec.defaultState)
            end
        end
    else
        self:setLiftableAxleState(spec.state, nil)
    end
end


---
function LiftableAxle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    local spec = self.spec_liftableAxle
    self:clearActionEventsTable(spec.actionEvents)

    if isActiveForInputIgnoreSelection then
        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.inputAction, self, LiftableAxle.actionEvent, true, false, false, true, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

        LiftableAxle.updateActionEvents(self)
    end
end


---
function LiftableAxle.actionEvent(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_liftableAxle
    self:setLiftableAxleState(not spec.state)
end


---
function LiftableAxle.updateActionEvents(self)
    local spec = self.spec_liftableAxle

    local actionEvent = spec.actionEvents[spec.inputAction]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.state and spec.texts.lift or spec.texts.lower)
    end
end


---
function LiftableAxle:setLiftableAxleState(state, fixedHeight, skipAnimation, noEventSend)
    local spec = self.spec_liftableAxle

    if spec.state ~= state or spec.fixedHeight ~= fixedHeight then
        if fixedHeight ~= nil then
            state = fixedHeight >= 0.5
        end

        spec.state = state
        spec.fixedHeight = fixedHeight

        local currentTime = self:getAnimationTime(spec.animationName)
        if fixedHeight ~= nil then
            local direction = math.sign(fixedHeight - currentTime)
            self:playAnimation(spec.animationName, direction * spec.animationSpeed, currentTime, true)
            self:setAnimationStopTime(spec.animationName, fixedHeight)
        else
            local direction = state and 1 or -1
            self:stopAnimation(spec.animationName, true)
            self:playAnimation(spec.animationName, direction * spec.animationSpeed, currentTime, true)
        end

        if skipAnimation then
            AnimatedVehicle.updateAnimationByName(self, spec.animationName, 9999999, true)
        end

        if self.isClient and spec.inputAction ~= nil then
            LiftableAxle.updateActionEvents(self)
        end
    end

    LiftableAxleEvent.sendEvent(self, spec.state, spec.fixedHeight, noEventSend)
end


---
function LiftableAxle:getLiftableAxleAttacherJointHeight(attacherJointIndex)
    local spec = self.spec_liftableAxle
    if spec.animationName ~= nil then
        local jointDesc = self:getAttacherJointByJointDescIndex(attacherJointIndex)
        for _, data in ipairs(spec.attacherJointData) do
            for _, node in ipairs(data.nodes) do
                if node == jointDesc.jointTransform then
                    if data.isActive then
                        return data.currentHeight
                    end
                end
            end
        end
    end

    return nil
end


---
function LiftableAxle:getIsSmoothAttachUpdateAllowed(superFunc, implement)
    if not superFunc(self, implement) then
        return false
    end

    local spec = self.spec_liftableAxle
    if spec.animationName ~= nil and self:getIsAnimationPlaying(spec.animationName) then
        return false
    end

    return true
end
