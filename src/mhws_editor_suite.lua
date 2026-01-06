local re = re
local imgui = imgui

local Core = require("_CatLib")
local Imgui = require("_CatLib.imgui")

if rawget(_G, "__MHWS_EDITOR_SUITE_LOADED") == true then
    return
end
_G.__MHWS_EDITOR_SUITE_LOADED = true

_G.__MHWS_EDITOR_SUITE_ACTIVE = true
_G.__MHWS_EDITOR_SUITE = _G.__MHWS_EDITOR_SUITE or {}

-- Error capture helpers: makes it easy to copy/paste errors without relying on the in-game console.
do
    local api = _G.__MHWS_EDITOR_SUITE
    api._error_log_path = api._error_log_path or "reframework\\autorun\\mhws_errors.log"
    api._last_error = api._last_error or nil

    local function setClipboardText(text)
        if imgui ~= nil and imgui.set_clipboard_text ~= nil then
            imgui.set_clipboard_text(text)
            return true
        end
        if re ~= nil and re.set_clipboard_text ~= nil then
            re.set_clipboard_text(text)
            return true
        end
        return false
    end

    local function appendToFile(path, text)
        local ok, err = pcall(function()
            local f = io.open(path, "ab")
            if f == nil then
                return
            end
            f:write(text)
            f:close()
        end)
        return ok, err
    end

    local function recordError(where, err)
        local msg = string.format(
            "[%s] %s\n%s\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            tostring(where),
            tostring(err)
        )

        local ok_tb, tb = pcall(function()
            return debug.traceback("", 2)
        end)
        if ok_tb and tb ~= nil then
            msg = msg .. tb .. "\n"
        end
        msg = msg .. "\n"

        api._last_error = msg
        appendToFile(api._error_log_path, msg)
    end

    api.record_error = recordError
    api.set_clipboard_text = api.set_clipboard_text or setClipboardText
    api.append_to_file = api.append_to_file or appendToFile
    _G.__MHWS_LOG_ERROR = recordError
end

pcall(require, "item_editor")
pcall(require, "weapon_armor_editor")
pcall(require, "ItemBoxEditor")
pcall(require, "max_slots_skills")

local function findFirstExistingPath(candidates)
    for _, candidatePath in ipairs(candidates) do
        local ok, exists = pcall(function()
            local normalized = tostring(candidatePath):gsub("/", "\\")
            local renamed, err = os.rename(normalized, normalized)
            if renamed then
                return true
            end
            err = tostring(err or "")
            local lower = err:lower()
            -- Many Windows setups return errors even when the file exists (e.g. access denied,
            -- file in use, permission issues). Treat those as "exists".
            if lower:find("permission") or lower:find("access") or lower:find("denied") or lower:find("used") then
                return true
            end
            -- Only treat clear "missing" errors as non-existent.
            if lower:find("no such file") or lower:find("cannot find") or lower:find("not found") then
                return false
            end
            -- Unknown error: assume it exists to avoid false negatives.
            return true
        end)
        if ok and exists == true then
            return candidatePath
        end
    end
    return nil
end

local function tryLaunchExe(candidates)
    -- Prefer native plugin if present (works under ScriptRunner sandbox).
    local tools = rawget(_G, "mhws_tools")
    if tools ~= nil and type(tools) == "table" then
        -- Only expose explicit actions, not arbitrary process launch.
        local isRe = false
        local isMhwsEditor = false
        for _, p in ipairs(candidates) do
            local s = tostring(p):lower()
            if s:find("re%-editor%.exe") or s:find("re%-editor\\re%-editor%.exe") then
                isRe = true
                break
            end
            if s:find("mhws%-editor%.exe") or s:find("mhws%-editor\\mhws%-editor%.exe") then
                isMhwsEditor = true
            end
        end

        if isMhwsEditor and tools.launch_mhws_editor ~= nil then
            local ok_call, res = pcall(function()
                return tools.launch_mhws_editor()
            end)
            if ok_call and res ~= nil then
                if res.ok == true then
                    return true, res.detail
                end
                return false, res.detail or "launch_mhws_editor failed"
            end
            return false, "launch_mhws_editor threw an error"
        end

        if isRe and tools.launch_re_editor ~= nil then
            local ok_call, res = pcall(function()
                return tools.launch_re_editor()
            end)
            if ok_call and res ~= nil then
                if res.ok == true then
                    return true, res.detail
                end
                return false, res.detail or "launch_re_editor failed"
            end
            return false, "launch_re_editor threw an error"
        end
    end

    local exePath = findFirstExistingPath(candidates)
    if exePath == nil then
        return false, "not found"
    end

    exePath = exePath:gsub("/", "\\")
    local ok_exec, exec_err = pcall(function()
        os.execute(string.format('start "" "%s"', exePath))
    end)
    if not ok_exec then
        return false, tostring(exec_err)
    end
    return true, exePath
end

local suite = Core.NewMod("MHWS Editor Suite")

suite.Menu(function()
    local api = _G.__MHWS_EDITOR_SUITE

    local ok, result = xpcall(function()
        local configChanged = false
        local launchState = api._launch_state or {}
        api._launch_state = launchState

        Imgui.Tree("Item Box Editor", function()
            if api.draw_item_box_editor ~= nil then
                local ok_draw, err = xpcall(api.draw_item_box_editor, debug.traceback)
                if not ok_draw and api.record_error ~= nil then
                    api.record_error("suite:draw_item_box_editor", err)
                    imgui.text("Error captured (see Diagnostics).")
                end
            else
                imgui.text("ItemBoxEditor not loaded yet...")
            end
        end)

        Imgui.Tree("Item Editor", function()
            if api.draw_item_editor ~= nil then
                local ok_draw, changedOrErr = xpcall(api.draw_item_editor, debug.traceback)
                if ok_draw then
                    configChanged = configChanged or (changedOrErr == true)
                elseif api.record_error ~= nil then
                    api.record_error("suite:draw_item_editor", changedOrErr)
                    imgui.text("Error captured (see Diagnostics).")
                end
            else
                imgui.text("item_editor not loaded yet...")
            end
        end)

        Imgui.Tree("Weapon And Armor Editor", function()
            if api.draw_weapon_armor_editor ~= nil then
                local ok_draw, changedOrErr = xpcall(api.draw_weapon_armor_editor, debug.traceback)
                if ok_draw then
                    configChanged = configChanged or (changedOrErr == true)
                elseif api.record_error ~= nil then
                    api.record_error("suite:draw_weapon_armor_editor", changedOrErr)
                    imgui.text("Error captured (see Diagnostics).")
                end
            else
                imgui.text("weapon_armor_editor not loaded yet...")
            end
        end)

        Imgui.Tree("Max Slots And Skills", function()
            if api.draw_max_slots_skills ~= nil then
                local ok_draw, err = xpcall(api.draw_max_slots_skills, debug.traceback)
                if not ok_draw and api.record_error ~= nil then
                    api.record_error("suite:draw_max_slots_skills", err)
                    imgui.text("Error captured (see Diagnostics).")
                end
            else
                imgui.text("max_slots_skills not loaded yet...")
            end
        end)

        Imgui.Tree("RE-Editor", function()
            imgui.text("For MHWS, RE-Editor builds as MHWS-Editor.")
            if imgui.button("Launch MHWS-Editor (RE-Editor)") then
                local okLaunch, detail = tryLaunchExe({
                    "MHWS-Editor/MHWS-Editor.exe",
                    "RE-Editor/MHWS-Editor.exe",
                    "MHWS-Editor.exe",
                })
                if okLaunch then
                    launchState.re_editor = string.format("Launched: %s", detail)
                else
                    launchState.re_editor = string.format(
                        "Launch failed: %s\nExpected: MHWS-Editor/MHWS-Editor.exe (or RE-Editor/MHWS-Editor.exe)",
                        tostring(detail)
                    )
                end
            end

            if launchState.re_editor ~= nil then
                imgui.text(launchState.re_editor)
            end
        end)

        Imgui.Tree("Diagnostics", function()
            local lastError = api._last_error

            local tools = rawget(_G, "mhws_tools")
            imgui.text(string.format("mhws_tools plugin loaded: %s", (tools ~= nil and type(tools) == "table") and "yes" or "no"))

            imgui.text("REFramework log files:")
            if imgui.button("Open reframework/log.txt") then
                local okOpen, detail = tryLaunchExe({
                    "reframework/log.txt",
                    "reframework\\log.txt",
                })
                if okOpen then
                    launchState.diag_open_log = string.format("Opened: %s", detail)
                else
                    launchState.diag_open_log = "Not found: reframework/log.txt"
                end
            end

            if imgui.button("Open mhws_errors.log") then
                local okOpen, detail = tryLaunchExe({
                    api._error_log_path,
                })
                if okOpen then
                    launchState.diag_open_suite_log = string.format("Opened: %s", detail)
                else
                    launchState.diag_open_suite_log = string.format("Not found: %s", tostring(api._error_log_path))
                end
            end

            if lastError ~= nil then
                if imgui.button("Copy last captured error") then
                    local copied = false
                    if api.set_clipboard_text ~= nil then
                        copied = api.set_clipboard_text(lastError) == true
                    end
                    launchState.diag_copied = copied and "Copied to clipboard." or "Clipboard API not available. Use mhws_errors.log instead."
                end
                imgui.text_wrapped(lastError)
            else
                imgui.text("No captured errors yet.")
            end

            if launchState.diag_open_log ~= nil then
                imgui.text(launchState.diag_open_log)
            end
            if launchState.diag_open_suite_log ~= nil then
                imgui.text(launchState.diag_open_suite_log)
            end
            if launchState.diag_copied ~= nil then
                imgui.text(launchState.diag_copied)
            end
        end)

        return configChanged
    end, debug.traceback)

    if not ok then
        if api ~= nil and api.record_error ~= nil then
            api.record_error("suite.Menu", result)
        end
        return false
    end

    return result
end)

re.on_frame(function()
    local api = _G.__MHWS_EDITOR_SUITE
    if api ~= nil and api.on_frame_item_box_editor ~= nil then
        local ok, err = xpcall(api.on_frame_item_box_editor, debug.traceback)
        if (not ok) and api.record_error ~= nil then
            api.record_error("suite.on_frame_item_box_editor", err)
        end
    end
end)
