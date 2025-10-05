







---Base Class for placeables
-- 
-- Note about terrain modification on placement:
-- If terrain modification is enabled using the placeable.leveling#requireLeveling attribute, the configuration needs
-- at least one leveling area to be defined (ramps are optional). These areas represent parallelograms which are passed
-- to terrain modification functions. They are defined by start, width and height nodes which in this case should be
-- set up to form rectangular shapes. For the best results, create a new transform group for each area at the starting
-- positions and add separate nodes for the three defining points in the placeable object I3D file.
-- 
local Placeable_mt = Class(Placeable, Object)














































---
function Placeable.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onPreLoad")
    SpecializationUtil.registerEvent(placeableType, "onLoad")
    SpecializationUtil.registerEvent(placeableType, "onPostLoad")
    SpecializationUtil.registerEvent(placeableType, "onPreLoadFinished")
    SpecializationUtil.registerEvent(placeableType, "onLoadFinished")
    SpecializationUtil.registerEvent(placeableType, "onRegistered")
    SpecializationUtil.registerEvent(placeableType, "onPreDelete")
    SpecializationUtil.registerEvent(placeableType, "onDelete")
    SpecializationUtil.registerEvent(placeableType, "onSave")
    SpecializationUtil.registerEvent(placeableType, "onReadStream")
    SpecializationUtil.registerEvent(placeableType, "onWriteStream")
    SpecializationUtil.registerEvent(placeableType, "onReadUpdateStream")
    SpecializationUtil.registerEvent(placeableType, "onWriteUpdateStream")
    SpecializationUtil.registerEvent(placeableType, "onDirtyMaskCleared")
    SpecializationUtil.registerEvent(placeableType, "onPreFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onPostFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onUpdate")
    SpecializationUtil.registerEvent(placeableType, "onUpdateTick")
    SpecializationUtil.registerEvent(placeableType, "onDraw")
    SpecializationUtil.registerEvent(placeableType, "onHourChanged")
    SpecializationUtil.registerEvent(placeableType, "onMinuteChanged")
    SpecializationUtil.registerEvent(placeableType, "onDayChanged")
    SpecializationUtil.registerEvent(placeableType, "onPeriodChanged")
    SpecializationUtil.registerEvent(placeableType, "onWeatherChanged")
    SpecializationUtil.registerEvent(placeableType, "onFarmlandStateChanged")
    SpecializationUtil.registerEvent(placeableType, "onBuy")
    SpecializationUtil.registerEvent(placeableType, "onSell")
    SpecializationUtil.registerEvent(placeableType, "onOwnerChanged")
end


---
function Placeable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "register", Placeable.register)
    SpecializationUtil.registerFunction(placeableType, "getPosition", Placeable.getPosition)
    SpecializationUtil.registerFunction(placeableType, "getIsOnFarmland", Placeable.getIsOnFarmland)
    SpecializationUtil.registerFunction(placeableType, "getFarmlandId", Placeable.getFarmlandId)
    SpecializationUtil.registerFunction(placeableType, "setPose", Placeable.setPose)
    SpecializationUtil.registerFunction(placeableType, "setOwnerFarmId", Placeable.setOwnerFarmId)
    SpecializationUtil.registerFunction(placeableType, "setLoadingStep", Placeable.setLoadingStep)
    SpecializationUtil.registerFunction(placeableType, "setLoadingState", Placeable.setLoadingState)
    SpecializationUtil.registerFunction(placeableType, "addToPhysics", Placeable.addToPhysics)
    SpecializationUtil.registerFunction(placeableType, "removeFromPhysics", Placeable.removeFromPhysics)
    SpecializationUtil.registerFunction(placeableType, "collectPickObjects", Placeable.collectPickObjects)
    SpecializationUtil.registerFunction(placeableType, "getNeedWeatherChanged", Placeable.getNeedWeatherChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedHourChanged", Placeable.getNeedHourChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedMinuteChanged", Placeable.getNeedMinuteChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedDayChanged", Placeable.getNeedDayChanged)
    SpecializationUtil.registerFunction(placeableType, "getName", Placeable.getName)
    SpecializationUtil.registerFunction(placeableType, "getImageFilename", Placeable.getImageFilename)
    SpecializationUtil.registerFunction(placeableType, "getCanBeRenamedByFarm", Placeable.getCanBeRenamedByFarm)
    SpecializationUtil.registerFunction(placeableType, "setName", Placeable.setName)
    SpecializationUtil.registerFunction(placeableType, "getPrice", Placeable.getPrice)
    SpecializationUtil.registerFunction(placeableType, "canBuy", Placeable.canBuy)
    SpecializationUtil.registerFunction(placeableType, "getCanBePlacedAt", Placeable.getCanBePlacedAt)
    SpecializationUtil.registerFunction(placeableType, "canBeSold", Placeable.canBeSold)
    SpecializationUtil.registerFunction(placeableType, "getDestructionMethod", Placeable.getDestructionMethod)
    SpecializationUtil.registerFunction(placeableType, "previewNodeDestructionNodes", Placeable.previewNodeDestructionNodes)
    SpecializationUtil.registerFunction(placeableType, "performNodeDestruction", Placeable.performNodeDestruction)
    SpecializationUtil.registerFunction(placeableType, "updateOwnership", Placeable.updateOwnership)
    SpecializationUtil.registerFunction(placeableType, "setOverlayColor", Placeable.setOverlayColor)
    SpecializationUtil.registerFunction(placeableType, "setOverlayColorNodes", Placeable.setOverlayColorNodes)
    SpecializationUtil.registerFunction(placeableType, "getDailyUpkeep", Placeable.getDailyUpkeep)
    SpecializationUtil.registerFunction(placeableType, "getSellPrice", Placeable.getSellPrice)
    SpecializationUtil.registerFunction(placeableType, "setPreviewPosition", Placeable.setPreviewPosition)
    SpecializationUtil.registerFunction(placeableType, "setPropertyState", Placeable.setPropertyState)
    SpecializationUtil.registerFunction(placeableType, "getPropertyState", Placeable.getPropertyState)
    SpecializationUtil.registerFunction(placeableType, "setVisibility", Placeable.setVisibility)
    SpecializationUtil.registerFunction(placeableType, "getIsSynchronized", Placeable.getIsSynchronized)
    SpecializationUtil.registerFunction(placeableType, "getIsPreplaced", Placeable.getIsPreplaced)
end


---
function Placeable.init()
    local schema = Placeable.xmlSchema

    local basePath = "placeable"
    schema:register(XMLValueType.STRING, basePath .. "#type", "Placeable type", nil, true)
    schema:registerAutoCompletionDataSource(basePath .. "#type", "$dataS/placeableTypes.xml", "placeableTypes.type#name")
    schema:register(XMLValueType.STRING, basePath .. ".annotation", "Annotation", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".base.filename", "Placeable i3d file", nil, true)
    schema:register(XMLValueType.BOOL,   basePath .. ".base.canBeRenamed", "Placeable can be renamed by player", false)
    schema:register(XMLValueType.BOOL,   basePath .. ".base.boughtWithFarmland", "Placeable is bough with farmland", false)
    schema:register(XMLValueType.BOOL,   basePath .. ".base.buysFarmland", "Placeable buys farmland it is placed on", false)
    schema:register(XMLValueType.FLOAT,  basePath .. ".base.buysFarmland#priceScale", "Price scale for the farmland price", 1)
    schema:register(XMLValueType.BOOL,   basePath .. ".base.canBeDeleted", "Placeable can be deleted by the player, set to false if it should be set farm 0 on sell instead", true)
    StoreManager.registerStoreDataXMLPaths(schema, basePath)
    I3DUtil.registerI3dMappingXMLPaths(schema, basePath)


    local savegameSchema = Placeable.xmlSchemaSavegame
    local basePathSavegame = "placeables.placeable(?)"
    savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#isDeleted", "If the preplaced placeable is deleted in the savegame")
    savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#isPreplaced", "If the placeable is preplaced in the map")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#uniqueId", "Placeable's unique id")
    savegameSchema:register(XMLValueType.BOOL, "placeables#loadAnyFarmInSingleplayer", "Load any farm in singleplayer. Causes any placeable with any farmId to be loaded.", false)
    savegameSchema:register(XMLValueType.INT, "placeables#version", "Version of map placeables file")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#name", "Custom name set by player to be used instead of store item name")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#nameL10nKey", "custom l10n key for name set in preplaced/default placeables xml")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. ".customImage#filename", "Path to a custom image file")
    savegameSchema:register(XMLValueType.VECTOR_TRANS, basePathSavegame .. "#position", "Position")
    savegameSchema:register(XMLValueType.VECTOR_ROT, basePathSavegame .. "#rotation", "Rotation")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#filename", "Path to xml filename")
    savegameSchema:register(XMLValueType.FLOAT, basePathSavegame .. "#age", "Age of placeable in months.", 0)
    savegameSchema:register(XMLValueType.FLOAT, basePathSavegame .. "#price", "Price of placeable")
    savegameSchema:register(XMLValueType.INT, basePathSavegame .. "#farmId", "Owner farmland", 0)
    savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#defaultFarmProperty", "Is property of default farm. Causes object to be removed on non-starter games.", false)
    savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#canBeDeletedOverwrite", "Placeable can be deleted", false)
    savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#boughtWithFarmlandOverwrite", "Placeable is bought with farmland overwritten by savegame", false)
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#modName", "Name of mod")
    savegameSchema:register(XMLValueType.INT, basePathSavegame .. "#sinceVersion", "Version of xml file when this placeable was added. Will cause placeable to appear on older, existing saves")
    savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#tourId", "Tour id")


    for name, spec in pairs(g_placeableSpecializationManager:getSpecializations()) do
        local classObj = ClassUtil.getClassObject(spec.className)
        if classObj ~= nil then
            if rawget(classObj, "registerXMLPaths") then
                classObj.registerXMLPaths(schema, basePath)
            end

            if rawget(classObj, "registerSavegameXMLPaths") then
                classObj.registerSavegameXMLPaths(savegameSchema, basePathSavegame .. "." .. name)
            end
        end
    end

    g_storeManager:addSpecType("placeableSlots", "shopListAttributeIconSlots", nil, Placeable.getSpecValueSlots, StoreSpecies.PLACEABLE)

    g_placeableConfigurationManager:addConfigurationType("color", g_i18n:getText("configuration_color"), nil, PlaceableConfigurationItemColor)
end


---
function Placeable.postInit()
    local schema = Placeable.xmlSchema
    local schemaSavegame = Placeable.xmlSchemaSavegame

    local configurations = g_placeableConfigurationManager:getConfigurations()
    for _, configuration in pairs(configurations) do
        if configuration.itemClass.registerXMLPaths ~= nil then
            configuration.itemClass.registerXMLPaths(schema, configuration.configurationsKey, configuration.configurationKey .. "(?)")
        end

        if configuration.itemClass.registerSavegameXMLPaths ~= nil then
            configuration.itemClass.registerSavegameXMLPaths(schemaSavegame, "placeables.placeable(?).configuration(?)")

            -- for backward compatibility
            configuration.itemClass.registerSavegameXMLPaths(schemaSavegame, "placeables.placeable(?).boughtConfiguration(?)")
        end
    end
end


---
function Placeable.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or Placeable_mt)

    self.finishedLoading = false

    self.rootNode = nil

    self.loadingState = PlaceableLoadingState.OK
    self.loadingStep = SpecializationLoadStep.CREATED

    self.isDeleting = false
    self.isDeleted = false
    self.isLoadedFromSavegame = false

    self.loadingTasks = {}
    self.readyForFinishLoading = false

    self.propertyState = PlaceablePropertyState.OWNED

    self.age = 0
    self.price = 0
    self.pickObjects = {}

    self.undoTimer = 0

    -- The unique id of placeable used to reference it from elsewhere.
    self.uniqueId = nil

    return self
end


---
function Placeable:setFilename(filename)
    self.configFileName = filename
    self.configFileNameClean = Utils.getFilenameInfo(filename, true)

    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(filename)
end


---
function Placeable:setConfigurations(configurations, boughtConfigurations, configurationData)
    self.configurations, self.boughtConfigurations = configurations, boughtConfigurations

    self.configurationData = configurationData or self.configurationData
    if self.configurationData == nil then
        self.configurationData = {}
    end

    self.sortedConfigurationNames = {}
    for configName, _ in pairs(self.configurations) do
        table.insert(self.sortedConfigurationNames, configName)
    end

    table.sort(self.sortedConfigurationNames, function(a, b)
        return a < b
    end)
end


---
function Placeable:setType(typeDef)
    assertWithCallstack(self.configFileName ~= nil, "Setting placeable type without setting a filename previously. Call 'setFilename' first!")

    if self.configurations ~= nil then
        local configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "placeableType", self.configurations["placeableType"])
        if configItem ~= nil then
            if configItem.placeableType ~= nil then
                local configType = g_placeableTypeManager:getTypeByName(configItem.placeableType, self.customEnvironment)
                if configType ~= nil then
                    typeDef = configType
                else
                   Logging.warning("Unknown placeable type '%s' in configuration for '%s'", configItem.placeableType, self.configFileName)
                end
            end
        end
    end

    SpecializationUtil.initSpecializationsIntoTypeClass(g_placeableTypeManager, typeDef, self)
end


---
function Placeable:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
    self.loadCallbackFunction = loadCallbackFunction
    self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
    self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end


---
function Placeable:loadCallback()
    if self.loadCallbackFunction ~= nil then
        self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
        self.loadCallbackFunctionTarget = nil
        self.loadCallbackFunctionArguments = nil
    end
end


---
function Placeable:load(placeableLoadingData)
    self.placeableLoadingData = placeableLoadingData

    local placeableSystem = g_currentMission.placeableSystem

    self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)

    if self.type == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find placeableType '%s'", self.typeName)
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return self.loadingState
    end

    self.xmlFile = XMLFile.load("placeableXml", self.configFileName, Placeable.xmlSchema)
    self.savegame = placeableLoadingData.savegameData

    self.storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if self.storeItem ~= nil then
        self.brand = g_brandManager:getBrandByIndex(self.storeItem.brandIndex)
        self.lifetime = self.storeItem.lifetime
    end

    -- pass function pointers from specializations to 'self'
    SpecializationUtil.copyTypeFunctionsInto(self.type, self)

    -- check if one of the configurations is not set - e.g. if new configurations are available but not in savegame
    local item = g_storeManager:getItemByXMLFilename(self.configFileName)
    if item ~= nil and item.configurations ~= nil then
        -- check if the loaded configurations do match the configuration sets
        -- if not we apply the set which has the most common configurations
        -- e.g. if a new configuration was added to the configuration set we make sure we don't break old savegames
        if item.configurationSets ~= nil and #item.configurationSets > 0 then
            if not ConfigurationUtil.getConfigurationsMatchConfigSets(self.configurations, item.configurationSets) then
                local closestSet, closestSetMatches = ConfigurationUtil.getClosestConfigurationSet(self.configurations, item.configurationSets)
                if closestSet ~= nil then
                    for configName, index in pairs(closestSet.configurations) do
                        self.configurations[configName] = index
                    end

                    Logging.xmlInfo(self.xmlFile, "Savegame configurations do not match the configuration sets! Apply closest configuration set '%s' with %d matching configurations.", closestSet.name, closestSetMatches)
                end
            end
        end

        for configName, _ in pairs(item.configurations) do
            local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)
            if self.configurations[configName] == nil then
                ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
            end
            -- base configuration is always included
            ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, configName, defaultConfigId)
        end
        -- check if currently used configurations are still available
        for configName, value in pairs(self.configurations) do
            if item.configurations[configName] == nil then
                Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", configName)
                self.configurations[configName] = nil
                self.boughtConfigurations[configName] = nil
            else
                local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)
                if #item.configurations[configName] < value then
                    Logging.xmlWarning(self.xmlFile, "Configuration with index '%d' is not present anymore. Using default configuration instead!", value)

                    if self.boughtConfigurations[configName] ~= nil then
                        self.boughtConfigurations[configName][value] = nil
                        if next(self.boughtConfigurations[configName]) == nil then
                            self.boughtConfigurations[configName] = nil
                        end
                    end
                    ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
                else
                    ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, configName, value)
                end
            end
        end
    end

    SpecializationUtil.createSpecializationEnvironments(self, function(specName, specEntryName)
        Logging.xmlError(self.xmlFile, "The placeable specialization '%s' could not be added because variable '%s' already exists!", specName, specEntryName)
        self:setLoadingState(PlaceableLoadingState.ERROR)
    end)

    SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
    if self.loadingState ~= PlaceableLoadingState.OK then
        Logging.xmlError(self.xmlFile, "Placeable pre-loading failed!")
        self.xmlFile:delete()
        return false
    end

    ConfigurationUtil.raiseConfigurationItemEvent(self, "onPreLoad")

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.filename", "placeable.base.filename")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.dayNightObjects", "Visibility Condition-Tab in GIANTS Editor / Exporter")

    self.preplacedIndex = placeableLoadingData:getPreplacedIndex()
    self.isPreplaced = self.preplacedIndex ~= nil
    self.customImageFilename = nil

    self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("placeable.base.filename"), self.baseDirectory)

    if self.isPreplaced then
        self.i3dFilename = placeableLoadingData.customI3DFilename or self.i3dFilename
    end

    if self.i3dFilename ~= nil and string.contains(self.i3dFilename, "\\") then
        Logging.xmlWarning(self.xmlFile, "Filename contains backslashes, which are not allowed! (%s)", "placeable.base.filename")
    end

    self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)

    if self.isPreplaced then
        local preplacedNode = placeableSystem:getPreplacedNodeByIndex(self.preplacedIndex)
        if preplacedNode == nil then
            Logging.xmlError(self.xmlFile, "Placeable loading failed. Preplaced node not defined!")
            self.xmlFile:delete()
            return false
        end

        self:i3dFileLoaded(preplacedNode, LoadI3DFailedReason.NONE, nil, nil)

    else
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
    end

    return true
end


---
function Placeable:i3dFileLoaded(i3dNode, failedReason, args, i3dLoadingId)
    if i3dNode == 0 then
        self:setLoadingState(PlaceableLoadingState.ERROR)
        Logging.xmlError(self.xmlFile, "Placeable i3d loading failed!")
        self:loadCallback()
        return
    end

    self.i3dNode = i3dNode
    self.rootNode = self.i3dNode

    if self.isDeleted then
        self:setLoadingState(PlaceableLoadingState.CANCELED)
        self:loadCallback()
        return
    end

    g_asyncTaskManager:addTask(function()
        self:loadFinished()
    end)
end

























































































































---
function Placeable:onFinishedLoading()
    if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        -- change all terrain decals to regular decals while in placement preview to avoid issues with virtual texture
        I3DUtil.iterateRecursively(self.rootNode, function(node)
            if getHasClassId(node, ClassIds.SHAPE) and getIsTerrainDecal(node) then
                setIsTerrainDecal(node, false)
                setIsNonRenderable(node, false)
--              TODO: missing setRenderedInViewports in binding
            end
        end)
    end

    self:setVisibility(true)

    if self.isServer and self.savegame ~= nil then
        if getXMLString(self.savegame.xmlFile.handle, self.savegame.key .. "#mapBoundId") ~= nil then
            Logging.xmlWarning(self.savegame.xmlFile, "Attribute 'mapBoundId' is not supported anymore for '%s'. Use 'isPreplaced' and 'uniqueId' instead!", self.savegame.key)
        end

        self.isLoadingFromSavegameXML = true
        for id, spec in pairs(self.specializations) do
            local name = self.specializationNames[id]

            if spec.loadFromXMLFile ~= nil then
                spec.loadFromXMLFile(self, self.savegame.xmlFile, self.savegame.key.."."..name, self.savegame.reset)
            end
        end
        self.isLoadingFromSavegameXML = false

        local boughtWithFarmlandSavegameOverwrite = self.savegame.xmlFile:getValue(self.savegame.key .. "#boughtWithFarmlandOverwrite")
        if boughtWithFarmlandSavegameOverwrite ~= nil then
            self.boughtWithFarmlandSavegameOverwrite = boughtWithFarmlandSavegameOverwrite
        end

        local canBeDeletedOverwrite = self.savegame.xmlFile:getValue(self.savegame.key .. "#canBeDeletedOverwrite")
        if canBeDeletedOverwrite ~= nil then
            self.canBeDeletedOverwrite = canBeDeletedOverwrite
        end

        local customImageFilename = self.savegame.xmlFile:getValue(self.savegame.key .. ".customImage#filename")
        if customImageFilename ~= nil then
            self.customImageFilename = NetworkUtil.convertFromNetworkFilename(customImageFilename)
--#debug             if not textureFileExists(self.customImageFilename) then
--#debug                 Logging.xmlWarning(self.savegame.xmlFile, "custom image '%s' defined for '%s' does not exist", customImageFilename, self.savegame.key)
--#debug             end
        end

        -- custom name set by player
        self.nameCustom = self.savegame.xmlFile:getValue(self.savegame.key .. "#name")

        -- custom l10n key set by mapper
        local nameL10nKey = self.savegame.xmlFile:getValue(self.savegame.key .. "#nameL10nKey")
        if nameL10nKey ~= nil then
            self:setNameL10nKey(nameL10nKey)
        end

        self.age = self.savegame.xmlFile:getValue(self.savegame.key.."#age", 0)
        self.price = self.savegame.xmlFile:getValue(self.savegame.key.."#price", self.price)

        if not self.savegame.ignoreFarmId then
            -- Use a call so any sub-objects of the placeable can be updated
            self:setOwnerFarmId(self.savegame.xmlFile:getValue(self.savegame.key .. "#farmId", AccessHandler.EVERYONE), true)
        end

        self.isLoadedFromSavegame = true
    end

    self:setLoadingStep(SpecializationLoadStep.FINISHED)
    SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)

    if self.isLoadedFromSavegame then
        self:finalizePlacement()
    end

    -- if we are the server or in single player we don't need to be synchronized
    if self.isServer then
        self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    end

    self.finishedLoading = true

    if self.placeableLoadingData.isRegistered then
        self:register()
    end

    self:loadCallback()

    self.savegame = nil
end


---
function Placeable:onLoadingError(msg, ...)
    if self.xmlFile ~= nil then
        Logging.xmlError(self.xmlFile, msg, ...)
        self.xmlFile:delete()
        self.xmlFile = nil
    else
        Logging.error(msg, ...)
    end

    self:setLoadingState(PlaceableLoadingState.ERROR)
    self:loadCallback()
end


---Creates a loading task in the loadingTasks table with the given target and returns it.
-- @param any target The id or reference used to track the loading task.
-- @return table task The created loading task.
function Placeable:createLoadingTask(target)
    return SpecializationUtil.createLoadingTask(self, target)
end


---Marks the given task as done, and calls onFinishedLoading, if readyForFinishLoading is true.
-- @param table task The task to mark as complete. Should be obtained from createLoadingTask.
function Placeable:finishLoadingTask(task)
    SpecializationUtil.finishLoadingTask(self, task)
end


---Called if placeable is placed
function Placeable:finalizePlacement()
    SpecializationUtil.raiseEvent(self, "onPreFinalizePlacement")

    self:addToPhysics()

    local placeableSystem = g_currentMission.placeableSystem
    placeableSystem:addPlaceable(self)
    if self.isPreplaced then
        placeableSystem:addPreplacedPlaceable(self)
    end
    g_currentMission:addOwnedItem(self)

    self:collectPickObjects(self.rootNode)
    for _, node in pairs(self.pickObjects) do
        g_currentMission:addNodeObject(node, self)
    end

    if (self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland) or self.boughtWithFarmlandSavegameOverwrite then
        if self.isServer then
            self:updateOwnership()
        end

        g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    end
    SpecializationUtil.raiseEvent(self, "onFinalizePlacement")

    SpecializationUtil.raiseEvent(self, "onPostFinalizePlacement")

    if self:getNeedWeatherChanged() then
        g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.weatherChanged, self)
    end
    if self:getNeedHourChanged() then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end
    if self:getNeedMinuteChanged() then
        g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
    end
    if self:getNeedDayChanged() then
        g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
    end
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)

    g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
end



---Deleting placeable
function Placeable:delete(immediate)
    self.markedForDeletion = true

    if not g_currentMission.isExitingGame then
        if not immediate then
            g_currentMission.placeableSystem:markPlaceableForDeletion(self)
            return
        end
    end

    if self.isDeleted then
        Logging.devError("Trying to delete a already deleted placeable")
        printCallstack()
        return
    end

    g_messageCenter:unsubscribeAll(self)

    if self.tourId ~= nil then
        g_guidedTourManager:removePlaceable(self.tourId)
    end

    self.isDeleting = true
    SpecializationUtil.raiseEvent(self, "onPreDelete")

    local placeableSystem = g_currentMission.placeableSystem
    placeableSystem:removePlaceable(self)

    g_currentMission:removeOwnedItem(self)

    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end

    for _, node in pairs(self.pickObjects) do
        g_currentMission:removeNodeObject(node)
    end

    SpecializationUtil.raiseEvent(self, "onDelete")

    if not self.isPreplaced then
        if self.rootNode ~= nil then
--             Logging.devWarning("Deleting placeable '%s'. Rootnode: '%d', IsPreplaced: '%s'", self.configFileName, self.rootNode, self.isPreplaced)
            delete(self.rootNode)
            self.rootNode = nil
        end
    end

    if self.isPreplaced then
        placeableSystem:removePreplacedPlaceable(self)
    end

    if self.xmlFile ~= nil then
        self.xmlFile:delete()
        self.xmlFile = nil
    end

    self.isDeleting = false
    self.isDeleted = true

    Placeable:superClass().delete(self)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Placeable:readStream(streamId, connection, objectId)
    Placeable:superClass().readStream(self, streamId, connection, objectId)

    local data = PlaceableLoadingData.new()

    local filename
    local isPreplaced = streamReadBool(streamId)
    if isPreplaced then
        local preplacedIndex = streamReadUInt16(streamId)
        local placeableSystem = g_currentMission.placeableSystem
        filename = placeableSystem:getPreplacedFilenameByIndex(preplacedIndex)
        local uniqueId = placeableSystem:getPreplacedUniqueIdByIndex(preplacedIndex)

        data:setPreplacedIndex(preplacedIndex)
        data:setFilename(filename)
        data:setUniqueId(uniqueId)
    else
        filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        local posX = streamReadFloat32(streamId)
        local posY = streamReadFloat32(streamId)
        local posZ = streamReadFloat32(streamId)
        local rotX = streamReadFloat32(streamId)
        local rotY = streamReadFloat32(streamId)
        local rotZ = streamReadFloat32(streamId)

        data:setFilename(filename)
        data:setPosition(posX, posY, posZ)
        data:setRotation(rotX, rotY, rotZ)
    end

    local configurations, boughtConfigurations, configurationData = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, filename)

    self.propertyState = PlaceablePropertyState.readStream(streamId)
    data:setPropertyState(self.propertyState)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setConfigurations(configurations)
    data:setBoughtConfigurations(boughtConfigurations)
    data:setConfigurationData(configurationData)

    local asyncCallbackFunction = function(_, placeable, loadingState)
        if loadingState == PlaceableLoadingState.OK then
            g_client:onObjectFinishedAsyncLoading(placeable)
        else
            Logging.error("Failed to load placeable on client")
            printCallstack()
        end
    end

    data:loadPlaceableOnClient(self, asyncCallbackFunction, nil)
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Placeable:writeStream(streamId, connection)
    Placeable:superClass().writeStream(self, streamId, connection)

    if streamWriteBool(streamId, self.isPreplaced) then
        streamWriteUInt16(streamId, self.preplacedIndex)
    else
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
        local x,y,z = getTranslation(self.rootNode)
        local x_rot,y_rot,z_rot = getRotation(self.rootNode)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        streamWriteFloat32(streamId, x_rot)
        streamWriteFloat32(streamId, y_rot)
        streamWriteFloat32(streamId, z_rot)
    end

    ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.configFileName, self.configurations, self.boughtConfigurations, self.configurationData)

    PlaceablePropertyState.writeStream(streamId, self.propertyState)
end


---Called on client side when placeable was fully loaded
-- @param integer streamId stream ID
-- @param table connection connection
function Placeable:postReadStream(streamId, connection)
    self:finalizePlacement()

    if Placeable.DEBUG_NETWORK then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners["onReadStream"]) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetReadOffset(streamId)
            spec["onReadStream"](self, streamId, connection)
            print("  "..tostring(className).." read " .. streamGetReadOffset(streamId)-startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
    end

    if streamReadBool(streamId) then
        self:setName(streamReadString(streamId), true)
    end

    if streamReadBool(streamId) then
        local nameL10nKey = streamReadString(streamId)
        self:setNameL10nKey(nameL10nKey)
    end

    if streamReadBool(streamId) then
        self.customImageFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    end

    self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)

    self:raiseActive()
end


---Called on server side when placeable was fully loaded on client side
-- @param integer streamId stream ID
-- @param table connection connection
function Placeable:postWriteStream(streamId, connection)
    if Placeable.DEBUG_NETWORK then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners["onWriteStream"]) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetWriteOffset(streamId)
            spec["onWriteStream"](self, streamId, connection)
            print("  "..tostring(className).." Wrote " .. streamGetWriteOffset(streamId)-startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
    end

    if streamWriteBool(streamId, self.nameCustom ~= nil) then
        streamWriteString(streamId, self.nameCustom)
    end

    if streamWriteBool(streamId, self.nameL10nKey ~= nil) then
        streamWriteString(streamId, self.nameL10nKey)
    end

    if streamWriteBool(streamId, self.customImageFilename ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.customImageFilename))
    end
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function Placeable:readUpdateStream(streamId, timestamp, connection)
    if Placeable.DEBUG_NETWORK_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners["onReadUpdateStream"]) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetReadOffset(streamId)
            spec["onReadUpdateStream"](self, streamId, timestamp, connection)
            print("  "..tostring(className).." read " .. streamGetReadOffset(streamId)-startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
    end
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function Placeable:writeUpdateStream(streamId, connection, dirtyMask)
    if Placeable.DEBUG_NETWORK_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners["onWriteUpdateStream"]) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetWriteOffset(streamId)
            spec["onWriteUpdateStream"](self, streamId, connection, dirtyMask)
            print("  "..tostring(className).." Wrote " .. streamGetWriteOffset(streamId)-startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
    end
end


---Get save attributes and nodes
-- @param string nodeIdent node ident
-- @return string attributes attributes
-- @return string nodes nodes
function Placeable:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)

    if not self.isPreplaced then
        xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
        xmlFile:setValue(key .. "#position", getTranslation(self.rootNode))
        xmlFile:setValue(key .. "#rotation", getRotation(self.rootNode))
    end

    xmlFile:setValue(key .. "#age", self.age)
    xmlFile:setValue(key .. "#price", self.price)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or 1)

    if self.tourId ~= nil then
        xmlFile:setValue(key.."#tourId", self.tourId)
    end

    -- custom name set by player
    if self.canBeRenamed then
        if self.nameCustom ~= nil and self.nameCustom:trim() ~= "" then
            xmlFile:setValue(key.."#name", self.nameCustom)
        end
    end

    -- custom l10n key set by mapper
    if self.nameL10nKey ~= nil then
        if g_i18n:hasText(self.nameL10nKey, self.customEnvironment) then
            xmlFile:setValue(key.."#nameL10nKey", self.nameL10nKey)
        end
    end

    if self.boughtWithFarmlandSavegameOverwrite ~= nil then
        xmlFile:setValue(key.."#boughtWithFarmlandOverwrite", self.boughtWithFarmlandSavegameOverwrite)
    end

    if self.canBeDeletedOverwrite ~= nil then
        xmlFile:setValue(key.."#canBeDeletedOverwrite", self.canBeDeletedOverwrite)
    end

    if self.customImageFilename ~= nil then
        xmlFile:setValue(key..".customImage#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.customImageFilename)))
    end

    ConfigurationUtil.saveConfigurationsToXMLFile(self.configFileName, xmlFile, key .. ".configuration", self.configurations, self.boughtConfigurations, self.configurationData)

    for id, spec in pairs(self.specializations) do
        local name = self.specializationNames[id]

        if spec.saveToXMLFile ~= nil then
            spec.saveToXMLFile(self, xmlFile, key.."."..name, usedModNames)
        end
    end
end






---
function Placeable:setPropertyState(state)
    self.propertyState = state
end


---
function Placeable:getPropertyState()
    return self.propertyState
end








































---
function Placeable:setVisibility(state)
    for _, component in pairs(self.components) do
        setVisibility(component.node, state)
    end
end


---
function Placeable:getIsSynchronized()
    return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end






---
function Placeable:getNeedsSaving()
    return true
end


---Gets this placeable's unique id.
-- @return string uniqueId This placeable's unique id.
function Placeable:getUniqueId()
    return self.uniqueId
end


---Sets this placeable's unique id. Note that a placeable's id should not be changed once it has been first set.
-- @param string uniqueId The unique id to use.
function Placeable:setUniqueId(uniqueId)
    --#debug Assert.isType(uniqueId, "string", string.format("Placeable unique id must be a string! (%s)", self.configFileName))
    --#debug Assert.isNil(self.uniqueId, string.format("Should not change a placeable's unique id '%s'! (%s)", self.uniqueId, self.configFileName))
    self.uniqueId = uniqueId
end


---
function Placeable:update(dt)
    SpecializationUtil.raiseEvent(self, "onUpdate", dt)
end


---
function Placeable:updateTick(dt)
    SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end


---
function Placeable:draw()
    SpecializationUtil.raiseEvent(self, "onDraw")
end


---Get current placeable name including custom names set by mapper or user
-- @return string name
function Placeable:getName()
    return self.nameCustom or self.nameL10n or (self.storeItem and self.storeItem.name)
end


---
function Placeable:getImageFilename()
    return self.customImageFilename or self.storeItem.imageFilename
end


---
function Placeable:getCanBeRenamedByFarm(farmId)
    return self.canBeRenamed and self:getOwnerFarmId() == farmId
end


---Sets a persistent custom name for the placeable if allowed
-- @param string name name to be used, use nil to reset to default name (store item name)
-- @param boolean noEventSend
-- @return boolean success
function Placeable:setName(name, noEventSend)
    if self.canBeRenamed then
        if name and name:trim() == "" then
            return false
        end

        PlaceableNameEvent.sendEvent(self, name, noEventSend)

        self.nameCustom = name
        g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)  -- TODO: move to a less general placeable speci?
        g_messageCenter:publish(MessageType.LOADING_STATIONS_CHANGED)  -- TODO: move to a less general placeable speci?
        return true
    end
    return false
end


---Sets a persistent custom name loca key
-- @param string nameL10nKey
function Placeable:setNameL10nKey(nameL10nKey)
    nameL10nKey = string.gsub(nameL10nKey, "$l10n_", "")  -- unify to version without prefix as required by hasText()
    local mapCustomEnv = g_currentMission.missionInfo.customEnvironment
    if g_i18n:hasText(nameL10nKey, mapCustomEnv) then
        self.nameL10nKey = nameL10nKey
        self.nameL10n = g_i18n:getText(nameL10nKey, mapCustomEnv)
    end
end


---
function Placeable:onBuy()
    SpecializationUtil.raiseEvent(self, "onBuy")

    local serverFarmId = g_currentMission:getFarmId()
    local numPlaceables = 0
    for _, existingPlaceable in ipairs(g_currentMission.placeableSystem.placeables) do
        if existingPlaceable:getOwnerFarmId() == serverFarmId then
            numPlaceables = numPlaceables + 1
        end
    end
    g_achievementManager:tryUnlock("NumPlaceables", numPlaceables)
end


---
function Placeable:onSell()
    g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
    SpecializationUtil.raiseEvent(self, "onSell")
end


---
function Placeable:getPrice()
    return self.price
end


---Returns true if we can place a building
-- checking item count
-- @return boolean canBuy
function Placeable:canBuy()
    local storeItem = self.storeItem
    local maxItemCount = storeItem.maxItemCount
    if maxItemCount == nil then
        return true
    end

    if g_currentMission:getNumOfItems(storeItem, g_currentMission:getFarmId()) < storeItem.maxItemCount then
        return true
    end

    return false
end


---
function Placeable:getCanBePlacedAt(x, y, z, farmId)
    return true, nil
end


---
function Placeable:canBeSold()
    return true, nil
end


---
function Placeable:getDestructionMethod()
    return Placeable.DESTRUCTION.SELL
end


---
function Placeable:previewNodeDestructionNodes(node)
    return nil
end


---
-- @param entityId node
-- @return boolean didDestroyNode
-- @return boolean doDestroyPlacable should be true if the destroyed node was the last one to not have an empty placeable left
function Placeable:performNodeDestruction(node)
    return false, false
end


---
function Placeable:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
    if (self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland) or self.boughtWithFarmlandSavegameOverwrite then
        if self:getIsOnFarmland(farmlandId) then
            self:updateOwnership()
        end
    end
end





---
function Placeable:register(alreadySent)
    Placeable:superClass().register(self, alreadySent)

    SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end







---
function Placeable:setOwnerFarmId(farmId, noEventSend)
    if self.buysFarmland then
        g_farmlandManager:setLandOwnership(self:getFarmlandId(), farmId)
    end

    Placeable:superClass().setOwnerFarmId(self, farmId, noEventSend)

    -- only raise event if placeable LOAD-step passed as functions in specializations registered there
    if self.loadingStep > SpecializationLoadStep.LOAD then
        SpecializationUtil.raiseEvent(self, "onOwnerChanged")
    end

    if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        -- re-add the item, so the shop controller is updated correctly
        g_currentMission:removeOwnedItem(self)
        g_currentMission:addOwnedItem(self)
    end
end




























---
function Placeable:setLoadingState(loadingState)
    local name = PlaceableLoadingState.getName(loadingState)
    if name ~= nil then
        self.loadingState = loadingState
    else
        printCallstack()
        Logging.error("Invalid loading state '%s'!", loadingState)
    end
end


---Collect shapes that can be used for picking. Adds them to the mission for
-- node -> object reference.
-- @param integer node node id
function Placeable:collectPickObjects(node)
    if getRigidBodyType(node) ~= RigidBodyType.NONE then
        table.insert(self.pickObjects, node)
    end
    local numChildren = getNumOfChildren(node)
    for i=1, numChildren do
        self:collectPickObjects(getChildAt(node, i-1))
    end
end


---Sets the loadingStep value of this placeable, logging an error if the given step is invalid.
-- @param SpecializationLoadStep loadingStep The loading step to set.
function Placeable:setLoadingStep(loadingStep)
    SpecializationUtil.setLoadingStep(self, loadingStep)
end


---Set the overlay color and its alpha
function Placeable:setOverlayColor(r, g, b, alpha)
    if self.overlayColorNodes == nil then
        self.overlayColorNodes = {}
        self:setOverlayColorNodes(self.rootNode, self.overlayColorNodes)
    end

    for i = 1, #self.overlayColorNodes do
        setShaderParameter(self.overlayColorNodes[i], "placeableColorScale", r, g, b, alpha, false)
    end
end


---Finds all shape nodes that support color overlay
-- @param integer node id of node
-- @param table nodeTable table to save the nodes
function Placeable:setOverlayColorNodes(node, nodeTable)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
        nodeTable[#nodeTable + 1] = node
    end

    local numChildren = getNumOfChildren(node)
    for i=0, numChildren-1 do
        self:setOverlayColorNodes(getChildAt(node, i), nodeTable)
    end
end


---Returns daily up keep
-- @return integer dailyUpkeep daily up keep
function Placeable:getDailyUpkeep()
    local storeItem = self.storeItem

    local multiplier = 1
    if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
        local ageMultiplier = math.min(self.age/storeItem.lifetime, 1)
        multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
    end
    return StoreItemUtil.getDailyUpkeep(storeItem, self.configurations) * multiplier
end


---Returns current sell price, can be full price if placeable was recently bought
-- Use Placeable:getMonetaryValue() if the actual value is needed
-- @return integer sellPrice sell price
-- @return boolean forFullPrice e.g. if building was sold right after placement
function Placeable:getSellPrice()
    if self.undoTimer > g_time - Placeable.UNDO_DURATION and self.undoTimer > g_currentMission.lastConstructionScreenOpenTime
        and g_currentMission.lastConstructionScreenOpenTime > 0 then
        return self.price, true
    end

    return self:getMonetaryValue(), false
end















---Returns if a placeable should be deleted or moved to farm 0 on sell
-- @return integer sellPrice Placeable.SELL_AND_DELETE or Placeable.SELL_AND_SPECTATOR_FARM
function Placeable:getSellAction()
    local farmlandId = self:getFarmlandId()
    local isOnPublicGround = g_farmlandManager:getFarmlandOwner(farmlandId) == FarmManager.SPECTATOR_FARM_ID

    -- keep placeables on farm 0 if they are on public ground (e.g. prod points) or cannot be deleted and
    local isPreplaced = self:getIsPreplaced()
    if isPreplaced and (isOnPublicGround or not self.canBeDeleted) then
        return Placeable.SELL_AND_SPECTATOR_FARM
    end

    if self.canBeDeletedOverwrite == false then
        return Placeable.SELL_AND_SPECTATOR_FARM
    end

    return Placeable.SELL_AND_DELETE
end


---
function Placeable:addToPhysics()
    if self.rootNode ~= nil then
        addToPhysics(self.rootNode)
    end
end


---
function Placeable:removeFromPhysics()
    if self.rootNode ~= nil then
        removeFromPhysics(self.rootNode)
    end
end


---
function Placeable:setPreviewPosition(x, y, z, rotX, rotY, rotZ)
    setWorldTranslation(self.rootNode, x, y, z)
    setRotation(self.rootNode, 0, rotY, 0)
end


---
function Placeable:getNeedWeatherChanged()
    return false
end


---
function Placeable:weatherChanged()
    SpecializationUtil.raiseEvent(self, "onWeatherChanged")
end


---
function Placeable:getNeedHourChanged()
    return false
end


---
function Placeable:hourChanged(hour)
    SpecializationUtil.raiseEvent(self, "onHourChanged", hour)
end


---
function Placeable:getNeedMinuteChanged()
    return false
end


---
function Placeable:minuteChanged(minute)
    SpecializationUtil.raiseEvent(self, "onMinuteChanged", minute)
end


---
function Placeable:getNeedDayChanged()
    return false
end


---
function Placeable:dayChanged(day)
    SpecializationUtil.raiseEvent(self, "onDayChanged", day)
end


---
function Placeable:periodChanged(period)
    self.age = self.age + 1
    SpecializationUtil.raiseEvent(self, "onPeriodChanged", period)
end


---
function Placeable.getSpecValueSlots(storeItem, realItem)
    local numOwned = g_currentMission:getNumOfItems(storeItem)
    local slotUsage = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, numOwned == 0)

    return string.format("+%0d $SLOTS$", slotUsage)
end
