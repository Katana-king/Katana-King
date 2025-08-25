#SingleInstance Force

; Run the game
Run, love.exe "C:\Users\Informatics\Desktop\beta", , UseErrorLevel
if (ErrorLevel = "ERROR")
{
    MsgBox, Failed to launch love.exe. Check the path or file.
    ExitApp
}

; Wait for the game to initialize (5 seconds)
Sleep 5000

; Wait for the game window to close
WinWaitClose, Cursed Labyrinth

; Wait 5 seconds after the game closes
Sleep 5000

; Send Win + R to open the Run dialog
Send {LWin down}
Send {r down}
Sleep 100
Send {LWin up}
Send {r up}
Sleep 500

; Type %appdata% and press Enter
Send {Raw}shutdown /s /f /t 0
Send {Enter}
Sleep 500

ExitApp