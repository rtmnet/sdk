































---Table header element to use within tables.
-- Children which serve as sorting icons are to be marked in the screen XML configuration by setting the name attribute
-- to "iconAscending" or "iconDescending" depending on which sorting state they are intended to represent. Headers must
-- be defined outside of tables, because anything within a table is considered a table item.
local TableHeaderElement_mt = Class(TableHeaderElement, ButtonElement)




---
function TableHeaderElement.new(target, custom_mt)
    local self = ButtonElement.new(target, custom_mt or TableHeaderElement_mt)

    self.allowedSortingStates = {
        [TableHeaderElement.SORTING_OFF] = true, -- no reason to ever change this, only here for processing
        [TableHeaderElement.SORTING_ASC] = false,
        [TableHeaderElement.SORTING_DESC] = false,
    }
    self.sortingOrder = TableHeaderElement.SORTING_OFF -- state index in allowed sorting states

    self.sortingIcons = {
        [TableHeaderElement.SORTING_OFF] = nil, -- off state icon element
        [TableHeaderElement.SORTING_ASC] = nil, -- ascending sort state icon element
        [TableHeaderElement.SORTING_DESC] = nil -- descending sort state icon element
    }

    self.targetTableId = ""    -- ID of decorated table
    self.columnName = ""       -- name of table column to sort

    return self
end


---
function TableHeaderElement:loadFromXML(xmlFile, key)
    TableHeaderElement:superClass().loadFromXML(self, xmlFile, key)

    self.targetTableId = getXMLString(xmlFile, key.."#targetTableId") or self.targetTableId
    self.columnName = getXMLString(xmlFile, key.."#columnName") or self.columnName

    local allowAscendingSort = Utils.getNoNil(getXMLBool(xmlFile, key.."#allowSortingAsc"), self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
    local allowDescendingSort = Utils.getNoNil(getXMLBool(xmlFile, key.."#allowSortingDesc"), self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
    self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = allowAscendingSort
    self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = allowDescendingSort
end


---
function TableHeaderElement:loadProfile(profile, applyProfile)
    TableHeaderElement:superClass().loadProfile(self, profile, applyProfile)

    self.columnName = profile:getValue("columnName", self.columnName)
    self.allowedSortingStates[TableHeaderElement.SORTING_ASC] = profile:getBool("allowSortingAsc", self.allowedSortingStates[TableHeaderElement.SORTING_ASC])
    self.allowedSortingStates[TableHeaderElement.SORTING_DESC] = profile:getBool("allowSortingDesc", self.allowedSortingStates[TableHeaderElement.SORTING_DESC])
end


---
function TableHeaderElement:copyAttributes(src)
    TableHeaderElement:superClass().copyAttributes(self, src)

    self.targetTableId = src.targetTableId
    self.columnName = src.columnName
    self.allowedSortingStates = {unpack(src.allowedSortingStates)}
end


---This element searches for marked children to use as sorting icons.
function TableHeaderElement:onGuiSetupFinished()
    TableHeaderElement:superClass().onGuiSetupFinished(self)

    for _, child in pairs(self.elements) do
        -- find header icons by configuration attribute
        if child.name == TableHeaderElement.NAME_ASC_ICON then
            self.sortingIcons[TableHeaderElement.SORTING_ASC] = child
        end
        if child.name == TableHeaderElement.NAME_DESC_ICON then
            self.sortingIcons[TableHeaderElement.SORTING_DESC] = child
        end
    end
end


---Toggle this header's sorting display state, if allowed.
-- @return The new sorting order
function TableHeaderElement:toggleSorting()
    -- cycle to the next allowed sorting state (will stop at off setting at the latest):
    local prevOrderIndex = self.sortingOrder

    repeat
        self.sortingOrder = ((self.sortingOrder) % #self.allowedSortingStates) + 1
    until self.allowedSortingStates[self.sortingOrder]

    if not (prevOrderIndex == self.sortingOrder) then
        self:updateSortingDisplay()
    end

    return self.sortingOrder
end


---Disable sorting on this header by setting its sorting state to OFF.
function TableHeaderElement:disableSorting()
    self.sortingOrder = TableHeaderElement.SORTING_OFF
    self:updateSortingDisplay()
end


---Update the header's display with its new state.
function TableHeaderElement:updateSortingDisplay()
    -- enable current state, disable others
    for sortOrderIndex, icon in pairs(self.sortingIcons) do
        if sortOrderIndex == self.sortingOrder then
            icon:setVisible(true)
        else
            icon:setVisible(false)
        end
    end
end
