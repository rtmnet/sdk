














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableBunkerSilo.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableBunkerSilo.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableBunkerSilo)
end


---
function PlaceableBunkerSilo.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateBunkerSiloWalls", PlaceableBunkerSilo.updateBunkerSiloWalls)
    SpecializationUtil.registerFunction(placeableType, "setWallVisibility", PlaceableBunkerSilo.setWallVisibility)
    SpecializationUtil.registerFunction(placeableType, "getIsBunkerSiloExtendable", PlaceableBunkerSilo.getIsBunkerSiloExtendable)
end


---
function PlaceableBunkerSilo.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementPosition", PlaceableBunkerSilo.getPlacementPosition)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementRotation", PlaceableBunkerSilo.getPlacementRotation)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasOverlap", PlaceableBunkerSilo.getHasOverlap)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "startPlacementCheck", PlaceableBunkerSilo.startPlacementCheck)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableBunkerSilo.canBeSold)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBunkerSilo.setOwnerFarmId)
end


---
function PlaceableBunkerSilo.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("BunkerSilo")
    BunkerSilo.registerXMLPaths(schema, basePath .. ".bunkerSilo")
    schema:register(XMLValueType.BOOL,   basePath .. ".bunkerSilo#isExtendable",        "Checks if silo is extendable. If set 'siloToSiloDistance' needs to be provided as well", false)
    schema:register(XMLValueType.FLOAT,  basePath .. ".bunkerSilo#siloToSiloDistance",  "Silo to silo distance required for aligning multiple silos of the same type next to each other")
    schema:register(XMLValueType.FLOAT,  basePath .. ".bunkerSilo#snapDistance",        "Snap distance for building an array of the same silo", "siloToSiloDistance * 1.1")
    schema:register(XMLValueType.STRING, basePath .. ".bunkerSilo#sellWarningText",     "Sell warning text")
    schema:setXMLSpecializationType()
end


---
function PlaceableBunkerSilo.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("BunkerSilo")
    BunkerSilo.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableBunkerSilo:onLoad(savegame)
    local spec = self.spec_bunkerSilo

    spec.bunkerSilo = BunkerSilo.new(self.isServer, self.isClient)
    if not spec.bunkerSilo:load(self.components, self.xmlFile, "placeable.bunkerSilo", self.i3dMappings) then
        spec.bunkerSilo:delete()
    end

    spec.isExtendable = self.xmlFile:getValue("placeable.bunkerSilo#isExtendable", false)
    if spec.isExtendable then
        spec.siloSiloDistance = self.xmlFile:getValue("placeable.bunkerSilo#siloToSiloDistance")
        if spec.siloSiloDistance == nil then
            Logging.xmlError(self.xmlFile, "Bunker Silo is marked as extendable but 'placeable.bunkerSilo#siloToSiloDistance' is not set")
            self:setLoadingState(PlaceableLoadingState.ERROR)
            return
        end
        spec.snapDistance = self.xmlFile:getValue("placeable.bunkerSilo#snapDistance") or spec.siloSiloDistance * 1.1
    end

    spec.sellWarningText = g_i18n:convertText(self.xmlFile:getValue("placeable.bunkerSilo#sellWarningText", "$l10n_info_bunkerSiloNotEmpty"))
end


---
function PlaceableBunkerSilo:onDelete()
    local spec = self.spec_bunkerSilo

    self:updateBunkerSiloWalls(true)
    if spec.bunkerSilo ~= nil then
        spec.bunkerSilo:delete()
    end
    g_currentMission.placeableSystem:removeBunkerSilo(self)
end


---
function PlaceableBunkerSilo:onFinalizePlacement()
    local spec = self.spec_bunkerSilo
    local ownerFarmId = self:getOwnerFarmId()

    self:updateBunkerSiloWalls(false)
    spec.bunkerSilo:register(true)
    spec.bunkerSilo:setOwnerFarmId(ownerFarmId, true)
    g_currentMission.placeableSystem:addBunkerSilo(self)
end


---
function PlaceableBunkerSilo:onReadStream(streamId, connection)
    local spec = self.spec_bunkerSilo

    local bunkerSiloId = NetworkUtil.readNodeObjectId(streamId)
    spec.bunkerSilo:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.bunkerSilo, bunkerSiloId)
end


---
function PlaceableBunkerSilo:onWriteStream(streamId, connection)
    local spec = self.spec_bunkerSilo

    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.bunkerSilo))
    spec.bunkerSilo:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.bunkerSilo)
end


---
function PlaceableBunkerSilo:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_bunkerSilo

    return spec.bunkerSilo:loadFromXMLFile(xmlFile, key)
end


---
function PlaceableBunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_bunkerSilo

    spec.bunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
end


---
function PlaceableBunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
    local spec = self.spec_bunkerSilo
    spec.bunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
end


---
function PlaceableBunkerSilo:getIsBunkerSiloExtendable()
    local spec = self.spec_bunkerSilo
    return spec.isExtendable
end


---
function PlaceableBunkerSilo:updateBunkerSiloWalls(isDeleting)
    local spec = self.spec_bunkerSilo
    if self.rootNode ~= nil then
        local x, y, z = getWorldTranslation(self.rootNode)
        local placeableSystem = g_currentMission.placeableSystem
        for _, placeable in ipairs(placeableSystem:getBunkerSilos()) do
            if placeable:getIsBunkerSiloExtendable() and placeable ~= self and placeable:getOwnerFarmId() == self:getOwnerFarmId() then
                if placeable.configFileName == self.configFileName then
                    local lx, _, lz = worldToLocal(placeable.rootNode, x, y, z)
                    local distance = MathUtil.vector2Length(lx, lz)
                    if distance < spec.siloSiloDistance + 0.5 then
                        local isLeft = lx > 0

                        if isDeleting then
                            -- always set walls visible
                            if isLeft then
                                placeable:setWallVisibility(true, nil)
                            else
                                placeable:setWallVisibility(nil, true)
                            end
                        else
                            if isLeft then
                                placeable:setWallVisibility(false, nil)
                            else
                                placeable:setWallVisibility(nil, false)
                            end
                        end
                    end
                end
            end
        end
    end
end


---
function PlaceableBunkerSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
    local spec = self.spec_bunkerSilo

    superFunc(self, farmId, noEventSend)

    if spec.bunkerSilo ~= nil then
        spec.bunkerSilo:setOwnerFarmId(farmId, true)
    end
end


---
function PlaceableBunkerSilo:onSell()
    local spec = self.spec_bunkerSilo

    spec.bunkerSilo:clearSiloArea()
end


---
function PlaceableBunkerSilo:canBeSold(superFunc)
    local spec = self.spec_bunkerSilo

    if spec.bunkerSilo.fillLevel > 0 then
        return true, spec.sellWarningText
    end

    return true, nil
end



---
-- @param function superFunc
-- @param float? x
-- @param float? y
-- @param float? z
-- @param float? rotY
function PlaceableBunkerSilo:startPlacementCheck(superFunc, x, y, z, rotY)
    local spec = self.spec_bunkerSilo
    superFunc(self, x, y, z, rotY)

    if x == nil then
        return
    end

    if not spec.isExtendable then
        return
    end

    spec.foundSnappingSilo = nil
    spec.foundSnappingSiloSide = 0
    local nearestDistance = spec.snapDistance
    for _, placeable in ipairs(g_currentMission.placeableSystem:getBunkerSilos()) do
        if placeable:getOwnerFarmId() == g_localPlayer.farmId then
            if placeable.configFileName == self.configFileName then

                local lx, _, lz = worldToLocal(placeable.rootNode, x, y, z)
                local distance = MathUtil.vector2Length(lx, lz)
                if distance < nearestDistance then
                    nearestDistance = distance
                    spec.foundSnappingSilo = placeable
                    spec.foundSnappingSiloSide = math.sign(lx)
                end
            end
        end
    end
end


---
function PlaceableBunkerSilo:getHasOverlap(superFunc, x, y, z, rotY, checkFunc)

    local spec = self.spec_bunkerSilo
    local overwrittenCheckFunc = checkFunc

    if spec.foundSnappingSilo ~= nil then
        overwrittenCheckFunc = function(hitObjectId)
            local object = g_currentMission:getNodeObject(hitObjectId)
            if object == spec.foundSnappingSilo then
                return false
            end

            if checkFunc ~= nil then
                return checkFunc(hitObjectId)
            end

            return hitObjectId ~= g_terrainNode
        end
    end

    return superFunc(self, x, y, z, rotY, overwrittenCheckFunc)
end


---
function PlaceableBunkerSilo:getPlacementRotation(superFunc, x, y, z)
    x, y, z = superFunc(self, x, y, z)

    local spec = self.spec_bunkerSilo
    if spec.foundSnappingSilo ~= nil then
        local dx, _, dz = localDirectionToWorld(spec.foundSnappingSilo.rootNode, 0, 0, 1)
        x, y, z = 0, MathUtil.getYRotationFromDirection(dx, dz), 0
    end

    return x, y, z
end


---
function PlaceableBunkerSilo:getPlacementPosition(superFunc, x, y, z)
    x, y, z = superFunc(self, x, y, z)

    local spec = self.spec_bunkerSilo
    if spec.foundSnappingSilo ~= nil then
        x, y, z = localToWorld(spec.foundSnappingSilo.rootNode, spec.siloSiloDistance * spec.foundSnappingSiloSide, 0, 0)
    end

    return x, y, z
end
