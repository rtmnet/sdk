






















---
function PlowPacker.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PlowPacker")

    schema:register(XMLValueType.STRING, "vehicle.plow.packer#inputAction", "Input action name for packer toggling", "IMPLEMENT_EXTRA4")

    schema:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateLeft", "Packer deactivate animation left side")
    schema:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateRight", "Packer deactivate animation left side")
    schema:register(XMLValueType.FLOAT, "vehicle.plow.packer#animationSpeed", "Packer animation speed", 1)
    schema:register(XMLValueType.INT, "vehicle.plow.packer#foldingConfig", "Folding configuration with available packer", 1)

    schema:register(XMLValueType.BOOL, "vehicle.plow.packer#partialDeactivated", "Only some parts of the packer are deactivated", false)

    schema:register(XMLValueType.STRING, "vehicle.plow.packer.lowerAnimation#name", "Lower animation that is played while packer is active")
    schema:register(XMLValueType.FLOAT, "vehicle.plow.packer.lowerAnimation#speed", "Lower animation speed", 1)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#packerState", "Packer state")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#lastPackerState", "Last packer state while turning")
end


---
function PlowPacker.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Plow, specializations)
       and SpecializationUtil.hasSpecialization(Cultivator, specializations)
       and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end


---
function PlowPacker.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setPackerState", PlowPacker.setPackerState)
    SpecializationUtil.registerFunction(vehicleType, "getIsPackerAllowed", PlowPacker.getIsPackerAllowed)
end


---
function PlowPacker.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setRotationMax", PlowPacker.setRotationMax)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setPlowAIRequirements", PlowPacker.setPlowAIRequirements)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setFoldState", PlowPacker.setFoldState)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", PlowPacker.processCultivatorArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseCultivatorAIRequirements", PlowPacker.getUseCultivatorAIRequirements)
end


---
function PlowPacker.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", PlowPacker)
end


---
function PlowPacker:onLoad(savegame)
    local spec = self.spec_plowPacker

    local actionName = self.xmlFile:getValue("vehicle.plow.packer#inputAction", "IMPLEMENT_EXTRA4")
    if actionName ~= nil then
        spec.packerInputActionIndex = InputAction[actionName]
    end

    spec.packerDeactivateLeftAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateLeft")
    spec.packerDeactivateRightAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateRight")
    spec.packerDeactivateAnimSpeed = self.xmlFile:getValue("vehicle.plow.packer#animationSpeed", 1)

    spec.packerFoldingConfiguration = self.xmlFile:getValue("vehicle.plow.packer#foldingConfig", 1)
    spec.packerAvailable = self.configurations["folding"] == spec.packerFoldingConfiguration and spec.packerDeactivateLeftAnimation ~= nil and spec.packerDeactivateRightAnimation ~= nil

    spec.partialDeactivated = self.xmlFile:getValue("vehicle.plow.packer#partialDeactivated", false)

    spec.lowerAnimation = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#name")
    spec.lowerAnimationSpeed = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#speed", 1)

    spec.packerActivateText = g_i18n:getText("action_activatePacker", self.customEnvironment)
    spec.packerDeactivateText = g_i18n:getText("action_deactivatePacker", self.customEnvironment)

    spec.packerState = true

    spec.delayedFoldStateChange = nil
    spec.delayedLowerAnimationUpdate = false
end


---
function PlowPacker:onPostLoad(savegame)
    local spec = self.spec_plowPacker
    self:setPlowAIRequirements()

    if savegame ~= nil and not savegame.resetVehicles then
        if spec.packerAvailable then
            local packerState = savegame.xmlFile:getValue(savegame.key..".plowPacker#packerState")
            if packerState ~= nil then
                self:setPackerState(packerState, true, true)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
            end

            spec.lastPackerState = savegame.xmlFile:getValue(savegame.key..".plowPacker#lastPackerState")
        end
    end
end


---
function PlowPacker:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        xmlFile:setValue(key.."#packerState", spec.packerState)

        if spec.lastPackerState ~= nil then
            xmlFile:setValue(key.."#lastPackerState", spec.lastPackerState)
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function PlowPacker:onReadStream(streamId, connection)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        local packerState = streamReadBool(streamId)

        if self:getIsPackerAllowed() then
            self:setPackerState(packerState, true, true)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function PlowPacker:onWriteStream(streamId, connection)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        streamWriteBool(streamId, spec.packerState)
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function PlowPacker:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isServer then
        local spec = self.spec_plowPacker
        if spec.packerAvailable then
            if spec.lastPackerState ~= nil then
                if self:getIsPackerAllowed() then
                    if spec.lastPackerState == false then
                        self:setPackerState(false, true)
                    end

                    spec.lastPackerState = nil
                end
            end

            if spec.delayedFoldStateChange ~= nil then
                if not self:getIsAnimationPlaying(spec.packerDeactivateLeftAnimation)
                and not self:getIsAnimationPlaying(spec.packerDeactivateRightAnimation) then
                    local data = spec.delayedFoldStateChange
                    data.superFunc(self, data.direction, data.moveToMiddle, false)
                    spec.delayedFoldStateChange = nil
                end
            end

            if spec.delayedLowerAnimationUpdate then
                if not self:getIsAnimationPlaying(spec.packerDeactivateLeftAnimation)
                and not self:getIsAnimationPlaying(spec.packerDeactivateRightAnimation) then
                    local isLowered = self:getIsLowered()
                    local animationTime = self:getAnimationTime(spec.lowerAnimation)
                    if (isLowered and animationTime <= 0.5) or (not isLowered and animationTime > 0.5) then
                        self:playAnimation(spec.lowerAnimation, isLowered and spec.lowerAnimationSpeed or -spec.lowerAnimationSpeed, nil, true)
                    end

                    spec.delayedLowerAnimationUpdate = false
                end
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function PlowPacker:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isClient then
        if self.spec_plowPacker.packerAvailable then
            PlowPacker.updateActionEventText(self)
        end
    end
end


---
function PlowPacker:setRotationMax(superFunc, rotationMax, noEventSend, turnAnimationTime)
    if self.isServer then
        if self.spec_plow.rotationMax ~= rotationMax then
            local spec = self.spec_plowPacker
            if spec.packerAvailable then
                if spec.lastPackerState == nil then
                    spec.lastPackerState = spec.packerState
                    self:setPackerState(true, true)
                end
            end
        end
    end

    superFunc(self, rotationMax, noEventSend, turnAnimationTime)
end


---
function PlowPacker:setPlowAIRequirements(superFunc, excludedGroundTypes)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        if spec.packerState or spec.partialDeactivated then
            return superFunc(self, PlowPacker.CULTIVATED_GROUND_TYPES)
        end
    end

    return superFunc(self, excludedGroundTypes)
end


---
function PlowPacker:setFoldState(superFunc, direction, moveToMiddle, noEventSend)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        if direction ~= 0 and direction ~= self.spec_foldable.turnOnFoldDirection and self:getIsPackerAllowed() and not spec.packerState then
            if self.isServer then
                if spec.lastPackerState == nil then
                    spec.lastPackerState = spec.packerState
                    self:setPackerState(true, true)

                    spec.delayedFoldStateChange = {superFunc=superFunc, direction=direction, moveToMiddle=moveToMiddle}
                end
            end

            -- sync the event to the server / client to they can set the 'lastPackerState' correctly
            local specFoldable = self.spec_foldable
            if specFoldable.foldMiddleAnimTime == nil then
                moveToMiddle = false
            end
            if specFoldable.foldMoveDirection ~= direction or specFoldable.moveToMiddle ~= moveToMiddle then
                if noEventSend == nil or noEventSend == false then
                    if g_server ~= nil then
                        g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle), nil, nil, self)
                    else
                        g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle))
                    end
                end
            end

            return
        end
    end

    superFunc(self, direction, moveToMiddle, noEventSend)
end


---
function PlowPacker:processCultivatorArea(superFunc, workArea, dt)
    local spec = self.spec_cultivator

    local xs,_,zs = getWorldTranslation(workArea.start)
    local xw,_,zw = getWorldTranslation(workArea.width)
    local xh,_,zh = getWorldTranslation(workArea.height)

    FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

    if not self.isServer and self.currentUpdateDistance > PlowPacker.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end

    local params = spec.workAreaParameters

    local realArea, area = FSDensityMapUtil.updatePlowPackerArea(xs, zs, xw, zw, xh, zh, params.angle)

    params.lastChangedArea = params.lastChangedArea + realArea
    params.lastStatsArea = params.lastStatsArea + realArea
    params.lastTotalArea = params.lastTotalArea + area

    spec.isWorking = self:getLastSpeed() > 0.5

    return realArea, area
end


---Returns if cultivator ai requirements should be used
-- @return boolean useAIRequirements use ai requirements
function PlowPacker:getUseCultivatorAIRequirements(superFunc)
    return false
end


---
function PlowPacker:setPackerState(newState, updateAnimations, noEventSend)
    local spec = self.spec_plowPacker

    if newState == nil then
        newState = not spec.packerState
    end

    if updateAnimations == nil then
        updateAnimations = true
    end

    if newState ~= spec.packerState then
        spec.packerState = newState

        if updateAnimations then
            local direction = newState and -1 or 1
            if self.spec_plow.rotationMax then
                self:playAnimation(spec.packerDeactivateLeftAnimation, spec.packerDeactivateAnimSpeed * direction, nil, true)
            else
                self:playAnimation(spec.packerDeactivateRightAnimation, spec.packerDeactivateAnimSpeed * direction, nil, true)
            end
        end

        -- if packer is activated we update the lowering animation after the packer has been lowered
        -- so we sync the lowering state in case it has been changed while the packer was lifted
        if newState then
            if spec.lowerAnimation ~= nil then
                local isLowered = self:getIsLowered()
                local animationTime = self:getAnimationTime(spec.lowerAnimation)
                if (isLowered and animationTime <= 0.5) or (not isLowered and animationTime > 0.5) then
                    spec.delayedLowerAnimationUpdate = true
                end
            end
        end

        self:setPlowAIRequirements()

        PlowPackerStateEvent.sendEvent(self, newState, updateAnimations, noEventSend)
    end

    PlowPacker.updateActionEventText(self)
end


---
function PlowPacker:getIsPackerAllowed()
    if self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) then
        return false
    end

    if self:getFoldAnimTime() ~= (self.spec_foldable.turnOnFoldDirection > 0 and 1 or 0) then
        return false
    end

    local spec = self.spec_plowPacker
    if spec.delayedFoldStateChange ~= nil then
        return false
    end

    if not spec.packerAvailable then
        return false
    end

    return true
end


---
function PlowPacker:onSetLowered(lowered)
    local spec = self.spec_plowPacker

    if self:getIsPackerAllowed() then
        if spec.packerState then
            if spec.lowerAnimation ~= nil then
                self:playAnimation(spec.lowerAnimation, lowered and spec.lowerAnimationSpeed or -spec.lowerAnimationSpeed, nil, true)
            end
        end
    end
end


---
function PlowPacker:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_plowPacker
        if spec.packerAvailable then
            self:clearActionEventsTable(spec.actionEvents)

            if isActiveForInput and spec.packerInputActionIndex ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.packerInputActionIndex, self, PlowPacker.actionEventPackerDeactivate, false, true, false, true)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                PlowPacker.updateActionEventText(self)
            end
        end
    end
end


---
function PlowPacker.updateActionEventText(self)
    local spec = self.spec_plowPacker

    local actionEvent = spec.actionEvents[spec.packerInputActionIndex]
    if actionEvent ~= nil then
        if spec.packerState then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.packerDeactivateText)
        else
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.packerActivateText)
        end

        g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsPackerAllowed())
    end
end


---
function PlowPacker.actionEventPackerDeactivate(self, actionName, inputValue, callbackState, isAnalog, isMouse)
    self:setPackerState()
end
