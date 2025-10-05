








---
local CrabSteeringHUDExtension_mt = Class(CrabSteeringHUDExtension)


---Create a new instance of CrabSteeringHUDExtension.
-- @param table vehicle Vehicle which has the specialization required by a sub-class
function CrabSteeringHUDExtension.new(vehicle, customMt)
    local self = setmetatable({}, customMt or CrabSteeringHUDExtension_mt)

    self.priority = GS_PRIO_VERY_HIGH

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)

    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)

    self.crabSteeringModeText = g_i18n:getText("action_crabSteeringModeSelected")

    self.vehicle = vehicle

    self:storeScaledValues()

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)

    return self
end
