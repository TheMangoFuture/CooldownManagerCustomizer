local addonName, addonTable = ...

-- Localization table
local L = setmetatable({}, {
    __index = function(t, k)
        return k -- Fallback to the key if no translation is found
    end
})

addonTable.L = L

-- English (enUS) - Default
L["ERROR_ADDON_TABLE_NOT_RECEIVED"] = "|cffff0000ERROR:|r CooldownManagerCustomizer - addonTable not received from loader!"
L["ERROR_POPULATE_OPTIONS_NOT_FOUND"] = "%s: Error - PopulateOptions function (expected in Options.lua) not found!"
L["ERROR_ADDON_NOT_READY"] = "%s: Error - Addon not fully ready."
L["ERROR_DATABASE_NOT_READY"] = "%s: Error - Database not ready."
L["USAGE_HIDE"] = "%s: Usage: /cmc hide <SpellID>"
L["USAGE_SHOW"] = "%s: Usage: /cmc show <SpellID>"
L["USAGE_TOGGLE"] = "%s: Usage: /cmc toggle <SpellID>"
L["SPELL_ALREADY_HIDDEN"] = "%s: SpellID %s is already hidden."
L["SPELL_ALREADY_SHOWN"] = "%s: SpellID %s is already shown (or was never hidden)."
L["HIDING_SPELL"] = "%s: Hiding SpellID %s"
L["SHOWING_SPELL"] = "%s: Showing SpellID %s"
L["TOGGLING_SPELL_SHOWN"] = "%s: Toggling SpellID %s to SHOWN"
L["TOGGLING_SPELL_HIDDEN"] = "%s: Toggling SpellID %s to HIDDEN"
L["LIST_HIDDEN_SPELLS"] = "%s: Currently Hidden Spell IDs:"
L["NO_HIDDEN_SPELLS"] = "(None)"
L["MANUAL_REFRESH"] = "%s: Manual refresh requested."
L["ERROR_REFRESH_FUNCTION_NOT_FOUND"] = "%s: Error - Addon table/refresh function not found in delayed timer."
L["UNKNOWN_COMMAND"] = "%s: Unknown command '%s'. Type /cmc for help."
L["COMMANDS_HEADER"] = "%s: Commands:"
L["COMMAND_CONFIG"] = "/cmc config - Opens the configuration window"
L["COMMAND_HIDE"] = "/cmc hide <SpellID> - Hides a spell"
L["COMMAND_SHOW"] = "/cmc show <SpellID> - Shows a spell"
L["COMMAND_TOGGLE"] = "/cmc toggle <SpellID> - Toggles hiding a spell"
L["COMMAND_LIST"] = "/cmc list - Lists currently hidden SpellIDs"
L["COMMAND_REFRESH"] = "/cmc refresh - Manually refreshes the CooldownViewer UI"
L["SPELL_ID_TOOLTIP"] = "Spell ID: "

-- Russian (ruRU)
if GetLocale() == "ruRU" then
    L["ERROR_ADDON_TABLE_NOT_RECEIVED"] = "|cffff0000ОШИБКА:|r CooldownManagerCustomizer - addonTable не получен от загрузчика!"
    L["ERROR_POPULATE_OPTIONS_NOT_FOUND"] = "%s: Ошибка - функция PopulateOptions (ожидается в Options.lua) не найдена!"
    L["ERROR_ADDON_NOT_READY"] = "%s: Ошибка - аддон не полностью готов."
    L["ERROR_DATABASE_NOT_READY"] = "%s: Ошибка - база данных не готова."
    L["USAGE_HIDE"] = "%s: Использование: /cmc hide <SpellID>"
    L["USAGE_SHOW"] = "%s: Использование: /cmc show <SpellID>"
    L["USAGE_TOGGLE"] = "%s: Использование: /cmc toggle <SpellID>"
    L["SPELL_ALREADY_HIDDEN"] = "%s: SpellID %s уже скрыт."
    L["SPELL_ALREADY_SHOWN"] = "%s: SpellID %s уже отображается (или никогда не был скрыт)."
    L["HIDING_SPELL"] = "%s: Скрытие SpellID %s"
    L["SHOWING_SPELL"] = "%s: Отображение SpellID %s"
    L["TOGGLING_SPELL_SHOWN"] = "%s: Переключение SpellID %s на ОТОБРАЖЕНИЕ"
    L["TOGGLING_SPELL_HIDDEN"] = "%s: Переключение SpellID %s на СКРЫТИЕ"
    L["LIST_HIDDEN_SPELLS"] = "%s: Текущие скрытые SpellID:"
    L["NO_HIDDEN_SPELLS"] = "(Нет)"
    L["MANUAL_REFRESH"] = "%s: Запрошен ручной перезапуск."
    L["ERROR_REFRESH_FUNCTION_NOT_FOUND"] = "%s: Ошибка - таблица аддона/функция обновления не найдена в отложенном таймере."
    L["UNKNOWN_COMMAND"] = "%s: Неизвестная команда '%s'. Введите /cmc для помощи."
    L["COMMANDS_HEADER"] = "%s: Команды:"
    L["COMMAND_CONFIG"] = "/cmc config - Открывает окно настроек"
    L["COMMAND_HIDE"] = "/cmc hide <SpellID> - Скрывает заклинание"
    L["COMMAND_SHOW"] = "/cmc show <SpellID> - Показывает заклинание"
    L["COMMAND_TOGGLE"] = "/cmc toggle <SpellID> - Переключает скрытие заклинания"
    L["COMMAND_LIST"] = "/cmc list - Список текущих скрытых SpellID"
    L["COMMAND_REFRESH"] = "/cmc refresh - Ручное обновление интерфейса CooldownViewer"
    L["SPELL_ID_TOOLTIP"] = "ID заклинания: "
end
