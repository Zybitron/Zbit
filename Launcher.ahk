/************************************************************************
 * @description Launcher for the Zybit
 * @author Luka ...
 * @license MIT-Open-Source
 * @date 2025/05/20
 * @version v0.0.0-0
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance Force

/* LIBS AND INCLUDES */


#Include lib\Neutron\Neutron.ahk
#Include lib\PathScanLib.ahk
#Include lib\IsProcessElevated.ahk
#Include lib\FindText.ahk
#Include lib\webhook.ahk
#Include lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include lib\Gdip_All.ahk

/*-------------------------------*/

/* SETTINGS AND VARIABLES */
; Move sensitive data to config

global autoUpdateEnabled := false
global g_KillSwitch := false
global debug := 1
global robloxWindow := "ahk_exe RobloxPlayerBeta.exe"
global SendWebhooks := ""
global MacroStartTime := A_TickCount
global StageStartTime := A_TickCount
pid := DllCall("GetCurrentProcessId", "uint")
sendLogWebhookv := ""
production := ""
/* Auto Run Functions */
if production {
    CheckIfAdmin()
}

/*-------------------------------*/

mainWin := NeutronWindow()
mainWin.Load("GUI/index.html")
mainWin.Show("w1200 h800")
mainWin.OnEvent("Escape", (*) => (Logger("Escape event triggered - Exiting app"), ExitApp()))

/*-------------------------------*/

/* HOTKEYS */

F1:: (Logger("F1 pressed - Setup called"), Setup())
F4:: (Logger("F4 pressed - Pause called"), Pause())
F12:: (Logger("F12 pressed - ToggleKillSwitch called"), ToggleKillSwitch())

/*-------------------------------*/

/* FUNCTIONS */

/**
 * Logs a message to debug_log.log and optionally sends to webhook.
 * @param {string} msg - The message to log.
 */
Logger(msg) {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    logLine := "[" timestamp "] " msg "`n"
    FileAppend(logLine, "debug_log.log")
}

/**
 * Checks if the process is running as administrator.
 * Exits if not elevated.
 */
CheckIfAdmin() {
    Logger("CheckIfAdmin called")
    if !IsProcessElevated(pid) {
        Logger("Process not elevated - exiting")
        return false
    }
    else {
        Logger("Process is elevated")
        return true
    }
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
    Logger("BetterClick called at (" x ", " y ") with button: " LR)
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep 50
}

ToggleKillSwitch() {
    global g_KillSwitch
    g_KillSwitch := !g_KillSwitch
    Logger("Kill Switch toggled: " (g_KillSwitch ? "ON" : "OFF"))
    ToolTip(g_KillSwitch ? "Kill Switch ACTIVATED" : "Kill Switch DEACTIVATED")
    SetTimer(() => ToolTip(), -1500)
}

Setup(unitSlots := []) {
    Logger("Setup called")
    if WinExist(robloxWindow) {
        Logger("Roblox window found")
        global MacroStartTime := A_TickCount
        Logger("SetupMacro called")
        if WinExist(robloxWindow) {
            WinActivate(robloxWindow)
            Sleep 50
            WinMove(27, 15, 800, 600, robloxWindow)
            Sleep 50
        } else {
            Logger("Roblox window not found in SetupMacro")
            MsgBox("Roblox window not found.", "Error", 16)
            return
        }
        ScanAndPlace(unitSlots)
    } else {
        Logger("Roblox window not found")
        MsgBox("Roblox window not found.", "Error", 16)
        return
    }
}

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
    }
    else {
        SendInput("{Left}")
        Sleep 400
        SendInput("{Left}")
    }
    Sleep 500
    SendInput("{Esc}")
    Sleep 1000
}

Reconnect() {
    Logger("Reconnect called")
    static retryCount := 0
    static maxRetries := 5
    /*
    ; Check for Disconnected Screen
    color := PixelGetColor(519, 329) ; Get color at (519, 329)
    global hasReconnect
    if (color = 0x393B3D) {
        ;if (DisconnectCheckbox.Value = 1) {
        ;    sendDCWebhook()
        ;}
    
        ; Use Roblox deep linking to reconnect
        Run("roblox://placeID=" 8304191830)
        Sleep 2000
        if WinExist(RobloxWindow) {
            WinMove(27, 15, 800, 600, RobloxWindow)
            WinActivate(RobloxWindow)
            Sleep 1000
        }
        loop {
            Sleep 15000
            if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
                Logger("Reconnected successfully")
                hasReconnect := 1
                ;return GoToRaids() ; Check for challenges in the lobby
            }
            else {
                Logger("Reconnect failed, retrying")
                if (++retryCount > maxRetries) {
                    Logger("Reconnect: Max retries reached. Aborting.")
                    MsgBox("Failed to reconnect after " maxRetries " attempts.", "Error", 16)
                    retryCount := 0
                    return
                }
                Reconnect()
            }
        }
    }*/
}

ScanAndPlace(unitSlots) {
    Logger("ScanAndPlace called")
    MouseMove(763, 553)
    Sleep 100
    SendInput("{4}")
    Sleep 1000
    dots := ScanPath(27, 15, 800, 600, true, 10, "200FF00")
    Logger("Dots scanned: " dots.Length)
    Sleep 100
    MsgBox("Dots scanned: " dots.Length)
    MsgBox(unitSlots.Length)
    ; PlaceUnits logic inlined here
    WinGetPos(&winX, &winY, &winWidth, &winHeight, robloxWindow)
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
            if (!checkiftrue()) {
                Logger("checkiftrue failed at (" dot.x ", " dot.y ")")
                continue
            }
            slot := unitSlots[index]
            Logger("Placing unit from slot " slot " at (" dot.x ", " dot.y ")")
            Send(slot "")
            Sleep(50)
            if debug {
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

checkiftrue() {
    Logger("checkiftrue called")
    pixelX := 221
    pixelY := 323
    expectedColor := "0x090909"
    if (!IsInteger(pixelX) || !IsInteger(pixelY) || !expectedColor) {
        Logger("checkiftrue parameters missing or invalid")
        return false
    }
    Sleep(1000)
    color := PixelGetColor(pixelX, pixelY)
    Logger("PixelGetColor at (" pixelX ", " pixelY "): " color)
    if (color != expectedColor) {
        Logger("Color mismatch: expected " expectedColor ", got " color)
        return false
    }
    Logger("Color matched: " color)
    return true
}

/* Neutron Events */

LaunchMacroNeutron(neutron, event) {
    Logger("LaunchMacroNeutron called")
    selectedMacro := neutron.qs("#macroSelect").value
    Logger("Selected macro: " selectedMacro)
    if (selectedMacro = "pathfinder") {
        Logger(selectedMacro " mode selected")
        ; TODO: Make it open Active Gui
        Macro1()
    } else {
        Logger(selectedMacro " mode selected")
        MsgBox(selectedMacro " mode is not implemented yet.")
    }
}

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

/*-------------------------------*/
/* Macros */
Macro1() {
    Logger(selectedMacro " called")
    Sleep(100)
    Setup(unitSlots := ["1", "2", "3", "4", "5"])
}

/* WEBHOOKS */

; TODO: Implement sendLogWebhook and other webhook-related functions
; TODO: Move all magic numbers and hardcoded values to config or constants
; TODO: Modularize codebase (split macros, GUI, and utilities)
; TODO: Add unit tests and CI/CD integration
; TODO: Add cleanup logic for graceful shutdown
; TODO: Automate version management and changelog generation !!!!!!!!!!!!Important!!!!!!!!!!!!!!!!!!!!!!!
; TODO: Fix close button in Neutron !!!!!!!!!!!!!!!!!!!!!!!!!!!
