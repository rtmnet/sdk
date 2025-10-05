










---Info box with key-value layout
local InfoDisplayKeyValueBox_mt = Class(InfoDisplayKeyValueBox, InfoDisplayBox)


---
function InfoDisplayKeyValueBox.new(infoDisplay, uiScale, customMt)
    local self = InfoDisplayBox.new(infoDisplay, uiScale, customMt or InfoDisplayKeyValueBox_mt)

    self.lines = {}
    self.title = "Unknown Title"

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.fieldInfo_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgBottom = g_overlayManager:createOverlay("gui.fieldInfo_bottom", 0, 0, 0, 0)
    self.bgBottom:setColor(r, g, b, a)
    self.bgTop = g_overlayManager:createOverlay("gui.fieldInfo_top", 0, 0, 0, 0)
    self.bgTop:setColor(r, g, b, a)

    r, g, b, a = unpack(HUD.COLOR.ACTIVE)
    self.warningIcon = g_overlayManager:createOverlay("gui.fieldInfo_warning", 0, 0, 0, 0)
    self.warningIcon:setColor(r, g, b, a)

    return self
end
