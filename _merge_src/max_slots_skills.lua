if rawget(_G, "__MHWS_MAX_SLOTS_SKILLS_LOADED") == true then
    return
end
_G.__MHWS_MAX_SLOTS_SKILLS_LOADED = true

local imgui = imgui
local log = log
local sdk = sdk

local Core = require("_CatLib")
local Imgui = require("_CatLib.imgui")

local function safeCall(label, fn)
    local ok, res = xpcall(fn, debug.traceback)
    if ok then
        return true, res
    end
    return false, string.format("%s\n%s", tostring(label), tostring(res))
end

local function safeUi(label, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then
        if log ~= nil and log.error ~= nil then
            log.error(tostring(label) .. "\n" .. tostring(err))
        end
    end
end

local function getVariousDataManager()
    if Core ~= nil and Core.GetVariousDataManager ~= nil then
        local mgr = Core.GetVariousDataManager()
        if mgr ~= nil then
            return mgr
        end
    end

    if sdk ~= nil and sdk.get_managed_singleton ~= nil then
        return sdk.get_managed_singleton("app.VariousDataManager")
    end

    return nil
end

local function forEachValue(values, fn)
    if values == nil then
        return 0
    end

    local count = 0
    for _, value in pairs(values) do
        if value ~= nil then
            fn(value)
            count = count + 1
        end
    end

    return count
end

local function applySlotsToEntry(entry)
    local slotList = entry._SlotLevel
    if slotList == nil then
        return
    end

    -- Some tables are arrays of structs with _Value, others may be plain int arrays.
    if slotList.get_size ~= nil and slotList.get_Item ~= nil and slotList.set_Item ~= nil then
        for i = 0, slotList:get_size() - 1 do
            local ele = slotList:get_Item(i)
            if type(ele) == "number" then
                slotList:set_Item(i, 3)
            elseif ele ~= nil and ele._Value ~= nil then
                ele._Value = 3
                slotList:set_Item(i, ele)
            else
                -- Best effort: try direct set
                pcall(function()
                    slotList:set_Item(i, 3)
                end)
            end
        end
        entry._SlotLevel = slotList
        return
    end

    for k, ele in pairs(slotList) do
        if type(ele) == "number" then
            if slotList.set_Item ~= nil then
                pcall(function()
                    slotList:set_Item(k, 3)
                end)
            else
                slotList[k] = 3
            end
        elseif ele ~= nil and ele._Value ~= nil then
            ele._Value = 3
            if slotList.set_Item ~= nil then
                pcall(function()
                    slotList:set_Item(k, ele)
                end)
            end
        end
    end
end

local function applySkillsToEntry(entry)
    local skillLevel = entry._SkillLevel
    if skillLevel == nil then
        return
    end

    if skillLevel.get_size ~= nil and skillLevel.get_Item ~= nil and skillLevel.set_Item ~= nil then
        for i = 0, skillLevel:get_size() - 1 do
            local val = skillLevel:get_Item(i)
            if type(val) == "number" then
                if val >= 1 then
                    skillLevel:set_Item(i, 10)
                end
            elseif val ~= nil and val.m_value ~= nil then
                if val.m_value >= 1 then
                    skillLevel:set_Item(i, 10)
                end
            end
        end
        entry._SkillLevel = skillLevel
        return
    end

    for k, val in pairs(skillLevel) do
        local n = val
        if type(val) ~= "number" and val ~= nil and val.m_value ~= nil then
            n = val.m_value
        end
        if type(n) == "number" and n >= 1 then
            if skillLevel.set_Item ~= nil then
                pcall(function()
                    skillLevel:set_Item(k, 10)
                end)
            else
                skillLevel[k] = 10
            end
        end
    end
end

local function applyWeapons(maxSlots, maxSkills)
    local mgr = getVariousDataManager()
    if mgr == nil then
        return false, "Game not initialized yet."
    end

    local equip = mgr._Setting and mgr._Setting._EquipDatas
    if equip == nil then
        return false, "Equip data not available."
    end

    local weaponKeys = {
        "_WeaponBow",
        "_WeaponChargeAxe",
        "_WeaponGunLance",
        "_WeaponHammer",
        "_WeaponHeavyBowgun",
        "_WeaponLance",
        "_WeaponLightBowgun",
        "_WeaponLongSword",
        "_WeaponRod",
        "_WeaponShortSword",
        "_WeaponSlashAxe",
        "_WeaponTachi",
        "_WeaponTwinSword",
        "_WeaponWhistle",
    }

    local total = 0
    for _, key in ipairs(weaponKeys) do
        local container = equip[key]
        local values = container and container._Values
        total = total + forEachValue(values, function(entry)
            if maxSlots then
                applySlotsToEntry(entry)
            end
            if maxSkills then
                applySkillsToEntry(entry)
            end
        end)
    end

    return true, string.format("Weapons updated: %d entries", total)
end

local function applyArmors(maxSlots, maxSkills)
    local mgr = getVariousDataManager()
    if mgr == nil then
        return false, "Game not initialized yet."
    end

    local values = mgr._Setting
        and mgr._Setting._EquipDatas
        and mgr._Setting._EquipDatas._ArmorData
        and mgr._Setting._EquipDatas._ArmorData._Values

    if values == nil then
        return false, "Armor data not available."
    end

    local total = forEachValue(values, function(entry)
        if maxSlots then
            applySlotsToEntry(entry)
        end
        if maxSkills then
            applySkillsToEntry(entry)
        end
    end)

    return true, string.format("Armors updated: %d entries", total)
end

local function applyTalismans(maxSlots, maxSkills)
    local mgr = getVariousDataManager()
    if mgr == nil then
        return false, "Game not initialized yet."
    end

    local setting = mgr._Setting
    if setting == nil then
        return false, "VariousDataManager setting not available."
    end

    local totalSlots = 0
    local totalSkills = 0

    if maxSlots then
        local slotValues = setting._RandomAmuletAccSlot and setting._RandomAmuletAccSlot._Values
        if slotValues == nil then
            return false, "Talisman slot table not available."
        end
        totalSlots = forEachValue(slotValues, function(entry)
            entry._SlotLevel01 = 3
            entry._SlotLevel02 = 3
            entry._SlotLevel03 = 3
        end)
    end

    if maxSkills then
        local skillValues = setting._RandomAmuletLotSkillTable and setting._RandomAmuletLotSkillTable._Values
        if skillValues == nil then
            return false, "Talisman skill table not available."
        end
        totalSkills = forEachValue(skillValues, function(entry)
            entry._SkillLv = 10
        end)
    end

    local parts = {}
    if maxSlots then
        table.insert(parts, string.format("slots: %d", totalSlots))
    end
    if maxSkills then
        table.insert(parts, string.format("skills: %d", totalSkills))
    end

    return true, "Talismans updated (" .. table.concat(parts, ", ") .. ")"
end

local function DrawMaxSlotsSkillsMenu()
    local api = _G.__MHWS_EDITOR_SUITE or {}
    _G.__MHWS_EDITOR_SUITE = api

    api._max_slots_skills_state = api._max_slots_skills_state or { last = nil }
    local state = api._max_slots_skills_state

    imgui.text("Applies preset edits to game data (in-memory).")
    imgui.text("Restart the game to revert to original values.")

    Imgui.Tree("Weapons", function()
        safeUi("max_slots_skills: Weapons UI", function()
            if imgui.button("Apply Max Slots##MaxSlotsWeapons") then
            local ok_call, res = safeCall("applyWeapons(maxSlots=true)", function()
                return applyWeapons(true, false)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Max Skills##MaxSkillsWeapons") then
            local ok_call, res = safeCall("applyWeapons(maxSkills=true)", function()
                return applyWeapons(false, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Both##MaxBothWeapons") then
            local ok_call, res = safeCall("applyWeapons(maxSlots=true,maxSkills=true)", function()
                return applyWeapons(true, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
        end)
    end)

    Imgui.Tree("Armors", function()
        safeUi("max_slots_skills: Armors UI", function()
            if imgui.button("Apply Max Slots##MaxSlotsArmors") then
            local ok_call, res = safeCall("applyArmors(maxSlots=true)", function()
                return applyArmors(true, false)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Max Skills##MaxSkillsArmors") then
            local ok_call, res = safeCall("applyArmors(maxSkills=true)", function()
                return applyArmors(false, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Both##MaxBothArmors") then
            local ok_call, res = safeCall("applyArmors(maxSlots=true,maxSkills=true)", function()
                return applyArmors(true, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
        end)
    end)

    Imgui.Tree("Talismans (Generated)", function()
        safeUi("max_slots_skills: Talismans UI", function()
            if imgui.button("Apply Max Slots##MaxSlotsTalismans") then
            local ok_call, res = safeCall("applyTalismans(maxSlots=true)", function()
                return applyTalismans(true, false)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Max Skills##MaxSkillsTalismans") then
            local ok_call, res = safeCall("applyTalismans(maxSkills=true)", function()
                return applyTalismans(false, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
            imgui.same_line()
            if imgui.button("Apply Both##MaxBothTalismans") then
            local ok_call, res = safeCall("applyTalismans(maxSlots=true,maxSkills=true)", function()
                return applyTalismans(true, true)
            end)
            if ok_call then
                local ok_apply, msg = res
                state.last = (ok_apply and "OK: " or "ERR: ") .. tostring(msg)
            else
                state.last = "ERR: " .. tostring(res)
            end
            end
        end)
    end)

    if state.last ~= nil then
        imgui.text_wrapped(state.last)
    end

    return false
end

_G.__MHWS_EDITOR_SUITE = _G.__MHWS_EDITOR_SUITE or {}
_G.__MHWS_EDITOR_SUITE.draw_max_slots_skills = DrawMaxSlotsSkillsMenu

if log ~= nil and log.info ~= nil then
    log.info("MHWS Editor Suite: max_slots_skills module loaded")
end
