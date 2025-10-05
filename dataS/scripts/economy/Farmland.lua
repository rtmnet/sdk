









---This class wraps all farmland data
local Farmland_mt = Class(Farmland)














---Create field definition object
-- @return table instance Instance of object
function Farmland.new(customMt)
    local self = setmetatable({}, customMt or Farmland_mt)

    self.isOwned = false
    self.xWorldPos = nil
    self.zWorldPos = nil
    self.field = nil

    return self
end


---Load farmland data from xml
-- @param XMLFile xmlFile handle of xml file
-- @param string key current xml element key
-- @return boolean true if loading was successful else false
function Farmland:load(xmlFile, key)
    self.id = xmlFile:getValue(key.."#id")

    if self.id == nil or self.id == 0 then
        Logging.xmlError(xmlFile, "Invalid farmland id '%s'!", self.id)
        return false
    end

    self.xWorldPos, self.zWorldPos = xmlFile:getValue(key .. "#indicatorPosition")

    local name = xmlFile:getValue(key.."#name")
    if name ~= nil then
        name = g_i18n:convertText(name, g_currentMission.loadingMapModName)
    end
    self.name = name or tostring(self.id)

    self.areaInHa = xmlFile:getValue(key.."#areaInHa", 2.5)

    self.fixedPrice = xmlFile:getValue(key.."#price")
    if self.fixedPrice == nil then
        self.priceFactor = xmlFile:getValue(key.."#priceScale", 1)
    end
    self.price = self.fixedPrice or 1

    self:updatePrice()

    self.npcIndex = g_npcManager:getRandomIndex()
    local npc = g_npcManager:getNPCByName(xmlFile:getValue(key.."#npcName"))
    if npc ~= nil then
        self.npcIndex = npc.index
    end

    self.isOwned = false
    self.showOnFarmlandsScreen = xmlFile:getValue(key.."#showOnFarmlandsScreen", true)
    self.defaultFarmProperty = xmlFile:getValue(key.."#defaultFarmProperty", false)
    self.farmId = FarmlandManager.NO_OWNER_FARM_ID

    return true
end


---Delete field definition object
function Farmland:delete()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
end















---Set farmland area indicator world position
-- @param float xWorldPos farmland indicator x world position
-- @param float zWorldPos farmland size in ha
function Farmland:setIndicatorPosition(xWorldPos, zWorldPos)
    self.xWorldPos, self.zWorldPos = xWorldPos, zWorldPos

    if self.mapHotspot ~= nil then
        self.mapHotspot:setWorldPosition(xWorldPos, zWorldPos)
    end
end


























---Set farmland area
-- @param float areaInHa farmland size in ha
function Farmland:setArea(areaInHa)
    self.areaInHa = areaInHa
    if self.fixedPrice == nil then
        self:updatePrice()
    end
end
