














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableHusbandryLiquidManure.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableHusbandryLiquidManure.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryLiquidManure.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryLiquidManure.updateProduction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryLiquidManure.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryLiquidManure.getConditionInfos)
end


---
function PlaceableHusbandryLiquidManure.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryLiquidManure)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryLiquidManure)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryLiquidManure)
end


---
function PlaceableHusbandryLiquidManure.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.liquidManure"
    schema:register(XMLValueType.FLOAT, basePath .. ".manure#factor", "Factor to transform straw to manure", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".manure#active", "Enable manure production", true)
    schema:setXMLSpecializationType()
end


---
function PlaceableHusbandryLiquidManure:onLoad(savegame)
    local spec = self.spec_husbandryLiquidManure

    spec.litersPerHour = 0
    spec.fillType = FillType.LIQUIDMANURE
    spec.info = {title=g_i18n:getText("fillType_liquidManure"), text=""}
end


---
function PlaceableHusbandryLiquidManure:onFinalizePlacement()
    local spec = self.spec_husbandryLiquidManure
    if not self:getHusbandryIsFillTypeSupported(spec.fillType) then
        Logging.warning("Missing filltype 'liquidManure' in husbandry storage!")
    end
end


---
function PlaceableHusbandryLiquidManure:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    if self.isServer then
        local spec = self.spec_husbandryLiquidManure

        if spec.litersPerHour > 0 then
            local liters = foodFactor * spec.litersPerHour * g_currentMission.environment.timeAdjustment
            self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.fillType, nil, nil, nil)
        end
    end

    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end


---
function PlaceableHusbandryLiquidManure:updateProduction(superFunc, foodFactor)
    local factor = superFunc(self, foodFactor)

    if self.isServer then
        local spec = self.spec_husbandryLiquidManure
        local freeCapacity = self:getHusbandryFreeCapacity(spec.fillType)
        if freeCapacity <= 0 then
            factor = factor * 0.75
        end
    end

    return factor
end


---
function PlaceableHusbandryLiquidManure:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryLiquidManure

    spec.litersPerHour = 0
    for _, cluster in ipairs(clusters) do
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
        if subType ~= nil then
            local liquidManure = subType.output.liquidManure
            if liquidManure ~= nil then
                local age = cluster:getAge()
                local litersPerAnimal = liquidManure:get(age)
                local litersPerDay = litersPerAnimal * cluster:getNumAnimals()

                spec.litersPerHour = spec.litersPerHour + (litersPerDay / 24)
            end
        end
    end
end


---
function PlaceableHusbandryLiquidManure:getConditionInfos(superFunc)
    local infos = superFunc(self)
    local spec = self.spec_husbandryLiquidManure

    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillType)
    if fillType ~= nil then
        local info = {}
        info.title = fillType.title
        info.value = self:getHusbandryFillLevel(spec.fillType)
        local capacity = self:getHusbandryCapacity(spec.fillType)
        local ratio = 1
        if capacity > 0 then
            ratio = info.value / capacity
        else
            info.disabled = true
            info.title = string.format("%s (%s)", info.title, g_i18n:getText("info_husbandryMissingLiquidManureTank"))
        end
        info.ratio = math.clamp(ratio, 0, 1)
        info.invertedBar = true

        table.insert(infos, info)
    end

    return infos
end


---
function PlaceableHusbandryLiquidManure:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryLiquidManure

    local fillLevel = self:getHusbandryFillLevel(spec.fillType)
    spec.info.text = string.format("%d l", fillLevel)
    table.insert(infoTable, spec.info)
end
