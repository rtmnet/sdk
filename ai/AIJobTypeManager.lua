










---This class handles all npcs
local AIJobTypeManager_mt = Class(AIJobTypeManager)


---Creating manager
-- @return table instance instance of object
function AIJobTypeManager.new(isServer, customMt)
    local self = setmetatable({}, customMt or AIJobTypeManager_mt)

    self.isServer = isServer

    return self
end


---Load data on map load
-- @return boolean true if loading was successful else false
function AIJobTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    self.jobTypes = {}
    self.nameToIndex = {}
    self.classObjectToIndex = {}
    AIJobType = self.nameToIndex

    self:registerJobType("GOTO", "$l10n_ai_jobTitleGoto", AIJobGoTo)
    self:registerJobType("FIELDWORK", "$l10n_ai_jobTitleFieldWork", AIJobFieldWork)
    self:registerJobType("CONVEYOR", "$l10n_ai_jobTitleConveyor", AIJobConveyor)
    self:registerJobType("DELIVER", "$l10n_ai_jobTitleDeliver", AIJobDeliver)
    self:registerJobType("LOAD_AND_DELIVER", "$l10n_ai_jobTitleLoadAndDeliver", AIJobLoadAndDeliver)
end


---
function AIJobTypeManager:delete()
    self.jobTypes = {}
    self.nameToIndex = {}
    self.classObjectToIndex = {}
    AIJobType = self.nameToIndex
end


---
function AIJobTypeManager:registerJobType(name, title, classObject)
    if not ClassUtil.getIsValidIndexName(name) then
        Logging.warning("'%s' is not a valid name for a ai job type!", tostring(name))
        return nil
    end

    name = string.upper(name)

    if self.nameToIndex[name] ~= nil then
        Logging.warning("AI job type '%s' already exists!", tostring(name))
        return nil
    end

    local jobType = {}
    jobType.name = name
    jobType.title = g_i18n:convertText(title)
    jobType.classObject = classObject
    jobType.index = #self.jobTypes + 1

    table.insert(self.jobTypes, jobType)
    self.nameToIndex[name] = jobType.index
    self.classObjectToIndex[classObject] = jobType.index

    return jobType
end


---
function AIJobTypeManager:getJobTypeIndex(job)
    local classObject = ClassUtil.getClassObjectByObject(job)
    if classObject == nil then
        return nil
    end

    return self.classObjectToIndex[classObject]
end


---
function AIJobTypeManager:createJob(typeIndex)
    if typeIndex == nil then
        return nil
    end

    local jobType = self.jobTypes[typeIndex]
    if jobType == nil then
        return nil
    end

    local job = jobType.classObject.new(self.isServer)
    job.jobTypeIndex = typeIndex

    return job
end


---
function AIJobTypeManager:getJobTypeByIndex(index)
    return self.jobTypes[index]
end


---
function AIJobTypeManager:getJobTypeIndexByName(name)
    if name == nil then
        return nil
    end

    name = string.upper(name)

    return self.nameToIndex[name]
end
