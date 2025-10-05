








---
local HandToolSetHolderEvent_mt = Class(HandToolSetHolderEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function HandToolSetHolderEvent.emptyNew()
    local self = Event.new(HandToolSetHolderEvent_mt)
    return self
end


---
function HandToolSetHolderEvent.new(handTool, holder)
    local self = HandToolSetHolderEvent.emptyNew()

    self.handTool = handTool
    self.holder = holder
    self.hasHolder = holder ~= nil

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function HandToolSetHolderEvent:readStream(streamId, connection)

    self.handTool = NetworkUtil.readNodeObject(streamId)
    self.hasHolder = streamReadBool(streamId)
    if self.hasHolder then
        self.holder = NetworkUtil.readNodeObject(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function HandToolSetHolderEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.handTool)
    if streamWriteBool(streamId, self.holder ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.holder)
    end
end


---Run action on receiving side
-- @param Connection connection connection
function HandToolSetHolderEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end

    if self.handTool ~= nil and self.handTool:getIsSynchronized() then
        if (self.hasHolder and self.holder ~= nil) or not self.hasHolder then
            self.handTool:setHolder(self.holder, true)
        end
    end

    g_messageCenter:publish(HandToolSetHolderEvent)
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table handTool handTool
-- @param table holder holder
-- @param boolean noEventSend no event send
function HandToolSetHolderEvent.sendEvent(handTool, holder, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(HandToolSetHolderEvent.new(handTool, holder))
        else
            g_client:getServerConnection():sendEvent(HandToolSetHolderEvent.new(handTool, holder))
        end
    end
end
