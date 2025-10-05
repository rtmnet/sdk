

















---List item element to be used and laid out by SmoothListElement
-- Used layers: "image" for a background image.
local ListItemElement_mt = Class(ListItemElement, BitmapElement)




---
function ListItemElement.new(target, custom_mt)
    local self = BitmapElement.new(target, custom_mt or ListItemElement_mt)

    self.mouseEntered = false
    self.allowSelected = true
    self.autoSelectChildren = false
    self.handleFocus = false
    self.hideSelection = false

    self.alternateChildren = false
    self.alternateBackgroundColor = nil

    self.attributes = {}

    return self
end


---
function ListItemElement:loadFromXML(xmlFile, key)
    ListItemElement:superClass().loadFromXML(self, xmlFile, key)

    self.allowSelected = Utils.getNoNil(getXMLBool(xmlFile, key.."#allowSelected"), self.allowSelected)
    self.autoSelectChildren = Utils.getNoNil(getXMLBool(xmlFile, key.."#autoSelectChildren"), self.autoSelectChildren)
    self.alternateChildren = Utils.getNoNil(getXMLBool(xmlFile, key.."#alternateChildren"), self.alternateChildren)
    self.hideSelection = Utils.getNoNil(getXMLBool(xmlFile, key.."#hideSelection"), self.hideSelection)

    self:addCallback(xmlFile, key.."#onFocus", "onFocusCallback") -- TODO: change to onHighlight()
    self:addCallback(xmlFile, key.."#onLeave", "onLeaveCallback")
    self:addCallback(xmlFile, key.."#onClick", "onClickCallback")
end


---
function ListItemElement:loadProfile(profile, applyProfile)
    ListItemElement:superClass().loadProfile(self, profile, applyProfile)

    self.allowSelected = profile:getBool("allowSelected", self.allowSelected)
    self.autoSelectChildren = profile:getBool("autoSelectChildren", self.autoSelectChildren)
    self.alternateChildren = profile:getBool("alternateChildren", self.alternateChildren)
    self.hideSelection = profile:getBool("hideSelection", self.hideSelection)

    if not self.alternateBackgroundLoaded then
        self.backgroundColor = table.clone(GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL))
        self.alternateBackgroundColor = GuiUtils.getColorArray(profile:getValue("alternateBackgroundColor"))
        self.alternateBackgroundLoaded = true
    end

end


---
function ListItemElement:copyAttributes(src)
    ListItemElement:superClass().copyAttributes(self, src)

    self.allowSelected = src.allowSelected
    self.isSectionHeader = src.isSectionHeader
    self.autoSelectChildren = src.autoSelectChildren
    self.hideSelection = src.hideSelection

    self.backgroundColor = src.backgroundColor
    self.alternateChildren = src.alternateChildren
    self.alternateBackgroundColor = src.alternateBackgroundColor
    self.alternateBackgroundLoaded = src.alternateBackgroundLoaded

    self.onLeaveCallback = src.onLeaveCallback
    self.onFocusCallback = src.onFocusCallback
    self.onClickCallback = src.onClickCallback
end


---
function ListItemElement:onClose()
    ListItemElement:superClass().onClose(self)
    self:reset()
end











---
function ListItemElement:setSelected(selected)
    ListItemElement:superClass().setSelected(self, selected and not self.hideSelection and self.allowSelected)
end


---
function ListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsVisible() then
        if ListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
            eventUsed = true
        end

        if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot) then
            if not isDown and not isUp then
                if self.handleFocus then
                    FocusManager:setHighlight(self)
                end

                if not self.mouseEntered then
                    self.mouseEntered = true
                    if self.handleFocus then
                        self:raiseCallback("onFocusCallback", self)
                    end
                end
            end

            if isDown then
                if button == Input.MOUSE_BUTTON_LEFT then
                    self.mouseDown = true
                    eventUsed = self:raiseCallback("onClickCallback", self)
                end
            end

            if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
                self.mouseDown = false
            end
        else
            if self.mouseEntered then
                self.mouseEntered = false
                if self.handleFocus then
                    self:raiseCallback("onLeaveCallback", self)
                end
            end

            self.mouseDown = false
            if self.handleFocus and self:getIsHighlighted() then
                FocusManager:unsetHighlight(self)
            end
        end
    end

    return eventUsed
end


---
function ListItemElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsVisible() then
        if ListItemElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) then
            eventUsed = true
        end

        if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot) then
            if not isDown and not isUp then
                if self.handleFocus then
                    FocusManager:setHighlight(self)
                end

                if not self.touchEntered then
                    self.touchEntered = true
                    if self.handleFocus then
                        self:raiseCallback("onFocusCallback", self)
                    end
                end
            end

            if isDown then
                self.touchDown = true
                eventUsed = self:raiseCallback("onClickCallback", self)
            end

            if isUp and self.touchDown then
                self.touchDown = false
            end
        else
            if self.touchEntered then
                self.touchEntered = false
                if self.handleFocus then
                    self:raiseCallback("onLeaveCallback", self)
                end
            end

            self.touchDown = false
            if self.handleFocus and self:getIsHighlighted() then
                FocusManager:unsetHighlight(self)
            end
        end
    end

    return eventUsed
end









---Get the actual focus target, in case a child or parent element needs to be targeted instead.
-- Override from BitmapElement: Only focuses children if #autoSelectChildren is true
-- @param incomingDirection (Optional) If specified, may return different targets for different incoming directions.
-- @param moveDirection (Optional) Actual movement direction per input. This is the opposing direction of incomingDirection.
-- @return GuiElement Actual element to focus.
function ListItemElement:getFocusTarget(incomingDirection, moveDirection)
    if self.autoSelectChildren then
        return ListItemElement:superClass().getFocusTarget(self, incomingDirection, moveDirection)
    else
        return self
    end
end
