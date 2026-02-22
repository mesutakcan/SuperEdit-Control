/*
SuperEdit Examples Script
Demonstrates all modes and features of the SuperEdit class.
For detailed information, see the readme.md file.
===========================================================
Mesut Akcan

github.com/akcansoft
youtube.com/mesutakcan
===========================================================
22/02/2026
*/

#Requires AutoHotkey v2.0
#Include SuperEdit.ahk

global SuperEditList := []
global displayBox, infoTxt

mGui := Gui(, "SuperEdit - Feature Examples")
mGui.SetFont("s10", "Segoe UI")

; Helper to register pairs for ShowValues/ClearAll
AddExample(txtObj, editObj) {
	SuperEditList.Push({ txt: txtObj, edt: editObj })
	return editObj
}

; -------------------------------------------------------
; INPUT MODES
; -------------------------------------------------------

; --- 1: Standard ---
e1 := AddExample(mGui.Add("Text", "x10 y10 w150", "1. Standard (All):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Any character allowed..."))

; --- 2: Numeric ---
e2 := AddExample(mGui.Add("Text", "x10 y+15 w150", "2. Numeric only:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Only numbers and one dot..."))
e2.ModeNumeric()

; --- 3: Alpha - All Unicode ---
e3 := AddExample(mGui.Add("Text", "x10 y+15 w150", "3. Alpha (Unicode):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Any Unicode letter..."))
e3.ModeAlpha()

; --- 4: Alpha - Turkish (ExcludeChars: Q, W, X) ---
e4 := AddExample(mGui.Add("Text", "x10 y+15 w150", "4. Alpha (Turkish):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Turkish letters...", , "tr-TR"))
e4.ExcludeChars := "QWXqwx"
e4.ModeAlpha()
e4.SetFocusColors("ff0000", "ffffff")

; --- 5: Alpha - English ---
e5 := AddExample(mGui.Add("Text", "x10 y+15 w150", "5. Alpha (English):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "English letters...", , "en-US"))
e5.ModeAlpha()

; --- 6: Alpha - French ---
e6 := AddExample(mGui.Add("Text", "x10 y+15 w150", "6. Alpha (French):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "French letters..."))
e6.ModeAlpha("fr-FR")

; --- 7: Auto Uppercase, Turkish locale (i->I with dot, correct mapping) ---
e7 := AddExample(mGui.Add("Text", "x10 y+15 w150", "7. Uppercase:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Auto uppercase, i becomes dotted I..."))
e7.ModeUpper()

; --- 8: Auto Lowercase ---
e8 := AddExample(mGui.Add("Text", "x10 y+15 w150", "8. Lowercase:"),
	SuperEdit(mGui, "x+5 yp-2 w250 BackgroundFFB889", "auto lowercase..."))
e8.ModeLower()

; --- 9: Sentence Case ---
e9 := AddExample(mGui.Add("Text", "x10 y+15 w150", "9. Sentence Case:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "First letter of each sentence..."))
e9.ModeSentence()

; --- 10: Title Case + OnChange event ---
e10 := AddExample(mGui.Add("Text", "x10 y+15 w150", "10. Title Case:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Every Word Starts Upper...", , "en-US"))
e10.ModeTitle()
e10.OnEvent("Change", (ctrl, *) => infoTxt.Text := "Live (e10): " . e10.Value)

; -------------------------------------------------------
; PROPERTIES
; -------------------------------------------------------

; --- 11: MaxLength ---
e11 := AddExample(mGui.Add("Text", "x10 y+15 w150", "11. MaxLength (4):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Max 4 digits..."))
e11.ModeNumeric()
e11.MaxLength := 4

; --- 12: ReadOnly via property (system bg color auto-applied) ---
e12 := AddExample(mGui.Add("Text", "x10 y+15 w150", "12. ReadOnly:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "", "This content is read-only"))
e12.ReadOnly := true

; --- 13: ReadOnly via opts string ---
e13 := AddExample(mGui.Add("Text", "x10 y+15 w150", "13. ReadOnly (opts):"),
	SuperEdit(mGui, "x+5 yp-2 w250 ReadOnly", "", "ReadOnly set in opts string"))

; --- 14: Custom Focus Colors ---
e14 := AddExample(mGui.Add("Text", "x10 y+15 w150", "14. Focus Colors:"),
	SuperEdit(mGui, "x+5 yp-2 w250 cBlue", "Custom focus color..."))
e14.SetFocusColors("D698FA", "660099")

; --- 15: Focus Colors Disabled + SetNormalColors ---
e15 := AddExample(mGui.Add("Text", "x10 y+15 w150", "15. No Focus Color:"),
	SuperEdit(mGui, "x+5 yp-2 w250"))
e15.SetNormalColors("E8F4FD", "003366")
e15.EnableFocusColors(false)
e15.SetPlaceholder("Focus color disabled, custom normal color...")

; --- 16: EnterToTab disabled + Password ---
e16 := AddExample(mGui.Add("Text", "x10 y+15 w150", "16. Password:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Enter stays here (EnterToTab=false)..."))
e16.Opt("+Password")
e16.EnterToTab := false

; --- 17: InitialText + SetNormalColors + SetFocusColors ---
e17 := AddExample(mGui.Add("Text", "x10 y+15 w150", "17. Initial + Colors:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Edit me...", "Hello, SuperEdit!"))
e17.SetNormalColors("D4EDDA", "155724")
e17.SetFocusColors("155724", "FFFFFF")

; -------------------------------------------------------
; INFO & BUTTONS
; -------------------------------------------------------
infoTxt := mGui.Add("Text", "x10 y+20 w410 c006400",
	"Tip: Enter acts like Tab (except ex.16). Right-click to paste and test modes!")

mGui.Add("Button", "x10 y+12", "Show Values").OnEvent("Click", ShowValues)
mGui.Add("Button", "x+8", "Clear All").OnEvent("Click", ClearAll)
mGui.Add("Button", "x+8", "SelectAll #1").OnEvent("Click",
	(*) => (e1.Focus(), SetTimer(() => e1.SelectAll(), -1)))
mGui.Add("Button", "x+8", "ToUpper #9").OnEvent("Click", (*) => e9.ToUpper())
mGui.Add("Button", "x+8", "ToLower #9").OnEvent("Click", (*) => e9.ToLower())

; --- Right panel: values display ---
mGui.Add("GroupBox", "x460 y5 w310 h680", "Current Values")
displayBox := mGui.Add("Edit",
	"x470 y25 w290 h650 ReadOnly -E0x200 BackgroundF8F9FA",
	"Click [Show Values]...")

mGui.Show("w790")

; -------------------------------------------------------
; HANDLERS
; -------------------------------------------------------
ShowValues(*) {
	out := ""
	for item in SuperEditList {
		out .= item.txt.Text " : " item.edt.Value "`n"
	}
	displayBox.Value := out
}

ClearAll(*) {
	for item in SuperEditList {
		item.edt.Clear()
	}
}