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

local function findFirstExistingPath(candidates)
    for _, candidatePath in ipairs(candidates) do
        local f = io.open(candidatePath, "rb")
        if f ~= nil then
            f:close()
            return candidatePath
        end
    end
    return nil
end

local function tryLaunchExe(candidates)
    local exePath = findFirstExistingPath(candidates)
    if exePath == nil then
        return false, "not found"
    end

    exePath = exePath:gsub("/", "\\")
    os.execute(string.format('start "" "%s"', exePath))
    return true, exePath
end

local suite = Core.NewMod("MHWS Editor Suite")

suite.Menu(function()
    local api = _G.__MHWS_EDITOR_SUITE
    local configChanged = false
    local launchState = api._launch_state or {}
    api._launch_state = launchState

    Imgui.Tree("Item Box Editor", function()
        if api.draw_item_box_editor ~= nil then
            api.draw_item_box_editor()
        else
            imgui.text("ItemBoxEditor not loaded yet...")
        end
    end)

    Imgui.Tree("Item Editor", function()
        if api.draw_item_editor ~= nil then
            local changed = api.draw_item_editor()
            configChanged = configChanged or (changed == true)
        else
            imgui.text("item_editor not loaded yet...")
        end
    end)

    Imgui.Tree("Weapon And Armor Editor", function()
        if api.draw_weapon_armor_editor ~= nil then
            local changed = api.draw_weapon_armor_editor()
            configChanged = configChanged or (changed == true)
        else
            imgui.text("weapon_armor_editor not loaded yet...")
        end
    end)

    Imgui.Tree("RE-Editor", function()
        if imgui.button("Launch RE-Editor") then
            local ok, detail = tryLaunchExe({
                "RE-Editor/RE-Editor.exe",
                "RE-Editor.exe",
            })
            if ok then
                launchState.re_editor = string.format("Launched: %s", detail)
            else
                launchState.re_editor = "RE-Editor.exe not found. Put it in the game folder as RE-Editor/RE-Editor.exe or RE-Editor.exe"
            end
        end

        if launchState.re_editor ~= nil then
            imgui.text(launchState.re_editor)
        end
    end)

    Imgui.Tree("Diagnostics", function()
        local lastError = api._last_error

        imgui.text("REFramework log files:")
        if imgui.button("Open reframework/log.txt") then
            local ok, detail = tryLaunchExe({
                "reframework/log.txt",
                "reframework\\log.txt",
            })
            if ok then
                launchState.diag_open_log = string.format("Opened: %s", detail)
            else
                launchState.diag_open_log = "Not found: reframework/log.txt"
            end
        end

        if imgui.button("Open mhws_errors.log") then
            local ok, detail = tryLaunchExe({
                api._error_log_path,
            })
            if ok then
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
end)

re.on_frame(function()
    local api = _G.__MHWS_EDITOR_SUITE
    if api ~= nil and api.on_frame_item_box_editor ~= nil then
        api.on_frame_item_box_editor()
    end
end)
