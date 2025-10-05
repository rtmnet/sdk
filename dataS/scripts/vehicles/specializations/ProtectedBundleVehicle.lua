













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function ProtectedBundleVehicle.prerequisitesPresent(specializations)
    return true
end


---
function ProtectedBundleVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ProtectedBundleVehicle")

    schema:register(XMLValueType.BOOL, "vehicle.protectedBundleVehicle#isBundleRoot", "Vehicle acts are bundle root vehicle (the only vehicle to be selectable, shown in overview, sellable, resetable)", false)
    schema:register(XMLValueType.BOOL, "vehicle.protectedBundleVehicle#isBundleChild", "Vehicle acts as bundle child vehicle (can not be selected, not shown in map overview, reset and sold with attacher vehicle)", false)
    schema:register(XMLValueType.STRING, "vehicle.protectedBundleVehicle#bundleFilename", "Path to bundle xml file (required for reset of the vehicle to spawn the bundle instead of the single vehicle)")

    schema:setXMLSpecializationType()
end


---
function ProtectedBundleVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getReloadXML", ProtectedBundleVehicle.getReloadXML)
end


---
function ProtectedBundleVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ProtectedBundleVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", ProtectedBundleVehicle)
end


---Called on loading
-- @param table savegame savegame
function ProtectedBundleVehicle:onLoad(savegame)
    local spec = self.spec_protectedBundleVehicle

    spec.isBundleRoot = self.xmlFile:getValue("vehicle.protectedBundleVehicle#isBundleRoot", false)
    spec.isBundleChild = self.xmlFile:getValue("vehicle.protectedBundleVehicle#isBundleChild", false)
    spec.bundleFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.protectedBundleVehicle#bundleFilename"), self.baseDirectory)
    if spec.bundleFilename ~= nil then
        if g_storeManager:getItemByXMLFilename(spec.bundleFilename) == nil then
            Logging.xmlWarning(self.xmlFile, "Missing bundle vehicle store item for '%s'", spec.bundleFilename)
        end
    end

    if spec.isBundleChild then
        self.canBeReset = false
        self.showInVehicleOverview = false
        self.allowSelection = false
    end

    if not self.isServer or not spec.isBundleChild then
        SpecializationUtil.removeEventListener(self, "onPostDetach", ProtectedBundleVehicle)
    end
end


---
function ProtectedBundleVehicle:onPostDetach()
    if not g_currentMission.vehicleSystem.isReloadRunning and not g_currentMission.isTeleporting and not self.isDeleted and not self.isDeleting then
        self:delete()
    end
end


---Get reload xml
-- @return string xml xml
function ProtectedBundleVehicle:getReloadXML(superFunc)
    local spec = self.spec_protectedBundleVehicle
    if spec.isBundleRoot and spec.bundleFilename ~= nil then
        local vehicleXMLFile = superFunc(self)
        if vehicleXMLFile ~= nil then
            vehicleXMLFile:setValue("vehicles.vehicle(0)#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(spec.bundleFilename)))
        end
        return vehicleXMLFile
    end

    return superFunc(self)
end
