;#Requires AutoHotkey v2.0
#Include Gdip_All.ahk
#SingleInstance Force

ScanPath(startX, startY, width := 800, height := 600, debug := false, dotSpacing := 10, dotColor := "00FF00") {
    token := Gdip_Startup()
    if !token {
        MsgBox("Failed to start GDI+")
        return
    }

    if (debug) {
        FileAppend("ScanPath: " startX ", " startY ", " width ", " height "`n", "debug_log.txt")
    }

    hdcScreen := GetDC(0)
    hdcMem := CreateCompatibleDC(hdcScreen)
    hbmScreen := CreateCompatibleBitmap(hdcScreen, width, height)
    obm := SelectObject(hdcMem, hbmScreen)
    BitBlt(hdcMem, 0, 0, width, height, hdcScreen, startX, startY, 0x00CC0020)
    ReleaseDC(0, hdcScreen)

    pBitmap := Gdip_CreateBitmapFromHBITMAP(hbmScreen)

    overlayGui := Gui("+AlwaysOnTop -Caption +E0x80000 +ToolWindow", "PathOverlay")
    overlayGui.BackColor := "000000"
    overlayGui.Show("x" startX " y" startY " w" width " h" height " NA")
    hwnd := overlayGui.Hwnd

    hbm := CreateDIBSection(width, height)
    hdc := CreateCompatibleDC()
    obm2 := SelectObject(hdc, hbm)
    graphics := Gdip_GraphicsFromHDC(hdc)
    Gdip_SetSmoothingMode(graphics, 4)

    pathColor := {r: 0x95, g: 0x22, b: 0x3A}  ; Path color to detect
    tolerance := 15  ; Reduce tolerance to be more strict about matching color
    pathPen := Gdip_CreatePen("0xFF" dotColor, 2)
    dotBrush := Gdip_BrushCreateSolid("0xFF" dotColor)

    prevX := -1
    prevY := -1
    prevDirection := ""  ; Track previous direction for corner detection
    dotRadius := 4
    drawLeft := true

    dots := []  ; Array to store the positions of the detected dots

    Loop height {
        y := A_Index - 1
        maxGroupLen := 0
        bestStart := -1
        x := 0
        while (x < width) {
            argb := Gdip_GetPixel(pBitmap, x, y)
            r := (argb >> 16) & 0xFF
            g := (argb >> 8) & 0xFF
            b := argb & 0xFF

            ; Tighter color matching threshold to recognize path color more accurately
            if (Abs(r - pathColor.r) < tolerance && Abs(g - pathColor.g) < tolerance && Abs(b - pathColor.b) < tolerance) {
                start := x
                while (x < width) {
                    argb := Gdip_GetPixel(pBitmap, x, y)
                    r := (argb >> 16) & 0xFF
                    g := (argb >> 8) & 0xFF
                    b := argb & 0xFF
                    if !(Abs(r - pathColor.r) < tolerance && Abs(g - pathColor.g) < tolerance && Abs(b - pathColor.b) < tolerance)
                        break
                    x++
                }
                groupLen := x - start
                if (groupLen > maxGroupLen) {
                    maxGroupLen := groupLen
                    bestStart := start
                }
            } else {
                x++
            }
        }

        if (bestStart >= 0) {
            centerX := bestStart + (maxGroupLen / 2)
            absX := startX + centerX
            absY := startY + y

            ; Detect a corner (if direction changes)
            if (prevX >= 0 && prevY >= 0) {
                ; Horizontal or Vertical Movement?
                if (prevX != absX) {  ; Horizontal movement
                    if (prevDirection != "Horizontal") {
                        dots.Push({x: absX, y: absY})  ; Add corner
                        prevDirection := "Horizontal"
                    }
                } else {  ; Vertical movement
                    if (prevDirection != "Vertical") {
                        dots.Push({x: absX, y: absY})  ; Add corner
                        prevDirection := "Vertical"
                    }
                }
            }

            ; Draw the line and dot
            Gdip_DrawLine(graphics, pathPen, prevX - startX, prevY - startY, centerX, y)

            if (Mod(y, dotSpacing) == 0) {
                Gdip_FillEllipse(graphics, dotBrush, centerX - (dotRadius / 2), y - (dotRadius / 2), dotRadius, dotRadius)
                dots.Push({x: absX, y: absY})
            }

            prevX := absX
            prevY := absY
        }
    }

    UpdateLayeredWindow(hwnd, hdc, startX, startY, width, height)

    Gdip_DeleteBrush(dotBrush)
    Gdip_DeletePen(pathPen)
    Gdip_DeleteGraphics(graphics)
    SelectObject(hdc, obm2)
    DeleteDC(hdc)
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    DeleteObject(hbm)
    DeleteObject(hbmScreen)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(token)

    SetTimer(() => overlayGui.Destroy(), -5000)

    return dots  
}