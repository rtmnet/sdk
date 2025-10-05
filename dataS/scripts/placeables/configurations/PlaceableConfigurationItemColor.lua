











---Stores the data of a single color configuration
local PlaceableConfigurationItemColor_mt = Class(PlaceableConfigurationItemColor, PlaceableConfigurationItem)


---
function PlaceableConfigurationItemColor.new(configName, customMt)
    local self = PlaceableConfigurationItemColor:superClass().new(configName, PlaceableConfigurationItemColor_mt)

    self.isCustomColor = false
    self.isManualConfig = false

    return self
end


---
function PlaceableConfigurationItemColor:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    if not PlaceableConfigurationItemColor:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
        return false
    end

    local colorStr = xmlFile:getValue(configKey .. "#color", nil, true)
    local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(colorStr, customEnvironment)
    if color ~= nil then
        if self.hasDefaultName then
            self.name = title or self.name
        end
        self.color = color
    else
        self.color = string.getVector(colorStr)
        if self.color ~= nil and #self.color ~= 3 then
            Logging.xmlWarning(xmlFile, "Invalid rgb color '%s' in '%s'", colorStr, configKey)
            self.color = nil
        end
    end

    self.uiColor = xmlFile:getValue(configKey .. "#uiColor", nil, true)

    local materialTemplateName = xmlFile:getValue(configKey .. "#materialTemplateName")
    if materialTemplateName ~= nil then
        color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(materialTemplateName, customEnvironment)
        if color ~= nil then
            self.color = self.color or color

            if self.name == nil or self.name == "" then
                self.name = title or self.name
            end
        else
            Logging.xmlWarning(xmlFile, "Material template '%s' not defined for '%s'", materialTemplateName, configKey)
        end
    end

    if self.color == nil then
        self.color = {1, 1, 1}
    end

    self.uiColor = self.uiColor or self.color
    self.isManualConfig = true

    return true
end


---
function PlaceableConfigurationItemColor:saveToXMLFile(xmlFile, key, isActive, configurationData)
    PlaceableConfigurationItemColor:superClass().saveToXMLFile(self, xmlFile, key, isActive, configurationData)

    if self.isCustomColor then
        if configurationData.color ~= nil then
            xmlFile:setValue(key .. "#color", configurationData.color[1], configurationData.color[2], configurationData.color[3])
        end

        if configurationData.materialTemplateName ~= nil then
            xmlFile:setValue(key .. "#materialTemplateName", configurationData.materialTemplateName)
        end
    end
end


---
function PlaceableConfigurationItemColor:loadFromSavegameXMLFile(xmlFile, key, configurationData)
    PlaceableConfigurationItemColor:superClass().loadFromSavegameXMLFile(self, xmlFile, key, configurationData)

    if self.isCustomColor then
        configurationData.color = xmlFile:getValue(key .. "#color", nil, true)
        configurationData.materialTemplateName = xmlFile:getValue(key .. "#materialTemplateName")
    end
end


---
function PlaceableConfigurationItemColor:readFromStream(streamId, connection, configurationData)
    if self.isCustomColor then
        local r, g, b = NetworkUtil.readCompressedColor(streamId)
        configurationData.color = {r, g, b}

        local templateIndex = streamReadUIntN(streamId, VehicleMaterialManager.NUM_BITS_TEMPLATE)
        configurationData.materialTemplateName = g_vehicleMaterialManager:getMaterialTemplateNameByIndex(templateIndex)
    end
end


---
function PlaceableConfigurationItemColor:writeToStream(streamId, connection, configurationData)
    if self.isCustomColor then
        local r, g, b = 1, 1, 1
        if configurationData.color ~= nil then
            r, g, b = configurationData.color[1], configurationData.color[2], configurationData.color[3]
        end

        NetworkUtil.writeCompressedColor(streamId, r, g, b)

        local templateIndex = g_vehicleMaterialManager:getMaterialTemplateIndexByName(configurationData.materialTemplateName)
        streamWriteUIntN(streamId, math.clamp(templateIndex, 0, VehicleMaterialManager.MAX_TEMPLATE_INDEX), VehicleMaterialManager.NUM_BITS_TEMPLATE)
    end
end


---
function PlaceableConfigurationItemColor:hasDataChanged(configurationData1, configurationData2)
    if self.isCustomColor then
        if configurationData1.color ~= nil and configurationData2.color ~= nil then
            if math.abs(configurationData1.color[1] - configurationData2.color[1]) > 0.00001
            or math.abs(configurationData1.color[2] - configurationData2.color[2]) > 0.00001
            or math.abs(configurationData1.color[3] - configurationData2.color[3]) > 0.00001 then
                return true
            end
        elseif configurationData1.color ~= nil or configurationData2.color ~= nil then
            return true
        end

        if configurationData1.materialTemplateName ~= configurationData2.materialTemplateName then
            return true
        end
    end

    return false
end


---
function PlaceableConfigurationItemColor:getColor(placeable)
    local color, _ = self:getColorAndMaterialFromPlaceable(placeable)
    return color
end


---
function PlaceableConfigurationItemColor:getColorAndMaterialFromPlaceable(placeable)
    local color, materialTemplateName = self.color, self.materialTemplateName

    if placeable ~= nil then
        local data = placeable.configurationData[self.configName]
        if data ~= nil then
            local configurationData = data[self.index]
            if configurationData ~= nil then
                if configurationData.color ~= nil then
                    color = configurationData.color
                end

                if configurationData.materialTemplateName ~= nil then
                    materialTemplateName = configurationData.materialTemplateName
                end
            end
        end
    end

    return table.clone(color), materialTemplateName
end


---
function PlaceableConfigurationItemColor:onSizeLoad(xmlFile, sizeData)
    -- exclude dynamic color configurations without xml definition
    if self.configKey ~= "" then
        PlaceableConfigurationItemColor:superClass().onSizeLoad(self, xmlFile, sizeData)
    end
end


---
function PlaceableConfigurationItemColor:onPostLoad(placeable, configId)
    PlaceableConfigurationItemColor:superClass().onPostLoad(self, placeable, configId)

    local configurationDesc = g_placeableConfigurationManager:getConfigurationDescByName(self.configName)
    local xmlFile = placeable.xmlFile

    local color, _ = self:getColorAndMaterialFromPlaceable(placeable)

    local r, g, b = unpack(color)
    for _, materialKey in xmlFile:iterator(configurationDesc.configurationsKey.. ".material") do
        local slotName = xmlFile:getValue(materialKey .. "#slotName")
        PlaceableConfigurationItemColor.applyColor(placeable.rootNode, slotName, r, g, b)
    end

    for _, nodeKey in xmlFile:iterator(configurationDesc.configurationsKey .. ".node") do
        local node = xmlFile:getValue(nodeKey .. "#node", nil, placeable.components, placeable.i3dMappings)
        if node ~= nil then
            setShaderParameter(node, "colorScale0", r, g, b, 1, false)
        end
    end
end

















---
function PlaceableConfigurationItemColor.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
    PlaceableConfigurationItemColor:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)

    local defaultColorIndex = xmlFile:getValue(baseKey.."#defaultColorIndex")

    if xmlFile:getValue(baseKey.."#useDefaultColors", false) or (g_modIsLoaded["FS25_unlimitedColorConfigurations"] and #configurationItems > 0) then
        local price = xmlFile:getValue(baseKey.."#price", 1000)

        for i, brandMaterialName in pairs(PlaceableConfigurationItemColor.DEFAULT_COLORS) do
            local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(brandMaterialName, customEnvironment)
            if color ~= nil then
                local configItem = PlaceableConfigurationItemColor.new(configName)

                configItem.name = title or configItem.name

                if i == defaultColorIndex then
                    configItem.isDefault = true
                    configItem.price = 0
                else
                    configItem.price = price
                end

                configItem.name = configItem.name or title
                configItem.color = color
                configItem.uiColor = color
                configItem.saveId = brandMaterialName

                table.insert(configurationItems, configItem)
                configItem:setIndex(#configurationItems)
            end
        end

        local configItem = PlaceableConfigurationItemColor.new(configName)

        configItem.name = g_i18n:getText("ui_colorPicker_custom")

        configItem.price = price

        configItem.color = {1, 1, 1, 1}
        configItem.uiColor = {1, 1, 1, 1}
        configItem.materialTemplateName = "calibratedPaint"
        configItem.isCustomColor = true
        configItem.isSelectable = false
        configItem.saveId = "CUSTOM_COLOR"

        table.insert(configurationItems, configItem)
        configItem:setIndex(#configurationItems)
    end

    if defaultColorIndex == nil then
        local defaultIsDefined = false
        for _, item in ipairs(configurationItems) do
            if item.isDefault ~= nil and item.isDefault then
                defaultIsDefined = true
            end
        end

        if not defaultIsDefined then
            if #configurationItems > 0 then
                configurationItems[1].isDefault = true
                configurationItems[1].price = 0
            end
        end
    end
end


---
function PlaceableConfigurationItemColor.getFallbackConfigId(configs, configId, configName, configFileName)
    local numManualConfigs = 0
    for _, config in pairs(configs) do
        if config.isManualConfig then
            numManualConfigs = numManualConfigs + 1
        end
    end

    -- prior to patch 3, we used the color index as saveId, now we use the brand material name
    local configIndex = tonumber(configId)
    if configIndex ~= nil then
        if configIndex > numManualConfigs then
            local brandMaterialName = PlaceableConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2[configIndex - numManualConfigs]
            for _, config in pairs(configs) do
                if config.saveId == brandMaterialName then
                    return config.index, config.saveId
                end
            end
        end

        return nil, nil
    end

    return nil, nil
end


---
function PlaceableConfigurationItemColor.registerXMLPaths(schema, rootPath, configPath)
    PlaceableConfigurationItemColor:superClass().registerXMLPaths(schema, rootPath, configPath)

    schema:register(XMLValueType.INT, rootPath .. "#defaultColorIndex", "Default color index on start")
    schema:register(XMLValueType.BOOL, rootPath .. "#useDefaultColors", "Use default colors", false)
    schema:register(XMLValueType.INT, rootPath .. "#price", "Default color price", 1000)

    schema:register(XMLValueType.STRING, rootPath .. ".material(?)#slotName")
    schema:register(XMLValueType.NODE_INDEX, rootPath .. ".node(?)#node")
    schema:register(XMLValueType.STRING, configPath .. "#color", "Configuration color", "1 1 1 1")
    schema:register(XMLValueType.COLOR, configPath .. "#uiColor", "Configuration UI color", "1 1 1 1")
    schema:register(XMLValueType.STRING, configPath .. "#materialTemplateName", "Name of the material template to use")
end


---
function PlaceableConfigurationItemColor.registerSavegameXMLPaths(schema, basePath)
    PlaceableConfigurationItemColor:superClass().registerSavegameXMLPaths(schema, basePath)

    schema:register(XMLValueType.VECTOR_3, basePath .. "#color", "Configuration color", "1 1 1")
    schema:register(XMLValueType.STRING, basePath .. "#materialTemplateName", "Name of material template to use")
end
