







































---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AIFieldWorker.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIJobVehicle, specializations)
       and SpecializationUtil.hasSpecialization(Drivable, specializations)
end


























































































































































---
function AIFieldWorker:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_aiFieldWorker
    if spec.isActive ~= nil then
        xmlFile:setValue(key .. "#isActive", spec.isActive)
    end

    if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
        spec.reconstructionData = {}
        for i, strategy in ipairs(spec.driveStrategies) do
            if strategy.fillReconstructionData ~= nil then
                strategy:fillReconstructionData(spec.reconstructionData)
            end
        end
    end

    for strategyIndex, strategyData in ipairs(AIFieldWorker.registeredDriveStrategies) do
        if strategyData.class.saveToXML ~= nil then
            strategyData.class.saveToXML(spec.reconstructionData, xmlFile, key)
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function AIFieldWorker:onReadStream(streamId, connection)
    if streamReadBool(streamId) then
        self:startFieldWorker()
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function AIFieldWorker:onWriteStream(streamId, connection)
    local spec = self.spec_aiFieldWorker
    streamWriteBool(streamId, spec.isActive)
end










































































---
-- @param float dt time since last call in ms
function AIFieldWorker:updateAIFieldWorker(dt)
    local spec = self.spec_aiFieldWorker

    self:clearAIDebugTexts()
    self:clearAIDebugLines()

    if self:getIsFieldWorkActive() then
        if #spec.driveStrategies > 0 then
            local vX,vY,vZ = getWorldTranslation(self:getAISteeringNode())

            local tX, tZ, moveForwards, maxSpeedStra, maxSpeed, distanceToStop
            for _, driveStrategy in ipairs(spec.driveStrategies) do
                tX, tZ, moveForwards, maxSpeedStra, distanceToStop = driveStrategy:getDriveData(dt, vX,vY,vZ)
                maxSpeed = math.min(maxSpeedStra or math.huge, maxSpeed or math.huge)
                if tX ~= nil or not self:getIsFieldWorkActive() then
                    break
                end
            end

            if tX == nil or MathUtil.isNan(tX) or MathUtil.isNan(tZ) then
                if self:getIsFieldWorkActive() then -- check if AI is still active, because it might have been kicked by a strategy
                    self:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
                end
            end

            if not self:getIsFieldWorkActive() then
                return
            end

            local minimumSpeed = 5
            local lookAheadDistance = 5

            -- use different settings while turning
            -- so we are more pricise when stopping at end point in small turning segments
            if self:getAIFieldWorkerIsTurning() then
                minimumSpeed = 1.5
                lookAheadDistance = 2
            end

            local distSpeed = math.max(minimumSpeed, maxSpeed * math.min(1, distanceToStop/lookAheadDistance))
            local speedLimit, _ = self:getSpeedLimit(true)
            maxSpeed = math.min(maxSpeed, distSpeed, speedLimit)
            maxSpeed = math.min(maxSpeed, self:getCruiseControlMaxSpeed())

            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                self:addAIDebugText(string.format("===> maxSpeed = %.2f", maxSpeed))
            end

            -- set drive values
            spec.aiDriveParams.moveForwards = moveForwards
            spec.aiDriveParams.tX = tX
            spec.aiDriveParams.tY = vY
            spec.aiDriveParams.tZ = tZ
            spec.aiDriveParams.maxSpeed = maxSpeed
            spec.aiDriveParams.valid = true
        end

        if spec.aiDriveParams.valid then
            local moveForwards = spec.aiDriveParams.moveForwards
            local tX = spec.aiDriveParams.tX
            local tY = spec.aiDriveParams.tY
            local tZ = spec.aiDriveParams.tZ
            local maxSpeed = spec.aiDriveParams.maxSpeed

            local pX, _, pZ
            if moveForwards then
                pX, _, pZ = worldToLocal(self:getAISteeringNode(), tX, tY, tZ)
            else
                pX, _, pZ = worldToLocal(self:getAIReverserNode(), tX, tY, tZ)
            end

            local acceleration = 1.0
            local isAllowedToDrive = maxSpeed ~= 0

            AIVehicleUtil.driveToPoint(self, dt, acceleration, isAllowedToDrive, moveForwards, pX, pZ, maxSpeed)
        end

        self:raiseAIEvent("onAIFieldWorkerActive", "onAIImplementActive")
    end
end
















































































































































































---Set drive strategies depending on the vehicle
function AIFieldWorker:updateAIFieldWorkerDriveStrategies()
    local spec = self.spec_aiFieldWorker

    if #spec.aiImplementList > 0 then
        if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
            for i=#spec.driveStrategies, 1, -1 do
                spec.driveStrategies[i]:delete()
                table.remove(spec.driveStrategies, i)
            end
            spec.driveStrategies = {}
        end

        for strategyIndex, strategyData in ipairs(AIFieldWorker.registeredDriveStrategies) do
            for _, childVehicle in pairs(self.rootVehicle.childVehicles) do -- using all vehicles since the combine can also be standalone without cutter - so no ai implement
                if strategyData.func(childVehicle) then
                    table.insert(spec.driveStrategies, strategyData.class.new(spec.reconstructionData))
                    break
                end
            end
        end

        for i=1, #spec.driveStrategies do
            spec.driveStrategies[i]:setAIVehicle(self)
        end
    end
end





















































---
function AIFieldWorker:aiContinue(superFunc)
    superFunc(self)

    local spec = self.spec_aiFieldWorker
    if spec.isActive and not spec.isTurning then
        self:raiseAIEvent("onAIFieldWorkerContinue", "onAIImplementContinue")
    end

    spec.isBlocked = false
end
