--------------------------------------------------------------------------------
-- Core.lua for CooldownManagerCustomizer
--------------------------------------------------------------------------------
local addonName, addonTable = ...
if not addonTable then
    DEFAULT_CHAT_FRAME:AddMessage(addonTable.L["ERROR_ADDON_TABLE_NOT_RECEIVED"], 1.0, 0.1, 0.1)
    return
end

_G[addonName] = addonTable

local db = nil
local optionsPopulated = false
-- preserve original blizz api function before hooking
local originalGetCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet

--------------------------------------------------------------------------------
-- Core Hook Logic
--------------------------------------------------------------------------------
local function HookedGetCooldownViewerCategorySet(category)
    local result = originalGetCategorySet(category)
    local potentialCooldownIDs = {}

    if type(result) == "table" then
        for key, value in pairs(result) do
            if type(value) == "number" then
                table.insert(potentialCooldownIDs, value)
            end
        end
    elseif type(result) == "number" then
        table.insert(potentialCooldownIDs, result)
    end

    -- sorting the table to improve efficiency
    table.sort(potentialCooldownIDs)

    if not db or not db.hiddenSpells or next(db.hiddenSpells) == nil then
        return potentialCooldownIDs 
    end

    local filteredCooldownIDsTable = {}
    for _, cooldownID in ipairs(potentialCooldownIDs) do
        if type(cooldownID) == "number" then
            local cooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            if cooldownInfo and cooldownInfo.spellID and not db.hiddenSpells[cooldownInfo.spellID] then
                table.insert(filteredCooldownIDsTable, cooldownID)
            end
        end
    end
    return filteredCooldownIDsTable
end

--------------------------------------------------------------------------------
-- Addon Functions (Attached to addonTable)
--------------------------------------------------------------------------------
function addonTable:RefreshCooldownViewers()
    local viewers = {
        _G["EssentialCooldownViewer"],
        _G["UtilityCooldownViewer"],
        _G["BuffIconCooldownViewer"],
        _G["BuffBarCooldownViewer"],
    }
    for _, viewerFrame in ipairs(viewers) do
        if viewerFrame and viewerFrame.RefreshLayout then
            viewerFrame:RefreshLayout()
        end
    end
end

function addonTable:PopulateOptionsIfReady()
    if optionsPopulated or not _G.GetSpellInfo then
        return
    end

    if addonTable.PopulateOptions then
        optionsPopulated = true
        addonTable:PopulateOptions()
    else
        print(string.format(addonTable.L["ERROR_POPULATE_OPTIONS_NOT_FOUND"], addonName))
    end
end

function addonTable:OnInitialize()
    -- should only setup db once - debug details removed to look for multiple
    if not db then
        CooldownViewerFilterDB = CooldownViewerFilterDB or {}
        CooldownViewerFilterDB.hiddenSpells = CooldownViewerFilterDB.hiddenSpells or {}
        db = CooldownViewerFilterDB
    end
    if C_CooldownViewer.GetCooldownViewerCategorySet == originalGetCategorySet then
        C_CooldownViewer.GetCooldownViewerCategorySet = HookedGetCooldownViewerCategorySet
    end
end

--------------------------------------------------------------------------------
-- Event Handling Frame
--------------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("SPELLS_CHANGED")

initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addonTable:OnInitialize()
    elseif event == "SPELLS_CHANGED" then
        addonTable:PopulateOptionsIfReady()
    end
end)

-------------------
-- Adding spell ID to tooltip by default
-------------------
local function AddSpellIDToTooltip(tooltip, data)
    local spellName, spellID = tooltip:GetSpell()
    if spellID then
        tooltip:AddLine(" ")
        tooltip:AddLine(addonTable.L["SPELL_ID_TOOLTIP"] .. tostring(spellID), 1, 1, 1)
    end
end
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddSpellIDToTooltip)

--------------------------------------------------------------------------------
-- Slash Command Handler
--------------------------------------------------------------------------------
SLASH_COOLDOWNMANAGERFILTER1 = "/cmc"
SlashCmdList["COOLDOWNMANAGERFILTER"] = function(msg)
    local AddonGlobalTable = _G[addonName]
    if not AddonGlobalTable or not AddonGlobalTable.RefreshCooldownViewers then
        print(string.format(addonTable.L["ERROR_ADDON_NOT_READY"], addonName))
        return
    end
    if not db then
        print(string.format(addonTable.L["ERROR_DATABASE_NOT_READY"], addonName))
        return
    end

    msg = msg and strtrim(msg) or ""
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    if not cmd then cmd = "" end
    cmd = cmd:lower()
    arg = strtrim(arg)

    local needsRefresh = false
    local spellID = tonumber(arg)

    if cmd == "config" or cmd == "cfg" then
        AddonGlobalTable:ToggleConfigUI()
        needsRefresh = false -- cfg or config won't need a full UI reload to work
    elseif cmd == "hide" then
        if spellID then
            if db.hiddenSpells[spellID] then
                print(string.format(addonTable.L["SPELL_ALREADY_HIDDEN"], addonName, spellID))
            else
                db.hiddenSpells[spellID] = true
                print(string.format(addonTable.L["HIDING_SPELL"], addonName, spellID))
                needsRefresh = true
            end
        else
            print(string.format(addonTable.L["USAGE_HIDE"], addonName))
        end
    elseif cmd == "show" then
        if spellID then
            if not db.hiddenSpells[spellID] then
                print(string.format(addonTable.L["SPELL_ALREADY_SHOWN"], addonName, spellID))
            else
                db.hiddenSpells[spellID] = nil -- nil removes from saved list
                print(string.format(addonTable.L["SHOWING_SPELL"], addonName, spellID))
                needsRefresh = true
            end
        else
            print(string.format(addonTable.L["USAGE_SHOW"], addonName))
        end
    elseif cmd == "toggle" then
        if spellID then
            if db.hiddenSpells[spellID] then
                db.hiddenSpells[spellID] = nil
                print(string.format(addonTable.L["TOGGLING_SPELL_SHOWN"], addonName, spellID))
            else
                db.hiddenSpells[spellID] = true
                print(string.format(addonTable.L["TOGGLING_SPELL_HIDDEN"], addonName, spellID))
            end
            needsRefresh = true
        else
            print(string.format(addonTable.L["USAGE_TOGGLE"], addonName))
        end
    elseif cmd == "list" then
        print(string.format(addonTable.L["LIST_HIDDEN_SPELLS"], addonName))
        local found = false
        for id, hidden in pairs(db.hiddenSpells) do
            if hidden == true then
                print("- " .. id)
                found = true
            end
        end
        if not found then print(addonTable.L["NO_HIDDEN_SPELLS"]) end
        needsRefresh = false
    elseif cmd == "refresh" then
        print(string.format(addonTable.L["MANUAL_REFRESH"], addonName))
        needsRefresh = true
    elseif cmd == "" then 
        needsRefresh = false
        print(string.format(addonTable.L["COMMANDS_HEADER"], addonName))
        print(addonTable.L["COMMAND_CONFIG"])
        print(addonTable.L["COMMAND_HIDE"])
        print(addonTable.L["COMMAND_SHOW"])
        print(addonTable.L["COMMAND_TOGGLE"])
        print(addonTable.L["COMMAND_LIST"])
        print(addonTable.L["COMMAND_REFRESH"])
    else 
        print(string.format(addonTable.L["UNKNOWN_COMMAND"], addonName, cmd))
        needsRefresh = false
    end

    -- short delay for refresh execute in case of server tick rate issue
    if needsRefresh then
        C_Timer.After(0.1, function()
            local CurrentAddonTable = _G[addonName]
            if CurrentAddonTable and CurrentAddonTable.RefreshCooldownViewers then
                CurrentAddonTable:RefreshCooldownViewers()
            else
                -- if this happens the whole addon is super broke. should never see this.
                print(string.format(addonTable.L["ERROR_REFRESH_FUNCTION_NOT_FOUND"], addonName))
            end
        end)
    end
end
