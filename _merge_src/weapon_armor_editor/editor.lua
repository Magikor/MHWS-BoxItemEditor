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

local _M = {}

local WeaponTypeNames = Core.GetEnumMap("app.WeaponDef.TYPE")
WeaponTypeNames[-1] = nil
WeaponTypeNames[14] = nil

---@param def SharpnessDef
function _M.SharpnessDefEditor(def)
	local configChanged = false
    local changed = false

    local function _editKey(key)
        changed, def[key] = imgui.drag_int(key, def[key], 1, 0, 500)
        configChanged = configChanged or changed
    end

    imgui.text("Sharpness:")
    _editKey("Red")
    _editKey("Orange")
    _editKey("Yellow")
    _editKey("Green")
    _editKey("Blue")
    _editKey("White")
    _editKey("Purple")

    return configChanged, def
end

---@param def SlotDef
function _M.SlotDefEditor(def)
	local configChanged = false
    local changed = false

    local function _editKey(key)
        changed, def[key] = imgui.slider_int(key, def[key], 0, 3)
        configChanged = configChanged or changed
    end

    imgui.text("Slot Level:")
    _editKey("First")
    _editKey("Second")
    _editKey("Third")

    return configChanged, def
end

---@param def SkillDef
function _M.SkillDefEditor(def, isWeapon)
	local configChanged = false
    local changed = false
    
    local allSkillNames
    if isWeapon then
        allSkillNames = Core.GetAllWeaponSkills()
    else
        allSkillNames = Core.GetAllArmorSkills()
    end
    for i, skill in pairs(def.Skills) do
        local label = string.format("Skill %d", i)
        imgui.text(string.format("Skill %d: %d", i, skill.ID))

        changed, skill.ID = imgui.combo(label, skill.ID, allSkillNames)
        configChanged = configChanged or changed

        local maxLevel = Core.GetEquipSkillMaxLevel(skill.ID)
        if maxLevel > 0 then
            changed, skill.Level = imgui.slider_int(label .. " Level", skill.Level, 1, maxLevel)
            configChanged = configChanged or changed            
        end
    end

    return configChanged, def
end

local InsectLevel = Core.GetEnumMap("app.WeaponDef.ROD_INSECT_LV")
InsectLevel[-1] = nil
InsectLevel[Core.TypeField("app.WeaponDef.ROD_INSECT_LV", "MAX"):get_data()] = nil

local SwitchAxeBinType = Core.GetEnumMap("app.Wp08Def.BIN_TYPE")
SwitchAxeBinType[Core.TypeField("app.Wp08Def.BIN_TYPE", "MAX"):get_data()] = nil

local ChargeBladeBinType = Core.GetEnumMap("app.Wp09Def.BIN_TYPE")
ChargeBladeBinType[Core.TypeField("app.Wp09Def.BIN_TYPE", "MAX"):get_data()] = nil

local GunlanceShellType = Core.GetEnumMap("app.Wp07Def.SHELL_TYPE")
GunlanceShellType[Core.TypeField("app.Wp07Def.SHELL_TYPE", "MAX"):get_data()] = nil

local GunlanceShellLevel = Core.GetEnumMap("app.Wp07ShellLevel.SHELL_LV")
GunlanceShellLevel[Core.TypeField("app.Wp07ShellLevel.SHELL_LV", "MAX"):get_data()] = nil

local HuntingHornUniqueType = Core.GetEnumMap("app.Wp05Def.UNIQUE_TYPE")
HuntingHornUniqueType[Core.TypeField("app.Wp05Def.UNIQUE_TYPE", "MAX"):get_data()] = nil

local HuntingHornHibikiType = Core.GetEnumMap("app.Wp05Def.WP05_HIBIKI_SKILL_TYPE")
HuntingHornHibikiType[Core.TypeField("app.Wp05Def.WP05_HIBIKI_SKILL_TYPE", "MAX"):get_data()] = nil

local HuntingHornHighFreqType = Core.GetEnumMap("app.Wp05Def.WP05_MUSIC_SKILL_HIGH_FREQ_TYPE")
HuntingHornHighFreqType[Core.TypeField("app.Wp05Def.WP05_MUSIC_SKILL_HIGH_FREQ_TYPE", "MAX"):get_data()] = nil

---@param conf WeaponConfig
local function WeaponTypeEditor(conf, wpType)
    if not wpType then
        return false, conf
    end
	local configChanged = false
    local changed = false
    
    local function _header()
        imgui.text(string.format("%s options:", Core.GetWeaponTypeName(wpType)))
    end

    if wpType == CONST.WeaponType.InsectGlaive then
        
        _header()

        changed, conf.InsectGlaiveInsectLevel = imgui.combo("Insect Level", conf.InsectGlaiveInsectLevel, InsectLevel)
        configChanged = configChanged or changed

    elseif wpType == CONST.WeaponType.SwitchAxe then
        
        _header()

        changed, conf.SwitchAxeBinType = imgui.combo("Bin Type", conf.SwitchAxeBinType, SwitchAxeBinType)
        configChanged = configChanged or changed
    
        changed, conf.SwitchAxeBinValue = imgui.drag_int("Bin Value", conf.SwitchAxeBinValue, 1, 0, 1600)
        configChanged = configChanged or changed
    
    elseif wpType == CONST.WeaponType.Gunlance then
        
        _header()

        changed, conf.GunlanceShellType = imgui.combo("Shell Type", conf.GunlanceShellType, GunlanceShellType)
        configChanged = configChanged or changed
    
        changed, conf.GunlanceShellLevel = imgui.combo("Shell Level", conf.GunlanceShellLevel, GunlanceShellLevel)
        configChanged = configChanged or changed
    
    elseif wpType == CONST.WeaponType.HuntingHorn then
        
        _header()

        changed, conf.HuntingHornUniqueType = imgui.combo("Unique Type", conf.HuntingHornUniqueType, HuntingHornUniqueType)
        configChanged = configChanged or changed
    
        changed, conf.HuntingHornHibikiSkillType = imgui.combo("Hibiki Skill Type", conf.HuntingHornHibikiSkillType, HuntingHornHibikiType)
        configChanged = configChanged or changed
    
        changed, conf.HuntingHornHighFreqType = imgui.combo("High Freq Type", conf.HuntingHornHighFreqType, HuntingHornHighFreqType)
        configChanged = configChanged or changed
    
    elseif wpType == CONST.WeaponType.ChargeBlade then

        _header()

        changed, conf.ChargeBladeBinType = imgui.combo("Bin Type", conf.ChargeBladeBinType, ChargeBladeBinType)
        configChanged = configChanged or changed
    
    end

    return configChanged, conf
end

local WeaponAttr = Core.GetEnumMap("app.WeaponDef.ATTR")

---@param conf WeaponConfig
function _M.WeaponConfEditor(conf, overrideMode, wpType)
	local configChanged = false
    local changed = false
    local isFlagChange = false

    if not overrideMode then
        changed, conf.IsUsingCustomValues = imgui.checkbox("Use Custom Config (if false, use global settings instead)", conf.IsUsingCustomValues)
        configChanged = configChanged or changed
        isFlagChange = changed
    end

    changed, conf.Attack = imgui.drag_int("Attack", conf.Attack, 1, 10, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Defense = imgui.drag_int("Defense", conf.Defense, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Critical = imgui.drag_int("Critical", conf.Critical, 0, 0, 100)
    configChanged = configChanged or changed

    changed, conf.AttributeType = imgui.combo("Attribute Type", conf.AttributeType, WeaponAttr)
    configChanged = configChanged or changed

    if overrideMode or conf.AttributeType > 0 then
        changed, conf.AttributeValue = imgui.drag_int("Attribute Value", conf.AttributeValue, 1, 1, 1600)
        configChanged = configChanged or changed
    end

    changed, conf.SubAttributeType = imgui.combo("Sub Attribute Type", conf.SubAttributeType, WeaponAttr)
    configChanged = configChanged or changed

    if overrideMode or conf.SubAttributeType > 0 then
        changed, conf.SubAttributeValue = imgui.drag_int("Sub Attribute Value", conf.SubAttributeValue, 1, 1, 1600)
        configChanged = configChanged or changed
    end
    
    changed, conf.Sharpness = _M.SharpnessDefEditor(conf.Sharpness)
    configChanged = configChanged or changed

    changed, conf.Slot = _M.SlotDefEditor(conf.Slot)
    configChanged = configChanged or changed

    if not overrideMode and wpType ~= nil then
        changed, conf = WeaponTypeEditor(conf, wpType)
        configChanged = configChanged or changed
    end
    
    if not overrideMode then
        changed, conf.Skill = _M.SkillDefEditor(conf.Skill, true)
        configChanged = configChanged or changed
    end

    if configChanged and not isFlagChange then
        conf.IsUsingCustomValues = true
    end

    return configChanged, conf
end

---@param data app.user_data.WeaponData.cData
---@param index number
---@param wpType number
function _M.InspectWeaponData(data, arrIdx, wpType)
    ---@type number
    local index = data._Index
    local name = Core.GetWeaponName(data)

    local changed = false

    local wpTypeStr = tostring(wpType)
    local indexStr = tostring(index)

    if not EditorConf.Config.Weapons[wpTypeStr] then
        EditorConf.Config.Weapons[wpTypeStr] = {}
    end

    local conf = Utils.MergeTablesRecursive(EditorUtils.WeaponConfigFromData(data), EditorConf.Config.Weapons[wpTypeStr][indexStr])
    EditorConf.Config.Weapons[wpTypeStr][indexStr] = conf

    local open = imgui.tree_node(string.format("[%d] %s", index, name))
    if conf.IsUsingCustomValues then
        imgui.same_line()
        imgui.text(" Custom")
    end
    if open then
        changed, conf = _M.WeaponConfEditor(conf, false, wpType)

        if changed then
            EditorConf.Config.Weapons[wpTypeStr][indexStr] = conf
        end
        
        imgui.tree_pop()
    end

    return changed
end

function _M.InspectWeaponType(wpType)
    local values = EditorUtils.GetWeaponDataByWeaponType(wpType)
    if not values then
        imgui.text(string.format("Weapon Type: %s data not found", Core.GetWeaponTypeName(wpType)))
        return
    end

    local configChanged = false
    Imgui.Tree(Core.GetWeaponTypeName(wpType), function ()
        Core.ForEach(values, function (weaponData, i)
            local changed = _M.InspectWeaponData(weaponData, i, wpType)
            configChanged = configChanged or changed
        end)
    end)

    return configChanged
end

---@param conf WeaponGlobalConfigAdder
function _M.WeaponConfigGlobalAdderEditor(conf)
    local changed, configChanged = false, false

    changed, conf.Attack = imgui.drag_int("Attack", conf.Attack, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Defense = imgui.drag_int("Defense", conf.Defense, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Critical = imgui.drag_int("Critical", conf.Critical, 1, 0, 100)
    configChanged = configChanged or changed
    
    changed, conf.AttributeValue = imgui.drag_int("Attribute Value", conf.AttributeValue, 1, 0, 1600)
    configChanged = configChanged or changed

    changed, conf.SubAttributeValue = imgui.drag_int("Sub Attribute Value", conf.SubAttributeValue, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Sharpness = _M.SharpnessDefEditor(conf.Sharpness)
    configChanged = configChanged or changed

    changed, conf.Slot = _M.SlotDefEditor(conf.Slot)
    configChanged = configChanged or changed

    return configChanged, conf
end

---@param conf WeaponGlobalConfigMultiplier
function _M.WeaponConfigGlobalMultiplierEditor(conf)
    local changed, configChanged = false, false

    changed, conf.Attack = imgui.drag_float("Attack", conf.Attack, 0.01, 0, 10)
    configChanged = configChanged or changed
    
    changed, conf.Defense = imgui.drag_float("Defense", conf.Defense, 0.01, 0, 10)
    configChanged = configChanged or changed
    
    changed, conf.Critical = imgui.drag_float("Critical", conf.Critical, 0.01, 0, 10)
    configChanged = configChanged or changed
    
    changed, conf.AttributeValue = imgui.drag_float("Attribute Value", conf.AttributeValue, 0.01, 0, 10)
    configChanged = configChanged or changed

    changed, conf.SubAttributeValue = imgui.drag_float("Sub Attribute Value", conf.SubAttributeValue, 0.01, 0, 10)
    configChanged = configChanged or changed

    local function _editKey(key)
        changed, conf.Sharpness[key] = imgui.drag_float(key, conf.Sharpness[key], 0.01, 0, 10)
        configChanged = configChanged or changed
    end

    imgui.text("Sharpness:")
    _editKey("Red")
    _editKey("Orange")
    _editKey("Yellow")
    _editKey("Green")
    _editKey("Blue")
    _editKey("White")
    _editKey("Purple")

    return configChanged, conf
end

---@param conf WeaponGlobalConfigOverride
function _M.WeaponConfigGlobalOverrideEditor(conf)
    return _M.WeaponConfEditor(conf, true)
end

---@param def ResistanceDef
function _M.ResistanceDefEditor(def)
	local configChanged = false
    local changed = false

    local function _editKey(key)
        changed, def[key] = imgui.drag_int(key, def[key], 1, -100, 100)
        configChanged = configChanged or changed
    end

    imgui.text("Resistance:")
    _editKey("Fire")
    _editKey("Water")
    _editKey("Thunder")
    _editKey("Ice")
    _editKey("Dragon")

    return configChanged, def
end

---@param conf ArmorConfig
function _M.ArmorConfEditor(conf, overrideMode)
	local configChanged = false
    local changed = false
    local isFlagChange = false

    if not overrideMode then
        changed, conf.IsUsingCustomValues = imgui.checkbox("Use Custom Config (if false, use global settings instead)", conf.IsUsingCustomValues)
        configChanged = configChanged or changed
        isFlagChange = changed
    end

    changed, conf.Defense = imgui.drag_int("Defense", conf.Defense, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Resistance = _M.ResistanceDefEditor(conf.Resistance)
    configChanged = configChanged or changed

    changed, conf.Slot = _M.SlotDefEditor(conf.Slot)
    configChanged = configChanged or changed

    if not overrideMode then
        changed, conf.Skill = _M.SkillDefEditor(conf.Skill)
        configChanged = configChanged or changed
    end

    if configChanged and not isFlagChange then
        conf.IsUsingCustomValues = true
    end

    return configChanged, conf
end

---@param data app.user_data.ArmorData.cData
function _M.InspectArmorData(data)
    ---@type number
    local index = data._Index
    local name = Core.GetArmorName(data)

    local changed = false

    local indexStr = tostring(index)

    local conf = Utils.MergeTablesRecursive(EditorUtils.ArmorConfigFromData(data), EditorConf.Config.Armors[indexStr])

    local open = imgui.tree_node(string.format("[%d] %s", index, name))
    if conf.IsUsingCustomValues then
        imgui.same_line()
        imgui.text(" Custom")
    end
    if open then
        changed, conf = _M.ArmorConfEditor(conf)

        if changed then
            EditorConf.Config.Armors[indexStr] = conf
        end

        imgui.tree_pop()
    end

    return changed
end

---@param conf ArmorGlobalConfigAdder
function _M.ArmorConfigGlobalAdderEditor(conf)
    local changed, configChanged = false, false

    changed, conf.Defense = imgui.drag_int("Defense", conf.Defense, 1, 0, 1600)
    configChanged = configChanged or changed
    
    changed, conf.Resistance = _M.ResistanceDefEditor(conf.Resistance)
    configChanged = configChanged or changed

    changed, conf.Slot = _M.SlotDefEditor(conf.Slot)
    configChanged = configChanged or changed

    return configChanged, conf
end

---@param conf ArmorGlobalConfigMultiplier
function _M.ArmorConfigGlobalMultiplierEditor(conf)
    local changed, configChanged = false, false

    changed, conf.Defense = imgui.drag_float("Defense", conf.Defense, 0.01, 0, 10)
    configChanged = configChanged or changed
    
    local function _editKey(key)
        changed, conf.Resistance[key] = imgui.drag_float(key, conf.Resistance[key], 0.01, 0, 10)
        configChanged = configChanged or changed
    end

    -- imgui.text("Resistance:")
    -- _editKey("Fire")
    -- _editKey("Water")
    -- _editKey("Thunder")
    -- _editKey("Ice")
    -- _editKey("Dragon")

    return configChanged, conf
end

---@param conf ArmorGlobalConfigOverride
function _M.ArmorConfigGlobalOverrideEditor(conf)
    return _M.ArmorConfEditor(conf, true)
end

return _M
