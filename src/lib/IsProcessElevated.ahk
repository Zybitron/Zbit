; =====================
; IsProcessElevated - Privilege Check Utility for Zybitron
; =====================

#Requires AutoHotkey v2.0

/************************************************************************
 * @description Checks if a process is running with elevated privileges.
 * @author jNizM (mod. 2023)
 * @license Open Source
 * @date 2023-01-16
 ***********************************************************************/

/**
 * Checks if the given process is elevated (run as admin).
 * @param {int} ProcessID - The process identifier.
 * @returns {bool} True if elevated, false otherwise.
 */
IsProcessElevated(ProcessID){
    static INVALID_HANDLE_VALUE := -1
    static PROCESS_QUERY_INFORMATION := 0x0400
    static PROCESS_QUERY_LIMITED_INFORMATION := 0x1000
    static TOKEN_QUERY := 0x0008
    static TOKEN_QUERY_SOURCE := 0x0010
    static TokenElevation := 20
    hProcess := DllCall("OpenProcess", "UInt", PROCESS_QUERY_INFORMATION, "Int", False, "UInt", ProcessID, "Ptr")
    if (!hProcess) || (hProcess = INVALID_HANDLE_VALUE) {
        hProcess := DllCall("OpenProcess", "UInt", PROCESS_QUERY_LIMITED_INFORMATION, "Int", False, "UInt", ProcessID, "Ptr")
        if (!hProcess) || (hProcess = INVALID_HANDLE_VALUE)
            throw OSError()
    }
    if !(DllCall("advapi32\OpenProcessToken", "Ptr", hProcess, "UInt", TOKEN_QUERY | TOKEN_QUERY_SOURCE, "Ptr*", &hToken := 0)) {
        DllCall("CloseHandle", "Ptr", hProcess)
        throw OSError()
    }
    if !(DllCall("advapi32\GetTokenInformation", "Ptr", hToken, "Int", TokenElevation, "UInt*", &IsElevated := 0, "UInt", 4, "UInt*", &Size := 0)) {
        DllCall("CloseHandle", "Ptr", hToken)
        DllCall("CloseHandle", "Ptr", hProcess)
        throw OSError()
    }
    DllCall("CloseHandle", "Ptr", hToken)
    DllCall("CloseHandle", "Ptr", hProcess)
    return IsElevated
}

; --- End of File ---