#NoEnv
#MaxHotkeysPerInterval 200
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; --- Global Variables ---
global MacroRunning := 0
global CurrentHotkey := "q"
global GuiMainDisabled := 0

; Target Executable
global TargetWin := "ahk_exe RobloxPlayerBeta.exe"

; Stored Initial Mouse Position (Preserved strictly in RAM, not written to INI)
global SavedMouseX := 0
global SavedMouseY := 0

; Fail Safe Inactivity Watchdog
global InactivityTimeoutSec := 10
global LastClickTick := 0

; Zone Coordinates
global B1_X1 := 0, global B1_Y1 := 0, global B1_X2 := 0, global B1_Y2 := 0
global B2_X1 := 0, global B2_Y1 := 0, global B2_X2 := 0, global B2_Y2 := 0
global B3_X1 := 0, global B3_Y1 := 0, global B3_X2 := 0, global B3_Y2 := 0
global ActiveBox := ""

global EnableCyanColor := 1
global CyanColor := ""
global EnableExtraColor := 0
global BubbleTolerance := 15
global ClickColor := ""
global RestartColor := ""
global IniFile := A_ScriptDir . "\settings_v2.ini"
global FrameHwnd := 0

; Setup Overlay Coordinates
global CurX := 400, global CurY := 300, global CurW := 100, global CurH := 5

; Single Active Extra Bubble Color
global ExtraColor := "0x806DBF"

; --- AutoSell Timer Variables ---
global EnableAutoSell := 0
global AutoSellIntervalMin := 5
global LastSellTick := 0

; --- AutoSell Sequence Variables ---
global SellKeyChoice := "f"
global CustomSellKey := "e"
global EnablePos05 := 1
global Pos05_X := 0, global Pos05_Y := 0
global Pos1_X := 0, global Pos1_Y := 0
global Pos2_X := 0, global Pos2_Y := 0

; Position-Specific Glide and Hover Timers
global SelectedPosTiming := "Pos 0.5"
global Glide_Pos05 := 300, global Hover_Pos05 := 200
global Glide_Pos1  := 300, global Hover_Pos1  := 200
global Glide_Pos2  := 300, global Hover_Pos2  := 200

; Return to Spot Timing Variables
global ReturnDelayMs := 500
global ReturnGlideMs := 300

; --- GUI Setup ---
Gui, Main: New, +AlwaysOnTop
Gui, Add, Tab3, x5 y5 w280 h720 vMainTabs, Macro|AutoSell|Fail Safe

; ==================== TAB 1: MACRO ====================
Gui, Tab, Macro
Gui, Add, Text, x15 y35, 1. Setup Scan Zones:
Gui, Add, Button, x15 y55 w250 gSetZone1, 🎯 Zone 1: Bubble Box
Gui, Add, Button, x15 y85 w250 gSetZone2, 🎯 Zone 2: Scan Line
Gui, Add, Button, x15 y115 w250 gSetZone3, 🎯 Zone 3: Restart Box

Gui, Add, Text, x15 y150, 2. Target Colors:
Gui, Add, Button, x15 y170 w110 gPickCyanColor, 🧪 Cyan Bubble
Gui, Add, Progress, x+5 w75 h23 vCyanVisual -Smooth +Border cWhite BackgroundWhite, 100
Gui, Add, CheckBox, x+8 y174 vEnableCyanColor gToggleCyanColor Checked, On

Gui, Add, Button, x15 y200 w115 gPickClickColor, 🧪 Click Color
Gui, Add, Progress, x+5 w130 h23 vClickVisual -Smooth +Border cWhite BackgroundWhite, 100

Gui, Add, Button, x15 y230 w115 gPickRestartColor, 🧪 Restart Color
Gui, Add, Progress, x+5 w130 h23 vRestartVisual -Smooth +Border cWhite BackgroundWhite, 100

Gui, Add, Text, x15 y262, Extra Bubble Color (Single Active):
Gui, Add, CheckBox, x15 y280 vEnableExtraColor gToggleExtraColor, Enable Extra Color
Gui, Add, Text, x140 y281, Tol:
Gui, Add, Edit, x165 y278 w45 vBubbleToleranceInput gSaveAllSettings Number, 15

; Single Active Color Display
Gui, Add, Button, x15 y305 w115 h24 gPickExtraColorManual, 🧪 Custom Pick
Gui, Add, Progress, x+5 w130 h24 vExtraVisual -Smooth +Border cWhite BackgroundWhite, 100

; 3 Preset Buttons
Gui, Add, Button, x15 y335 w250 h24 gSetPresetVoid, Void Storm Bubbles
Gui, Add, Button, x15 y364 w250 h24 gSetPresetLava, Lava bubbles
Gui, Add, Button, x15 y393 w250 h24 gSetPresetVolcano, Volcano SFA bubbles

Gui, Add, Text, x15 y430, Click Cooldown (ms):
Gui, Add, Edit, x15 y448 w250 vNeedleCooldownInput gSaveAllSettings, 150

Gui, Add, Text, x15 y475, Scan Speed / Rate (ms):
Gui, Add, Edit, x15 y493 w250 vScanRateInput gSaveAllSettings, 30

Gui, Add, Text, x15 y520, Restart Delay (ms):
Gui, Add, Edit, x15 y538 w250 vRestartDelayInput gSaveAllSettings, 1000

Gui, Add, Text, x15 y575, ⌨️ Toggle Key:
Gui, Add, Edit, x100 y572 w50 vHotkeyInput gUpdateHotkey Limit1, q
Gui, Add, Text, x15 y605 w130 vStatus, Status: Ready
Gui, Add, Button, x150 y600 w115 h25 vStartBtn gToggleMacro Default, ▶️ Start

; ==================== TAB 2: AUTOSELL ====================
Gui, Tab, AutoSell
Gui, Add, CheckBox, x15 y35 vEnableAutoSell gSaveAllSettings, Enable Timer-Based AutoSell

Gui, Add, Text, x15 y60, AutoSell Interval (Minutes):
Gui, Add, Edit, x15 y78 w250 vAutoSellIntervalMinInput gSaveAllSettings Number, 5

Gui, Add, Text, x15 y105 w250 vTimerStatus, Next Sell In: Inactive

Gui, Add, Text, x15 y128, Key To Press (Step 1):
Gui, Add, Radio, x15 y146 vRadioKeyF gUpdateKeySelection Checked, F
Gui, Add, Radio, x65 y146 vRadioKeyE gUpdateKeySelection, E
Gui, Add, Radio, x115 y146 vRadioKeyCustom gUpdateKeySelection, Other:
Gui, Add, Edit, x175 y143 w50 vCustomSellKey gSaveAllSettings Limit1, e

Gui, Add, CheckBox, x15 y170 vEnablePos05 gSaveAllSettings, Enable Position 0.5 Click
Gui, Add, Button, x15 y192 w250 vBtnPos05 gPickPosition05, 📍 Position 0.5: (0, 0)
Gui, Add, Button, x15 y222 w250 vBtnPos1 gPickPosition1, 📍 Position 1: (0, 0)
Gui, Add, Button, x15 y252 w250 vBtnPos2 gPickPosition2, 📍 Position 2: (0, 0)

Gui, Add, Text, x15 y285, Select Position Timers:
Gui, Add, DropDownList, x15 y303 w250 vSelectedPosTiming gOnTimingTargetChange, Pos 0.5||Pos 1|Pos 2

Gui, Add, Text, x15 y333, Step Glide Time (ms):
Gui, Add, Edit, x15 y351 w250 vGlideTimeInput gSaveActiveTiming Number, 300

Gui, Add, Text, x15 y378, Step Hover Time (ms):
Gui, Add, Edit, x15 y396 w250 vHoverTimeInput gSaveActiveTiming Number, 200

Gui, Add, Text, x15 y428, Back To Fishing Spot Settings:
Gui, Add, Text, x15 y448, Wait Until Glide Back (ms):
Gui, Add, Edit, x15 y466 w250 vReturnDelayMsInput gSaveAllSettings Number, 500

Gui, Add, Text, x15 y493, Return Glide Time (ms):
Gui, Add, Edit, x15 y511 w250 vReturnGlideMsInput gSaveAllSettings Number, 300

; ==================== TAB 3: FAIL SAFE ====================
Gui, Tab, Fail Safe
Gui, Add, Text, x15 y35, Fail Safe Inactivity Watchdog:
Gui, Add, Text, x15 y60 w250, Configure how many seconds without a click before the macro executes an automated fail-safe click at the initial saved position.
Gui, Add, Text, x15 y110, Timeout Duration (Seconds):
Gui, Add, Edit, x15 y130 w250 vInactivityTimeoutSecInput gSaveAllSettings Number, 10
Gui, Add, Text, x15 y165 w250 cGray, Default is 10 seconds. Counter automatically resets on every single click made by the macro.

Gui, Show, w290, Fishing Macro V2

OnMessage(0x0201, "WM_LBUTTONDOWN")
LoadAllSettings()

Hotkey, %CurrentHotkey%, ToggleMacro, On UseErrorLevel
return

; --- Format & Swatch Helper ---
FormatHexColor(val) {
    if (val = "" || val = "ERROR")
        return ""
    clean := RegExReplace(val, "i)^(0x|#)")
    if (clean = "")
        return ""
    if (RegExMatch(clean, "^[0-9]+$") && StrLen(clean) > 6)
        clean := Format("{:X}", val)
    clean := SubStr("000000" . clean, -5)
    StringUpper, clean, clean
    return "0x" . clean
}

UpdateVisualSwatch(controlVar, colorHex) {
    clean := RegExReplace(colorHex, "i)^(0x|#)")
    if (StrLen(clean) = 6) {
        GuiControl, Main: +c%clean% +Background%clean%, %controlVar%
        GuiControl, Main:, %controlVar%, 100
    } else {
        GuiControl, Main: +cWhite +BackgroundWhite, %controlVar%
        GuiControl, Main:, %controlVar%, 100
    }
}

; --- Preset Color Handlers ---
SetPresetVoid:
    ExtraColor := "0x806DBF"
    UpdateVisualSwatch("ExtraVisual", ExtraColor)
    SaveAllSettings()
return

SetPresetLava:
    ExtraColor := "0xFD5F0A"
    UpdateVisualSwatch("ExtraVisual", ExtraColor)
    SaveAllSettings()
return

SetPresetVolcano:
    ExtraColor := "0xB000D0"
    UpdateVisualSwatch("ExtraVisual", ExtraColor)
    SaveAllSettings()
return

PickExtraColorManual:
    SampleScreenColor("Extra")
return

; --- Smooth Mouse Glide Movement ---
GlideMouseMove(targetX, targetY, durationMs) {
    CoordMode, Mouse, Screen
    MouseGetPos, startX, startY
    if (durationMs <= 0) {
        MouseMove, %targetX%, %targetY%, 0
        return
    }

    interval := 15
    steps := Max(1, Floor(durationMs / interval))
    loop, %steps% {
        progress := A_Index / steps
        curX := Round(startX + (targetX - startX) * progress)
        curY := Round(startY + (targetY - startY) * progress)
        MouseMove, %curX%, %curY%, 0
        DllCall("Sleep", "UInt", interval)
    }
    MouseMove, %targetX%, %targetY%, 0
}

; --- Click Execution ---
SendSavedClick() {
    global LastClickTick, SavedMouseX, SavedMouseY
    CoordMode, Mouse, Screen
    MouseGetPos, CurrentX, CurrentY
    Click, %SavedMouseX%, %SavedMouseY%
    MouseMove, %CurrentX%, %CurrentY%, 0
    LastClickTick := A_TickCount
}

; --- Fail Safe Inactivity Watchdog ---
BackgroundInactivityWatchdog:
    if (!MacroRunning || InactivityTimeoutSec <= 0)
        return

    timeoutMs := InactivityTimeoutSec * 1000
    if (A_TickCount - LastClickTick >= timeoutMs) {
        SendSavedClick()
    }
return

WM_LBUTTONDOWN() {
    if (A_Gui = "FrameBox") {
        PostMessage, 0xA1, 2,,, A
    }
}

SetZone1:
    ActiveBox := "B1"
    w := Abs(B1_X2 - B1_X1)
    h := Abs(B1_Y2 - B1_Y1)
    CurX := (w > 0 && B1_X2 != 0) ? Min(B1_X1, B1_X2) : 400
    CurY := (h > 0 && B1_Y2 != 0) ? Min(B1_Y1, B1_Y2) : 300
    CurW := (w > 0) ? w : 100
    CurH := (h > 0) ? h : 30
    ShowSetupBox("Zone 1 Setup (Bubble Box)", 1)
return

SetZone2:
    ActiveBox := "B2"
    w := Abs(B2_X2 - B2_X1)
    h := Abs(B2_Y2 - B2_Y1)
    CurX := (w > 0 && B2_X2 != 0) ? Min(B2_X1, B2_X2) : 400
    CurY := (h > 0 && B2_Y2 != 0) ? Min(B2_Y1, B2_Y2) : 300
    CurW := (w > 0) ? w : 100
    CurH := (h > 0) ? h : 5
    ShowSetupBox("Zone 2 Setup (Scan Line Position)", 0)
return

SetZone3:
    ActiveBox := "B3"
    w := Abs(B3_X2 - B3_X1)
    h := Abs(B3_Y2 - B3_Y1)
    CurX := (w > 0 && B3_X2 != 0) ? Min(B3_X1, B3_X2) : 400
    CurY := (h > 0 && B3_Y2 != 0) ? Min(B3_Y1, B3_Y2) : 300
    CurW := (w > 0) ? w : 100
    CurH := (h > 0) ? h : 30
    ShowSetupBox("Zone 3 Setup (Restart Box)", 1)
return

ShowSetupBox(titleText, allowResize) {
    Gui, Main: +Disabled

    Gui, FrameBox: Destroy
    if (allowResize) {
        Gui, FrameBox: New, +Resize +AlwaysOnTop +ToolWindow +HwndFrameHwnd -Caption
    } else {
        Gui, FrameBox: New, +AlwaysOnTop +ToolWindow +HwndFrameHwnd -Caption
    }
    
    Gui, FrameBox: Color, Red
    Gui, FrameBox: Add, Text, x0 y0 w100p h100p BackgroundRed, 

    Gui, FrameBox: Show, x%CurX% y%CurY% w%CurW% h%CurH% NoActivate
    WinMove, ahk_id %FrameHwnd%,, %CurX%, %CurY%, %CurW%, %CurH%
    WinSet, Transparent, 220, ahk_id %FrameHwnd%

    ToolTip, % titleText . "`n- Arrow Keys: Nudge position`n- Drag: Move box`n- Press ENTER to save."
    
    Hotkey, Up, NudgeUp, On
    Hotkey, Down, NudgeDown, On
    Hotkey, Left, NudgeLeft, On
    Hotkey, Right, NudgeRight, On
    Hotkey, Enter, ConfirmBoxCoords, On
}

NudgeUp:
    WinGetPos, curWinX, curWinY, curWinW, curWinH, ahk_id %FrameHwnd%
    curWinY -= 1
    WinMove, ahk_id %FrameHwnd%,, %curWinX%, %curWinY%
return
NudgeDown:
    WinGetPos, curWinX, curWinY, curWinW, curWinH, ahk_id %FrameHwnd%
    curWinY += 1
    WinMove, ahk_id %FrameHwnd%,, %curWinX%, %curWinY%
return
NudgeLeft:
    WinGetPos, curWinX, curWinY, curWinW, curWinH, ahk_id %FrameHwnd%
    curWinX -= 1
    WinMove, ahk_id %FrameHwnd%,, %curWinX%, %curWinY%
return
NudgeRight:
    WinGetPos, curWinX, curWinY, curWinW, curWinH, ahk_id %FrameHwnd%
    curWinX += 1
    WinMove, ahk_id %FrameHwnd%,, %curWinX%, %curWinY%
return

ConfirmBoxCoords:
    Hotkey, Up, Off
    Hotkey, Down, Off
    Hotkey, Left, Off
    Hotkey, Right, Off
    Hotkey, Enter, Off
    ToolTip
    
    if (FrameHwnd) {
        WinGetPos, WX, WY, WW, WH, ahk_id %FrameHwnd%

        if (ActiveBox = "B1") {
            B1_X1 := WX, B1_Y1 := WY, B1_X2 := WX + WW, B1_Y2 := WY + WH
        } else if (ActiveBox = "B2") {
            B2_X1 := WX, B2_Y1 := WY, B2_X2 := WX + WW, B2_Y2 := WY + WH
        } else if (ActiveBox = "B3") {
            B3_X1 := WX, B3_Y1 := WY, B3_X2 := WX + WW, B3_Y2 := WY + WH
        }
    }
    
    Gui, FrameBox: Destroy
    Gui, Main: -Disabled
    Gui, Main: Show
    SaveAllSettings()
    GuiControl, Main:, Status, Status: %ActiveBox% Saved
return

; --- Click Position Pickers ---
PickPosition05:
    PickPositionCoord("05")
return

PickPosition1:
    PickPositionCoord("1")
return

PickPosition2:
    PickPositionCoord("2")
return

PickPositionCoord(posType) {
    global GuiMainDisabled, Pos05_X, Pos05_Y, Pos1_X, Pos1_Y, Pos2_X, Pos2_Y
    GuiMainDisabled := 1
    Gui, Main: +Disabled
    ToolTip, Click on the screen to set Position %posType%

    CoordMode, Mouse, Screen
    While (GuiMainDisabled) {
        MouseGetPos, curMX, curMY
        ToolTip, 📍 Click to Set Position %posType% (%curMX%`, %curMY%), % (curMX + 15), % (curMY + 15), 1
        if (GetKeyState("LButton", "P")) {
            if (posType = "05") {
                Pos05_X := curMX, Pos05_Y := curMY
                GuiControl, Main:, BtnPos05, 📍 Pos 0.5: (%Pos05_X%`, %Pos05_Y%)
            } else if (posType = "1") {
                Pos1_X := curMX, Pos1_Y := curMY
                GuiControl, Main:, BtnPos1, 📍 Pos 1: (%Pos1_X%`, %Pos1_Y%)
            } else if (posType = "2") {
                Pos2_X := curMX, Pos2_Y := curMY
                GuiControl, Main:, BtnPos2, 📍 Pos 2: (%Pos2_X%`, %Pos2_Y%)
            }
            KeyWait, LButton
            GuiMainDisabled := 0
            break
        }
        Sleep, 30
    }
    ToolTip, , , , 1
    SaveAllSettings()
    Gui, Main: -Disabled
    Gui, Main: Show
}

; --- Timing UI Management ---
OnTimingTargetChange:
    Gui, Main: Submit, NoHide
    if (SelectedPosTiming = "Pos 0.5") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos05%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos05%
    } else if (SelectedPosTiming = "Pos 1") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos1%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos1%
    } else if (SelectedPosTiming = "Pos 2") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos2%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos2%
    }
return

SaveActiveTiming:
    Gui, Main: Submit, NoHide
    if (SelectedPosTiming = "Pos 0.5") {
        Glide_Pos05 := GlideTimeInput
        Hover_Pos05 := HoverTimeInput
    } else if (SelectedPosTiming = "Pos 1") {
        Glide_Pos1 := GlideTimeInput
        Hover_Pos1 := HoverTimeInput
    } else if (SelectedPosTiming = "Pos 2") {
        Glide_Pos2 := GlideTimeInput
        Hover_Pos2 := HoverTimeInput
    }
    SaveAllSettings()
return

; --- Color Pickers ---
PickCyanColor:
    SampleScreenColor("Cyan")
return

PickClickColor:
    SampleScreenColor("Click")
return

PickRestartColor:
    SampleScreenColor("Restart")
return

SampleScreenColor(targetType) {
    global CyanColor, ClickColor, RestartColor, ExtraColor, IniFile
    
    Gui, Main: +Disabled
    ToolTip, Click anywhere on screen to pick color...
    
    While (!GetKeyState("LButton", "P")) {
        MouseGetPos, mX, mY
        ToolTip, █ Click to sample color, % (mX + 15), % (mY + 15), 1
        Sleep, 30
    }
    KeyWait, LButton
    
    CoordMode, Pixel, Screen
    MouseGetPos, cX, cY
    PixelGetColor, sampledRGB, %cX%, %cY%, RGB
    ToolTip, , , , 1
    
    formattedColor := FormatHexColor(sampledRGB)
    
    if (targetType = "Cyan") {
        CyanColor := formattedColor
        UpdateVisualSwatch("CyanVisual", CyanColor)
        IniWrite, %CyanColor%, %IniFile%, Settings, CyanColor
    } else if (targetType = "Click") {
        ClickColor := formattedColor
        UpdateVisualSwatch("ClickVisual", ClickColor)
        IniWrite, %ClickColor%, %IniFile%, Settings, ClickColor
    } else if (targetType = "Restart") {
        RestartColor := formattedColor
        UpdateVisualSwatch("RestartVisual", RestartColor)
        IniWrite, %RestartColor%, %IniFile%, Settings, RestartColor
    } else if (targetType = "Extra") {
        ExtraColor := formattedColor
        UpdateVisualSwatch("ExtraVisual", ExtraColor)
        IniWrite, %ExtraColor%, %IniFile%, Settings, ExtraColor
    }
    
    Gui, Main: -Disabled
    Gui, Main: Show
}

ToggleCyanColor:
    Gui, Main: Submit, NoHide
    SaveAllSettings()
return

ToggleExtraColor:
    Gui, Main: Submit, NoHide
    SaveAllSettings()
return

UpdateKeySelection:
    Gui, Main: Submit, NoHide
    if (RadioKeyF)
        SellKeyChoice := "f"
    else if (RadioKeyE)
        SellKeyChoice := "e"
    else if (RadioKeyCustom)
        SellKeyChoice := "custom"
    SaveAllSettings()
return

; --- Settings Management ---
LoadAllSettings() {
    global
    IniRead, SavedNeedle, %IniFile%, Settings, NeedleCooldownInput, 150
    IniRead, SavedRate, %IniFile%, Settings, ScanRateInput, 30
    IniRead, SavedRestartDelay, %IniFile%, Settings, RestartDelayInput, 1000
    IniRead, SavedHotkey, %IniFile%, Settings, CurrentHotkey, q
    
    IniRead, rawCyan, %IniFile%, Settings, CyanColor, % ""
    IniRead, EnableCyanColor, %IniFile%, Settings, EnableCyanColor, 1
    IniRead, rawClick, %IniFile%, Settings, ClickColor, % ""
    IniRead, rawRestart, %IniFile%, Settings, RestartColor, % ""
    IniRead, rawExtra, %IniFile%, Settings, ExtraColor, 0x806DBF
    IniRead, EnableExtraColor, %IniFile%, Settings, EnableExtraColor, 0
    IniRead, BubbleTolerance, %IniFile%, Settings, BubbleTolerance, 15

    CyanColor := FormatHexColor(rawCyan)
    ClickColor := FormatHexColor(rawClick)
    RestartColor := FormatHexColor(rawRestart)
    ExtraColor := FormatHexColor(rawExtra)
    if (ExtraColor = "")
        ExtraColor := "0x806DBF"

    UpdateVisualSwatch("ExtraVisual", ExtraColor)

    IniRead, EnableAutoSell, %IniFile%, AutoSell, EnableAutoSell, 0
    IniRead, AutoSellIntervalMin, %IniFile%, AutoSell, AutoSellIntervalMin, 5
    
    IniRead, SellKeyChoice, %IniFile%, AutoSellAction, SellKeyChoice, f
    IniRead, CustomSellKey, %IniFile%, AutoSellAction, CustomSellKey, e
    IniRead, EnablePos05, %IniFile%, AutoSellAction, EnablePos05, 1
    IniRead, Pos05_X, %IniFile%, AutoSellAction, Pos05_X, 0
    IniRead, Pos05_Y, %IniFile%, AutoSellAction, Pos05_Y, 0
    IniRead, Pos1_X, %IniFile%, AutoSellAction, Pos1_X, 0
    IniRead, Pos1_Y, %IniFile%, AutoSellAction, Pos1_Y, 0
    IniRead, Pos2_X, %IniFile%, AutoSellAction, Pos2_X, 0
    IniRead, Pos2_Y, %IniFile%, AutoSellAction, Pos2_Y, 0
    
    IniRead, Glide_Pos05, %IniFile%, AutoSellTimings, Glide_Pos05, 300
    IniRead, Hover_Pos05, %IniFile%, AutoSellTimings, Hover_Pos05, 200
    IniRead, Glide_Pos1,  %IniFile%, AutoSellTimings, Glide_Pos1,  300
    IniRead, Hover_Pos1,  %IniFile%, AutoSellTimings, Hover_Pos1,  200
    IniRead, Glide_Pos2,  %IniFile%, AutoSellTimings, Glide_Pos2,  300
    IniRead, Hover_Pos2,  %IniFile%, AutoSellTimings, Hover_Pos2,  200

    IniRead, ReturnDelayMs, %IniFile%, AutoSellTimings, ReturnDelayMs, 500
    IniRead, ReturnGlideMs, %IniFile%, AutoSellTimings, ReturnGlideMs, 300

    IniRead, InactivityTimeoutSec, %IniFile%, FailSafe, InactivityTimeoutSec, 10

    IniRead, B1_X1, %IniFile%, Zones, B1_X1, 0
    IniRead, B1_Y1, %IniFile%, Zones, B1_Y1, 0
    IniRead, B1_X2, %IniFile%, Zones, B1_X2, 0
    IniRead, B1_Y2, %IniFile%, Zones, B1_Y2, 0
    
    IniRead, B2_X1, %IniFile%, Zones, B2_X1, 0
    IniRead, B2_Y1, %IniFile%, Zones, B2_Y1, 0
    IniRead, B2_X2, %IniFile%, Zones, B2_X2, 0
    IniRead, B2_Y2, %IniFile%, Zones, B2_Y2, 0

    IniRead, B3_X1, %IniFile%, Zones, B3_X1, 0
    IniRead, B3_Y1, %IniFile%, Zones, B3_Y1, 0
    IniRead, B3_X2, %IniFile%, Zones, B3_X2, 0
    IniRead, B3_Y2, %IniFile%, Zones, B3_Y2, 0

    CurrentHotkey := SavedHotkey
    GuiControl, Main:, HotkeyInput, %CurrentHotkey%
    GuiControl, Main:, EnableCyanColor, %EnableCyanColor%
    GuiControl, Main:, EnableExtraColor, %EnableExtraColor%
    GuiControl, Main:, BubbleToleranceInput, %BubbleTolerance%
    GuiControl, Main:, NeedleCooldownInput, %SavedNeedle%
    GuiControl, Main:, ScanRateInput, %SavedRate%
    GuiControl, Main:, RestartDelayInput, %SavedRestartDelay%

    GuiControl, Main:, EnableAutoSell, %EnableAutoSell%
    GuiControl, Main:, AutoSellIntervalMinInput, %AutoSellIntervalMin%

    GuiControl, Main:, CustomSellKey, %CustomSellKey%
    GuiControl, Main:, EnablePos05, %EnablePos05%
    GuiControl, Main:, InactivityTimeoutSecInput, %InactivityTimeoutSec%

    GuiControl, Main:, GlideTimeInput, %Glide_Pos05%
    GuiControl, Main:, HoverTimeInput, %Hover_Pos05%

    GuiControl, Main:, ReturnDelayMsInput, %ReturnDelayMs%
    GuiControl, Main:, ReturnGlideMsInput, %ReturnGlideMs%

    if (Pos05_X > 0 && Pos05_Y > 0)
        GuiControl, Main:, BtnPos05, 📍 Pos 0.5: (%Pos05_X%`, %Pos05_Y%)
    if (Pos1_X > 0 && Pos1_Y > 0)
        GuiControl, Main:, BtnPos1, 📍 Pos 1: (%Pos1_X%`, %Pos1_Y%)
    if (Pos2_X > 0 && Pos2_Y > 0)
        GuiControl, Main:, BtnPos2, 📍 Pos 2: (%Pos2_X%`, %Pos2_Y%)

    if (SellKeyChoice = "e") {
        GuiControl, Main:, RadioKeyE, 1
        GuiControl, Main:, RadioKeyF, 0
        GuiControl, Main:, RadioKeyCustom, 0
    } else if (SellKeyChoice = "custom") {
        GuiControl, Main:, RadioKeyCustom, 1
        GuiControl, Main:, RadioKeyF, 0
        GuiControl, Main:, RadioKeyCustom, 0
    } else {
        GuiControl, Main:, RadioKeyF, 1
        GuiControl, Main:, RadioKeyE, 0
        GuiControl, Main:, RadioKeyCustom, 0
    }
    
    UpdateVisualSwatch("CyanVisual", CyanColor)
    UpdateVisualSwatch("ClickVisual", ClickColor)
    UpdateVisualSwatch("RestartVisual", RestartColor)
}

SaveAllSettings() {
    global
    Gui, Main: Submit, NoHide
    IniWrite, %NeedleCooldownInput%, %IniFile%, Settings, NeedleCooldownInput
    IniWrite, %ScanRateInput%, %IniFile%, Settings, ScanRateInput
    IniWrite, %RestartDelayInput%, %IniFile%, Settings, RestartDelayInput
    IniWrite, %CurrentHotkey%, %IniFile%, Settings, CurrentHotkey
    IniWrite, %CyanColor%, %IniFile%, Settings, CyanColor
    IniWrite, %EnableCyanColor%, %IniFile%, Settings, EnableCyanColor
    IniWrite, %ExtraColor%, %IniFile%, Settings, ExtraColor
    IniWrite, %EnableExtraColor%, %IniFile%, Settings, EnableExtraColor
    
    BubbleTolerance := BubbleToleranceInput
    IniWrite, %BubbleTolerance%, %IniFile%, Settings, BubbleTolerance
    
    IniWrite, %ClickColor%, %IniFile%, Settings, ClickColor
    IniWrite, %RestartColor%, %IniFile%, Settings, RestartColor

    IniWrite, %EnableAutoSell%, %IniFile%, AutoSell, EnableAutoSell
    AutoSellIntervalMin := AutoSellIntervalMinInput
    IniWrite, %AutoSellIntervalMin%, %IniFile%, AutoSell, AutoSellIntervalMin

    IniWrite, %SellKeyChoice%, %IniFile%, AutoSellAction, SellKeyChoice
    IniWrite, %CustomSellKey%, %IniFile%, AutoSellAction, CustomSellKey
    IniWrite, %EnablePos05%, %IniFile%, AutoSellAction, EnablePos05
    IniWrite, %Pos05_X%, %IniFile%, AutoSellAction, Pos05_X
    IniWrite, %Pos05_Y%, %IniFile%, AutoSellAction, Pos05_Y
    IniWrite, %Pos1_X%, %IniFile%, AutoSellAction, Pos1_X
    IniWrite, %Pos1_Y%, %IniFile%, AutoSellAction, Pos1_Y
    IniWrite, %Pos2_X%, %IniFile%, AutoSellAction, Pos2_X
    IniWrite, %Pos2_Y%, %IniFile%, AutoSellAction, Pos2_Y
    
    IniWrite, %Glide_Pos05%, %IniFile%, AutoSellTimings, Glide_Pos05
    IniWrite, %Hover_Pos05%, %IniFile%, AutoSellTimings, Hover_Pos05
    IniWrite, %Glide_Pos1%,  %IniFile%, AutoSellTimings, Glide_Pos1
    IniWrite, %Hover_Pos1%,  %IniFile%, AutoSellTimings, Hover_Pos1
    IniWrite, %Glide_Pos2%,  %IniFile%, AutoSellTimings, Glide_Pos2
    IniWrite, %Hover_Pos2%,  %IniFile%, AutoSellTimings, Hover_Pos2

    ReturnDelayMs := ReturnDelayMsInput
    ReturnGlideMs := ReturnGlideMsInput
    IniWrite, %ReturnDelayMs%, %IniFile%, AutoSellTimings, ReturnDelayMs
    IniWrite, %ReturnGlideMs%, %IniFile%, AutoSellTimings, ReturnGlideMs

    InactivityTimeoutSec := InactivityTimeoutSecInput
    IniWrite, %InactivityTimeoutSec%, %IniFile%, FailSafe, InactivityTimeoutSec
    
    IniWrite, %B1_X1%, %IniFile%, Zones, B1_X1
    IniWrite, %B1_Y1%, %IniFile%, Zones, B1_Y1
    IniWrite, %B1_X2%, %IniFile%, Zones, B1_X2
    IniWrite, %B1_Y2%, %IniFile%, Zones, B1_Y2
    
    IniWrite, %B2_X1%, %IniFile%, Zones, B2_X1
    IniWrite, %B2_Y1%, %IniFile%, Zones, B2_Y1
    IniWrite, %B2_X2%, %IniFile%, Zones, B2_X2
    IniWrite, %B2_Y2%, %IniFile%, Zones, B2_Y2

    IniWrite, %B3_X1%, %IniFile%, Zones, B3_X1
    IniWrite, %B3_Y1%, %IniFile%, Zones, B3_Y1
    IniWrite, %B3_X2%, %IniFile%, Zones, B3_X2
    IniWrite, %B3_Y2%, %IniFile%, Zones, B3_Y2
}

UpdateHotkey:
    Gui, Main: Submit, NoHide
    if (HotkeyInput = "")
        return
    if (CurrentHotkey != "")
        Hotkey, %CurrentHotkey%, Off, UseErrorLevel
        
    CurrentHotkey := HotkeyInput
    Hotkey, %CurrentHotkey%, ToggleMacro, On, UseErrorLevel
    SaveAllSettings()
return

; --- Timer Countdown Display Updater ---
UpdateAutoSellTimerUI:
    if (!MacroRunning || !EnableAutoSell) {
        GuiControl, Main:, TimerStatus, Next Sell In: Inactive
        return
    }
    
    intervalMs := AutoSellIntervalMin * 60000
    elapsed := A_TickCount - LastSellTick
    remainingSec := Max(0, Floor((intervalMs - elapsed) / 1000))
    
    remM := Floor(remainingSec / 60)
    remS := Mod(remainingSec, 60)
    
    padS := (remS < 10) ? "0" . remS : remS
    GuiControl, Main:, TimerStatus, Next Sell In: %remM%m %padS%s
return

ExecuteAutoSellSequence() {
    global SellKeyChoice, CustomSellKey, EnablePos05, Pos05_X, Pos05_Y, Pos1_X, Pos1_Y, Pos2_X, Pos2_Y
    global Glide_Pos05, Hover_Pos05, Glide_Pos1, Hover_Pos1, Glide_Pos2, Hover_Pos2
    global ReturnDelayMs, ReturnGlideMs, SavedMouseX, SavedMouseY
    CoordMode, Mouse, Screen

    keyToPress := (SellKeyChoice = "f") ? "f" : (SellKeyChoice = "e") ? "e" : CustomSellKey

    ; Step 1: Trigger Key
    if (keyToPress != "") {
        Send, {%keyToPress% down}
        Sleep, 50
        Send, {%keyToPress% up}
        Sleep, 200
    }

    ; Step 2: Pos 0.5 (Controlled via EnablePos05 CheckBox)
    if (EnablePos05 && Pos05_X > 0 && Pos05_Y > 0) {
        GlideMouseMove(Pos05_X, Pos05_Y, Glide_Pos05)
        Sleep, %Hover_Pos05%
        Click, %Pos05_X%, %Pos05_Y%
        Sleep, 200
    }

    ; Step 3: Pos 1
    if (Pos1_X > 0 && Pos1_Y > 0) {
        GlideMouseMove(Pos1_X, Pos1_Y, Glide_Pos1)
        Sleep, %Hover_Pos1%
        Click, %Pos1_X%, %Pos1_Y%
        Sleep, 200
    }

    ; Step 4: Pos 2
    if (Pos2_X > 0 && Pos2_Y > 0) {
        GlideMouseMove(Pos2_X, Pos2_Y, Glide_Pos2)
        Sleep, %Hover_Pos2%
        Click, %Pos2_X%, %Pos2_Y%
        Sleep, 200
    }

    ; Step 5: Wait until time has passed, glide back to fishing spot, then click
    if (ReturnDelayMs > 0)
        Sleep, %ReturnDelayMs%

    GlideMouseMove(SavedMouseX, SavedMouseY, ReturnGlideMs)
    SendSavedClick()
    Sleep, 200
}

ToggleMacro:
    if (MacroRunning) {
        MacroRunning := 0
        SetTimer, BackgroundInactivityWatchdog, Off
        SetTimer, UpdateAutoSellTimerUI, Off
        GuiControl, Main:, TimerStatus, Next Sell In: Inactive
        GuiControl, Main:, StartBtn, ▶️ Start
        GuiControl, Main:, Status, Status: Stopped
        return
    }
    
    Gui, Main: Submit, NoHide
    CoordMode, Mouse, Screen
    
    MouseGetPos, SavedMouseX, SavedMouseY
    
    MacroRunning := 1
    LastClickTick := A_TickCount
    LastSellTick := A_TickCount
    
    SetTimer, BackgroundInactivityWatchdog, 250
    SetTimer, UpdateAutoSellTimerUI, 1000
    
    GuiControl, Main:, StartBtn, ⏹️ Stop
    SetTimer, MainWorkflow, -10
return

; --- MAIN WORKFLOW LOOP ---
MainWorkflow:
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ScanX1 := Min(B1_X1, B1_X2)
    ScanY1 := Min(B1_Y1, B1_Y2)
    ScanX2 := Max(B1_X1, B1_X2)
    ScanY2 := Max(B1_Y1, B1_Y2)

    While (MacroRunning) {
        ; STEP 0: Check AutoSell Timer Before Every Single Cast
        if (EnableAutoSell && AutoSellIntervalMin > 0) {
            sellIntervalMs := AutoSellIntervalMin * 60000
            if (A_TickCount - LastSellTick >= sellIntervalMs) {
                GuiControl, Main:, Status, Status: Timer Expired - Selling...
                ExecuteAutoSellSequence()
                LastSellTick := A_TickCount
                Sleep, 300
            }
        }

        ; STEP 1: Initial Cast Click
        GuiControl, Main:, Status, Status: Step 1 - Initial Click...
        SendSavedClick()
        Sleep, 300

        ; STEP 2: Strict Scan in Zone 1 (Cyan Bubble + Single Active Extra Bubble Color)
        GuiControl, Main:, Status, Status: Step 2 - Scanning Bubble...
        Loop {
            if (!MacroRunning)
                break 2

            BubbleFound := 0

            if (EnableCyanColor && CyanColor != "") {
                PixelSearch, FX, FY, %ScanX1%, %ScanY1%, %ScanX2%, %ScanY2%, %CyanColor%, %BubbleTolerance%, Fast RGB
                if (ErrorLevel = 0)
                    BubbleFound := 1
            }

            if (!BubbleFound && EnableExtraColor && ExtraColor != "") {
                PixelSearch, EFX, EFY, %ScanX1%, %ScanY1%, %ScanX2%, %ScanY2%, %ExtraColor%, %BubbleTolerance%, Fast RGB
                if (ErrorLevel = 0)
                    BubbleFound := 1
            }

            if (BubbleFound) {
                SendSavedClick()
                break
            }

            Sleep, %ScanRateInput%
        }

        ; STEP 3: Wait for Restart Color with a 2-second timeout (Tolerance set to 5)
        GuiControl, Main:, Status, Status: Step 3 - Waiting for Minigame...
        WaitStart := A_TickCount

        Loop {
            if (!MacroRunning)
                break 2

            PixelSearch, UIX, UIY, %B3_X1%, %B3_Y1%, %B3_X2%, %B3_Y2%, %RestartColor%, 5, Fast RGB
            if (ErrorLevel = 0)
                break

            if (A_TickCount - WaitStart >= 2000) {
                GuiControl, Main:, Status, Status: UI Timeout - Resetting...
                Sleep, %RestartDelayInput%
                continue 2
            }

            Sleep, 20
        }

        ; STEP 4: Minigame Active Loop (Tolerance set to 5)
        GuiControl, Main:, Status, Status: Step 4 - Minigame Active...
        While (MacroRunning) {
            PixelSearch, UIX, UIY, %B3_X1%, %B3_Y1%, %B3_X2%, %B3_Y2%, %RestartColor%, 5, Fast RGB
            if (ErrorLevel != 0) {
                GuiControl, Main:, Status, Status: Minigame Ended - Waiting Delay...
                Sleep, %RestartDelayInput%
                break
            }

            PixelSearch, WX, WY, %B2_X1%, %B2_Y1%, %B2_X2%, %B2_Y2%, %ClickColor%, 5, Fast RGB
            if (ErrorLevel = 0) {
                SendSavedClick()
                Sleep, %NeedleCooldownInput%
            }

            Sleep, %ScanRateInput%
        }
    }

    GuiControl, Main:, StartBtn, ▶️ Start
    GuiControl, Main:, Status, Status: Stopped
return

FrameBoxGuiClose:
return

MainGuiClose:
F2::ExitApp
