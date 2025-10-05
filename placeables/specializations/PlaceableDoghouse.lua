


















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableDoghouse.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableDoghouse.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "dogInteractionTriggerCallback", PlaceableDoghouse.dogInteractionTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "isDoghouseRegistered", PlaceableDoghouse.isDoghouseRegistered)
    SpecializationUtil.registerFunction(placeableType, "registerDoghouseToMission", PlaceableDoghouse.registerDoghouseToMission)
    SpecializationUtil.registerFunction(placeableType, "unregisterDoghouseToMission", PlaceableDoghouse.unregisterDoghouseToMission)
    SpecializationUtil.registerFunction(placeableType, "setFoodBowlState", PlaceableDoghouse.setFoodBowlState)
    SpecializationUtil.registerFunction(placeableType, "getDog", PlaceableDoghouse.getDog)
    SpecializationUtil.registerFunction(placeableType, "getSpawnNode", PlaceableDoghouse.getSpawnNode)
end



---
function PlaceableDoghouse.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableDoghouse.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableDoghouse.canBuy)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableDoghouse.getCanBePlacedAt)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableDoghouse.getNeedHourChanged)
end


---
function PlaceableDoghouse.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableDoghouse)
end


---
function PlaceableDoghouse.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Doghouse")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dogHouse.dog#node", "Dog link node")
    schema:register(XMLValueType.STRING, basePath .. ".dogHouse.dog#xmlFilename", "Dog xml filename")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dogHouse.nameplate#node", "Name plate node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dogHouse.ball#node", "Ball node")
    schema:register(XMLValueType.STRING, basePath .. ".dogHouse.ball#filename", "Ball 3d file")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dogHouse.playerInteractionTrigger#node", "Interaction trigger node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dogHouse.bowl#foodNode", "Food node in bowl")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".dogHouse.bowl", "fillSound")
    schema:setXMLSpecializationType()
end


---
function PlaceableDoghouse.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Doghouse")
    Dog.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableDoghouse:onLoad(savegame)
    local spec = self.spec_doghouse
    local xmlFile = self.xmlFile

    spec.spawnNode = xmlFile:getValue("placeable.dogHouse.dog#node", nil, self.components, self.i3dMappings)
    if self.isServer then
        local posX, posY, posZ = getWorldTranslation(spec.spawnNode)
        local xmlFilename = Utils.getFilename(xmlFile:getValue("placeable.dogHouse.dog#xmlFilename"), self.baseDirectory)
        spec.dog = Dog.new(self.isServer, self.isClient)
        spec.dog:setOwnerFarmId(self:getOwnerFarmId(), true)
        if spec.dog:load(self, xmlFilename, posX, posY, posZ) then
            spec.dog:register()
        else
            Logging.xmlWarning(xmlFile, "Could not load dog!")
        end
    end

    spec.namePlateNode = xmlFile:getValue("placeable.dogHouse.nameplate#node", nil, self.components, self.i3dMappings)

    spec.ballSpawnNode = xmlFile:getValue("placeable.dogHouse.ball#node", nil, self.components, self.i3dMappings)
    if self.isServer then
        local dogBallFilename = Utils.getFilename(xmlFile:getValue("placeable.dogHouse.ball#filename"), self.baseDirectory)
        local x, y, z = getWorldTranslation(spec.ballSpawnNode)
        local rx, ry, rz = getWorldRotation(spec.ballSpawnNode)
        spec.dogBall = DogBall.new(self.isServer, self.isClient)
        spec.dogBall:setOwnerFarmId(self:getOwnerFarmId(), true)
        spec.dogBall:load(dogBallFilename, x, y, z, rx, ry, rz, self)
        spec.dogBall:register()
    end

    -- player interaction trigger
    spec.triggerNode = xmlFile:getValue("placeable.dogHouse.playerInteractionTrigger#node", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "dogInteractionTriggerCallback", self)
    end

    spec.foodNode = xmlFile:getValue("placeable.dogHouse.bowl#foodNode", nil, self.components, self.i3dMappings)
    if spec.foodNode == nil then
        Logging.xmlWarning(xmlFile, "Missing bowl food node in 'placeable.dogHouse.bowl#foodNode'!")
    else
        setVisibility(spec.foodNode, false)

        if g_client ~= nil then
            spec.foodFillSample = g_soundManager:loadSampleFromXML(xmlFile, "placeable.dogHouse.bowl", "fillSound", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings)
        end
    end

    spec.activatable = DoghouseActivatable.new(self)
end


---
function PlaceableDoghouse:onDelete()
    local spec = self.spec_doghouse

    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

    self:unregisterDoghouseToMission()

    if self.isServer then
        if spec.dogBall ~= nil and not spec.dogBall.isDeleted then -- Note: the dogBall might have been deleted by the server/client delete loop already
            spec.dogBall:delete()
            spec.dogBall = nil
        end
        if spec.dog ~= nil and not spec.dog.isDeleted then -- Note: the dogBall might have been deleted by the server/client delete loop already
            spec.dog:delete()
            spec.dog = nil
        end
    end

    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end

    if spec.foodFillSample ~= nil then
        g_soundManager:deleteSample(spec.foodFillSample)
        spec.foodFillSample = nil
    end
end


---
function PlaceableDoghouse:onFinalizePlacement()
    local spec = self.spec_doghouse

    if self.isServer and spec.dog ~= nil then
        spec.dog:finalizePlacement()
    end

    self:registerDoghouseToMission()
end


---
function PlaceableDoghouse:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_doghouse
        spec.dog = NetworkUtil.readNodeObject(streamId)
        if spec.dog ~= nil then
            spec.dog.spawner = self
        end
        if spec.foodNode ~= nil then
            setVisibility(spec.foodNode, streamReadBool(streamId))
        end
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function PlaceableDoghouse:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_doghouse
        NetworkUtil.writeNodeObject(streamId, spec.dog)
        if spec.foodNode ~= nil then
            streamWriteBool(streamId, getVisibility(spec.foodNode))
        end
    end
end


---
function PlaceableDoghouse:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_doghouse
    if spec.dog ~= nil then
        spec.dog:loadFromXMLFile(xmlFile, key)
    end
end


---
function PlaceableDoghouse:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_doghouse
    if spec.dog ~= nil then
        spec.dog:saveToXMLFile(xmlFile, key, usedModNames)
    end
end


---
function PlaceableDoghouse:dogInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self.spec_doghouse
    if spec.dog ~= nil then
        if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode and g_localPlayer.farmId == self:getOwnerFarmId() then
            if onEnter then
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            elseif onLeave then
                g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            end
        end
    end
end


---Returns true if a doghouse is registered
-- @return boolean canBuy
function PlaceableDoghouse:isDoghouseRegistered()
    local dogHouse = g_currentMission:getDoghouse(self:getOwnerFarmId())
    return dogHouse ~= nil
end


---Registers the doghouse to the mission game.
-- @return boolean true if registration went well
function PlaceableDoghouse:registerDoghouseToMission()
    if not self:isDoghouseRegistered() then
        g_currentMission.doghouses[self] = self
        return true
    end

    return false
end


---Registers the doghouse to the mission game.
-- @return boolean true if registration went well
function PlaceableDoghouse:unregisterDoghouseToMission()
    g_currentMission.doghouses[self] = nil

    return true
end


---
function PlaceableDoghouse:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)

    if self.isServer then
        local spec = self.spec_doghouse
        -- Note: we need to send events for the dog and the dogBall if we need to send one for the doghouse
        if spec.dog ~= nil then
            spec.dog:setOwnerFarmId(farmId, noEventSend)
        end
        if spec.dogBall ~= nil then
            spec.dogBall:setOwnerFarmId(farmId, noEventSend)
        end
    end
end


---
function PlaceableDoghouse:setFoodBowlState(isFilled, noEventSend)
    local spec = self.spec_doghouse
    if spec.foodNode ~= nil then
        PlaceableDoghouseFoodBowlStateEvent.sendEvent(self, isFilled, noEventSend)

        setVisibility(spec.foodNode, isFilled)

        if isFilled and spec.dog ~= nil then
            spec.dog:onFoodBowlFilled(spec.foodNode)

            if spec.foodFillSample ~= nil then
                g_soundManager:playSample(spec.foodFillSample)
            end
        end
    end
end


---
function PlaceableDoghouse:getDog()
    return self.spec_doghouse.dog
end


---
function PlaceableDoghouse:getSpawnNode()
    return self.spec_doghouse.spawnNode
end


---
function PlaceableDoghouse:getCanBePlacedAt(superFunc, x, y, z, farmId)
    if self:isDoghouseRegistered() then
        return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
    end

    return superFunc(self, x, y, z, farmId)
end


---
function PlaceableDoghouse:canBuy(superFunc)
    local canBuy, warning = superFunc(self)
    if not canBuy then
        return false, warning
    end

    if self:isDoghouseRegistered() then
        return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
    end

    return true, nil
end


---
function PlaceableDoghouse:getNeedHourChanged(superFunc)
    return true
end


---
function PlaceableDoghouse:onHourChanged()
    self:setFoodBowlState(false, true)
end
