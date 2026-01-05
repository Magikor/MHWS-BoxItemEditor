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

local mod = require("weapon_armor_editor.mod")
local EditorConf = require("weapon_armor_editor.conf")

local _M = {}

---@return app.user_data.WeaponData.cData[]
function _M.GetWeaponDataByWeaponType(type)
    local mgr = Core.GetVariousDataManager()
    if mgr == nil then
        return
    end

    local datas = mgr._Setting._EquipDatas

    if type == CONST.WeaponType.GreatSword then
        return datas._WeaponLongSword._Values
    elseif type == CONST.WeaponType.SwordShield then
        return datas._WeaponShortSword._Values
    elseif type == CONST.WeaponType.DualBlades then
        return datas._WeaponTwinSword._Values
    elseif type == CONST.WeaponType.LongSword then
        return datas._WeaponTachi._Values
    elseif type == CONST.WeaponType.Hammer then
        return datas._WeaponHammer._Values
    elseif type == CONST.WeaponType.HuntingHorn then
        return datas._WeaponWhistle._Values
    elseif type == CONST.WeaponType.Lance then
        return datas._WeaponLance._Values
    elseif type == CONST.WeaponType.Gunlance then
        return datas._WeaponGunLance._Values
    elseif type == CONST.WeaponType.SwitchAxe then
        return datas._WeaponSlashAxe._Values
    elseif type == CONST.WeaponType.ChargeBlade then
        return datas._WeaponChargeAxe._Values
    elseif type == CONST.WeaponType.InsectGlaive then
        return datas._WeaponRod._Values
    elseif type == CONST.WeaponType.Bow then
        return datas._WeaponBow._Values
    elseif type == CONST.WeaponType.HeavyBowgun then
        return datas._WeaponHeavyBowgun._Values
    elseif type == CONST.WeaponType.LightBowgun then
        return datas._WeaponLightBowgun._Values
    end
end

---@return app.user_data.ArmorData
function _M.GetArmorData()
    local mgr = Core.GetVariousDataManager()
    if mgr == nil then
        return
    end

    return mgr._Setting._EquipDatas._ArmorData
end

function _M.GetEquipWeapons()
    local index = Core.GetSaveDataManager():getCurrentUserSaveData():get_Equip()._EquipIndex.Index
    return {
        WeaponType = Core.GetPlayerWeaponType(),
        Index = index:get_Item(0),
        SubWeaponType = Core.GetPlayerSubWeaponType(),
        SubIndex = index:get_Item(7),
    }
end

---@param def SkillDef
---@param skills app.HunterDef.Skill_Serializable[]
---@param skillLevel number[]
---@return SkillDef
function _M.SkillDefFromData(def, skills, skillLevel)
    local function _update_skill(index)
        local fixedId = skills:get_Item(index)._Value
        local skillId = Core.GetSkillByFixed(fixedId)
        def.Skills[index+1].ID = skillId
        def.Skills[index+1].Level = skillLevel:get_Item(index)
    end
    
    for i = 0, def.Size - 1 do
        _update_skill(i)
    end

    return def
end

---@param def SkillDef
---@param skills app.HunterDef.Skill_Serializable[]
---@param skillLevel number[]
---@return SkillDef
function _M.ApplySkillDef(def, skills, skillLevel)
    if not def then
        return
    end
    local function _apply_skill(index)
        local fixedId = Core.GetFixedBySkill(def.Skills[index+1].ID)
        local elem = skills:get_Item(index)
        elem._Value = fixedId
        skills:set_Item(index, elem)

        skillLevel:set_Item(index, def.Skills[index+1].Level)
    end
    
    for i = 0, def.Size - 1 do
        _apply_skill(i)
    end

    return def
end

---@param data app.user_data.WeaponData.cData
---@return WeaponConfig
function _M.WeaponConfigFromData(data)
    local conf = EditorConf.NewWeaponConfig()

    conf.Attack = data._Attack
    conf.Defense = data._Defense
    conf.Critical = data._Critical
    conf.AttributeType = data._Attribute._Value
    conf.AttributeValue = data._AttributeValue
    conf.SubAttributeType = data._SubAttribute._Value
    conf.SubAttributeValue = data._SubAttributeValue

    conf.InsectGlaiveInsectLevel = Core.FixedToEnum("app.WeaponDef.ROD_INSECT_LV", data._RodInsectLv._Value)
    conf.SwitchAxeBinType = Core.FixedToEnum("app.Wp08Def.BIN_TYPE", data._Wp08BinType)
    conf.SwitchAxeBinValue = data._Wp08BinValue
    conf.GunlanceShellType = Core.FixedToEnum("app.Wp07Def.SHELL_TYPE", data._Wp07ShellType._Value)
    conf.GunlanceShellLevel = Core.FixedToEnum("app.Wp07ShellLevel.SHELL_LV", data._Wp07ShellLv._Value)
    conf.HuntingHornUniqueType = Core.FixedToEnum("app.Wp05Def.UNIQUE_TYPE", data._Wp05UniqueType._Value)
    conf.HuntingHornHibikiSkillType = Core.FixedToEnum("app.Wp05Def.WP05_HIBIKI_SKILL_TYPE", data._Wp05HibikiSkillType._Value)
    conf.HuntingHornHighFreqType = Core.FixedToEnum("app.Wp05Def.WP05_MUSIC_SKILL_HIGH_FREQ_TYPE", data._Wp05MusicSkillHighFreqType._Value)
    conf.ChargeBladeBinType = Core.FixedToEnum("app.Wp09Def.BIN_TYPE", data._Wp09BinType)

    local sharpnessList = data._SharpnessValList
    conf.Sharpness.Red = sharpnessList:get_Item(0)
    conf.Sharpness.Orange = sharpnessList:get_Item(1)
    conf.Sharpness.Yellow = sharpnessList:get_Item(2)
    conf.Sharpness.Green = sharpnessList:get_Item(3)
    conf.Sharpness.Blue = sharpnessList:get_Item(4)
    conf.Sharpness.White = sharpnessList:get_Item(5)
    conf.Sharpness.Purple = sharpnessList:get_Item(6)

    local slotList = data._SlotLevel
    conf.Slot.First = slotList:get_Item(0)._Value
    conf.Slot.Second = slotList:get_Item(1)._Value
    conf.Slot.Third = slotList:get_Item(2)._Value

    local skills = data._Skill
    local skillLevel = data._SkillLevel
    conf.Skill = _M.SkillDefFromData(conf.Skill, skills, skillLevel)

    return conf
end

---@param data app.user_data.ArmorData.cData
---@return ArmorConfig
function _M.ArmorConfigFromData(data)
    local conf = EditorConf.NewArmorConfig()

    conf.Defense = data._Defense

    local resistList = data._Resistance
    conf.Resistance.Fire = resistList:get_Item(0)
    conf.Resistance.Water = resistList:get_Item(1)
    conf.Resistance.Thunder = resistList:get_Item(2)
    conf.Resistance.Ice = resistList:get_Item(3)
    conf.Resistance.Dragon = resistList:get_Item(4)

    local slotList = data._SlotLevel
    conf.Slot.First = slotList:get_Item(0)._Value
    conf.Slot.Second = slotList:get_Item(1)._Value
    conf.Slot.Third = slotList:get_Item(2)._Value

    local skills = data._Skill
    local skillLevel = data._SkillLevel
    conf.Skill = _M.SkillDefFromData(conf.Skill, skills, skillLevel)

    return conf
end

---@param def SharpnessDef
function _M.NormalizeSharpnessDef(def)
    local function _normailize(val)
        if val <= 0 then
            return 0
        end
        return math.min(math.ceil(val), 30000)
    end

    def.Red = _normailize(def.Red)
    def.Orange = _normailize(def.Orange)
    def.Yellow = _normailize(def.Yellow)
    def.Green = _normailize(def.Green)
    def.Blue = _normailize(def.Blue)
    def.White = _normailize(def.White)
    def.Purple = _normailize(def.Purple)

    return def
end

---@param def SlotDef
function _M.NormalizeSlotDef(def)
    local function _normailize(val)
        if val <= 0 then
            return 0
        end
        return math.min(math.ceil(val), 3)
    end

    def.First = _normailize(def.First)
    def.Second = _normailize(def.Second)
    def.Third = _normailize(def.Third)

    return def
end

---@param def ResistanceDef
function _M.NormalizeResistanceDef(def)
    local function _normailize(val)
        if val <= -100 then
            return -100
        end
        return math.min(math.ceil(val), 100)
    end

    def.Fire = _normailize(def.Fire)
    def.Water = _normailize(def.Water)
    def.Thunder = _normailize(def.Thunder)
    def.Ice = _normailize(def.Ice)
    def.Dragon = _normailize(def.Dragon)

    return def
end

return _M
