









---
local AIMessageErrorUnloadingStationFull_mt = Class(AIMessageErrorUnloadingStationFull, AIMessage)


---
function AIMessageErrorUnloadingStationFull.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorUnloadingStationFull_mt)
    return self
end


---
function AIMessageErrorUnloadingStationFull:getI18NText()
    return g_i18n:getText("ai_messageErrorUnloadingStationFull")
end
