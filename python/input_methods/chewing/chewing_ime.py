#! python3
# Copyright (C) 2015 - 2016 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
# Modified: Clipboard Injection Only (No Chinese Input)
# All keys pass through EXCEPT Ctrl+O which injects clipboard text

from keycodes import *  # for VK_XXX constants
from textService import *
import os.path
import ctypes

# --- CLIPBOARD HELPER FUNCTIONS (CTYPES) ---
user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

def get_clipboard_text():
    CF_UNICODETEXT = 13
    text = ""
    if user32.OpenClipboard(None):
        try:
            if user32.IsClipboardFormatAvailable(CF_UNICODETEXT):
                h_clip_mem = user32.GetClipboardData(CF_UNICODETEXT)
                if h_clip_mem:
                    p_global = kernel32.GlobalLock(h_clip_mem)
                    if p_global:
                        text = ctypes.c_wchar_p(p_global).value
                        kernel32.GlobalUnlock(h_clip_mem)
        except Exception:
            pass
        finally:
            user32.CloseClipboard()
    if text:
        return text.replace('\r\n', '\n').replace('\r', '')
    return text


class ChewingTextService(TextService):
    def __init__(self, client):
        TextService.__init__(self, client)
        self.curdir = os.path.abspath(os.path.dirname(__file__))

    def onActivate(self):
        TextService.onActivate(self)
        # No custom icon button - just use the default

    def onDeactivate(self):
        TextService.onDeactivate(self)

    def filterKeyDown(self, keyEvent):
        # ONLY intercept Ctrl+O (keyCode 79 = 'O', VK_CONTROL = 0x11)
        if keyEvent.keyCode == 79 and keyEvent.isKeyDown(0x11):
            return True
        # Let ALL other keys pass through
        return False

    def onKeyDown(self, keyEvent):
        # Ctrl+O: Inject clipboard contents
        if keyEvent.keyCode == 79 and keyEvent.isKeyDown(0x11):
            text = get_clipboard_text()
            if text:
                self.setCommitString(text)
            return True
        return False

    def filterKeyUp(self, keyEvent):
        return False

    def onKeyUp(self, keyEvent):
        return False

    def onPreservedKey(self, guid):
        return False

    def onCommand(self, commandId, commandType):
        pass

    def onMenu(self, buttonId):
        return None

    def onKeyboardStatusChanged(self, opened):
        TextService.onKeyboardStatusChanged(self, opened)

    def onCompositionTerminated(self, forced):
        TextService.onCompositionTerminated(self, forced)
