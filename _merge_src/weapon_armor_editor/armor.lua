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

---@param data app.user_data.ArmorData.cData
---@param def ResistanceDef
function _M.ApplyResistanceDef(data, def)
    def = EditorUtils.NormalizeResistanceDef(def)

    local list = data._Resistance -- int32[]
    list:set_Item(0, def.Fire)
    list:set_Item(1, def.Water)
    list:set_Item(2, def.Thunder)
    list:set_Item(3, def.Ice)
    list:set_Item(4, def.Dragon)
    data._Resistance = list
end

---@param data app.user_data.ArmorData.cData
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

---@param data app.user_data.ArmorData.cData
---@param conf ArmorConfig
function _M.ApplyArmorConfig(data, conf)
    data._Defense = conf.Defense

    _M.ApplyResistanceDef(data, conf.Resistance)
    _M.ApplySlotDef(data, conf.Slot)
    
    local skills = data._Skill
    local skillLevel = data._SkillLevel
    EditorUtils.ApplySkillDef(conf.Skill, skills, skillLevel)
    data._Skill = skills
    data._SkillLevel = skillLevel
end

---@param data app.user_data.ArmorData.cData
function _M.ApplyGlobalConfig(data)
    local adder = EditorConf.Config.ArmorGlobalConfig.Adder
    local multiplier = EditorConf.Config.ArmorGlobalConfig.Multiplier
    local override = EditorConf.Config.ArmorGlobalConfig.Override

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

    data._Defense = _calc(data._Defense, "Defense")

    local resistList = data._Resistance -- int16[]
    local function _apply_resist(index, key)
        local function _calc_resist(val, key)
            local result = val
            if override.Resistance[key] ~= 0 then
                result = override.Resistance[key]
            else
                result = val * (multiplier.Resistance[key] + 1) + adder.Resistance[key]
            end
            
            if result <= -100 then
                return -100
            end
            -- min to int16
            return math.min(math.ceil(result), 100)
        end

        resistList:set_Item(index, _calc_resist(resistList:get_Item(index), key))
    end

    _apply_resist(0, "Fire")
    _apply_resist(1, "Water")
    _apply_resist(2, "Thunder")
    _apply_resist(3, "Ice")
    _apply_resist(4, "Dragon")
    data._Resistance = resistList

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
    local confs = EditorConf.Config.Armors
    local originals = EditorConf.ArmorsOriginal

    local values = EditorUtils.GetArmorData()._Values
    if values then
        Core.ForEach(values, function (armorData, i)
            local conf = confs[tostring(armorData._Index)]
            if conf and conf.IsUsingCustomValues then
                _M.ApplyArmorConfig(armorData, conf)
            else
                local origin = originals[tostring(armorData._Index)]
                if origin then
                    _M.ApplyArmorConfig(armorData, origin)
                    _M.ApplyGlobalConfig(armorData)
                end
            end
        end)
    end
end

function _M.RestoreAll()
    local originals = EditorConf.ArmorsOriginal

    local values = EditorUtils.GetArmorData()._Values
    if values and originals then
        Core.ForEach(values, function (armorData, i)
            local origin = originals[tostring(armorData._Index)]
            if origin then
                _M.ApplyArmorConfig(armorData, origin)
            end
        end)
    end
end

return _M
