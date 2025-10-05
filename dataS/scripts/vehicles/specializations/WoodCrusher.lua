















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function WoodCrusher.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations)
end


---
function WoodCrusher.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WoodCrusher")

    WoodCrusher.registerWoodCrusherXMLPaths(schema, "vehicle.woodCrusher")

    schema:register(XMLValueType.BOOL, "vehicle.woodCrusher#moveColDisableCollisionPairs", "Activate collision between move collisions and components", true)
    schema:register(XMLValueType.INT, "vehicle.woodCrusher#fillUnitIndex", "Fill unit index", 1)

    schema:setXMLSpecializationType()
end


---
function WoodCrusher.registerWoodCrusherXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#cutNode", "Cut node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#mainDrumRefNode", "Main drum reference node")
    schema:register(XMLValueType.FLOAT, key .. "#mainDrumRefNodeMaxY", "Max tree size the main drum can handle")

    schema:register(XMLValueType.NODE_INDEX, key .. ".moveTriggers.trigger(?)#node", "Move trigger")
    schema:register(XMLValueType.NODE_INDEX, key .. ".moveCollisions.collision(?)#node", "Move collision")

    schema:register(XMLValueType.FLOAT, key .. "#moveVelocityZ", "Move velocity Z (m/s)", 0.8)
    schema:register(XMLValueType.FLOAT, key .. "#moveMaxForce", "Move max. force (kN)", 7)
    schema:register(XMLValueType.NODE_INDEX, key .. "#shapeSizeDetectionNode", "At this node the tree shape size will be detected to set the #mainDrumRefNode")
    schema:register(XMLValueType.FLOAT, key .. "#cutSizeY", "Cut size Y", 1)
    schema:register(XMLValueType.FLOAT, key .. "#cutSizeZ", "Cut size Z", 1)

    schema:register(XMLValueType.NODE_INDEX, key .. ".downForceNodes.downForceNode(?)#node", "Down force node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".downForceNodes.downForceNode(?)#trigger", "Additional trigger (If defined the tree needs to be present in the mover trigger and inside this trigger)")
    schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#force", "Down force (kN)", 2)
    schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#sizeY", "Size Y in which the down force node detects trees", "Cut size Y")
    schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#sizeZ", "Size Z in which the down force node detects trees", "Cut size Z")

    schema:register(XMLValueType.BOOL, key .. "#automaticallyTurnOn", "Automatically turned on", false)

    EffectManager.registerEffectXMLPaths(schema, key .. ".crushEffects")
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. ".animationNodes")

    SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "start")
    SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "stop")
    SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "work")
    SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "idle")
end


---
function WoodCrusher.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onCrushedSplitShape", WoodCrusher.onCrushedSplitShape)
end


---
function WoodCrusher.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", WoodCrusher.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", WoodCrusher.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", WoodCrusher.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", WoodCrusher.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", WoodCrusher.getRequiresPower)
end


---
function WoodCrusher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodCrusher)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodCrusher)
end


---Called on loading
-- @param table savegame savegame
function WoodCrusher:onLoad(savegame)
    local spec = self.spec_woodCrusher

    WoodCrusher.loadWoodCrusher(self, spec, self.xmlFile, self.components, self.i3dMappings)

    local moveColDisableCollisionPairs = self.xmlFile:getValue("vehicle.woodCrusher#moveColDisableCollisionPairs", true)
    if moveColDisableCollisionPairs then
        for _, component in pairs(self.components) do
            for _, moveColNodes in pairs(spec.moveColNodes) do
                setPairCollision(component.node, moveColNodes.node, false)
            end
        end
    end

    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.woodCrusher#fillUnitIndex", 1)
end


---Called on deleting
function WoodCrusher:onDelete()
    WoodCrusher.deleteWoodCrusher(self, self.spec_woodCrusher)
end


---Called on on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function WoodCrusher:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_woodCrusher
        if streamReadBool(streamId) then
            spec.crushingTime = 1000
        else
            spec.crushingTime = 0
        end
    end
end


---Called on on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function WoodCrusher:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_woodCrusher
        streamWriteBool(streamId, spec.crushingTime > 0)
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function WoodCrusher:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    WoodCrusher.updateWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function WoodCrusher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    WoodCrusher.updateTickWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())

    local spec = self.spec_woodCrusher
    -- turn on/off automatically if tree node is in trigger
    if self.isServer then
        if g_currentMission.missionInfo.automaticMotorStartEnabled then
            if spec.turnOnAutomatically and self.setIsTurnedOn ~= nil then
                if next(spec.moveTriggerNodes) ~= nil then
                    if self.getIsMotorStarted ~= nil then
                        if not self:getIsMotorStarted() then
                            self:startMotor()
                        end
                    else
                        if self.attacherVehicle ~= nil then
                            if self.attacherVehicle.getIsMotorStarted ~= nil then
                                if not self.attacherVehicle:getIsMotorStarted() then
                                    self.attacherVehicle:startMotor()
                                end
                            end
                        end
                    end

                    if (self.getIsControlled == nil or not self:getIsControlled()) and not self:getIsTurnedOn() and self:getCanBeTurnedOn() then
                        self:setIsTurnedOn(true)
                    end
                    spec.turnOffTimer = 3000
                else
                    if self:getIsTurnedOn() then
                        if spec.turnOffTimer == nil then
                            spec.turnOffTimer = 3000
                        end
                        spec.turnOffTimer = spec.turnOffTimer - dt

                        if spec.turnOffTimer < 0 then
                            local rootAttacherVehicle = self:getRootVehicle()

                            if not rootAttacherVehicle.isControlled then
                                if self.getIsMotorStarted ~= nil then
                                    if self:getIsMotorStarted() then
                                        self:stopMotor()
                                    end
                                end

                                self:setIsTurnedOn(false)
                            end
                        end
                    end
                end
            end
        end
    end
end


---Called on turn on
-- @param boolean noEventSend no event send
function WoodCrusher:onTurnedOn()
    WoodCrusher.turnOnWoodCrusher(self, self.spec_woodCrusher)
end


---Called on turn off
-- @param boolean noEventSend no event send
function WoodCrusher:onTurnedOff()
    WoodCrusher.turnOffWoodCrusher(self, self.spec_woodCrusher)
end


---Returns if user is allowed to turn on the vehicle
-- @return boolean allow allow turn on
function WoodCrusher:getCanBeTurnedOn(superFunc)
    local spec = self.spec_woodCrusher
    if spec.turnOnAutomatically then
        return false
    end

    return superFunc(self)
end


---
function WoodCrusher:getConsumingLoad(superFunc)
    local value, count = superFunc(self)

    local spec = self.spec_woodCrusher
    if spec.crushingTime > 0 then
        value = value + 1
    end

    return value, count + 1
end


---
function WoodCrusher:getRequiresPower(superFunc)
    if self:getIsTurnedOn() then
        return true
    end

    return superFunc(self)
end


---Returns current dirt multiplier
-- @return float dirtMultiplier current dirt multiplier
function WoodCrusher:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)

    local spec = self.spec_woodCrusher
    if spec.crushingTime > 0 then
        multiplier = multiplier + self:getWorkDirtMultiplier()
    end

    return multiplier
end


---Returns current wear multiplier
-- @return float dirtMultiplier current wear multiplier
function WoodCrusher:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)

    local spec = self.spec_woodCrusher
    if spec.crushingTime > 0 then
        multiplier = multiplier + self:getWorkWearMultiplier()
    end

    return multiplier
end


---Called on crush split shape
-- @param table splitType split type
-- @param float volume volume
function WoodCrusher:onCrushedSplitShape(splitType, volume)
    local spec = self.spec_woodCrusher

    local damage = self:getVehicleDamage()
    if damage > 0 then
        volume = volume * (1 - damage * WoodCrusher.DAMAGED_YIELD_DECREASE)
    end

    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, volume * splitType.volumeToLiter * splitType.woodChipsPerLiter, FillType.WOODCHIPS, ToolType.UNDEFINED)
end


---Load wood crusher from xml file
-- @param table woodCrusher target wood crusher table
-- @param XMLFile xmlFile XMLFile instance
-- @param integer rootNode id of root node or list of components
-- @param table i3dMappings i3d mappings
function WoodCrusher.loadWoodCrusher(self, woodCrusher, xmlFile, rootNode, i3dMappings)
    woodCrusher.vehicle = self

    woodCrusher.woodCrusherSplitShapeCallback = WoodCrusher.woodCrusherSplitShapeCallback
    woodCrusher.woodCrusherMoveTriggerCallback = WoodCrusher.woodCrusherMoveTriggerCallback
    woodCrusher.woodCrusherDownForceTriggerCallback = WoodCrusher.woodCrusherDownForceTriggerCallback

    local xmlRoot = xmlFile:getRootName()
    local baseKey = xmlRoot .. ".woodCrusher"

    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusher.moveTrigger(0)#index", xmlRoot .. ".woodCrusher.moveTriggers.trigger#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusher.moveCollision(0)#index", xmlRoot .. ".woodCrusher.moveCollisions.collision#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusher.emitterShape(0)", xmlRoot .. ".woodCrusher.crushEffects with effectClass 'ParticleEffect'") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusherStartSound", xmlRoot .. ".woodCrusher.sounds.start") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusherIdleSound", xmlRoot .. ".woodCrusher.sounds.idle") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusherWorkSound", xmlRoot .. ".woodCrusher.sounds.work") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".woodCrusherStopSound", xmlRoot .. ".woodCrusher.sounds.stop") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".turnedOnRotationNodes.turnedOnRotationNode#type", xmlRoot .. ".woodCrusher.animationNodes.animationNode", "woodCrusher") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlRoot .. ".turnedOnScrollers.turnedOnScroller", xmlRoot .. ".woodCrusher.animationNodes.animationNode") --FS17 to FS19

    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#downForceNode", baseKey .. ".downForceNodes.downForceNode#node") --FS19 to FS22
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#downForce", baseKey .. ".downForceNodes.downForceNode#force") --FS19 to FS22
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#downForceSizeY", baseKey .. ".downForceNodes.downForceNode#sizeY") --FS19 to FS22
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#downForceSizeZ", baseKey .. ".downForceNodes.downForceNode#sizeZ") --FS19 to FS22

    woodCrusher.cutNode = xmlFile:getValue(baseKey .. "#cutNode", nil, rootNode, i3dMappings)
    woodCrusher.mainDrumRefNode = xmlFile:getValue(baseKey .. "#mainDrumRefNode", nil, rootNode, i3dMappings)
    woodCrusher.mainDrumRefNodeMaxY = xmlFile:getValue(baseKey .. "#mainDrumRefNodeMaxY", math.huge)

    if woodCrusher.mainDrumRefNode ~= nil then
        local mainDrumRefNodeParent = createTransformGroup("mainDrumRefNodeParent")
        link(getParent(woodCrusher.mainDrumRefNode), mainDrumRefNodeParent, getChildIndex(woodCrusher.mainDrumRefNode))
        setTranslation(mainDrumRefNodeParent, getTranslation(woodCrusher.mainDrumRefNode))
        setRotation(mainDrumRefNodeParent, getRotation(woodCrusher.mainDrumRefNode))
        link(mainDrumRefNodeParent, woodCrusher.mainDrumRefNode)
        setTranslation(woodCrusher.mainDrumRefNode, 0, 0, 0)
        setRotation(woodCrusher.mainDrumRefNode, 0, 0, 0)
    end

    woodCrusher.moveTriggers = {}
    local i = 0
    while true do
        local key = string.format("%s.moveTriggers.trigger(%d)", baseKey, i)
        if not xmlFile:hasProperty(key) then
            break
        end

        local node = xmlFile:getValue(key .. "#node", nil, rootNode, i3dMappings)
        if node ~= nil then
            if not CollisionFlag.getHasMaskFlagSet(node, CollisionFlag.TREE) then
                Logging.xmlWarning(self.xmlFile, "Missing collision filter mask %s. Please add this bit to move trigger node '%s' in '%s'", CollisionFlag.getBitAndName(CollisionFlag.TREE), getName(node), key)
                break
            end
            table.insert(woodCrusher.moveTriggers, node)
        end
        i = i + 1
    end

    woodCrusher.moveColNodes = {}
    i = 0
    while true do
        local key = string.format("%s.moveCollisions.collision(%d)", baseKey, i)
        if not xmlFile:hasProperty(key) then
            break
        end

        local moveColNode = {}
        moveColNode.node = xmlFile:getValue(key .. "#node", nil, rootNode, i3dMappings)
        if moveColNode.node ~= nil then
            moveColNode.transX, moveColNode.transY, moveColNode.transZ = getTranslation(moveColNode.node)
            table.insert(woodCrusher.moveColNodes, moveColNode)
        end
        i = i + 1
    end

    woodCrusher.moveVelocityZ = xmlFile:getValue(baseKey.."#moveVelocityZ", 0.8) -- m/s
    woodCrusher.moveMaxForce = xmlFile:getValue(baseKey.."#moveMaxForce", 7) -- input is kN
    woodCrusher.shapeSizeDetectionNode = xmlFile:getValue(baseKey.."#shapeSizeDetectionNode", nil, rootNode, i3dMappings)
    woodCrusher.cutSizeY = xmlFile:getValue(baseKey.."#cutSizeY", 1)
    woodCrusher.cutSizeZ = xmlFile:getValue(baseKey.."#cutSizeZ", 1)

    woodCrusher.downForceNodes = {}
    woodCrusher.downForceTriggers = {}
    xmlFile:iterate(baseKey .. ".downForceNodes.downForceNode", function(_, key)
        local downForceNode = {}
        downForceNode.node = xmlFile:getValue(key .. "#node", nil, rootNode, i3dMappings)
        if downForceNode.node ~= nil then
            downForceNode.force = xmlFile:getValue(key.."#force", 2)
            downForceNode.trigger = xmlFile:getValue(key .. "#trigger", nil, rootNode, i3dMappings)

            downForceNode.sizeY = xmlFile:getValue(key.."#sizeY", woodCrusher.cutSizeY)
            downForceNode.sizeZ = xmlFile:getValue(key.."#sizeZ", woodCrusher.cutSizeZ)

            downForceNode.woodCrusher = woodCrusher
            downForceNode.triggerNodes = {}

            if downForceNode.trigger ~= nil and woodCrusher.downForceTriggers[downForceNode.trigger] == nil then
                if self.isServer then
                    woodCrusher.downForceTriggers[downForceNode.trigger] = true
                    addTrigger(downForceNode.trigger, "woodCrusherDownForceTriggerCallback", woodCrusher)
                end
            end

            table.insert(woodCrusher.downForceNodes, downForceNode)
        end
    end)

    woodCrusher.moveTriggerNodes = {}
    if self.isServer and woodCrusher.moveTriggers ~= nil then
        for _,node in pairs(woodCrusher.moveTriggers) do
            addTrigger(node, "woodCrusherMoveTriggerCallback", woodCrusher)
        end
    end

    woodCrusher.crushNodes = {}
    woodCrusher.crushingTime = 0
    woodCrusher.turnOnAutomatically = xmlFile:getValue(baseKey .. "#automaticallyTurnOn", false)

    if self.isClient then
        woodCrusher.crushEffects = g_effectManager:loadEffect(xmlFile, baseKey..".crushEffects", rootNode, self, i3dMappings)

        woodCrusher.animationNodes = g_animationManager:loadAnimations(xmlFile, baseKey..".animationNodes", rootNode, self, i3dMappings)

        woodCrusher.isWorkSamplePlaying = false
        woodCrusher.samples = {}
        woodCrusher.samples.start = g_soundManager:loadSampleFromXML(xmlFile, baseKey..".sounds", "start", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, i3dMappings, self)
        woodCrusher.samples.stop  = g_soundManager:loadSampleFromXML(xmlFile, baseKey..".sounds", "stop", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, i3dMappings, self)
        woodCrusher.samples.work  = g_soundManager:loadSampleFromXML(xmlFile, baseKey..".sounds", "work", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, i3dMappings, self)
        woodCrusher.samples.idle  = g_soundManager:loadSampleFromXML(xmlFile, baseKey..".sounds", "idle", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, i3dMappings, self)
    end
end


---Delete wood crusher
function WoodCrusher.deleteWoodCrusher(self, woodCrusher)
    if woodCrusher.moveTriggers ~= nil then
        for _,node in pairs(woodCrusher.moveTriggers) do
            removeTrigger(node)
        end
    end

    if woodCrusher.downForceTriggers ~= nil then
        for trigger, _ in pairs(woodCrusher.downForceTriggers) do
            removeTrigger(trigger)
        end
    end

    g_effectManager:deleteEffects(woodCrusher.crushEffects)
    g_soundManager:deleteSamples(woodCrusher.samples)
    g_animationManager:deleteAnimations(woodCrusher.animationNodes)
end


---Update wood crusher
-- @param float dt time since last call in ms
function WoodCrusher.updateWoodCrusher(self, woodCrusher, dt, isTurnedOn)
    if isTurnedOn then
        if self.isServer then
            for node in pairs(woodCrusher.crushNodes) do
                WoodCrusher.crushSplitShape(self, woodCrusher, node)
                woodCrusher.crushNodes[node] = nil
                woodCrusher.moveTriggerNodes[node] = nil
            end

            local maxTreeSizeY = 0
            for id in pairs(woodCrusher.moveTriggerNodes) do
                if not entityExists(id) then
                    woodCrusher.moveTriggerNodes[id] = nil
                else
                    for i=1, #woodCrusher.downForceNodes do
                        local downForceNode = woodCrusher.downForceNodes[i]
                        if downForceNode.triggerNodes[id] ~= nil or downForceNode.trigger == nil then
                            local x, y, z = getWorldTranslation(downForceNode.node)
                            local nx, ny, nz = localDirectionToWorld(downForceNode.node, 1,0,0)
                            local yx, yy, yz = localDirectionToWorld(downForceNode.node, 0,1,0)

                            local minY,maxY, minZ,maxZ = testSplitShape(id, x,y,z, nx,ny,nz, yx,yy,yz, downForceNode.sizeY, downForceNode.sizeZ)
                            if minY ~= nil then
                                local cx,cy,cz = localToWorld(downForceNode.node, 0, (minY+maxY)*0.5, (minZ+maxZ)*0.5)
                                local downX,downY,downZ = localDirectionToWorld(downForceNode.node, 0, -downForceNode.force, 0)
                                addForce(id, downX, downY, downZ, cx,cy,cz, false)
                                --#debug drawDebugLine(cx, cy, cz, 1, 0, 0, cx+downX, cy+downY, cz+downZ, 0, 1, 0, true)
                            end
                        end
                    end

                    if woodCrusher.shapeSizeDetectionNode ~= nil then
                        local x, y, z = getWorldTranslation(woodCrusher.shapeSizeDetectionNode)
                        local nx, ny, nz = localDirectionToWorld(woodCrusher.shapeSizeDetectionNode, 1,0,0)
                        local yx, yy, yz = localDirectionToWorld(woodCrusher.shapeSizeDetectionNode, 0,1,0)

                        local minY, maxY, _, _ = testSplitShape(id, x, y, z, nx, ny, nz, yx, yy, yz, woodCrusher.cutSizeY, woodCrusher.cutSizeZ)
                        if minY ~= nil then
                            if woodCrusher.mainDrumRefNode ~= nil then
                                maxTreeSizeY = math.max(maxTreeSizeY, maxY)
                            end
                        end
                    end
                end
            end
            if woodCrusher.mainDrumRefNode ~= nil then
                local x, y, z = getTranslation(woodCrusher.mainDrumRefNode)
                local ty = math.min(maxTreeSizeY, woodCrusher.mainDrumRefNodeMaxY)
                if ty > y then
                    y = math.min(y + 0.0003*dt, ty)
                else
                    y = math.max(y - 0.0003*dt, ty)
                end

                setTranslation(woodCrusher.mainDrumRefNode, x, y, z)
            end

            if next(woodCrusher.moveTriggerNodes) ~= nil or woodCrusher.crushingTime > 0 then
                self:raiseActive()
            end
        end
    end
end


---Update tick wood crusher
-- @param float dt time since last call in ms
function WoodCrusher.updateTickWoodCrusher(self, woodCrusher, dt, isTurnedOn)
    if isTurnedOn then
        if self.isServer then
            if woodCrusher.cutNode ~= nil and next(woodCrusher.moveTriggerNodes) ~= nil then
                local x,y,z = getWorldTranslation(woodCrusher.cutNode)
                local nx,ny,nz = localDirectionToWorld(woodCrusher.cutNode, 1,0,0)
                local yx,yy,yz = localDirectionToWorld(woodCrusher.cutNode, 0,1,0)
                for id in pairs(woodCrusher.moveTriggerNodes) do
                    if entityExists(id) then
                        local lenBelow, lenAbove = getSplitShapePlaneExtents(id, x,y,z, nx,ny,nz)
                        if lenAbove ~= nil and lenBelow ~= nil then
                            if lenBelow <= 0.4 then
                                woodCrusher.moveTriggerNodes[id] = nil
                                WoodCrusher.crushSplitShape(self, woodCrusher, id)
                            elseif lenAbove >= 0.2 then
                                self.shapeBeingCut = id
                                local minY = splitShape(id, x,y,z, nx,ny,nz, yx,yy,yz, woodCrusher.cutSizeY, woodCrusher.cutSizeZ, "woodCrusherSplitShapeCallback", woodCrusher)
                                g_treePlantManager:removingSplitShape(id)
                                if minY ~= nil then
                                    woodCrusher.moveTriggerNodes[id] = nil
                                end
                            end
                        end
                    else
                        woodCrusher.moveTriggerNodes[id] = nil
                    end
                end
            end

            if self.isServer and woodCrusher.moveColNodes ~= nil then
                for _, moveColNode in pairs(woodCrusher.moveColNodes) do
                    setTranslation(moveColNode.node, moveColNode.transX, moveColNode.transY + math.random() * 0.005, moveColNode.transZ)
                end
            end
        end
    end

    if woodCrusher.crushingTime > 0 then
        woodCrusher.crushingTime = math.max(woodCrusher.crushingTime - dt, 0)
    end

    local isCrushing = woodCrusher.crushingTime > 0

    if self.isClient then
        if isCrushing then
            g_effectManager:setEffectTypeInfo(woodCrusher.crushEffects, FillType.WOODCHIPS)
            g_effectManager:startEffects(woodCrusher.crushEffects)
        else
            g_effectManager:stopEffects(woodCrusher.crushEffects)
        end

        if isTurnedOn and isCrushing then
            if not woodCrusher.isWorkSamplePlaying then
                g_soundManager:playSample(woodCrusher.samples.work)
                woodCrusher.isWorkSamplePlaying = true
            end
        else
            if woodCrusher.isWorkSamplePlaying then
                g_soundManager:stopSample(woodCrusher.samples.work)
                woodCrusher.isWorkSamplePlaying = false
            end
        end
    end
end


---Turn on wood crusher
function WoodCrusher.turnOnWoodCrusher(self, woodCrusher)
    if self.isServer and woodCrusher.moveColNodes ~= nil then
        for _, moveColNode in pairs(woodCrusher.moveColNodes) do
            setFrictionVelocity(moveColNode.node, woodCrusher.moveVelocityZ)
        end
    end

    if self.isClient then
        g_soundManager:stopSamples(woodCrusher.samples)
        woodCrusher.isWorkSamplePlaying = false
        g_soundManager:playSample(woodCrusher.samples.start)
        g_soundManager:playSample(woodCrusher.samples.idle, 0, woodCrusher.samples.start)

        if self.isClient then
            g_animationManager:startAnimations(woodCrusher.animationNodes)
        end
    end
end


---Turn off wood crusher
function WoodCrusher.turnOffWoodCrusher(self, woodCrusher)
    if self.isServer then
        for node in pairs(woodCrusher.crushNodes) do
            WoodCrusher.crushSplitShape(self, woodCrusher, node)
            woodCrusher.crushNodes[node] = nil
        end
        if woodCrusher.moveColNodes ~= nil then
            for _, moveColNode in pairs(woodCrusher.moveColNodes) do
                setFrictionVelocity(moveColNode.node, 0.0)
            end
        end
    end

    if self.isClient then
        g_effectManager:stopEffects(woodCrusher.crushEffects)
        g_soundManager:stopSamples(woodCrusher.samples)
        g_soundManager:playSample(woodCrusher.samples.stop)
        woodCrusher.isWorkSamplePlaying = false

        if self.isClient then
            g_animationManager:stopAnimations(woodCrusher.animationNodes)
        end
    end
end


---Crush split shape
-- @param integer shape id of shape
function WoodCrusher.crushSplitShape(self, woodCrusher, shape)
    local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(shape))
    if splitType ~= nil and splitType.woodChipsPerLiter > 0 then
        local volume = getVolume(shape)
        delete(shape)
        woodCrusher.crushingTime = 1000
        self:onCrushedSplitShape(splitType, volume)
    end
end


---Split shape callback
-- @param integer shape shape
-- @param boolean isBelow is below
-- @param boolean isAbove is above
-- @param float minY min y split position
-- @param float maxY max y split position
-- @param float minZ min z split position
-- @param float maxZ max z split position
function WoodCrusher.woodCrusherSplitShapeCallback(self, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    if not isBelow then
        self.crushNodes[shape] = shape
        g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
    end
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherActorId id of other actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
-- @param integer otherShapeId id of other shape
function WoodCrusher.woodCrusherMoveTriggerCallback(self, triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local vehicle = g_currentMission.nodeToObject[otherActorId]
    if vehicle == nil and getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC then
        local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherActorId))
        if splitType ~= nil and splitType.woodChipsPerLiter > 0 then
            if onEnter then
                self.moveTriggerNodes[otherActorId] = Utils.getNoNil(self.moveTriggerNodes[otherActorId],0)+1
                self.vehicle:raiseActive()
            elseif onLeave then
                local c = self.moveTriggerNodes[otherActorId]
                if c ~= nil then
                    c = c-1
                    if c == 0 then
                        self.moveTriggerNodes[otherActorId] = nil
                    else
                        self.moveTriggerNodes[otherActorId] = c
                    end
                end
            end
        end
    end
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherActorId id of other actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
-- @param integer otherShapeId id of other shape
function WoodCrusher.woodCrusherDownForceTriggerCallback(self, triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local vehicle = g_currentMission.nodeToObject[otherActorId]
    if vehicle == nil and getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC then
        local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherActorId))
        if splitType ~= nil and splitType.woodChipsPerLiter > 0 then
            for i=1, #self.downForceNodes do
                local downForceNode = self.downForceNodes[i]
                if downForceNode.trigger == triggerId then
                    if onEnter then
                        downForceNode.triggerNodes[otherActorId] = Utils.getNoNil(downForceNode.triggerNodes[otherActorId], 0) + 1
                        self.vehicle:raiseActive()
                    elseif onLeave then
                        local c = downForceNode.triggerNodes[otherActorId]
                        if c ~= nil then
                            c = c-1
                            if c == 0 then
                                downForceNode.triggerNodes[otherActorId] = nil
                            else
                                downForceNode.triggerNodes[otherActorId] = c
                            end
                        end
                    end
                end
            end
        end
    end
end
