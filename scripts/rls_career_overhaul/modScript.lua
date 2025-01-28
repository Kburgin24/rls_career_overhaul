local function loadExtensions()
    print("Starting extension loading sequence")
    
    if extensions.isExtensionLoaded("core_recoveryPrompt") then
        extensions.unload("core_recoveryPrompt")
    end
    load("core_recoveryPrompt")
    setExtensionUnloadMode("core_recoveryPrompt", "manual")

    if extensions.isExtensionLoaded("gameplay_traffic") then
        extensions.unload("gameplay_traffic")
    end
    load("gameplay_traffic")
    setExtensionUnloadMode("gameplay_traffic", "manual")

    if extensions.isExtensionLoaded("gameplay_traffic_vehicle") then
        extensions.unload("gameplay_traffic_vehicle")
    end
    load("gameplay_traffic_vehicle")
    setExtensionUnloadMode("gameplay_traffic_vehicle", "manual")

    if extensions.isExtensionLoaded("gameplay_events_freeroam_init") then
        extensions.unload("gameplay_events_freeroam_init")
    end
    load("gameplay_events_freeroam_init")
    setExtensionUnloadMode("gameplay_events_freeroam_init", "manual")

    if extensions.isExtensionLoaded("career_saveSystem") then
        extensions.unload("career_saveSystem")
    end
    load("career_saveSystem")
    setExtensionUnloadMode("career_saveSystem", "manual")

    if extensions.isExtensionLoaded("career_career") then
        extensions.unload("career_career")
    end
    load("career_career")
    setExtensionUnloadMode("career_career", "manual")

    if extensions.isExtensionLoaded("UIloader") then
        extensions.unload("UIloader")
    end
    load("UIloader")
    setExtensionUnloadMode("UIloader", "manual")
end

if not core_gamestate.state or core_gamestate.state.state ~= "career" then
    loadExtensions()
end