



















---Handles interpolating the player's graphical position and their actual position, to ensure it is smooth.
local PlayerPositionalInterpolator_mt = Class(PlayerPositionalInterpolator)











---Creates a new positional interpolator for the given player.
-- @param Player player The player whose root or graphical node's position will be interpolated.
-- @param integer targetNodeType The INTERPOLATION_TARGET_ENUM determining what type of node is interpolated.
-- @return PlayerPositionalInterpolator self The created instance.
function PlayerPositionalInterpolator.new(player, targetNodeType)

    -- Create the instance.
    local self = setmetatable({}, PlayerPositionalInterpolator_mt)

    -- The player owning the interpolator.
    self.player = player

    -- The type of node that is being moved by the interpolation.
    self.targetNodeType = targetNodeType

    self.timeInterpolator = InterpolationTime.new(1.2)

    local playerPositionX, playerPositionY, playerPositionZ = self.player:getPosition()
    self.positionInterpolator = InterpolatorPosition.new(playerPositionX, playerPositionY, playerPositionZ)

    self.interpolatedPositionX = playerPositionX
    self.interpolatedPositionY = playerPositionY
    self.interpolatedPositionZ = playerPositionZ

    self.interpolatedSpeed = 0
    self.interpolatedVelocityX = 0
    self.interpolatedVelocityY = 0
    self.interpolatedVelocityZ = 0

    local playerYaw = self.player:getYaw()
    self.yawInterpolator = InterpolatorAngle.new(playerYaw)

    local playerSpeed = self.player:getSpeed()
    self.speedInterpolator = InterpolatorValue.new(playerSpeed)

    local playerVerticalVelocity = self.player.mover.currentVelocityY
    self.verticalVelocityInterpolator = InterpolatorValue.new(playerVerticalVelocity)

    self.directionX, self.directionZ = 0, 0

    self.targetPhysicsIndex = -1

    self.player.mover.onPositionTeleport:registerListener(PlayerPositionalInterpolator.onPlayerPositionTeleport, self)

    -- Return the created instance.
    return self
end


---Updates the node based on the interpolated state.
-- @param float dt Delta time in ms.
function PlayerPositionalInterpolator:update(dt)
    local deltaTime = g_physicsDtUnclamped
    self.timeInterpolator:update(deltaTime)

    local alpha = self.timeInterpolator:getAlpha()
    local interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ = self.positionInterpolator:getInterpolatedValues(alpha)
    local interpolatedYaw = self.yawInterpolator:getInterpolatedValue(alpha)

    local dirX = interpolatedPositionX - self.interpolatedPositionX
    local dirZ = interpolatedPositionZ - self.interpolatedPositionZ
    local distance = MathUtil.vector2Length(dirX, dirZ)

    if not self.player.isOwner then
--         log(string.format("   Intp: %.4f %.4f | %.4f %.4f %.4f", alpha, distance, interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ))
    end

    local speedXZ = 0
    local speedY = 0
    if distance > 0 then
        dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
        speedXZ = distance / deltaTime
        speedY = (interpolatedPositionY - self.interpolatedPositionY) / deltaTime
    end

    self.interpolatedPositionX = interpolatedPositionX
    self.interpolatedPositionY = interpolatedPositionY
    self.interpolatedPositionZ = interpolatedPositionZ
    self.interpolatedYaw = interpolatedYaw
    self.interpolatedSpeed = speedXZ * 1000
    self.interpolatedVelocityX = dirX * speedXZ
    self.interpolatedVelocityZ = dirZ * speedXZ
    self.interpolatedVelocityY = speedY

    -- If this interpolator is targeting the root node, then it drives the position of the player.
    -- Otherwise; the interpolator is targeting the graphical node and it will return the interpolated position via getGraphicalPosition.
    if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
        self.player.mover:setPosition(interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ)
        self.player.mover:setMovementYaw(interpolatedYaw)
        self.player.mover:setSpeed(speedXZ)
        self.player.mover:setVelocity(self.interpolatedVelocityX, self.interpolatedVelocityZ, self.interpolatedVelocityZ)
    end
end


---Runs every tick (around 30 times a second) and handles preparing the state.
-- @param float dt Delta time in ms.
function PlayerPositionalInterpolator:updateTick(dt)
    if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
        local interpolator = self.positionInterpolator

        if self.targetPhysicsIndex >= 0 then
            -- Get the player's root position.
            local x, y, z = self.player.mover:getPosition()

            if not self.player.isOwner and getIsPhysicsUpdateIndexSimulated(self.targetPhysicsIndex) then
                self.targetPhysicsIndex = -1
            else
                -- Get the current target position of the interpolation.
                local targetPositionX = interpolator.targetPositionX
                local targetPositionY = interpolator.targetPositionY
                local targetPositionZ = interpolator.targetPositionZ

                -- Calculate the distance between the target position and current position, and determine if they are very close.
                local distanceX = math.abs(x - targetPositionX)
                local distanceY = math.abs(y - targetPositionY)
                local distanceZ = math.abs(z - targetPositionZ)
                local isVeryClose = distanceX < 0.001 and distanceY < 0.001 and distanceZ < 0.001

                -- If the position is close enough, prevent jittering by setting the target to it.
                if isVeryClose then
                    x = targetPositionX
                    y = targetPositionY
                    z = targetPositionZ
                end
            end

            self:setTargetPosition(x, y, z)

            -- Start a new time phase.
            self.timeInterpolator:startNewPhase(75)

            -- Set the other parameters with the same logic, use the target if it is close enough.
            local playerYaw = self.player:getYaw()
            local targetYaw = self.yawInterpolator.targetValue
            self:setTargetYaw(math.abs(playerYaw - targetYaw) < 0.005 and targetYaw or playerYaw)
        end
    end
end






---Sets the target position of the position interpolator to the given position.
-- @param float targetPositionX The target x position.
-- @param float targetPositionY The target y position.
-- @param float targetPositionZ The target z position.
function PlayerPositionalInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
    if not self.player.isOwner then
--         log("setTargetPosition", targetPositionX, targetPositionY, targetPositionZ)
--         printCallstack()
    end
    self.positionInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
end
















---Gets the currently interpolated position.
-- @return float interpolatedPositionX The interpolated x position.
-- @return float interpolatedPositionY The interpolated y position.
-- @return float interpolatedPositionZ The interpolated z position.
function PlayerPositionalInterpolator:getInterpolatedPosition()
    return self.interpolatedPositionX, self.interpolatedPositionY, self.interpolatedPositionZ
end


---Sets the target yaw of the yaw interpolator to the given angle.
-- @param float targetYaw The target rotation around the y axis.
function PlayerPositionalInterpolator:setTargetYaw(targetYaw)
    targetYaw = MathUtil.getValidLimit(targetYaw)
    self.yawInterpolator:setTargetAngle(targetYaw)
end
