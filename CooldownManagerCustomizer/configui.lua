--------------------------------------------------------------------------------
-- ConfigUI.lua for CooldownManagerCustomizer

-- New plan: I'll just put in a list of spells and their corresponding spell ID'S
-- I'll figure out how to make them clickable later
-- Mango - 4/18/25

--------------------------------------------------------------------------------
local addonName, addonTable = ...
if not addonTable 
    then print("CooldownManagerCustomizer: ERROR - ConfigUI.lua loaded but addonTable is missing!") 
    return
end

local db = nil
local listLineFrames = {}
local CONFIG_FRAME_NAME = addonName .. "ConfigFrame"

--------------------------------------------------------------------------------
-- Main UI Creation Function
--------------------------------------------------------------------------------
function addonTable:CreateConfigUI()
    if _G[CONFIG_FRAME_NAME] then return end

    local mainFrame = CreateFrame("Frame", CONFIG_FRAME_NAME, UIParent, "BasicFrameTemplate")
    if not mainFrame then print(addonName..": ERROR - Failed to create main frame!") return end
    mainFrame:SetSize(400, 350)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartSizing() else self:StartMoving() end end)
    -- note: shift to drag and resize causes a lua error. i'll fix this later.
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetToplevel(true)
    mainFrame:Hide()

    C_Timer.After(0, function()
        if not mainFrame or not mainFrame:GetName() then return end
        if not db and _G.CooldownViewerFilterDB then db = _G.CooldownViewerFilterDB end
        --if this happens something is really broke.
        if not db then print(addonName .. ": Config Timer - ERROR - DB not found! Cannot create content.")
            return end

        if _G[CONFIG_FRAME_NAME .. "TitleText"] then _G[CONFIG_FRAME_NAME .. "TitleText"]:Hide() end
        if _G[CONFIG_FRAME_NAME .. "CloseButton"] then _G[CONFIG_FRAME_NAME .. "CloseButton"]:Hide() end

        --title
        if not mainFrame.myTitleText then -- Create only once
            local titleText = mainFrame:CreateFontString(CONFIG_FRAME_NAME .. "MyTitleText", "ARTWORK", "GameFontNormalLarge")
            titleText:SetPoint("TOP", mainFrame, "TOP", -15, -3)
            titleText:SetText(addonName .. " Configuration")
            mainFrame.myTitleText = titleText
        end

        --content
        if not mainFrame.contentFrame then
            local contentFrame = CreateFrame("Frame", CONFIG_FRAME_NAME .. "Content", mainFrame)
            contentFrame:SetPoint("TOPLEFT", 10, -32)
            contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
            mainFrame.contentFrame = contentFrame
        end
        local contentFrame = mainFrame.contentFrame

        --addSpell
        if not mainFrame.addEditBox then
            local addLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            addLabel:SetPoint("TOPLEFT", 5, -5)
            addLabel:SetText("Spell ID to Hide:")
            addLabel:Show()

            local addEditBox = CreateFrame("EditBox", CONFIG_FRAME_NAME.."AddBox", contentFrame, "InputBoxTemplate")
            addEditBox:SetPoint("LEFT", addLabel, "RIGHT", 5, 0)
            addEditBox:SetSize(100, 20)
            addEditBox:SetAutoFocus(false)
            addEditBox:SetNumeric(true)
            addEditBox:SetMaxLetters(10)
            addEditBox:SetScript("OnEnterPressed", function(self)
                local spellID = tonumber(self:GetText())
                    if spellID then 
                        addonTable:HideSpellFromConfig(spellID)
                        self:SetText("")
                    end
                    self:ClearFocus()
                end)
            addEditBox:Show()
            mainFrame.addEditBox = addEditBox

            local addButton = CreateFrame("Button", CONFIG_FRAME_NAME.."AddButton", contentFrame, "UIPanelButtonTemplate")
            addButton:SetPoint("LEFT", addEditBox, "RIGHT", 5, 0)
            addButton:SetSize(60, 22)
            addButton:SetText("Hide")
            addButton:SetScript("OnClick", function()
            local spellID = tonumber(addEditBox:GetText()); if spellID then addonTable:HideSpellFromConfig(spellID); addEditBox:SetText(""); end
            end)
            addButton:Show()

            local listLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            listLabel:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -15)
            listLabel:SetText("Currently Hidden Spell IDs:")
            listLabel:Show()
            mainFrame.listLabel = listLabel -- Store reference if needed
        end

         -- frame should scroll. sometimes it doesn't? i'll fix later.
        if not mainFrame.scrollFrame then
            local scrollFrame = CreateFrame("ScrollFrame", CONFIG_FRAME_NAME .. "ListScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", mainFrame.listLabel, "BOTTOMLEFT", -5, -5)
            scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -25, 5)
            mainFrame.scrollFrame = scrollFrame

            local scrollChild = CreateFrame("Frame", CONFIG_FRAME_NAME .. "ListScrollChild", scrollFrame)
            scrollChild:SetWidth(scrollFrame:GetWidth() - 5)
            scrollChild:SetHeight(10)
            scrollFrame:SetScrollChild(scrollChild)
            mainFrame.scrollChild = scrollChild
        end
        addonTable:RefreshConfigUI()
    end)
end

--------------------------------------------------------------------------------
-- UI Action Functions
--------------------------------------------------------------------------------
function addonTable:HideSpellFromConfig(spellID)
    if not spellID then return end
    if not db then print(addonName .. ": DB not ready"); return end

    if db.hiddenSpells[spellID] then
        print(addonName .. ": SpellID", spellID, "is already hidden.")
        return
    end

    db.hiddenSpells[spellID] = true
    print(addonName .. ": Hiding SpellID", spellID)
    addonTable:RefreshConfigUI()

    -- delay in case of server tick rate issue
    C_Timer.After(0.1, function()
        if _G[addonName] and _G[addonName].RefreshCooldownViewers then
            _G[addonName]:RefreshCooldownViewers()
        end
    end)
end

function addonTable:ShowSpellFromConfig(spellID)
    if not spellID then return end
    if not db then print(addonName .. ": DB not ready"); return end

    if not db.hiddenSpells[spellID] then
        print(addonName .. ": SpellID", spellID, "is already shown.")
        return
    end

    db.hiddenSpells[spellID] = nil -- keep as nil otherwise it breaks
    print(addonName .. ": Showing SpellID", spellID)
    addonTable:RefreshConfigUI()

     -- queue the actual game UI refresh with delay
    C_Timer.After(0.1, function()
        if _G[addonName] and _G[addonName].RefreshCooldownViewers then
             _G[addonName]:RefreshCooldownViewers()
        end
    end)
end

--------------------------------------------------------------------------------
-- UI Update Function (Populates the scroll list)
--------------------------------------------------------------------------------

function addonTable:RefreshConfigUI()

    if not db and _G.CooldownViewerFilterDB then
        db = _G.CooldownViewerFilterDB
    end
    if not db then
        return -- Cannot proceed without DB
    end
    if not db.hiddenSpells then
        db.hiddenSpells = {}
    end

    local mainFrame = _G[CONFIG_FRAME_NAME]
    if not mainFrame then
        return
    end

    local scrollChild = mainFrame.scrollChild
    if not scrollChild then
        return
    end
    if type(scrollChild) ~= "table" or not scrollChild.GetName then
        return
    end


    for _, frame in ipairs(listLineFrames) do
        if frame and frame.Hide then frame:Hide() end
    end
    wipe(listLineFrames)

    local yOffset = -2
    local lineHeight = 20
    local listWidth = scrollChild:GetWidth()
    if not listWidth or listWidth <= 20 then listWidth = 280; print(addonName .. ": RefreshConfigUI - Warning: Invalid scrollChild width, using default 280.") end

    local sortedIDs = {}
    local hiddenCount = 0
    if type(db.hiddenSpells) == "table" then
        for id, hidden in pairs(db.hiddenSpells) do
            if hidden == true then
                table.insert(sortedIDs, id)
                hiddenCount = hiddenCount + 1
            end
        end
        table.sort(sortedIDs)
    end

    if hiddenCount == 0 then
        scrollChild:SetHeight(10)
        return
    end

    for i, spellID in ipairs(sortedIDs) do
        local lineFrameName = CONFIG_FRAME_NAME .. "ListLine" .. spellID
        local lineFrame = CreateFrame("Frame", lineFrameName, scrollChild)

        if lineFrame then
            lineFrame:SetSize(listWidth, lineHeight - 2)
            lineFrame:SetPoint("TOPLEFT", 0, yOffset)

            local idText = lineFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            if idText then
                idText:SetPoint("LEFT", 5, 0)
                idText:SetJustifyH("LEFT")
                idText:SetWidth(listWidth - 75)
                idText:SetText("ID: " .. spellID)

                local showButton = CreateFrame("Button", nil, lineFrame, "UIPanelButtonTemplate")
                if showButton then
                    showButton:SetSize(60, 18)
                    showButton:SetPoint("RIGHT", -5, 0)
                    showButton:SetText("Show")
                    showButton:SetScript("OnClick", function()
                        addonTable:ShowSpellFromConfig(spellID)
                    end)

                    lineFrame:Show()
                    table.insert(listLineFrames, lineFrame)
                    yOffset = yOffset - lineHeight

                else -- showButton failed
                    print(addonName .. ":    ERROR - Failed to create showButton for SpellID:", spellID)
                    lineFrame:Hide()
                end
            else -- idText failed
                print(addonName .. ":    ERROR - Failed to create idText for SpellID:", spellID)
                lineFrame:Hide()
            end
        else -- lineFrame failed
            print(addonName .. ":    ERROR - Failed to create lineFrame for SpellID:", spellID)
        end
    end
    local totalHeight = math.abs(yOffset) + 2
    if scrollChild and scrollChild.SetHeight then
         scrollChild:SetHeight(math.max(10, totalHeight))
    else
         print(addonName..": RefreshConfigUI - ERROR: scrollChild invalid before SetHeight.")
    end
end

--------------------------------------------------------------------------------
-- UI Toggling Function
--------------------------------------------------------------------------------
function addonTable:ToggleConfigUI()
    if not _G[CONFIG_FRAME_NAME] then
        addonTable:CreateConfigUI()
        --server tick rate protection
        C_Timer.After(0.1, function() addonTable:ToggleConfigUI() end)
        return
    end

    local mainFrame = _G[CONFIG_FRAME_NAME]
    if mainFrame then
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            if not db and _G.CooldownViewerFilterDB then db = _G.CooldownViewerFilterDB end
            if db then
                addonTable:RefreshConfigUI()
            else
                print(addonName..": Cannot refresh config UI on show, DB not ready.")
            end
            mainFrame:Show()
        end
    end
end
