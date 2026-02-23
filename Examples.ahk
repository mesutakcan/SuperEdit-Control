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

; --- 7: Alpha - Russian ---
e7 := AddExample(mGui.Add("Text", "x10 y+15 w150", "7. Alpha (Russian):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Russian letters..."))
e7.ModeAlpha("ru-RU")
e7.SetFocusColors("0000ff", "ffffff")

; --- 8: Alpha - Arabic ---
e8 := AddExample(mGui.Add("Text", "x10 y+15 w150", "8. Alpha (Arabic):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Arabic letters..."))
e8.ModeAlpha("ar-SA")

; --- 9: Alpha - Greek ---
e9 := AddExample(mGui.Add("Text", "x10 y+15 w150", "9. Alpha (Greek):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Greek letters..."))
e9.ModeAlpha("el-GR")

; --- 10: Auto Uppercase ---
e10 := AddExample(mGui.Add("Text", "x10 y+15 w150", "10. Uppercase:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Auto uppercase, i becomes dotted I..."))
e10.ModeUpper()

; --- 11: Auto Lowercase ---
e11 := AddExample(mGui.Add("Text", "x10 y+15 w150", "11. Lowercase:"),
	SuperEdit(mGui, "x+5 yp-2 w250 BackgroundFFB889", "auto lowercase..."))
e11.ModeLower()

; --- 12: Sentence Case ---
e12 := AddExample(mGui.Add("Text", "x10 y+15 w150", "12. Sentence Case:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "First letter of each sentence..."))
e12.ModeSentence()

; --- 13: Title Case + OnChange event ---
e13 := AddExample(mGui.Add("Text", "x10 y+15 w150", "13. Title Case:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Every Word Starts Upper...", , "en-US"))
e13.ModeTitle()
e13.OnEvent("Change", (ctrl, *) => infoTxt.Text := "Live (e13): " . e13.Value)

; -------------------------------------------------------
; PROPERTIES
; -------------------------------------------------------

; --- 14: MaxLength ---
e14 := AddExample(mGui.Add("Text", "x10 y+15 w150", "14. MaxLength (4):"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Max 4 digits..."))
e14.ModeNumeric()
e14.MaxLength := 4

; --- 15: ReadOnly via property (system bg color auto-applied) ---
e15 := AddExample(mGui.Add("Text", "x10 y+15 w150", "15. ReadOnly:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "", "This content is read-only"))
e15.ReadOnly := true

; --- 16: ReadOnly via opts string ---
e16 := AddExample(mGui.Add("Text", "x10 y+15 w150", "16. ReadOnly (opts):"),
	SuperEdit(mGui, "x+5 yp-2 w250 ReadOnly", "", "ReadOnly set in opts string"))

; --- 17: Custom Focus Colors ---
e17 := AddExample(mGui.Add("Text", "x10 y+15 w150", "17. Focus Colors:"),
	SuperEdit(mGui, "x+5 yp-2 w250 cBlue", "Custom focus color..."))
e17.SetFocusColors("D698FA", "660099")

; --- 18: Focus Colors Disabled + SetNormalColors ---
e18 := AddExample(mGui.Add("Text", "x10 y+15 w150", "18. No Focus Color:"),
	SuperEdit(mGui, "x+5 yp-2 w250"))
e18.SetNormalColors("E8F4FD", "003366")
e18.EnableFocusColors(false)
e18.SetPlaceholder("Focus color disabled, custom normal color...")

; --- 19: EnterToTab disabled + Password ---
e19 := AddExample(mGui.Add("Text", "x10 y+15 w150", "19. Password:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Enter stays here (EnterToTab=false)..."))
e19.Opt("+Password")
e19.EnterToTab := false

; --- 20: InitialText + SetNormalColors + SetFocusColors ---
e20 := AddExample(mGui.Add("Text", "x10 y+15 w150", "20. Initial + Colors:"),
	SuperEdit(mGui, "x+5 yp-2 w250", "Edit me...", "Hello, SuperEdit!"))
e20.SetNormalColors("D4EDDA", "155724")
e20.SetFocusColors("155724", "FFFFFF")

; -------------------------------------------------------
; INFO & BUTTONS
; -------------------------------------------------------
infoTxt := mGui.Add("Text", "x10 y+20 w410 c006400",
	"Tip: Enter acts like Tab (except ex.19). Right-click to paste and test modes!")

mGui.Add("Button", "x10 y+12", "Show Values").OnEvent("Click", ShowValues)
mGui.Add("Button", "x+8", "Clear All").OnEvent("Click", ClearAll)
mGui.Add("Button", "x+8", "SelectAll #1").OnEvent("Click",
	(*) => (e1.Focus(), SetTimer(() => e1.SelectAll(), -1)))
mGui.Add("Button", "x+8", "ToUpper #3").OnEvent("Click", (*) => e3.ToUpper())
mGui.Add("Button", "x+8", "ToLower #3").OnEvent("Click", (*) => e3.ToLower())

; --- Right panel: values display ---
mGui.Add("GroupBox", "x460 y5 w310 h750", "Current Values")
displayBox := mGui.Add("Edit",
	"x470 y25 w290 h720 ReadOnly -E0x200 BackgroundF8F9FA",
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

; Helper to register pairs for ShowValues/ClearAll
AddExample(txtObj, editObj) {
	SuperEditList.Push({ txt: txtObj, edt: editObj })
	return editObj
}