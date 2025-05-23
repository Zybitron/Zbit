; =====================
; Webhook Utilities for Zybitron
; ====================
/*
#Include Discord-Webhook-master\lib\WEBHOOK.ahk
#Include Gdip_All.ahk

; --- Utility Functions ---
CalculateElapsedTime(StartTime) {
    ElapsedTimeMs := A_TickCount - StartTime
    ElapsedTimeSec := Floor(ElapsedTimeMs / 1000)
    ElapsedHours := Floor(ElapsedTimeSec / 3600)
    ElapsedMinutes := Floor(Mod(ElapsedTimeSec, 3600) / 60)
    ElapsedSeconds := Mod(ElapsedTimeSec, 60)
    Return Format("{} hours, {} minutes", ElapsedHours, ElapsedMinutes)
}

; --- Webhook Senders ---
sendWebhook() {
    global MacroStartTime, StageStartTime, WebhookURL
    MacroRuntime := CalculateElapsedTime(MacroStartTime)
    StageRuntime := CalculateElapsedTime(StageStartTime)
    myEmbed := EmbedBuilder()
    myEmbed.setTitle(":tada: Stage Completed :tada:")
    myEmbed.setDescription(":stopwatch: Macro Runtime: " MacroRuntime "`n:stopwatch: Stage Runtime: " StageRuntime "")
    myEmbed.setColor(0x0A5EB0)
    myEmbed.setFooter({ text: "Taxi Webhooks" })
    try {
        if (WebhookURL != "") {
            webhook := WebHookBuilder(WebhookURL)
            webhook.send({ embeds: [myEmbed] })
            Logger("Sent webhook log successfully")
        }
    } catch {
        Logger("Failed to send webhook log")
    }
}

sendDCWebhook() {
    global MacroStartTime, StageStartTime, WebhookURL
    MacroRuntime := CalculateElapsedTime(MacroStartTime)
    StageRuntime := CalculateElapsedTime(StageStartTime)
    myEmbed := EmbedBuilder()
    myEmbed.setTitle(":exclamation: Client Disconnected :exclamation:")
    myEmbed.setDescription(":stopwatch: Disconnected At: " MacroRuntime "`n:stopwatch: Stage Runtime: " StageRuntime "")
    myEmbed.setColor(0xB00A0A)
    myEmbed.setFooter({ text: "Taxi Webhooks" })
    try {
        if (WebhookURL != "") {
            webhook := WebHookBuilder(WebhookURL)
            webhook.send({ embeds: [myEmbed] })
            Logger("Sent disconnect webhook log successfully")
        }
    } catch {
        Logger("Failed to send disconnect webhook log")
    }
}

sendRCWebhook() {
    global MacroStartTime, WebhookURL
    MacroRuntime := CalculateElapsedTime(MacroStartTime)
    myEmbed := EmbedBuilder()
    myEmbed.setTitle(":white_check_mark: Client Reconnected :white_check_mark:")
    myEmbed.setDescription(":stopwatch: Reconnected At: " MacroRuntime "")
    myEmbed.setColor(0x0AB02D)
    myEmbed.setFooter({ text: "Taxi Webhooks" })
    try {
        if (WebhookURL != "") {
            webhook := WebHookBuilder(WebhookURL)
            webhook.send({ embeds: [myEmbed] })
            Logger("Sent reconnect webhook log successfully")
        }
    } catch {
        Logger("Failed to send reconnect webhook log")
    }
}

sendLogWebhook(msg) {
    global WebhookURL
    try {
        if (WebhookURL != "") {
            webhook := WebHookBuilder(WebhookURL)
            embed := EmbedBuilder()
            embed.setTitle(Format("{} - Zybitron Log", A_UserName))
            embed.setDescription(msg)
            embed.setColor(0x5865F2)
            embed.setFooter({ text: "Zybitron Logger" })
            webhook.send({ embeds: [embed] })
        }
    } catch {
        ; Ignore webhook errors
    }
}

; --- Image Utility ---
; credits to faxi
CropImage(pBitmap, x, y, width, height) {
    pGraphics := Gdip_GraphicsFromImage(pBitmap)
    if !pGraphics {
        MsgBox("Failed to initialize graphics object")
        return
    }
    pCroppedBitmap := Gdip_CreateBitmap(width, height)
    if !pCroppedBitmap {
        MsgBox("Failed to create cropped bitmap")
        Gdip_DeleteGraphics(pGraphics)
        return
    }
    pTargetGraphics := Gdip_GraphicsFromImage(pCroppedBitmap)
    if !pTargetGraphics {
        MsgBox("Failed to initialize graphics for cropped bitmap")
        Gdip_DisposeImage(pCroppedBitmap)
        Gdip_DeleteGraphics(pGraphics)
        return
    }
    Gdip_DrawImage(pTargetGraphics, pBitmap, 0, 0, width, height, x, y, width, height)
    Gdip_DeleteGraphics(pGraphics)
    Gdip_DeleteGraphics(pTargetGraphics)
    return pCroppedBitmap
}

; --- End of File ---
