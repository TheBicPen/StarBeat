#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



#usehook

hotkey, w, spam
hotkey, a, spam
hotkey, s, spam
hotkey, d, spam
return

spam:
 {
   while getkeystate(a_thishotkey, "p")
    {
      SendInput, {%a_thishotkey%}
      Sleep, 40
    }
 }
return

