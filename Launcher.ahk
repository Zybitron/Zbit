/************************************************************************
 * @description Launcher for Zybit
 * @author Luka
 * @license MIT-Open-Source
 * @date 2025/05/20
 * @version v0.0.0-0
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance Force

/* --- CONSTANTS & CONFIG --- */
global ROBLOX_WINDOW := "ahk_exe RobloxPlayerBeta.exe"
global PLACEMENT_KEY := "{4}"
global SCAN_X := 27, SCAN_Y := 15, SCAN_W := 800, SCAN_H := 600
global SCAN_COLOR := "200FF00"
global PLACEMENT_MOUSE_X := 763, PLACEMENT_MOUSE_Y := 553
global CHECK_PIXEL_X := 221, CHECK_PIXEL_Y := 323, CHECK_COLOR := "0x090909"
global DEBUG := 1

/* --- LIBRARIES --- */
#Include lib\Neutron\Neutron.ahk
#Include lib\PathScanLib.ahk
#Include lib\IsProcessElevated.ahk
#Include lib\FindText.ahk
#Include lib\webhook.ahk
#Include lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include lib\Gdip_All.ahk

/* --- GLOBAL VARIABLES --- */
global autoUpdateEnabled := false
global g_KillSwitch := false
global SendWebhooks := ""
global MacroStartTime := A_TickCount
global StageStartTime := A_TickCount
global selectedMacro := ""
pid := DllCall("GetCurrentProcessId", "uint")
sendLogWebhookv := ""
production := ""

/* --- AUTO RUN --- */
if production {
    CheckIfAdmin()
}

/* --- MAIN WINDOW --- */
mainWin := NeutronWindow()
mainWin.Load("GUI/index.html")
mainWin.Show("w1200 h800")
mainWin.OnEvent("Escape", (*) => (Logger("Escape event triggered - Exiting app"), ExitApp()))

/* --- HOTKEYS --- */
F1:: (Logger("F1 pressed - Setup called"), Setup())
F4:: (Logger("F4 pressed - Pause called"), Pause())
F12:: (Logger("F12 pressed - ToggleKillSwitch called"), ToggleKillSwitch())

/* --- FUNCTIONS --- */

/**
 * Logs a message to debug_log.log.
 * @param {string} msg - The message to log.
 */
Logger(msg) {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    logLine := "[" timestamp "] " msg "`n"
    FileAppend(logLine, "debug_log.log")
}

/**
 * Checks if the process is running as administrator.
 * @return {boolean} True if elevated, false otherwise.
 */
CheckIfAdmin() {
    Logger("CheckIfAdmin called")
    if !IsProcessElevated(pid) {
        Logger("Process not elevated - exiting")
        return false
    }
    Logger("Process is elevated")
    return true
}

/**
 * Clicks at the specified coordinates with the given mouse button.
 * @param {int} x - X coordinate
 * @param {int} y - Y coordinate
 * @param {string} LR - Mouse button (default: "Left")
 */
BetterClick(x, y, LR := "Left") {
    if (!IsInteger(x) || !IsInteger(y)) {
        Logger("BetterClick: Invalid coordinates")
        return
    }
    Logger("BetterClick at (" x ", " y ") with button: " LR)
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep 50
}

/**
 * Toggles the global kill switch.
 */
ToggleKillSwitch() {
    global g_KillSwitch
    g_KillSwitch := !g_KillSwitch
    Logger("Kill Switch toggled: " (g_KillSwitch ? "ON" : "OFF"))
    ToolTip(g_KillSwitch ? "Kill Switch ACTIVATED" : "Kill Switch DEACTIVATED")
    SetTimer(() => ToolTip(), -1500)
}

/**
 * Sets up the macro environment and starts the placement process.
 * @param {Array} unitSlots - Array of unit slot keys to place.
 */
Setup(unitSlots := []) {
    Logger("Setup called")
    if WinExist(ROBLOX_WINDOW) {
        Logger("Roblox window found")
        global MacroStartTime := A_TickCount
        Logger("SetupMacro called")
        WinActivate(ROBLOX_WINDOW)
        Sleep 50
        WinMove(SCAN_X, SCAN_Y, SCAN_W, SCAN_H, ROBLOX_WINDOW)
        Sleep 50
        ScanAndPlace(unitSlots)
    } else {
        Logger("Roblox window not found")
        MsgBox("Roblox window not found.", "Error", 16)
    }
}

/**
 * Simulates tap-to-move in Roblox.
 * @param {boolean} toggle - Direction toggle.
 */
TapToMove(toggle) {
    Logger("TapToMove called with toggle: " toggle)
    SendInput("{Esc}")
    Sleep 1000
    BetterClick(246, 91)
    Sleep 500
    SendInput("{Down}")
    Sleep 100
    SendInput("{Down}")
    Sleep 500
    if (toggle) {
        SendInput("{Right}")
        Sleep 400
        SendInput("{Right}")
    } else {
        SendInput("{Left}")
        Sleep 400
        SendInput("{Left}")
    }
    Sleep 500
    SendInput("{Esc}")
    Sleep 1000
}

/**
 * Attempts to reconnect to Roblox if disconnected.
 * (Currently commented out/incomplete)
 */
Reconnect() {
    Logger("Reconnect called")
    static retryCount := 0
    static maxRetries := 5
    /*
    ; TODO: Implement reconnect logic using PixelGetColor and FindText
    */
}

/**
 * Scans for valid placement positions and places units accordingly.
 * @param {Array} unitSlots - Array of unit slot keys to place.
 */
ScanAndPlace(unitSlots) {
    Logger("ScanAndPlace called")
    MouseMove(PLACEMENT_MOUSE_X, PLACEMENT_MOUSE_Y)
    Sleep 100
    SendInput(PLACEMENT_KEY)
    Sleep 1000

    dots := ScanPath(SCAN_X, SCAN_Y, SCAN_W, SCAN_H, true, 10, SCAN_COLOR)
    Logger("Dots scanned: " dots.Length)
    Sleep 100

    MsgBox("Dots scanned: " dots.Length)
    MsgBox("Unit slots: " unitSlots.Length)

    WinGetPos(&winX, &winY, &winWidth, &winHeight, ROBLOX_WINDOW)
    filteredDots := []
    for index, dot in dots {
        if (Mod(index, 5) == 0) {
            filteredDots.Push(dot)
        }
    }
    Logger("Filtered dots: " filteredDots.Length)
    dots := filteredDots

    placedUnits := 0
    while (placedUnits < unitSlots.Length) {
        for index, dot in dots {
            if (dot.x < winX || dot.x > (winX + winWidth) || dot.y < winY || dot.y > (winY + winHeight)) {
                Logger("Dot out of window bounds: (" dot.x ", " dot.y ")")
                continue
            }
            Logger("Clicking dot at (" dot.x ", " dot.y ")")
            BetterClick(dot.x, dot.y)
            if (!CheckPlacementSuccess()) {
                Logger("Placement check failed at (" dot.x ", " dot.y ")")
                continue
            }
            slot := unitSlots[index]
            if !slot {
                Logger("No slot found for index " index)
                continue
            }
            Logger("Placing unit from slot " slot " at (" dot.x ", " dot.y ")")
            Send(slot "")
            Sleep(50)
            if DEBUG {
                ToolTip("Placed unit from slot " slot " at (" dot.x ", " dot.y ")", dot.x + 10, dot.y + 10)
                Sleep(500)
                ToolTip()
            }
            placedUnits++
            Logger("Units placed: " placedUnits)
            Sleep(100)
            if (placedUnits >= unitSlots.Length) {
                Logger("All units placed")
                break
            }
        }
    }
}

/**
 * Checks if the last placement was successful by verifying a pixel color.
 * @return {boolean} True if placement succeeded, false otherwise.
 */
CheckPlacementSuccess() {
    Logger("CheckPlacementSuccess called")
    color := PixelGetColor(CHECK_PIXEL_X, CHECK_PIXEL_Y)
    Logger("PixelGetColor at (" CHECK_PIXEL_X ", " CHECK_PIXEL_Y "): " color)
    if (color != CHECK_COLOR) {
        Logger("Color mismatch: expected " CHECK_COLOR ", got " color)
        return false
    }
    Logger("Color matched: " color)
    return true
}

/* --- NEUTRON EVENTS --- */

/**
 * Handles macro launch events from the Neutron GUI.
 */
LaunchMacroNeutron(neutron, event) {
    Logger("LaunchMacroNeutron called")
    selectedMacro := neutron.qs("#macroSelect").value
    Logger("Selected macro: " selectedMacro)
    if (selectedMacro = "pathfinder") {
        Logger(selectedMacro " mode selected")
        Macro1()
    } else {
        Logger(selectedMacro " mode selected")
        MsgBox(selectedMacro " mode is not implemented yet.")
    }
}

/**
 * Updates macro info in the Neutron GUI.
 */
updateMacroInfo(neutron, event) {
    Logger("updateMacroInfo called")
    global selectedMacro := neutron.qs("#macroSelect").value
    Logger("Selected macro for info: " selectedMacro)
    if (selectedMacro = "pathfinder") {
        html := "<span><b>Name:</b> Path Finder</span><br>"
        html .= "<span><b>Version:</b> v0.0.0-0</span><br>"
        html .= "<span><b>Author:</b> Luka</span><br>"
        html .= "<span><b>Description:</b> Automatically finds and places units in Roblox.</span>"
    } else if (selectedMacro = "testmode") {
        html := "<span><b>Name:</b> Test Mode</span><br>"
        html .= "<span><b>Version:</b> v0.0.0-0</span><br>"
        html .= "<span><b>Author:</b> N/A</span><br>"
        html .= "<span><b>Description:</b> Test automation features. (In progress)</span>"
    } else {
        html := "<span><b>Select a macro</b></span><br>"
    }
    Logger("Updating macroInfo HTML")
    neutron.qs("#macroInfo").innerHTML := html
}

/* --- MACROS --- */

/**
 * Example macro for pathfinder.
 */
Macro1() {
    Logger(selectedMacro " called")
    Sleep(100)
    Setup(["1", "2", "3", "4", "5"])
}

/* --- WEBHOOKS & TODOs --- */
/*
TODO:
- []Implement sendLogWebhook and other webhook-related functions.
- []Move all magic numbers and hardcoded values to config or constants.
- []Modularize codebase (split macros, GUI, and utilities).
- []Add unit tests and CI/CD integration.
- []Add cleanup logic for graceful shutdown.
- []Automate version management and changelog generation.
- []Fix close button in Neutron GUI.
*/
