











---Reference to a named frame to be displayed.
-- The reference will be resolved on loading and this element will be removed if the resolution succeeds.
local FrameReferenceElement_mt = Class(FrameReferenceElement, GuiElement)





---
function FrameReferenceElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or FrameReferenceElement_mt)

    self.referencedFrameName = ""

    return self
end


---
function FrameReferenceElement:loadFromXML(xmlFile, key)
    FrameReferenceElement:superClass().loadFromXML(self, xmlFile, key)

    self.referencedFrameName = getXMLString(xmlFile, key .. "#ref") or ""
end


---
function FrameReferenceElement:copyAttributes(src)
    FrameReferenceElement:superClass().copyAttributes(self, src)
    self.referencedFrameName = src.referencedFrameName
end
