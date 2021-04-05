#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 0


$w::
  While GetKeyState("w","P")
  {
    Send, w
    Sleep, 50
  }
Return

$a::
  While GetKeyState("a","P")
  {
    Send, a
    Sleep, 50
  }
Return

$s::
  While GetKeyState("s","P")
  {
    Send, s
    Sleep, 50
  }
Return

$d::
  While GetKeyState("d","P")
  {
    Send, d
    Sleep, 50
  }
Return
