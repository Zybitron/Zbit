#Requires AutoHotkey v2.0

main := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80000")
main.BackColor := "Black"
main.Show("x100 y100 w600 h400")  ; Main window

; Transparent overlay for hole
overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80000 +E0x20") ; Layered + Transparent
overlay.BackColor := "Green"  ; Dummy color for region
overlay.Show("x150 y150 w300 h300") ; Positioned over the black panel

; Create a hole in center of overlay
ow := 300, oh := 300
holeX := 100, holeY := 100, holeW := 100, holeH := 100

rgnFull := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
rgnHole := DllCall("CreateRectRgn", "int", holeX, "int", holeY, "int", holeX + holeW, "int", holeY + holeH, "ptr")
DllCall("CombineRgn", "ptr", rgnFull, "ptr", rgnFull, "ptr", rgnHole, "int", 4) ; RGN_DIFF
DllCall("SetWindowRgn", "ptr", overlay.Hwnd, "ptr", rgnFull, "int", true)
DllCall("DeleteObject", "ptr", rgnHole)

; Set fully opaque
WinSetTransparent(255, overlay.Hwnd)
