package external;

// idk if this works alright, i just grabbed these from their APIs
@:headerCode('
#include <iostream>

#ifdef _WIN32
#include <windows.h>
#elif __APPLE__
#include <Carbon/Carbon.h>
#elif __linux__
#include <X11/XKBlib.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>
#endif
')
class CapsLock
{
    @:functionCode('
    #ifdef _WIN32
        return GetKeyState(VK_CAPITAL) & 1;
    #elif __APPLE__
        EventModifiers modifiers = GetCurrentKeyModifiers();
        return (modifiers & alphaLock) != 0;
    #elif __linux__
        Display* display = XOpenDisplay(nullptr);
        if (display == nullptr) {
            return false;
        }

        XkbStateRec state;
        XkbGetState(display, XkbUseCoreKbd, &state);
        XCloseDisplay(display);

        return (state.locked_mods & LockMask) != 0;
    #else
        return false;
    #endif
        ')
    public static function enabled():Bool
    {
        return false;
    }
}