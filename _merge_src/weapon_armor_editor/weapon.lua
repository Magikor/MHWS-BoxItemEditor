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

---@param data app.user_data.WeaponData.cData
---@param def SharpnessDef
function _M.ApplySharpnessDef(data, def)
    def = EditorUtils.NormalizeSharpnessDef(def)

    local list = data._SharpnessValList -- int16[]
    list:set_Item(0, def.Red)
    list:set_Item(1, def.Orange)
    list:set_Item(2, def.Yellow)
    list:set_Item(3, def.Green)
    list:set_Item(4, def.Blue)
    list:set_Item(5, def.White)
    list:set_Item(6, def.Purple)
    data._SharpnessValList = list
end

---@param data app.user_data.WeaponData.cData
---@param def SlotDef
function _M.ApplySlotDef(data, def)
    if not def then return end

    def = EditorUtils.NormalizeSlotDef(def)

    local list = data._SlotLevel -- int16[]

    local function _set_slot(index, lv)
        local ele = list:get_Item(index)
        ele._Value = lv
        list:set_Item(index, ele)
    end

    _set_slot(0, def.First)
    _set_slot(1, def.Second)
    _set_slot(2, def.Third)
end

---@param data app.user_data.WeaponData.cData
---@param conf WeaponConfig
local function ApplyWeaponTypeConfig(data, conf, wpType)
    mod.verbose("applying weapon type %d - %s config", wpType, Core.GetWeaponTypeName(wpType))

    if wpType == CONST.WeaponType.InsectGlaive then
        
        data._RodInsectLv._Value = Core.EnumToFixed("app.WeaponDef.ROD_INSECT_LV", conf.InsectGlaiveInsectLevel)

    elseif wpType == CONST.WeaponType.SwitchAxe then
        
        data._Wp08BinType = Core.EnumToFixed("app.Wp08Def.BIN_TYPE", conf.SwitchAxeBinType)
        data._Wp08BinValue = conf.SwitchAxeBinValue
    
    elseif wpType == CONST.WeaponType.Gunlance then
        
        data._Wp07ShellType._Value = Core.EnumToFixed("app.Wp07Def.SHELL_TYPE", conf.GunlanceShellType)
        data._Wp07ShellLv._Value = Core.EnumToFixed("app.Wp07ShellLevel.SHELL_LV", conf.GunlanceShellLevel)
    
    elseif wpType == CONST.WeaponType.HuntingHorn then
        
        data._Wp05UniqueType._Value = Core.EnumToFixed("app.Wp05Def.UNIQUE_TYPE", conf.HuntingHornUniqueType)
        data._Wp05HibikiSkillType._Value = Core.EnumToFixed("app.Wp05Def.WP05_HIBIKI_SKILL_TYPE", conf.HuntingHornHibikiSkillType)
        data._Wp05MusicSkillHighFreqType._Value = Core.EnumToFixed("app.Wp05Def.WP05_MUSIC_SKILL_HIGH_FREQ_TYPE", conf.HuntingHornHighFreqType)
        
    elseif wpType == CONST.WeaponType.ChargeBlade then

        data._Wp09BinType = Core.EnumToFixed("app.Wp09Def.BIN_TYPE", conf.ChargeBladeBinType)
    
    end
end

---@param data app.user_data.WeaponData.cData
---@param conf WeaponConfig
function _M.ApplyWeaponConfig(data, conf, wpType)
    data._Attack = conf.Attack
    data._Defense = conf.Defense
    data._Critical = conf.Critical
    data._Attribute._Value = conf.AttributeType
    data._AttributeValue = conf.AttributeValue
    data._SubAttribute._Value = conf.SubAttributeType
    data._SubAttributeValue = conf.SubAttributeValue

    ApplyWeaponTypeConfig(data, conf, wpType)

    if wpType <= 10 then
        _M.ApplySharpnessDef(data, conf.Sharpness)
        _M.ApplySlotDef(data, conf.Slot)
    end

    local skills = data._Skill
    local skillLevel = data._SkillLevel
    EditorUtils.ApplySkillDef(conf.Skill, skills, skillLevel)
    data._Skill = skills
    data._SkillLevel = skillLevel
end

---@param data app.user_data.WeaponData.cData
function _M.ApplyGlobalConfig(data, wpType)
    local adder = EditorConf.Config.WeaponGlobalConfig.Adder
    local multiplier = EditorConf.Config.WeaponGlobalConfig.Multiplier
    local override = EditorConf.Config.WeaponGlobalConfig.Override

    local function _calc(val, key)
        if override[key] > 0 then
            -- min to int16
            return math.min(override[key], 30000)
        else
            -- min to int16
            local result = val * (multiplier[key] + 1) + adder[key]
            return math.min(result, 30000)
        end
    end

    data._Attack = _calc(data._Attack, "Attack")
    data._Defense = _calc(data._Defense, "Defense")
    data._Critical = _calc(data._Critical, "Critical")
    data._AttributeValue = _calc(data._AttributeValue, "AttributeValue")
    data._SubAttributeValue = _calc(data._SubAttributeValue, "SubAttributeValue")

    if override.AttributeType > 0 then
        data._Attribute._Value = override.AttributeType
    end

    if override.SubAttributeType > 0 then
        data._SubAttribute._Value = override.SubAttributeType
    end

    if wpType <= 10 then
        local sharpnessList = data._SharpnessValList -- int16[]
        local function _apply_sharpness(index, key)
            local function _calc_sharpness(val, key)
                local result = val
                if override.Sharpness[key] > 0 then
                    result = override.Sharpness[key]
                else
                    result = val * (multiplier.Sharpness[key] + 1) + adder.Sharpness[key]
                end
                
                if result <= 0 then
                    return 0
                end
                -- min to int16
                return math.min(math.ceil(result), 30000)
            end

            sharpnessList:set_Item(index, _calc_sharpness(sharpnessList:get_Item(index), key))
        end

        _apply_sharpness(0, "Red")
        _apply_sharpness(1, "Orange")
        _apply_sharpness(2, "Yellow")
        _apply_sharpness(3, "Green")
        _apply_sharpness(4, "Blue")
        _apply_sharpness(5, "White")
        _apply_sharpness(6, "Purple")
        data._SharpnessValList = sharpnessList
    end

    local slotLevelList = data._SlotLevel
    local function _apply_slot(index, key)
        local ele = slotLevelList:get_Item(index)
        local result = ele._Value

        if override.Slot[key] > 0 then
            result = override.Slot[key]
        else
            result = result + adder.Slot[key]
        end
        result = math.min(math.ceil(result), 3)
        result = math.max(result, 0)

        ele._Value = result
        slotLevelList:set_Item(index, ele)
    end

    _apply_slot(0, "First")
    _apply_slot(1, "Second")
    _apply_slot(2, "Third")
    data._SlotLevel = slotLevelList
end

function _M.ApplyModConfig()
    for wpType = 0, 13, 1 do
        mod.verbose("Editing %s", Core.GetWeaponTypeName(wpType))
        local confs = EditorConf.Config.Weapons[tostring(wpType)]
        local originals = EditorConf.WeaponsOriginal[tostring(wpType)]

        local values = EditorUtils.GetWeaponDataByWeaponType(wpType)
        if values and originals then
            Core.ForEach(values, function (weaponData, i)
                local idxStr = tostring(weaponData._Index)

                local conf = confs[idxStr]
                if conf and conf.IsUsingCustomValues then
                    mod.verbose("Using custom value for %s", Core.GetWeaponName(weaponData))
                    _M.ApplyWeaponConfig(weaponData, conf, wpType)
                else
                    local origin = originals[idxStr]
                    if origin then
                        mod.verbose("Revert to default value for %s", Core.GetWeaponName(weaponData))
                        _M.ApplyWeaponConfig(weaponData, origin, wpType)
                        mod.verbose("Using global value for %s", Core.GetWeaponName(weaponData))
                        _M.ApplyGlobalConfig(weaponData, wpType)
                    end
                end
            end)
        end
    end
end

function _M.RestoreAll()
    for wpType = 0, 13, 1 do
        local originals = EditorConf.WeaponsOriginal[tostring(wpType)]

        local values = EditorUtils.GetWeaponDataByWeaponType(wpType)
        if values and originals then
            Core.ForEach(values, function (weaponData, i)
                local origin = originals[tostring(weaponData._Index)]
                if origin then
                    _M.ApplyWeaponConfig(weaponData, origin, wpType)
                end
            end)
        end
    end
end

return _M
