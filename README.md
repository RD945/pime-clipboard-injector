# PIME Clipboard Injector

PIME Clipboard Injector is a Windows input method that inserts Unicode text from
the clipboard into the currently focused application. It is built on the PIME
Text Services Framework (TSF) launcher and uses `Ctrl+O` as its clipboard
injection shortcut.

The project is distributed as a self-contained package with the PIME launcher,
32-bit and 64-bit text service DLLs, and an embedded Python runtime. A separate
Python installation is not required.

## Upstream Source and Attribution

This project is based on the open-source
[EasyIME/PIME](https://github.com/EasyIME/PIME) project. The clipboard injector
was adapted from PIME's original
[Chewing input method](https://github.com/EasyIME/PIME/tree/master/python/input_methods/chewing),
including its
[`chewing_ime.py`](https://github.com/EasyIME/PIME/blob/master/python/input_methods/chewing/chewing_ime.py)
service implementation.

The upstream PIME project is licensed under the
[GNU Lesser General Public License v2.1](https://github.com/EasyIME/PIME/blob/master/LGPL-2.0.txt).
Refer to the upstream repository for its source code, contributors, build
instructions, and complete licensing information.

## Background: Chinese IME Composition

This project was inspired by the composition mechanism used by Chinese input
methods, particularly the Chewing input method originally included with PIME.
An Input Method Editor (IME) does not normally paste completed text directly.
Instead, it participates in the Windows Text Services Framework and builds a
piece of temporary text called a **composition**.

For example, a Chinese IME typically follows this sequence:

1. The user presses phonetic or character-component keys.
2. The IME keeps those keystrokes in a temporary composition buffer.
3. The IME displays candidate Chinese characters or phrases.
4. The user selects a candidate.
5. The IME commits the selected text to the focused application.

The text shown before the last step is often called pre-edit or composition
text. It can still be changed by the IME. Committing finalizes it and asks the
focused text control to accept it as text input.

PIME separates this process into a native Windows TSF component and a Python
backend. The original Chewing service used the Python backend to process keys,
manage composition state, show candidates, and return the selected Chinese text
to the native component for commitment.

Clipboard Injector keeps the same PIME and TSF commit path but removes the
Chinese phonetic processing, candidate selection, and normal composition UI.
Instead of constructing a Chinese phrase from keystrokes, it uses the current
Unicode clipboard text as the final commit string.

## How Clipboard Injection Works

When Clipboard Injector is active, the following happens when `Ctrl+O` is
pressed:

1. The native PIME text service receives the keyboard event through Windows
   TSF.
2. `PIMELauncher.exe` forwards the event to `python/server.py` as a JSON
   request.
3. `ChewingTextService.filterKeyDown()` checks for the `O` virtual key while
   the Control key is down. It returns `true`, telling PIME that the input
   method will handle this key combination.
4. `ChewingTextService.onKeyDown()` reads `CF_UNICODETEXT` from the Windows
   clipboard through the Win32 clipboard API.
5. Windows line endings are normalized and the text is passed to
   `TextService.setCommitString()`.
6. The Python backend includes that text in its JSON response as
   `commitString`.
7. The native PIME TSF component commits the string into the currently focused
   text control as input-method text.

The relevant implementation is in
`python/input_methods/chewing/chewing_ime.py`. The generic response and commit
state are handled by `python/textService.py`.

## Why It Can Work When Paste Is Disabled

Many applications implement "paste protection" only at the user-interface
event level. They may block `Ctrl+V`, disable a Paste menu item, reject a
clipboard paste message, or cancel a browser paste event. Those checks identify
an explicit paste operation.

Clipboard Injector does not send `Ctrl+V` and does not ask the target
application to execute its Paste command. The clipboard is read by the Python
backend, outside the target application, and the resulting characters are
returned through the IME's normal TSF commit mechanism. From the target text
control's perspective, it receives committed text from an active input method,
similar to receiving a completed Chinese phrase.

This difference can avoid restrictions that block only clipboard paste actions
while continuing to allow ordinary keyboard or IME text input. It does not
disable Windows security, obtain access to protected clipboard contents, or
guarantee insertion into every control. Applications can still reject text,
validate the resulting value, disable input methods, use secure desktop
controls, or otherwise restrict programmatic text input.

## Installation

1. Run `register.bat`.
2. Approve the Windows administrator prompt.
3. Wait for the registration script to finish.
4. Use `Win+Space` to select **Clipboard Injector** from the Windows input
   methods.

<img width="343" height="122" alt="image" src="https://github.com/user-attachments/assets/ed78bb6c-33d4-426d-915b-aa70d5d49dcb" />

The installer copies the package to `%ProgramFiles(x86)%\PIME`, registers the
text service, starts `PIMELauncher.exe`, and adds it to the current user's
Startup folder.

## Usage

1. Copy text to the clipboard.
2. Focus the application where the text should be inserted.
3. Ensure **Clipboard Injector** is the active input method.
4. Press `Ctrl+O`.

The clipboard text is committed through the Windows text service. All other
keyboard input passes through unchanged. While Clipboard Injector is active,
`Ctrl+O` is handled by the input method instead of the focused application's
usual Open command.

## Uninstallation

1. Run `unregister.bat`.
2. Approve the Windows administrator prompt.
3. Wait for the script to unregister the text service and remove the installed
   files and Startup shortcut.

## Project Structure

| Path | Purpose |
| --- | --- |
| `PIMELauncher.exe` | Starts and manages the input method backend |
| `backends.json` | Configures the embedded Python backend |
| `x86/PIMETextService.dll` | 32-bit Windows text service |
| `x64/PIMETextService.dll` | 64-bit Windows text service |
| `python/server.py` | Handles communication with PIME clients |
| `python/serviceManager.py` | Discovers and loads input methods |
| `python/textService.py` | Base text service protocol implementation |
| `python/input_methods/chewing/chewing_ime.py` | Clipboard injection behavior |
| `register.bat` | Installs and registers the package |
| `unregister.bat` | Unregisters and removes the package |

## Notes

- The input method reads Unicode text from the Windows clipboard.
- Windows-style clipboard line endings are normalized before insertion.
- `PIMELauncher.exe` starts automatically when the current user signs in after
  installation.
- Keep the packaged directory structure intact so the launcher can locate its
  backend and runtime files.
