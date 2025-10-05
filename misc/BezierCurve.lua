









---A bezier curve for smooth animations. Implicitly treats P0 and P3 as 0,0 and 1,1 respectively, and allows for 1 dimensional sampling.
local BezierCurve_mt = Class(BezierCurve)

































---Recalculates the coefficients based on the positions.
function BezierCurve:recalculateCoefficients()
    self.cx = 3 * self.positionX1
    self.bx = 3 * (self.positionX2 - self.positionX1) - self.cx
    self.ax = 1 - self.cx - self.bx

    self.cy = 3 * self.positionY1
    self.by = 3 * (self.positionY2 - self.positionY1) - self.cy
    self.ay = 1 - self.cy - self.by
end


---Sets the position X 1 value to the given value, clamped between 0 and 1.
-- @param float newValue The new value to use. Will be clamped between 0 and 1.
function BezierCurve:setPositionX1(newValue)
    --#debug Assert.isType(newValue, "number", "Position X 1 must be a number")
    self.positionX1 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end


---Sets the position Y 1 value to the given value.
-- @param float newValue The new value to use.
function BezierCurve:setPositionY1(newValue)
    --#debug Assert.isType(newValue, "number", "Position Y 1 must be a number")
    self.positionY1 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end


---Sets the position X 2 value to the given value, clamped between 0 and 1.
-- @param float newValue The new value to use. Will be clamped between 0 and 1.
function BezierCurve:setPositionX2(newValue)
    --#debug Assert.isType(newValue, "number", "Position X 2 must be a number")
    self.positionX2 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end


---Sets the position Y 2 value to the given value.
-- @param float newValue The new value to use.
function BezierCurve:setPositionY2(newValue)
    --#debug Assert.isType(newValue, "number", "Position Y 2 must be a number")
    self.positionY2 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end
