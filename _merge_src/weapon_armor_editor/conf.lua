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

local _M = {}

---@class WeaponGlobalConfigAdder
---@field Attack number
---@field Defense number
---@field Critical number
---@field AttributeValue number
---@field SubAttributeValue number
---@field Sharpness SharpnessDef
---@field Slot SlotDef

---@class WeaponGlobalConfigMultiplier
---@field Attack number
---@field Defense number
---@field Critical number
---@field AttributeValue number
---@field SubAttributeValue number
---@field Sharpness SharpnessDef

---@class WeaponGlobalConfigOverride
---@field Attack number
---@field Defense number
---@field Critical number
---@field AttributeType number
---@field AttributeValue number
---@field SubAttributeType number
---@field SubAttributeValue number
---@field Sharpness SharpnessDef
---@field Slot SlotDef
---@field Skill SkillDef

---@class WeaponGlobalConfig
---@field Adder WeaponGlobalConfigAdder
---@field Multiplier WeaponGlobalConfigMultiplier
---@field Override WeaponGlobalConfigOverride

---@return WeaponGlobalConfig
function _M.NewWeaponGlobalConfig()
    return {
        Adder = {
            Attack = 0,
            Defense = 0,
            Critical = 0,
            AttributeValue = 0,
            SubAttributeValue = 0,
            Sharpness = _M.NewSharpnessDef(),
            Slot = _M.NewSlotDef(),
        },
        Multiplier = {
            Attack = 0,
            Defense = 0,
            Critical = 0,
            AttributeValue = 0,
            SubAttributeValue = 0,
            Sharpness = _M.NewSharpnessDef(),
        },
        Override = {
            Attack = 0,
            Defense = 0,
            Critical = 0,
            AttributeType = 0,
            AttributeValue = 0,
            SubAttributeType = 0,
            SubAttributeValue = 0,
            Sharpness = _M.NewSharpnessDef(),
            Slot = _M.NewSlotDef(),
        }
    }
end

---@class WeaponConfig
---@field IsUsingCustomValues boolean
---@field Attack number
---@field Defense number
---@field Critical number
---@field AttributeType number
---@field AttributeValue number
---@field SubAttributeType number
---@field SubAttributeValue number
---@field Sharpness SharpnessDef
---@field Slot SlotDef
---@field Skill SkillDef
---@
---@field InsectGlaiveInsectLevel number
---@
---@field SwitchAxeBinType number
---@field SwitchAxeBinValue number
---@
---@field ChargeBladeBinType number
---@
---@field HuntingHornUniqueType number
---@field HuntingHornHighFreqType number
---@field HuntingHornHibikiSkillType number -- 响模式
---@
---@field GunlanceShellType number
---@field GunlanceShellLevel number

---@return WeaponConfig
function _M.NewWeaponConfig()
    return {
        IsUsingCustomValues = false,

        Sharpness = _M.NewSharpnessDef(),
        Slot = _M.NewSlotDef(),
        Skill = _M.NewSkillDef(4),

        InsectGlaiveInsectLevel = 0,
        SwitchAxeBinType = 0,
        SwitchAxeBinValue = 0,
        ChargeBladeBinType = 0,
        HuntingHornUniqueType = 0,
        HuntingHornHighFreqType = 0,
        HuntingHornHibikiSkillType = 0,
        GunlanceShellType = 0,
        GunlanceShellLevel = 0,
    }    
end

---@class SharpnessDef
---@field Red number 红色
---@field Orange number 橙色
---@field Yellow number 黄色
---@field Green number 绿色
---@field Blue number 蓝色
---@field White number 白色
---@field Purple number 紫色

---@return SharpnessDef
function _M.NewSharpnessDef()
    return {
        Red = 0,
        Orange = 0,
        Yellow = 0,
        Green = 0,
        Blue = 0,
        White = 0,
        Purple = 0,
    }
end

---@class SlotDef
---@field First number
---@field Second number
---@field Third number

---@return SlotDef
function _M.NewSlotDef()
    return {
        First = 0,
        Second = 0,
        Third = 0,
    }
end

---@class SkillDefData
---@field ID number
---@field Level number

---@class SkillDef
---@field Size number
---@field Skills SkillDefData[]

function _M.NewSkillDef(size)
    local def = {
        Size = size,
        Skills = {},
    }

    for i = 1, size do
        def.Skills[i] = {
            ID = 0,
            Level = 0,
        }
    end

    return def
end

---@class ResistanceDef
---@field Fire number
---@field Water number
---@field Thunder number
---@field Ice number
---@field Dragon number

---@return ResistanceDef
function _M.NewResistanceDef()
    return {
        Fire = 0,
        Water = 0,
        Thunder = 0,
        Ice = 0,
        Dragon = 0,
    }
end

---@class ArmorConfig
---@field Defense number
---@field Resistance ResistanceDef
---@field Slot SlotDef
---@field Skill SkillDef

---@return ArmorConfig
function _M.NewArmorConfig()
    return {
        Defense = 0,
        Resistance = _M.NewResistanceDef(),
        Slot = _M.NewSlotDef(),
        Skill = _M.NewSkillDef(7),
    }
end

---@class ArmorGlobalConfigAdder
---@field Defense number
---@field Resistance ResistanceDef
---@field Slot SlotDef

---@class ArmorGlobalConfigMultiplier
---@field Defense number
---@field Resistance ResistanceDef

---@class ArmorGlobalConfigOverride
---@field Defense number
---@field Resistance ResistanceDef
---@field Slot SlotDef

---@class ArmorGlobalConfig
---@field Adder ArmorGlobalConfigAdder
---@field Multiplier ArmorGlobalConfigMultiplier
---@field Override ArmorGlobalConfigOverride

---@return ArmorGlobalConfig
function _M.NewArmorGlobalConfig()
    return {
        Adder = {
            Defense = 0,
            Resistance = _M.NewResistanceDef(),
            Slot = _M.NewSlotDef(),
        },
        Multiplier = {
            Defense = 0,
            Resistance = _M.NewResistanceDef(),
        },
        Override = {
            Defense = 0,
            Resistance = _M.NewResistanceDef(),
            Slot = _M.NewSlotDef(),
        }
    }
end

---@alias ModWeaponIndexConfigs table<string, WeaponConfig>
---@alias ModWeaponTypeConfigs table<string, ModWeaponIndexConfigs>

---@alias ModArmorIndexConfigs table<string, ArmorConfig>

---@class WeaponAndArmorEditorModConfig : ModConfig
---@field Weapons ModArmorIndexConfigs
---@field WeaponsOriginal ModWeaponTypeConfigs
---@field WeaponGlobalConfig WeaponGlobalConfig
---@field Armors ModArmorIndexConfigs
---@field ArmorsOriginal ModArmorIndexConfigs
---@field ArmorGlobalConfig ArmorGlobalConfig

---@type WeaponAndArmorEditorModConfig
_M.Config = mod.Config

local SCRIPT_VERSION = "0.1"

local WEAPON_ORIGINAL_JSON = "weapon_and_armor_editor.weapon_original.json"

function _M.SaveWeaponOriginal()
    mod.SaveConfig(WEAPON_ORIGINAL_JSON, _M.WeaponsOriginal)
end

local ARMOR_ORIGINAL_JSON = "weapon_and_armor_editor.armor_original.json"

function _M.SaveArmorOriginal()
    mod.SaveConfig(ARMOR_ORIGINAL_JSON, _M.ArmorsOriginal)
end

local function InitWeaponConfig()
    if _M.Config.Weapons == nil then
        _M.Config.Weapons = {}
    end
    for i = 0, 13, 1 do
        if not _M.Config.Weapons[tostring(i)] then
            _M.Config.Weapons[tostring(i)] = {}
        end
    end

    ---@type ModWeaponTypeConfigs
    _M.WeaponsOriginal = mod.LoadConfig(WEAPON_ORIGINAL_JSON)

    -- TODO check game version
    if _M.WeaponsOriginal and _M.WeaponsOriginal.RecordVersion ~= SCRIPT_VERSION then
        _M.WeaponsOriginal = nil
        log.info("Script updated, rebuild game data")
    end

    if _M.WeaponsOriginal == nil then
        _M.WeaponsOriginal = {}
        _M.WeaponsOriginal.RecordVersion = SCRIPT_VERSION
        for i = 0, 13, 1 do
            _M.WeaponsOriginal[tostring(i)] = {}
        end
    end

    _M.Config.WeaponGlobalConfig = Utils.MergeTablesRecursive(_M.NewWeaponGlobalConfig(), _M.Config.WeaponGlobalConfig)
end

function _M.ClearWeaponData()
    _M.Config.Weapons = {}
    for i = 0, 13, 1 do
        _M.Config.Weapons[tostring(i)] = {}
    end
    _M.Config.WeaponGlobalConfig = _M.NewWeaponGlobalConfig()
end

local function InitArmorConfig()
    if _M.Config.Armors == nil then
        _M.Config.Armors = {}
    end

    ---@type ModArmorIndexConfigs
    _M.ArmorsOriginal = mod.LoadConfig(ARMOR_ORIGINAL_JSON)

    -- TODO check game version
    if _M.ArmorsOriginal and _M.ArmorsOriginal.RecordVersion ~= SCRIPT_VERSION then
        _M.ArmorsOriginal = nil
        log.info("Script updated, rebuild game data")
    end

    if _M.ArmorsOriginal == nil then
        _M.ArmorsOriginal = {}
        _M.ArmorsOriginal.RecordVersion = SCRIPT_VERSION
    end

    _M.Config.ArmorGlobalConfig = Utils.MergeTablesRecursive(_M.NewArmorGlobalConfig(), _M.Config.ArmorGlobalConfig)
end

function _M.ClearArmorData()
    _M.Config.Armors = {}
    _M.Config.ArmorGlobalConfig = _M.NewArmorGlobalConfig()
end

InitWeaponConfig()
InitArmorConfig()

return _M
