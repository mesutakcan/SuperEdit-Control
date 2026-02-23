/*
=============================================================
SuperEdit Class for AutoHotkey v2
=============================================================
Version: 1.0.1
Date: 23/02/2026
=============================================================
For detailed information, see the README.md file.
Github repo: https://github.com/akcansoft/Super-Edit-Control
=============================================================
Inspired by akcanSoft superText ActiveX Control
https://github.com/akcansoft/superText-ActiveX-Control
=============================================================
Mesut Akcan
github.com/akcansoft
youtube.com/mesutakcan
=============================================================
*/

#Requires AutoHotkey v2.0

class SuperEdit {
	static MODE_ALL := 0
	static MODE_NUMERIC := 1   ; digits 0-9 + single decimal point
	static MODE_ALPHA := 2   ; unicode letters only
	static MODE_UPPER := 3   ; auto uppercase (locale-aware)
	static MODE_LOWER := 4   ; auto lowercase (locale-aware)
	static MODE_SENTENCE := 5   ; sentence case
	static MODE_TITLE := 6   ; title case (first letter of each word)

	; LCMAP flags
	static LCMAP_LOWERCASE := 0x00000100
	static LCMAP_UPPERCASE := 0x00000200
	static LCMAP_LINGUISTIC_CASING := 0x01000000

	; Locale prefix (first 2 chars of BCP-47) -> allowed letter pattern for ModeAlpha.
	; ExcludeChars can further restrict within this set (e.g. Turkish QWX).
	; Unknown locales fall back to all Unicode letters.
	static _LocaleLetterPatterns := Map(
		"tr", "[abcçdefgğhıijklmnoöprsştuüvyzABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ]",
		"en", "[a-zA-Z]",
		"de", "[a-zA-ZäöüßÄÖÜ]",
		"fr", "[a-zA-ZàâæçéèêëîïôœùûüÿÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸ]",
		"es", "[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]",
		"pt", "[a-zA-ZáâãàçéêíóôõúÁÂÃÀÇÉÊÍÓÔÕÚ]",
		"it", "[a-zA-ZàèéìíîòóùúÀÈÉÌÍÎÒÓÙÚ]",
		"pl", "[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]",
		"ru", "[\p{Cyrillic}]",
		"ar", "[\p{Arabic}]",
		"el", "[\p{Greek}]"
	)

	; Constructor
	;   initialText : optional initial text for the control
	;   locale      : BCP-47 locale name, e.g. "tr-TR"; "" = auto-detect from keyboard
	__New(gui, opts := "", placeholder := "", initialText := "", locale := "") {

		this._mode := 0
		this._normalBg := "FFFFFF"  ; Default background color
		this._normalFg := "000000"  ; Default foreground color
		this._focusBg := "fffd76"   ; Default background color when focused
		this._focusFg := "b30000"   ; Default foreground color when focused
		this._useFocusColors := true  ; Use focus colors
		this._maxLen := 0             ; Maximum length of text
		this._readOnly := false       ; Read-only mode
		this._enterToTab := true      ; Enter key acts as Tab key
		this._inInternalEdit := false ; Internal edit mode
		this._userSetBg := false      ; true when caller explicitly chose a bg color
		this._excludeChars := ""      ; characters blocked in ModeAlpha (case-sensitive)
		; Empty locale means: auto-detect current input language.
		this._locale := locale

		fullOpts := opts ; Combine options
		optBg := this._ExtractOptionColor(fullOpts, "Background") ; Extract background color
		if (optBg != "") { ; If background color is extracted
			this._userSetBg := true ; Set background color
			this._normalBg := optBg ; Set background color
		}
		optFg := this._ExtractOptionColor(fullOpts, "c") ; Extract foreground color
		if (optFg != "") ; If foreground color is extracted
			this._normalFg := optFg ; Set foreground color

		; Detect ReadOnly inside opts string (e.g. "x10 y10 w200 ReadOnly")
		; so we know the control starts as read-only before .ReadOnly is set.
		if (this._HasOption(fullOpts, "ReadOnly")) ; If ReadOnly is detected
			this._readOnly := true ; Set ReadOnly

		this.ctrl := gui.Add("Edit", fullOpts) ; Add Edit control
		this.hwnd := this.ctrl.Hwnd ; Get HWND
		SuperEdit.Instances[this.hwnd] := this ; Add to instances

		if (placeholder != "") ; If placeholder is not empty
			SendMessage(0x1501, 1, StrPtr(placeholder), this.hwnd) ; Set placeholder

		if (initialText != "") ; If initialText is not empty
			this.ctrl.Value := initialText ; Set initialText

		; If ReadOnly was in opts and no custom background was set,
		; apply the standard Windows readonly background (COLOR_BTNFACE).
		if (this._readOnly && !this._userSetBg) { ; If ReadOnly is detected and no custom background is set
			roColor := this._GetSysColorHex(15)   ; COLOR_BTNFACE
			this._ApplyColors(roColor, this._normalFg) ; Apply colors
			; Do NOT update _normalBg — it stays "FFFFFF" so that if
			; ReadOnly is later removed, the normal white bg is restored.
		}

		this.ctrl.OnEvent("Focus", this._OnFocus.Bind(this)) ; Focus event
		this.ctrl.OnEvent("LoseFocus", this._OnLostFocus.Bind(this)) ; LoseFocus event
		this.ctrl.OnEvent("Change", this._OnCtrlChange.Bind(this)) ; Change event

		if !SuperEdit._Registered { ; If SuperEdit is not registered
			; WM_KEYDOWN and WM_CHAR via AHK OnMessage (reliable for these).
			OnMessage(0x0100, (wp, lp, m, h) => SuperEdit._HandleMessage(wp, lp, m, h)) ; WM_KEYDOWN
			OnMessage(0x0102, (wp, lp, m, h) => SuperEdit._HandleMessage(wp, lp, m, h)) ; WM_CHAR
			; WM_PASTE via OnMessage is NOT used here — it misses context-menu paste.
			; Each instance subclasses its own HWND instead (see below).
			SuperEdit._Registered := true
		}

		; Subclass this Edit control so we catch WM_PASTE (0x0302) at the
		; Windows level — the only way that is reliable for context-menu paste.
		; CallbackCreate keeps the function pointer alive as long as this object lives.
		; Capture `this` in a closure so the callback can reach the instance.
		; CallbackCreate needs a plain function; we wrap the static method.
		_inst := this
		this._subclassProc := CallbackCreate( ; Create callback
			(hwnd, msg, wp, lp, id, ref) => SuperEdit._SubclassProc(_inst, hwnd, msg, wp, lp, id, ref),
			"F",   ; "Fast" — no AHK thread switch
			6      ; HWND, UINT, WPARAM, LPARAM, UINT_PTR, DWORD_PTR
		)
		DllCall("SetWindowSubclass", ; Set window subclass
			"Ptr", this.hwnd, ; HWND
			"Ptr", this._subclassProc, ; Subclass procedure
			"UPtr", this.hwnd, ; Subclass ID
			"UPtr", 0) ; Reference data
	}

	static Instances := Map() ; Instances map
	static _Registered := false ; Registered flag

	; Windows subclass callback — intercepts messages at the HWND level.
	; Signature: (HWND, UINT uMsg, WPARAM, LPARAM, UINT_PTR uIdSubclass, DWORD_PTR dwRefData)
	; The first parameter (HWND hWnd) is bound to `_` (unused); `inst` is the SuperEdit instance.
	static _SubclassProc(inst, hwnd, msg, wParam, lParam, idSubclass, refData) {
		; WM_PASTE = 0x0302 — catches ALL paste sources including context menu
		if (msg = 0x0302) { ; WM_PASTE
			if (inst._mode != 0) ; If mode is not MODE_ALL
				return inst._DoPaste() ; Do paste
			; MODE_ALL: fall through to DefSubclassProc
		}

		; Forward everything else to the original Edit WndProc.
		return DllCall("DefSubclassProc", ; DefSubclassProc
			"Ptr", hwnd,
			"UInt", msg,
			"UPtr", wParam,
			"Ptr", lParam,
			"UPtr")
	}

	; Handle messages for each instance
	static _HandleMessage(wParam, lParam, msg, hwnd) {
		if SuperEdit.Instances.Has(hwnd) { ; If instance exists for HWND
			inst := SuperEdit.Instances[hwnd] ; Get instance for HWND
			if (msg = 0x0100) ; WM_KEYDOWN
				return inst._OnWMKeyDown(wParam, lParam, msg, hwnd)
			if (msg = 0x0102) ; WM_CHAR
				return inst._OnWMChar(wParam, lParam, msg, hwnd)
			if (msg = 0x0302) ; WM_PASTE
				return inst._OnWMPaste(wParam, lParam, msg, hwnd)
		}
	}

	; Forward unknown Edit properties/methods/events to wrapped control.
	__Get(name, params) { ; Get property
		if (!ObjHasOwnProp(this, "ctrl") || name = "ctrl") ; If property does not exist or is ctrl
			throw PropertyError("Unknown property", -1, name) ; Throw error
		return this.ctrl.%name% ; Return property
	}

	__Set(name, params, value) { ; Set property
		if (SubStr(name, 1, 1) = "_" || name = "ctrl" || name = "hwnd") { ; If property is _ or ctrl or hwnd
			if ObjHasOwnProp(this, name) ; If property exists
				this.%name% := value ; Set property
			else
				this.DefineProp(name, { Value: value }) ; Define property
			return value ; Return value
		}

		if (!ObjHasOwnProp(this, "ctrl")) ; If property does not exist
			throw PropertyError("Unknown property", -1, name) ; Throw error
		return this.ctrl.%name% := value ; Return property
	}

	__Call(name, params) { ; Call method
		if (!ObjHasOwnProp(this, "ctrl")) ; If property does not exist
			throw Error("Control is not initialized yet.") ; Throw error
		return this.ctrl.%name%(params*) ; Return property
	}

	; -------------------------------------------------------
	; VALUE
	; -------------------------------------------------------
	Value {
		get => this.ctrl.Value ; Get value
		set => (this.ctrl.Value := value) ; Set value
	}

	Clear() => (this.ctrl.Value := "") ; Clear value

	NumValue { ; Numeric value
		get {
			v := this.ctrl.Value ; Get value
			return IsNumber(v) ? Number(v) : 0 ; Return number or 0
		}
	}

	; -------------------------------------------------------
	; INPUT MODE
	; -------------------------------------------------------
	InputMode {
		get => this._mode ; Get mode
		set => (this._mode := value) ; Set mode
	}

	ModeAll() => (this._mode := 0) ; Set mode to all
	ModeNumeric() => (this._mode := 1) ; Set mode to numeric
	ModeAlpha(locale := "") { ; Set mode to alpha
		this._mode := 2
		if (locale != "")
			this._locale := locale
	}
	ModeUpper(locale := "") { ; Set mode to upper
		this._mode := 3
		if (locale != "")
			this._locale := locale
	}
	ModeLower(locale := "") { ; Set mode to lower
		this._mode := 4
		if (locale != "")
			this._locale := locale
	}
	ModeSentence(locale := "") { ; Set mode to sentence
		this._mode := 5
		if (locale != "")
			this._locale := locale
	}
	ModeTitle(locale := "") { ; Set mode to title
		this._mode := 6
		if (locale != "")
			this._locale := locale
	}

	; -------------------------------------------------------
	; LOCALE
	; -------------------------------------------------------
	Locale {
		get => (this._locale != "" ? this._locale : this._GetInputLocaleName()) ; Get locale
		set => (this._locale := value) ; Set locale
	}

	; Characters to block in ModeAlpha. Case-sensitive by default.
	; e.g. e.ExcludeChars := "QWXqwx"
	ExcludeChars {
		get => this._excludeChars ; Get exclude chars
		set => (this._excludeChars := value) ; Set exclude chars
	}

	; -------------------------------------------------------
	; COLORS
	; -------------------------------------------------------
	SetNormalColors(bgHex, fgHex) { ; Set normal colors
		this._useFocusColors := true
		this._userSetBg := true
		this._normalBg := bgHex
		this._normalFg := fgHex
		this._ApplyColors(bgHex, fgHex)
	}

	SetFocusColors(bgHex, fgHex) { ; Set focus colors
		this._useFocusColors := true
		this._focusBg := bgHex
		this._focusFg := fgHex
	}

	EnableFocusColors(enabled := true) => (this._useFocusColors := !!enabled)

	_ApplyColors(bgHex, fgHex) { ; Apply colors
		this.ctrl.Opt("Background" . bgHex)
		this.ctrl.Opt("c" . fgHex)
	}

	; -------------------------------------------------------
	; PROPERTIES
	; -------------------------------------------------------
	MaxLength {
		get => this._maxLen ; Get max length
		set {
			this._maxLen := value ; Set max length
			SendMessage(0x00C5, value, 0, this.hwnd) ; EM_LIMITTEXT
		}
	}

	ReadOnly {
		get => this._readOnly ; Get read-only
		set {
			this._readOnly := !!value ; Set read-only
			SendMessage(0x00CF, this._readOnly ? 1 : 0, 0, this.hwnd) ; EM_SETREADONLY
			; If no custom background was set, mirror the system ReadOnly color.
			if (!this._userSetBg) {
				if (this._readOnly) {
					; COLOR_BTNFACE (index 15) = standard Windows readonly/disabled bg
					roColor := this._GetSysColorHex(15)
					this._ApplyColors(roColor, this._normalFg)
				} else {
					; Restore default white edit background
					this._ApplyColors(this._normalBg, this._normalFg)
				}
			}
		}
	}

	EnterToTab {
		get => this._enterToTab ; Get enter to tab
		set => (this._enterToTab := !!value) ; Set enter to tab
	}

	SetPlaceholder(text) { ; Set placeholder
		this._placeholder := text
		SendMessage(0x1501, 1, StrPtr(text), this.hwnd)
	}

	SetFont(opts, fontName := "") => this.ctrl.SetFont(opts, fontName) ; Set font

	Enabled {
		get => this.ctrl.Enabled
		set => (this.ctrl.Enabled := value)
	}
	Enable() => (this.ctrl.Enabled := true)
	Disable() => (this.ctrl.Enabled := false)

	Visible {
		get => this.ctrl.Visible
		set => (this.ctrl.Visible := value)
	}
	Show() => (this.ctrl.Visible := true)
	Hide() => (this.ctrl.Visible := false)

	Move(x?, y?, w?, h?) => this.ctrl.Move(x?, y?, w?, h?)
	Focus() => this.ctrl.Focus()
	SelectAll() => SendMessage(0x00B1, 0, -1, this.hwnd)

	ToUpper() => (this.ctrl.Value := this._LCMap(this.ctrl.Value, true))
	ToLower() => (this.ctrl.Value := this._LCMap(this.ctrl.Value, false))

	; -------------------------------------------------------
	; EVENTS
	; -------------------------------------------------------
	OnChange(fn) => this.ctrl.OnEvent("Change", fn)
	OnFocus(fn) => this.ctrl.OnEvent("Focus", fn)
	OnLoseFocus(fn) => this.ctrl.OnEvent("LoseFocus", fn)

	; -------------------------------------------------------
	; INTERNAL - Focus colors
	; -------------------------------------------------------
	_OnFocus(ctrl, info) {
		if (this._useFocusColors && !this._readOnly)
			this._ApplyColors(this._focusBg, this._focusFg)
	}

	_OnLostFocus(ctrl, info) {
		if (this._useFocusColors && !this._readOnly)
			this._ApplyColors(this._normalBg, this._normalFg)
	}

	; -------------------------------------------------------
	; INTERNAL - Locale helpers
	; -------------------------------------------------------
	_GetSystemLocale() {
		buf := Buffer(170, 0) ; 85 WCHAR
		if !DllCall("GetUserDefaultLocaleName", "Ptr", buf, "Int", 85, "Int")
			return ""
		return StrGet(buf)
	}

	_GetInputLocaleName() {
		try {
			hwnd := WinActive("A")
			if (hwnd) {
				tid := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", 0, "UInt")
				hkl := DllCall("GetKeyboardLayout", "UInt", tid, "UPtr")
				lcid := hkl & 0xFFFF
				buf := Buffer(170, 0) ; 85 WCHAR
				if DllCall("LCIDToLocaleName", "UInt", lcid, "Ptr", buf, "Int", 85, "UInt", 0, "Int")
					return StrGet(buf)
			}
		} catch {
		}
		return this._GetSystemLocale()
	}

	_LCMap(text, toUpper) {
		if (text = "")
			return ""

		flag := (toUpper ? SuperEdit.LCMAP_UPPERCASE : SuperEdit.LCMAP_LOWERCASE) | SuperEdit.LCMAP_LINGUISTIC_CASING
		locale := (this._locale != "") ? this._locale : this._GetInputLocaleName()

		size := DllCall("LCMapStringEx"
			, "Str", locale
			, "UInt", flag
			, "Str", text
			, "Int", -1
			, "Ptr", 0
			, "Int", 0
			, "Ptr", 0, "Ptr", 0, "Ptr", 0
			, "Int")

		if (!size)
			return toUpper ? StrUpper(text) : StrLower(text)

		buf := Buffer(size * 2, 0)
		if !DllCall("LCMapStringEx"
			, "Str", locale
			, "UInt", flag
			, "Str", text
			, "Int", -1
			, "Ptr", buf
			, "Int", size
			, "Ptr", 0, "Ptr", 0, "Ptr", 0
			, "Int")
			return toUpper ? StrUpper(text) : StrLower(text)

		return StrGet(buf)
	}

	; -------------------------------------------------------
	; INTERNAL - Helpers
	; -------------------------------------------------------
	_RejectInput() { ; Reject input
		SoundBeep(1000, 40)
		return 0
	}

	_GetSelStartEnd() { ; Get selection start and end
		sel := SendMessage(0x00B0, 0, 0, this.hwnd) ; EM_GETSEL
		return [sel & 0xFFFF, (sel >> 16) & 0xFFFF]
	}

	_IsLetterChar(ch) => (ch ~= "^\p{L}$") ; Is letter char

	; Returns true if `ch` is allowed in ModeAlpha.
	; Rules applied in order:
	;   1. Must be a Unicode letter
	;   2. If locale is set and has a pattern, must match that pattern
	;   3. If ExcludeChars is set, must not be in the list
	_IsAllowedAlphaChar(ch) { ; Is allowed alpha char
		if !this._IsLetterChar(ch)
			return false
		if (this._locale != "") {
			prefix := StrLower(SubStr(this._locale, 1, 2))
			if SuperEdit._LocaleLetterPatterns.Has(prefix) {
				pattern := "^" . SuperEdit._LocaleLetterPatterns[prefix] . "$"
				if !(ch ~= pattern)
					return false
			}
		}
		if (this._excludeChars != "" && InStr(this._excludeChars, ch, true))
			return false
		return true
	}

	; Returns the Windows system color (GetSysColor) as a 6-digit hex string.
	;   colorIndex 15 = COLOR_BTNFACE  (standard readonly / disabled edit bg)
	;   colorIndex  5 = COLOR_WINDOW   (standard editable edit bg)
	_GetSysColorHex(colorIndex) {
		rgb := DllCall("GetSysColor", "Int", colorIndex, "UInt")
		r := (rgb & 0xFF)
		g := (rgb >> 8) & 0xFF
		b := (rgb >> 16) & 0xFF
		return Format("{:02X}{:02X}{:02X}", r, g, b)
	}

	; Returns true if `optName` appears as a standalone word in `opts`.
	_HasOption(opts, optName) {
		optLower := StrLower(opts)
		nameLower := StrLower(optName)
		for _, part in StrSplit(optLower, A_Space)
			if (part = nameLower)
				return true
		return false
	}

	_ExtractOptionColor(opts, prefix) { ; Extract option color
		if (opts = "")
			return ""

		prefixLen := StrLen(prefix)
		for _, part in StrSplit(opts, A_Space) {
			if (StrLen(part) <= prefixLen)
				continue
			if (StrLower(SubStr(part, 1, prefixLen)) != StrLower(prefix))
				continue
			; Avoid matching options like "Center" when prefix = "c"
			if (prefix = "c" && StrLower(part) = "center")
				continue
			return SubStr(part, prefixLen + 1)
		}
		return ""
	}

	_ShouldUpperSentence(textBefore) { ; Should upper sentence
		trimmed := RegExReplace(textBefore, "\s+$")
		if (trimmed = "")
			return true
		last := SubStr(trimmed, StrLen(trimmed), 1)
		return InStr(".?!", last) > 0
	}

	_ShouldUpperTitle(textBefore) { ; Should upper title
		if (textBefore = "")
			return true
		last := SubStr(textBefore, StrLen(textBefore), 1)
		return !this._IsLetterChar(last)
	}

	_FilterNumericText(text, existingWithoutSelection := "") { ; Filter numeric text
		result := ""
		loop parse text {
			ch := A_LoopField
			code := Ord(ch)
			isDigit := (code >= 48 && code <= 57)
			isDot := (code = 46)
			if (!isDigit && !isDot)
				continue
			if (isDot && InStr(existingWithoutSelection . result, "."))
				continue
			result .= ch
		}
		return result
	}

	_FilterAlphaText(text) { ; Filter alpha text
		result := ""
		loop parse text {
			ch := A_LoopField
			if this._IsAllowedAlphaChar(ch)
				result .= ch
		}
		return result
	}

	_TransformSentenceText(text, textBefore := "") { ; Transform sentence text
		result := ""
		needUpper := this._ShouldUpperSentence(textBefore)
		loop parse text {
			ch := A_LoopField
			if this._IsLetterChar(ch) {
				result .= needUpper ? this._LCMap(ch, true) : this._LCMap(ch, false)
				needUpper := false
			} else {
				result .= ch
				if (ch ~= "[.?!]")
					needUpper := true
			}
		}
		return result
	}

	_TransformTitleText(text, textBefore := "") { ; Transform title text
		result := ""
		needUpper := this._ShouldUpperTitle(textBefore)
		loop parse text {
			ch := A_LoopField
			if this._IsLetterChar(ch) {
				result .= needUpper ? this._LCMap(ch, true) : this._LCMap(ch, false)
				needUpper := false
			} else {
				result .= ch
				needUpper := true
			}
		}
		return result
	}

	_TransformChar(code, forceUpper := false, forceLower := false) {
		ch := Chr(code)
		if (forceUpper || this._mode = 3)
			return this._LCMap(ch, true)
		if (forceLower || this._mode = 4)
			return this._LCMap(ch, false)
		return ch
	}

	_SentenceCaseChar(code) { ; Sentence case char
		ch := Chr(code)
		if !this._IsLetterChar(ch)
			return ch

		sel := this._GetSelStartEnd()
		textBefore := SubStr(this.ctrl.Value, 1, sel[1])
		return this._ShouldUpperSentence(textBefore) ? this._LCMap(ch, true) : this._LCMap(ch, false)
	}

	_TitleCaseChar(code) { ; Title case char
		ch := Chr(code)
		if !this._IsLetterChar(ch)
			return ch

		sel := this._GetSelStartEnd()
		textBefore := SubStr(this.ctrl.Value, 1, sel[1])
		return this._ShouldUpperTitle(textBefore) ? this._LCMap(ch, true) : this._LCMap(ch, false)
	}

	_NormalizeWholeValue(text) { ; Normalize whole value
		if (this._mode = 0)
			return text
		if (this._mode = 1)
			return this._FilterNumericText(text)
		if (this._mode = 2)
			return this._FilterAlphaText(text)
		if (this._mode = 3)
			return this._LCMap(text, true)
		if (this._mode = 4)
			return this._LCMap(text, false)
		if (this._mode = 5)
			return this._TransformSentenceText(text)
		if (this._mode = 6)
			return this._TransformTitleText(text)
		return text
	}

	_OnCtrlChange(ctrl, info) { ; On ctrl change
		; Guard: skip if we triggered this change ourselves,
		; or if no transformation is needed (MODE_ALL).
		if (this._inInternalEdit || this._mode = 0)
			return

		current := this.ctrl.Value
		normalized := this._NormalizeWholeValue(current)
		if (normalized = current)
			return

		; Cursor position before we overwrite the value.
		sel := this._GetSelStartEnd()
		newPos := Min(StrLen(normalized), sel[1])

		this._inInternalEdit := true
		try {
			this.ctrl.Value := normalized
			SendMessage(0x00B1, newPos, newPos, this.hwnd)
		} finally {
			this._inInternalEdit := false
		}
	}

	; -------------------------------------------------------
	; INTERNAL - WM_KEYDOWN / WM_CHAR / WM_PASTE
	; -------------------------------------------------------
	_OnWMKeyDown(wParam, lParam, msg, hwnd) { ; On WM_KEYDOWN

		; Enter → Tab
		if (wParam = 13 && this._enterToTab) {
			SetTimer(() => SendInput("{Tab}"), -1)
			return 0
		}

		; Ctrl+V  (VK_V = 0x56)
		; Intercepting here is more reliable than WM_PASTE because
		; AHK's OnMessage does not always fire WM_PASTE for child controls.
		if (wParam = 0x56 && GetKeyState("Ctrl", "P")) {
			if (this._mode != 0)
				return this._DoPaste()
			return  ; MODE_ALL: let Edit handle it normally
		}

		; Shift+Insert  (VK_INSERT = 0x2D)
		if (wParam = 0x2D && GetKeyState("Shift", "P")) {
			if (this._mode != 0)
				return this._DoPaste()
			return
		}
	}

	; Unified paste handler.
	; Called from WM_KEYDOWN (primary) and WM_PASTE (fallback).
	_DoPaste() { ; Do paste
		if (this._readOnly)
			return 0

		clipText := A_Clipboard
		if (clipText = "")
			return 0

		sel := this._GetSelStartEnd()
		full := this.ctrl.Value
		textBefore := SubStr(full, 1, sel[1])
		textNoSel := SubStr(full, 1, sel[1]) . SubStr(full, sel[2] + 1)

		if (this._mode = 1)
			filtered := this._FilterNumericText(clipText, textNoSel)
		else if (this._mode = 2)
			filtered := this._FilterAlphaText(clipText)
		else if (this._mode = 3)
			filtered := this._LCMap(clipText, true)
		else if (this._mode = 4)
			filtered := this._LCMap(clipText, false)
		else if (this._mode = 5)
			filtered := this._TransformSentenceText(clipText, textBefore)
		else if (this._mode = 6)
			filtered := this._TransformTitleText(clipText, textBefore)
		else
			filtered := clipText

		; Block _OnCtrlChange from re-normalizing what we just inserted.
		this._inInternalEdit := true
		try
			SendMessage(0x00C2, 1, StrPtr(filtered), this.hwnd)   ; EM_REPLACESEL
		finally
			this._inInternalEdit := false

		return 0    ; block default paste
	}

	_OnWMChar(wParam, lParam, msg, hwnd) { ; On WM_CHAR

		if (this._readOnly && wParam >= 32)
			return this._RejectInput()

		if (wParam < 32)
			return

		if (this._mode = 1) {  ; NUMERIC
			isDigit := (wParam >= 48 && wParam <= 57)
			isDot := (wParam = 46)
			if (!isDigit && !isDot)
				return this._RejectInput()

			if (isDot) {
				sel := this._GetSelStartEnd()
				full := this.ctrl.Value
				existing := SubStr(full, 1, sel[1]) . SubStr(full, sel[2] + 1)
				if InStr(existing, ".")
					return this._RejectInput()
			}
			return
		}

		if (this._mode = 2) { ; ALPHA
			if !this._IsAllowedAlphaChar(Chr(wParam))
				return this._RejectInput()
			return
		}

		if (this._mode = 3 || this._mode = 4) { ; UPPER / LOWER
			transformed := this._TransformChar(wParam)
			SendMessage(0x00C2, 1, StrPtr(transformed), this.hwnd) ; EM_REPLACESEL
			return 0
		}

		if (this._mode = 5) { ; SENTENCE
			transformed := this._SentenceCaseChar(wParam)
			SendMessage(0x00C2, 1, StrPtr(transformed), this.hwnd)
			return 0
		}

		if (this._mode = 6) { ; TITLE
			transformed := this._TitleCaseChar(wParam)
			SendMessage(0x00C2, 1, StrPtr(transformed), this.hwnd)
			return 0
		}
	}

	_OnWMPaste(wParam, lParam, msg, hwnd) { ; On WM_PASTE
		; NOTE: Context-menu paste is now caught by the SetWindowSubclass
		; callback (_SubclassProc). This handler is kept for any remaining
		; edge-cases where WM_PASTE arrives via AHK OnMessage.
		if (this._mode = 0)
			return
		return this._DoPaste()
	}

	; -------------------------------------------------------
	; DESTRUCTOR
	; -------------------------------------------------------
	__Delete() {
		; Remove the window subclass before the control is destroyed.
		if (this._subclassProc) {
			DllCall("RemoveWindowSubclass",
				"Ptr", this.hwnd,
				"Ptr", this._subclassProc,
				"UPtr", this.hwnd)
			CallbackFree(this._subclassProc)
			this._subclassProc := 0
		}
		if SuperEdit.Instances.Has(this.hwnd)
			SuperEdit.Instances.Delete(this.hwnd)
	}
}