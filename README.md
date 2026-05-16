# SuperEdit Control for AutoHotkey v2

**SuperEdit** is a feature-rich wrapper for the standard [AutoHotkey v2](https://www.autohotkey.com/) `Edit` control. It adds input mode filtering, automatic case transformation, locale-aware text handling, focus styling, and more — all transparent to the rest of your code.

Inspired by the [akcanSoft superText ActiveX Control](https://github.com/akcansoft/superText-ActiveX-Control), rebuilt natively for AutoHotkey v2.

![Screen Shot](/screen_shot.png)

## Features

- **7 input modes** — numeric, alpha, uppercase, lowercase, sentence case, title case, or unrestricted
- **Locale-aware casing** — uses Windows `LCMapStringEx` API for correct results in Turkish, German, Greek, and all other Windows-supported languages
- **Locale-aware alpha filtering** — `ModeAlpha` can restrict input to a specific language's character set
- **ExcludeChars** — fine-grained character blocking within `ModeAlpha` (e.g. block Q/W/X for Turkish)
- **Paste filtering** — all transformations apply to pasted text too, including right-click → Paste (via `SetWindowSubclass`)
- **Focus colors** — customizable background and foreground colors when the control gains or loses focus
- **ReadOnly smart styling** — automatically applies the system `COLOR_BTNFACE` background when `ReadOnly` is enabled and no custom color is set
- **Enter → Tab** navigation — press Enter to move to the next control, like Tab
- **Placeholder text** — cue banner support via `EM_SETCUEBANNER`
- **Native pass-through** — unknown properties and methods are automatically forwarded to the underlying `Gui Edit` control

## Installation

1. Download `SuperEdit.ahk`.
2. Place it next to your script.
3. Include it:

```ahk2
#Include SuperEdit.ahk
```

## Quick Start

```ahk2
#Requires AutoHotkey v2.0
#Include SuperEdit.ahk

myGui := Gui()
myGui.SetFont("s10", "Segoe UI")

; Title case field with custom focus colors
eTitle := SuperEdit(myGui, "x10 y10 w300", "Enter a title...")
eTitle.ModeTitle()
eTitle.SetFocusColors("FFFFE0", "000080")

; Turkish uppercase field — i becomes İ, not I
eName := SuperEdit(myGui, "x10 y+10 w300", "Name Surname...", "", "tr-TR")
eName.ModeUpper()

; Numeric field, max 4 characters
eYear := SuperEdit(myGui, "x10 y+10 w80", "Year...")
eYear.ModeNumeric()
eYear.MaxLength := 4

myGui.Show()
```

## Constructor

```ahk2
SuperEdit(gui, opts, placeholder, initialText, locale)
```

| Parameter     | Type     | Default      | Description                                                                                     |
| ------------- | -------- | ------------ | ----------------------------------------------------------------------------------------------- |
| `gui`         | `Gui`    | *(required)* | Parent Gui object                                                                               |
| `opts`        | `String` | `""`         | Standard AHK Gui control options (position, size, colors, `ReadOnly`, etc.)                     |
| `placeholder` | `String` | `""`         | Cue banner text shown when the field is empty                                                   |
| `initialText` | `String` | `""`         | Text pre-filled into the control on creation                                                    |
| `locale`      | `String` | `""`         | BCP-47 locale name (e.g. `"tr-TR"`, `"de-DE"`). Empty = auto-detect from active keyboard layout |

Background and foreground colors can be set directly in `opts` using standard AHK syntax:

```ahk2
; Background and foreground via opts
e := SuperEdit(myGui, "x10 y10 w200 BackgroundFFFDE7 cFF6600", "placeholder...")
```

## Input Modes

Set a mode after creating the control. All modes apply to both typed input and pasted text.

```ahk2
e.ModeAll()              ; No filtering (default)
e.ModeNumeric()          ; Digits 0–9 and a single decimal point
e.ModeAlpha()            ; Unicode letters only
e.ModeAlpha("tr-TR")     ; Letters of the specified locale only
e.ModeUpper()            ; Auto uppercase
e.ModeUpper("tr-TR")     ; Auto uppercase with locale-aware mapping
e.ModeLower()            ; Auto lowercase
e.ModeSentence()         ; Capitalizes first letter after . ? !
e.ModeTitle()            ; Capitalizes first letter of every word
```

All mode methods accept an optional `locale` parameter. This is equivalent to setting `e.Locale := "..."` separately.

The current mode can also be read or set via the `InputMode` property using the static constants:

```ahk2
e.InputMode := SuperEdit.MODE_UPPER   ; same as e.ModeUpper()
MsgBox(e.InputMode)                   ; 3
```

**Static mode constants:**

| Constant                  | Value |
| ------------------------- | ----- |
| `SuperEdit.MODE_ALL`      | `0`   |
| `SuperEdit.MODE_NUMERIC`  | `1`   |
| `SuperEdit.MODE_ALPHA`    | `2`   |
| `SuperEdit.MODE_UPPER`    | `3`   |
| `SuperEdit.MODE_LOWER`    | `4`   |
| `SuperEdit.MODE_SENTENCE` | `5`   |
| `SuperEdit.MODE_TITLE`    | `6`   |

## Locale and Alpha Filtering

When `Locale` is set and `ModeAlpha` is active, only the characters defined for that locale are accepted. For locales not listed in the built-in table, all Unicode letters are allowed.

**Built-in locale patterns:**

| Locale prefix | Language   | Notes                                                        |
| ------------- | ---------- | ------------------------------------------------------------ |
| `tr`          | Turkish    | No Q, W, X in the pattern — use `ExcludeChars` to block them |
| `en`          | English    | a–z, A–Z only                                                |
| `de`          | German     | Includes ä ö ü ß                                             |
| `fr`          | French     | Includes accented Latin characters                           |
| `es`          | Spanish    | Includes á é í ó ú ü ñ                                       |
| `pt`          | Portuguese | Includes accented Latin characters                           |
| `it`          | Italian    | Includes accented Latin characters                           |
| `pl`          | Polish     | Includes ą ć ę ł ń ó ś ź ż                                   |
| `ru`          | Russian    | Cyrillic block                                               |
| `ar`          | Arabic     | Arabic block                                                 |
| `el`          | Greek      | Greek block                                                  |

> For locales not in the table, `ModeAlpha` falls back to accepting all Unicode letters.

### ExcludeChars

Use `ExcludeChars` to block specific characters within `ModeAlpha`. The check is **case-sensitive** — list both cases if needed.

```ahk2
; Turkish: block Q, W, X (both cases)
e.ExcludeChars := "QWXqwx"
e.ModeAlpha("tr-TR")
```

`ExcludeChars` works independently of locale. It can be used with or without a locale set, and can be changed at any time:

```ahk2
e.ExcludeChars := ""    ; remove all restrictions
```

## Properties

### Value and content

```ahk2
e.Value := "Hello"      ; set text
MsgBox(e.Value)         ; get text

MsgBox(e.NumValue)      ; returns Number(Value), or 0 if not numeric (read-only)
```

### ReadOnly

```ahk2
e.ReadOnly := true      ; make read-only; applies system COLOR_BTNFACE background automatically
e.ReadOnly := false     ; restore editable; restores normal background

; ReadOnly can also be set via opts at creation time:
e := SuperEdit(myGui, "x10 y10 w200 ReadOnly", "", "Fixed text")
```

When `ReadOnly` is set and no custom background color was specified, SuperEdit automatically applies the system `COLOR_BTNFACE` color (the standard Windows gray used for read-only and disabled fields). When `ReadOnly` is removed, the normal white background is restored.

> If a custom background was set (via `opts` or `SetNormalColors`), it is always preserved — ReadOnly does not override it.

### MaxLength

```ahk2
e.MaxLength := 10       ; limit to 10 characters (0 = no limit)
MsgBox(e.MaxLength)
```

### Locale

```ahk2
e.Locale := "tr-TR"     ; set locale
e.Locale := ""          ; revert to auto-detect from active keyboard layout
MsgBox(e.Locale)        ; returns the locale string (or auto-detected name if empty)
```

### EnterToTab

```ahk2
e.EnterToTab := true    ; pressing Enter moves focus to the next control (default)
e.EnterToTab := false   ; Enter key stays in the control (useful for password fields)
```

### ExcludeChars

```ahk2
e.ExcludeChars := "QWXqwx"   ; block these characters in ModeAlpha
e.ExcludeChars := ""          ; no restriction
```

### Enabled / Visible

```ahk2
e.Enabled := false      ; disable the control
e.Visible := false      ; hide the control
```

## Methods

### Text manipulation

```ahk2
e.Clear()               ; empty the field
e.SelectAll()           ; select all text
e.ToUpper()             ; convert existing text to uppercase (locale-aware)
e.ToLower()             ; convert existing text to lowercase (locale-aware)
```

### Colors

```ahk2
e.SetNormalColors("FFFFFF", "000000")   ; background, foreground when not focused
e.SetFocusColors("FFFD76", "B30000")    ; background, foreground when focused
e.EnableFocusColors(true)               ; enable focus color switching (default: true)
e.EnableFocusColors(false)              ; disable — colors never change on focus
```

Default focus colors: yellow background (`FFFD76`), dark red text (`B30000`).

### Other

```ahk2
e.Focus()                       ; give keyboard focus to the control
e.SetPlaceholder("Type here")   ; change the cue banner text
e.SetFont("s12 bold", "Arial")  ; change font
e.Enable()                      ; shorthand for e.Enabled := true
e.Disable()                     ; shorthand for e.Enabled := false
e.Show()                        ; shorthand for e.Visible := true
e.Hide()                        ; shorthand for e.Visible := false
e.Move(x, y, w, h)              ; reposition or resize the control
```

## Events

SuperEdit exposes three convenience event methods that wrap `OnEvent`:

```ahk2
e.OnChange((ctrl, info) => MsgBox("Changed: " . e.Value))
e.OnFocus((ctrl, info) => MsgBox("Focused"))
e.OnLoseFocus((ctrl, info) => MsgBox("Lost focus"))
```

Standard AHK `OnEvent` on `e.ctrl` also works for any other event.

## Paste handling

Filtering and transformation are applied to **all paste sources**:

| Source              | Handled by                                       |
| ------------------- | ------------------------------------------------ |
| `Ctrl+V`            | `WM_KEYDOWN` intercept                           |
| `Shift+Insert`      | `WM_KEYDOWN` intercept                           |
| Right-click → Paste | `SetWindowSubclass` (Windows-level WndProc hook) |

Standard `OnMessage(WM_PASTE)` is not reliable for child Edit controls and is not used as the primary mechanism.

## Native pass-through

Any property, method, or event not defined in SuperEdit is automatically forwarded to the underlying `Gui Edit` control via `__Get`, `__Set`, and `__Call` meta-functions:

```ahk2
e.Opt("+Password")          ; forwarded to ctrl.Opt()
e.Hwnd                      ; forwarded to ctrl.Hwnd
```

## Comparison: Edit vs SuperEdit

| Feature                    | `Gui Edit` | `SuperEdit`       |
| -------------------------- | ---------- | ----------------- |
| Input mode filtering       | ✗          | ✓ (7 modes)       |
| Paste filtering            | ✗          | ✓ (all sources)   |
| Locale-aware casing        | ✗          | ✓ (LCMapStringEx) |
| Locale-aware alpha filter  | ✗          | ✓                 |
| ExcludeChars               | ✗          | ✓                 |
| Focus colors               | ✗          | ✓                 |
| ReadOnly system color      | ✗          | ✓                 |
| Enter → Tab                | ✗          | ✓                 |
| Placeholder (constructor)  | ✗          | ✓                 |
| Initial text (constructor) | ✗          | ✓                 |

## Author

**Mesut Akcan**  
[Mesut Akcan Blog](https://mesutakcan.blogspot.com)\
[YouTube Channel](https://www.youtube.com/mesutakcan)

## Contributing

Contributions are welcome. Open a pull request or submit an issue to suggest features or report bugs.

## License

This project is licensed under the **GPL-3.0 License**. See the `LICENSE` file for details.
