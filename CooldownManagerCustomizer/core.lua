--------------------------------------------------------------------------------
-- Core.lua for CooldownManagerCustomizer
--------------------------------------------------------------------------------
local addonName, addonTable = ...
if not addonTable then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR:|r CooldownManagerCustomizer - addonTable not received from loader!", 1.0, 0.1, 0.1)
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

    --sorting the table to improve efficiency
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
        print(addonName .. ": Error - PopulateOptions function (expected in Options.lua) not found!")
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
            tooltip:AddLine("Spell ID: " .. tostring(spellID), 1, 1, 1)
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
         print(addonName .. ": Error - Addon not fully ready.")
         return
    end
    if not db then
         print(addonName .. ": Error - Database not ready.")
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
                print(addonName .. ": SpellID", spellID, "is already hidden.")
            else
                db.hiddenSpells[spellID] = true
                print(addonName .. ": Hiding SpellID", spellID)
                needsRefresh = true
            end
        else
            print(addonName .. ": Usage: /cmc hide <SpellID>")
        end
    elseif cmd == "show" then
        if spellID then
            if not db.hiddenSpells[spellID] then
                 print(addonName .. ": SpellID", spellID, "is already shown (or was never hidden).")
            else
                db.hiddenSpells[spellID] = nil -- nil removes from saved list
                print(addonName .. ": Showing SpellID", spellID)
                needsRefresh = true
            end
        else
            print(addonName .. ": Usage: /cmc show <SpellID>")
        end
    elseif cmd == "toggle" then
         if spellID then
             if db.hiddenSpells[spellID] then
                 db.hiddenSpells[spellID] = nil
                 print(addonName .. ": Toggling SpellID", spellID, "to SHOWN")
             else
                 db.hiddenSpells[spellID] = true
                 print(addonName .. ": Toggling SpellID", spellID, "to HIDDEN")
             end
             needsRefresh = true
         else
             print(addonName .. ": Usage: /cmc toggle <SpellID>")
         end
    elseif cmd == "list" then
        print(addonName .. ": Currently Hidden Spell IDs:")
        local found = false
        for id, hidden in pairs(db.hiddenSpells) do
            if hidden == true then
                print("- " .. id)
                found = true
            end
        end
        if not found then print("(None)") end
        needsRefresh = false
    elseif cmd == "refresh" then
        print(addonName .. ": Manual refresh requested.")
        needsRefresh = true
    elseif cmd == "" then 
        needsRefresh = false
        print(addonName .. ": Commands:")
        print("/cmc config - Opens the configuration window")
        print("/cmc hide <SpellID> - Hides a spell")
        print("/cmc show <SpellID> - Shows a spell")
        print("/cmc toggle <SpellID> - Toggles hiding a spell")
        print("/cmc list - Lists currently hidden SpellIDs")
        print("/cmc refresh - Manually refreshes the CooldownViewer UI")
    else 
         print(addonName .. ": Unknown command '" .. cmd .. "'. Type /cmc for help.")
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
                 print(addonName .. ": Error - Addon table/refresh function not found in delayed timer.")
            end
        end)
    end
end