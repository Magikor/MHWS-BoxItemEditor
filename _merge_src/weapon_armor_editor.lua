if rawget(_G, "__MHWS_WEAPON_ARMOR_EDITOR_LOADED") == true then
    return
end
_G.__MHWS_WEAPON_ARMOR_EDITOR_LOADED = true

local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type
local _ = _

local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local Imgui = require("_CatLib.imgui")
local Utils = require("_CatLib.utils")

local mod = require("weapon_armor_editor.mod")
local EditorConf = require("weapon_armor_editor.conf")
local EditorUtils = require("weapon_armor_editor.utils")
local Editor = require("weapon_armor_editor.editor")
local Weapon = require("weapon_armor_editor.weapon")
local Armor = require("weapon_armor_editor.armor")

local STANDALONE_MENU_ENABLED = false

local function DumpGameOriginalData()
    for i = 0, 13, 1 do
        if not EditorConf.WeaponsOriginal[tostring(i)] then
            EditorConf.WeaponsOriginal[tostring(i)] = {}
        end
        local confs = EditorConf.WeaponsOriginal[tostring(i)]

        local values = EditorUtils.GetWeaponDataByWeaponType(i)
        if values then
            Core.ForEach(values, function (weaponData, i)
                local idxStr = tostring(weaponData._Index)
                if not confs[idxStr] then
                    confs[idxStr] = EditorUtils.WeaponConfigFromData(weaponData)
                else
                    -- local data = Utils.MergeTablesRecursive(EditorUtils.WeaponConfigFromData(weaponData), confs[idxStr])
                    -- confs[idxStr] = data
                end
            end)
        end

        EditorConf.WeaponsOriginal[tostring(i)] = confs
    end

    EditorConf.SaveWeaponOriginal()

    local armors = EditorUtils.GetArmorData()
    if armors then
        local values = armors._Values
        if values then
            Core.ForEach(values, function (armorData, i)
                local idxStr = tostring(armorData._Index)
                if not EditorConf.ArmorsOriginal[idxStr] then
                    EditorConf.ArmorsOriginal[idxStr] = EditorUtils.ArmorConfigFromData(armorData)
                else
                    -- local data = Utils.MergeTablesRecursive(EditorUtils.ArmorConfigFromData(armorData), EditorConf.ArmorsOriginal[idxStr])
                    -- EditorConf.ArmorsOriginal[idxStr] = data
                end
            end)
        end
    end

    EditorConf.SaveArmorOriginal()
end

Core.OnLoading(function ()
    local mgr = Core.GetVariousDataManager()
    if mgr == nil then return end

    DumpGameOriginalData()
    Weapon.ApplyModConfig()
    Armor.ApplyModConfig()

    if mod.Config.Debug then
        Core.SendMessage("Weapon Armor Editor applied")
    end
end)

-- local ArmorSeriesFixedToSeries = Core.TypeField("app.ArmorDef", "FixedToSERIES"):get_data()
local ArmorSeriesNames = {}
local ArmorSeriesNamesInited = false
local function InitArmorSeriesName()
    if ArmorSeriesNamesInited then
        return
    end
    local mgr = Core.GetVariousDataManager()
    if mgr == nil then
        return
    end

    local values = mgr._Setting._EquipDatas._ArmorSeriesData._Values
    if not values then
        return
    end
    Core.ForEach(values, function (value, i)
        local seriesFixed = value._Series._Value
        local series = Core.FixedToEnum("app.ArmorDef.SERIES", seriesFixed)
        if series then
        -- if ArmorSeriesFixedToSeries:ContainsKey(seriesFixed) then
            -- local series = ArmorSeriesFixedToSeries:get_Item(seriesFixed)
            if series > 0 then
                ArmorSeriesNames[series] = {
                    Name = Core.GetLocalizedText(value._Name),
                    Index = value._Index,
                }
            end
        end
    end)

    ArmorSeriesNamesInited = true
end

local function DrawWeaponArmorEditorMenu()
	local configChanged = false
    local changed = false

    local mgr = Core.GetVariousDataManager()
    if mgr == nil then
        imgui.text("Game not inited yet...")
        return
    end

    -- UI filters (helps with massive weapon/armor lists)
    EditorConf.Config.UI = EditorConf.Config.UI or {
        weaponFilter = "",
        armorFilter = "",
        weaponOnlyCustom = false,
        armorOnlyCustom = false,
    }
    local ui = EditorConf.Config.UI

    Imgui.Tree("UI Filters", function()
        imgui.push_item_width(260)
        changed, ui.weaponFilter = imgui.input_text("Search Weapons (name/id)##WeaponFilter", ui.weaponFilter)
        imgui.pop_item_width()
        configChanged = configChanged or changed
        imgui.same_line()
        if imgui.button("Clear##ClearWeaponFilter") then
            ui.weaponFilter = ""
            configChanged = true
        end
        changed, ui.weaponOnlyCustom = imgui.checkbox("Weapons: only custom", ui.weaponOnlyCustom)
        configChanged = configChanged or changed

        imgui.push_item_width(260)
        changed, ui.armorFilter = imgui.input_text("Search Armors (name/id)##ArmorFilter", ui.armorFilter)
        imgui.pop_item_width()
        configChanged = configChanged or changed
        imgui.same_line()
        if imgui.button("Clear##ClearArmorFilter") then
            ui.armorFilter = ""
            configChanged = true
        end
        changed, ui.armorOnlyCustom = imgui.checkbox("Armors: only custom", ui.armorOnlyCustom)
        configChanged = configChanged or changed
    end)

    Imgui.Tree("Clear Data", function ()
        Imgui.Button("Clear Weapon Data", function ()
            EditorConf.ClearWeaponData()
            Weapon.ApplyModConfig()
            mod.SaveConfig()
        end)

        Imgui.Button("Clear Armor Data", function ()
            EditorConf.ClearArmorData()
            Armor.ApplyModConfig()
            mod.SaveConfig()
        end)
    end)

    Imgui.Tree("Weapons", function ()
        Imgui.Button("Apply", function ()
            Weapon.ApplyModConfig()
        end)
        -- Imgui.Button("Temp Restore All (no affect saved data)", function ()
        --     Weapon.RestoreAll()
        -- end)

        Imgui.Tree("Global Settings", function ()
            imgui.text("If Override Value > 0, Final Value = Override Value")
            imgui.text("otherwise, Final Value = Origin Value * (Multiplier + 1) + Adder")
            Imgui.Tree("Adder", function ()
                changed, mod.Config.WeaponGlobalConfig.Adder = Editor.WeaponConfigGlobalAdderEditor(mod.Config.WeaponGlobalConfig.Adder)
                configChanged = configChanged or changed
            end)
            Imgui.Tree("Multiplier", function ()
                changed, mod.Config.WeaponGlobalConfig.Multiplier = Editor.WeaponConfigGlobalMultiplierEditor(mod.Config.WeaponGlobalConfig.Multiplier)
                configChanged = configChanged or changed
            end)
            Imgui.Tree("Override Value", function ()
                changed, EditorConf.Config.WeaponGlobalConfig.Override = Editor.WeaponConfigGlobalOverrideEditor(mod.Config.WeaponGlobalConfig.Override)
                configChanged = configChanged or changed
            end)
            
        end)

        for i = 0, 13, 1 do
            changed = Editor.InspectWeaponType(i)
            configChanged = configChanged or changed
        end
    end)

    Imgui.Tree("Armors", function ()
        InitArmorSeriesName()

        Imgui.Button("Apply", function ()
            Armor.ApplyModConfig()
        end)

        -- Imgui.Button("Temp Restore All (no affect saved data)", function ()
        --     Armor.RestoreAll()
        -- end)

        Imgui.Tree("Global Settings", function ()
            imgui.text("If Override Value > 0, Final Value = Override Value")
            imgui.text("otherwise, Final Value = Origin Value * (Multiplier + 1) + Adder")
            Imgui.Tree("Adder", function ()
                changed, mod.Config.ArmorGlobalConfig.Adder = Editor.ArmorConfigGlobalAdderEditor(mod.Config.ArmorGlobalConfig.Adder)
                configChanged = configChanged or changed
            end)
            Imgui.Tree("Multiplier", function ()
                changed, mod.Config.ArmorGlobalConfig.Multiplier = Editor.ArmorConfigGlobalMultiplierEditor(mod.Config.ArmorGlobalConfig.Multiplier)
                configChanged = configChanged or changed
            end)
            Imgui.Tree("Override Value", function ()
                changed, mod.Config.ArmorGlobalConfig.Override = Editor.ArmorConfigGlobalOverrideEditor(mod.Config.ArmorGlobalConfig.Override)
                configChanged = configChanged or changed
            end)
            
        end)

        local armorData = mgr._Setting._EquipDatas._ArmorData._Table
        Core.ForEachDict(armorData, function (series, armorSet)
            local name = ArmorSeriesNames[series]
            if name then
                local seriesMatches = true
                local q = tostring((EditorConf.Config.UI and EditorConf.Config.UI.armorFilter) or "")
                if q ~= "" then
                    local qLower = q:lower()
                    local label = string.format("[%d] %s", name.Index, name.Name)
                    seriesMatches = label:lower():find(qLower, 1, true) ~= nil or tostring(series):find(q, 1, true) ~= nil
                end
                if not seriesMatches then
                    return
                end

                Imgui.Tree(string.format("[%d] %s", name.Index, name.Name), function ()
                    changed = Editor.InspectArmorData(armorSet:get_Helm())
                    configChanged = configChanged or changed
                    changed = Editor.InspectArmorData(armorSet:get_Chest())
                    configChanged = configChanged or changed
                    changed = Editor.InspectArmorData(armorSet:get_Arms())
                    configChanged = configChanged or changed
                    changed = Editor.InspectArmorData(armorSet:get_Waist())
                    configChanged = configChanged or changed
                    changed = Editor.InspectArmorData(armorSet:get_Legs())
                    configChanged = configChanged or changed
                end)
            end
        end)

    end)

    if configChanged then
        Weapon.ApplyModConfig()
        Armor.ApplyModConfig()
    end

    return configChanged

end

_G.__MHWS_EDITOR_SUITE = _G.__MHWS_EDITOR_SUITE or {}
_G.__MHWS_EDITOR_SUITE.draw_weapon_armor_editor = DrawWeaponArmorEditorMenu

if STANDALONE_MENU_ENABLED then
    mod.Menu(DrawWeaponArmorEditorMenu)
end