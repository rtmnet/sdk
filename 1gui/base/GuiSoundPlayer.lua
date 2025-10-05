









---This class loads known GUI sound samples as non-spatial samples to be played in the GUI (menu and HUD).
local GuiSoundPlayer_mt = Class(GuiSoundPlayer)















































































---Create a new GuiSoundPlayer instance.
-- @param table soundManager SoundManager reference
-- @return GuiSoundPlayer self
function GuiSoundPlayer.new(soundManager)
    local self = setmetatable({}, GuiSoundPlayer_mt)

    self.soundManager = soundManager
    self.soundSamples = self:loadSounds(GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH) -- name -> sample

    return self
end











---Load GUI sound samples from definitions.
function GuiSoundPlayer:loadSounds(sampleDefinitionXmlPath)
    local samples = {}

    local xmlFile = loadXMLFile("GuiSampleDefinitions", sampleDefinitionXmlPath)
    if xmlFile ~= nil and xmlFile ~= 0 then

        for _, key in pairs(GuiSoundPlayer.SOUND_SAMPLES) do
            if key ~= GuiSoundPlayer.SOUND_SAMPLES.NONE then
                local sample = self.soundManager:loadSample2DFromXML(xmlFile, GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT, key, "", 1, AudioGroup.GUI)
                if sample ~= nil then
                    local sampleList = {}
                    samples[key] = sampleList

                    -- Build a whole queue so we can play multiple sounds at once
                    table.insert(sampleList, sample)
                    for i = 2, GuiSoundPlayer.NUM_SAMPLES_PER_SOUND do
                        table.insert(sampleList, self.soundManager:cloneSample2D(sample))
                    end

                else
                    printWarning("Warning: Could not load GUI sound sample [" .. tostring(key) .. "]")
                end
            end
        end

        delete(xmlFile)
    end

    return samples
end


---Play a GUI sound sample identified by name.
-- The sample must have been loaded when the GUI was created.
-- @param string sampleName Name of the sample to play, use one of the identifiers in GuiSoundPlayer.SOUND_SAMPLES.
function GuiSoundPlayer:playSample(sampleName)
    if sampleName == GuiSoundPlayer.SOUND_SAMPLES.NONE then
        return
    end

    local sampleList = self.soundSamples[sampleName]

    if sampleList ~= nil then
        if sampleList.lastTime ~= nil and g_time - sampleList.lastTime < GuiSoundPlayer.SAMPLE_REPLAY_TIMEOUT then
            return
        end

        -- Get first free
        local sample
        for i = 1, #sampleList do
            if not self.soundManager:getIsSamplePlaying(sampleList[i]) then
                sample = sampleList[i]
                break
            end
        end

        if sample ~= nil then
            self.soundManager:playSample(sample)
            sampleList.lastTime = g_time
        end
    else
        Logging.devWarning("Tried playing GUI sample '%s' which has not been loaded.", sampleName)
    end
end
