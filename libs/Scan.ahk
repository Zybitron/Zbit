#Requires AutoHotkey v2.0
#Include Gdip_All.ahk

FindRedPath(region := {x: 0, y: 0, w: 1920, h: 1080}, offsetX := 15, autoClick := true) {
    if !Gdip_Startup() {
        MsgBox "GDI+ failed to start"
        return
    }

    x := region.x, y := region.y, w := region.w, h := region.h

    hbm := Gdip_BitmapFromScreen(x "|" y "|" (x + w) "|" (y + h))
    if !hbm {
        MsgBox "Failed to capture screen"
        return
    }

    pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
    Gdip_LockBits(pBitmap, 0, 0, w, h, &Stride, &Scan0, &BitmapData)

    found := false
    result := {}

    Loop row, 0, h - 1, 2 {
        Loop col, 0, w - 1, 2 {
            ARGB := NumGet(Scan0 + (row * Stride) + (col * 4), "UInt")
            R := (ARGB >> 16) & 0xFF
            G := (ARGB >> 8) & 0xFF
            B := ARGB & 0xFF

            if (R >= 160 && G <= 70 && B <= 70) {
                clickX := x + col + offsetX
                clickY := y + row

                if autoClick {
                    MouseMove(clickX, clickY)
                    Sleep(100)
                    Click "Left"
                }

                result := {x: clickX, y: clickY}
                found := true
                break
            }
        }
        if found
            break
    }

    Gdip_UnlockBits(pBitmap, &BitmapData)
    Gdip_DisposeImage(pBitmap)
    DeleteObject(hbm)
    Gdip_Shutdown()

    return found ? result : ""
}
