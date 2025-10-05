









---
local WoodContainerWrongLengthEvent_mt = Class(WoodContainerWrongLengthEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodContainerWrongLengthEvent.emptyNew()
    local self = Event.new(WoodContainerWrongLengthEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function WoodContainerWrongLengthEvent.new(object, state, x, y, z)
    local self = WoodContainerWrongLengthEvent.emptyNew()
    self.object = object

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodContainerWrongLengthEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodContainerWrongLengthEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function WoodContainerWrongLengthEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if g_currentMission:getFarmId() == self.object:getOwnerFarmId() then
            if calcDistanceFrom(getCamera(), self.object.rootNode) < 40 then
                local spec = self.object.spec_woodContainer
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(spec.texts.warningWoodContainerWrongLength, spec.targetLength))
            end
        end
    end
end
