













---Called by material holder to create material
-- @param any unused unused
-- @param integer id id
function MaterialUtil.onCreateBaseMaterial(_, id)
    local materialNameStr = getUserAttribute(id, "materialName")
    if materialNameStr == nil then
        Logging.i3dWarning(id, "Missing 'materialName' user attribute for MaterialUtil.onCreateBaseMaterial")
        return
    end

    g_materialManager:addBaseMaterial(materialNameStr, getMaterial(id, 0))
end


---Called by material holder to create material
-- @param entityId node id
-- @param string sourceFuncName used for logging
-- @return boolean success
-- @return integer fillTypeIndex
-- @return integer materialType
-- @return integer materialIndex
function MaterialUtil.validateMaterialAttributes(node, sourceFuncName)
    local fillTypeStr = getUserAttribute(node, "fillType")
    if fillTypeStr == nil then
        Logging.i3dWarning(node, "Missing 'fillType' user attribute for %q", sourceFuncName)
        return false
    end

    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
    if fillTypeIndex == nil then
        Logging.i3dWarning(node, "Unknown fillType %q in user attribute 'fillType' for %q", fillTypeStr, sourceFuncName)
        return false
    end

    local materialTypeName = getUserAttribute(node, "materialType")
    if materialTypeName == nil then
        Logging.i3dWarning(node, "Missing 'materialType' user attribute for %q", sourceFuncName)
        return false
    end

    local materialType = g_materialManager:getMaterialTypeByName(materialTypeName)
    if materialType == nil then
        Logging.i3dWarning(node, "Unknown materialType %q for %q", materialTypeName, sourceFuncName)
        return false
    end

    local matIdStr = Utils.getNoNil(getUserAttribute(node, "materialIndex"), 1)
    local materialIndex = tonumber(matIdStr)
    if materialIndex == nil then
        Logging.i3dWarning(node, "Invalid materialIndex %q for %q", matIdStr, sourceFuncName)
        return false
    end

    return true, fillTypeIndex, materialType, materialIndex
end


---Called by material holder to create material
-- @param any unused unused
-- @param integer id id
function MaterialUtil.onCreateMaterial(_, id)
    local isValid, fillTypeIndex, materialType, materialIndex = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateMaterial")
    if isValid then
        g_materialManager:addMaterial(fillTypeIndex, materialType, materialIndex, getMaterial(id, 0))
    end
end


---Called by material holder to create particle material
-- @param any unused unused
-- @param integer id id
function MaterialUtil.onCreateParticleMaterial(_, id)
    local isValid, fillTypeIndex, materialType, materialIndex = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateParticleMaterial")
    if isValid then
        g_materialManager:addParticleMaterial(fillTypeIndex, materialType, materialIndex, getMaterial(id, 0))
    end
end



---Called by particle holder to create particle system
-- @param any unused unused
-- @param integer id id
function MaterialUtil.onCreateParticleSystem(_, id)
    local particleTypeName = getUserAttribute(id, "particleType")
    if particleTypeName == nil then
        Logging.i3dWarning(id, "Missing 'particleType' user attribute for MaterialUtil.onCreateParticleSystem")
        return
    end

    local particleType = g_particleSystemManager:getParticleSystemTypeByName(particleTypeName)
    if particleType == nil then
        Logging.i3dWarning(id, "Unknown particleType '%s' given in 'particleType' user attribute for MaterialUtil.onCreateParticleSystem", particleTypeName)
        print(string.format("Available types: %s", table.concat(g_particleSystemManager.particleTypes, " ")))
        return
    end

    local defaultEmittingState = Utils.getNoNil(getUserAttribute(id, "defaultEmittingState"), false)
    local worldSpace = Utils.getNoNil(getUserAttribute(id, "worldSpace"), true)
    local forceFullLifespan = Utils.getNoNil(getUserAttribute(id, "forceFullLifespan"), false)

    local particleSystem = {}

    ParticleUtil.loadParticleSystemFromNode(id, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan)

    g_particleSystemManager:addParticleSystem(particleType, particleSystem)
end


---
function MaterialUtil.getMaterialBySlotName(node, materialName)
    if getHasClassId(node, ClassIds.SHAPE) then
        local numMaterials = getNumOfMaterials(node)
        for i=1, numMaterials do
            if getMaterialSlotName(node, i - 1) == materialName then
                return getMaterial(node, i - 1)
            end
        end
    end

    local numChildren = getNumOfChildren(node)
    for i=1, numChildren do
        local child = getChildAt(node, i - 1)
        local materialId = MaterialUtil.getMaterialBySlotName(child, materialName)
        if materialId ~= nil then
            return materialId
        end
    end

    return nil
end
