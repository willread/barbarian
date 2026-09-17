#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <math.h>
#include <wchar.h>
#ifndef CAIRN_BUILTIN
#include "vendor/gdextension_interface.h"
#endif

static HWND game_window;
static WNDPROC original_proc;
static UINT_PTR discovery_timer;
static UINT probe_message;

// Work with client dimensions: the title bar and DPI-scaled borders are not 16:9.
static void constrain_rect(RECT *rect, UINT edge, LONG border_x, LONG border_y) {
    double width = rect->right - rect->left - border_x;
    double height = rect->bottom - rect->top - border_y;
    double units;
    if (edge == WMSZ_LEFT || edge == WMSZ_RIGHT) units = width / 16.0;
    else if (edge == WMSZ_TOP || edge == WMSZ_BOTTOM) units = height / 9.0;
    else units = (16.0 * width + 9.0 * height) / 337.0;
    if (units < 40.0) units = 40.0;
    // Round individual pixels, not multiples of 16, so motion remains continuous.
    LONG outer_width = (LONG)floor(units * 16.0 + .5) + border_x;
    LONG outer_height = (LONG)floor(units * 9.0 + .5) + border_y;
    if (edge == WMSZ_LEFT || edge == WMSZ_TOPLEFT || edge == WMSZ_BOTTOMLEFT)
        rect->left = rect->right - outer_width;
    else rect->right = rect->left + outer_width;
    if (edge == WMSZ_TOP || edge == WMSZ_TOPLEFT || edge == WMSZ_TOPRIGHT)
        rect->top = rect->bottom - outer_height;
    else rect->bottom = rect->top + outer_height;
}

static LRESULT CALLBACK aspect_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    if (message == probe_message) return 0x169;
    if (message == WM_SIZING && (GetWindowLongPtrW(window, GWL_STYLE) & WS_THICKFRAME) && !IsZoomed(window)) {
        RECT outer, client;
        GetWindowRect(window, &outer);
        GetClientRect(window, &client);
        constrain_rect((RECT *)lparam, (UINT)wparam,
            outer.right - outer.left - client.right,
            outer.bottom - outer.top - client.bottom);
        return TRUE;
    }
    WNDPROC next = original_proc;
    if (message == WM_NCDESTROY) {
        SetWindowLongPtrW(window, GWLP_WNDPROC, (LONG_PTR)next);
        game_window = NULL;
        original_proc = NULL;
    }
    return CallWindowProcW(next, window, message, wparam, lparam);
}

static BOOL CALLBACK find_window(HWND window, LPARAM unused) {
    DWORD process;
    GetWindowThreadProcessId(window, &process);
    if (process != GetCurrentProcessId() || GetWindow(window, GW_OWNER)) return TRUE;
    wchar_t name[128];
    GetClassNameW(window, name, 128);
    if (wcscmp(name, L"Engine") != 0 && !wcsstr(name, L"Godot")) return TRUE;
    SetLastError(0);
    WNDPROC prior = (WNDPROC)SetWindowLongPtrW(window, GWLP_WNDPROC, (LONG_PTR)aspect_proc);
    if (!prior) return TRUE;
    original_proc = prior;
    game_window = window;
    return FALSE;
}

static VOID CALLBACK discover(HWND window, UINT message, UINT_PTR timer, DWORD tick) {
    if (!game_window) EnumWindows(find_window, 0);
    if (game_window && discovery_timer) {
        KillTimer(NULL, discovery_timer);
        discovery_timer = 0;
    }
}

static int has_argument(const wchar_t *command, const wchar_t *argument) {
    const wchar_t *at = command;
    size_t length = wcslen(argument);
    while ((at = wcsstr(at, argument))) {
        if ((at == command || at[-1] == L' ' || at[-1] == L'"') &&
            (at[length] == 0 || at[length] == L' ' || at[length] == L'"')) return 1;
        at += length;
    }
    return 0;
}

static void start_aspect(void) {
    const wchar_t *command = GetCommandLineW();
    if (has_argument(command, L"--editor") || has_argument(command, L"--headless")) return;
    probe_message = RegisterWindowMessageW(L"Cairn.NativeAspectRatio.16x9");
    EnumWindows(find_window, 0);
    if (!game_window) discovery_timer = SetTimer(NULL, 0, 50, discover);
}

static void stop_aspect(void) {
    if (discovery_timer) KillTimer(NULL, discovery_timer);
    discovery_timer = 0;
    if (game_window && IsWindow(game_window) && (WNDPROC)GetWindowLongPtrW(game_window, GWLP_WNDPROC) == aspect_proc)
        SetWindowLongPtrW(game_window, GWLP_WNDPROC, (LONG_PTR)original_proc);
    game_window = NULL;
    original_proc = NULL;
}

#ifndef CAIRN_BUILTIN
static void initialize(void *data, GDExtensionInitializationLevel level) {
    if (level == GDEXTENSION_INITIALIZATION_SCENE) start_aspect();
}
static void deinitialize(void *data, GDExtensionInitializationLevel level) {
    if (level == GDEXTENSION_INITIALIZATION_SCENE) stop_aspect();
}
__declspec(dllexport) GDExtensionBool cairn_aspect_init(GDExtensionInterfaceGetProcAddress get_proc,
    GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
    initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    initialization->userdata = NULL;
    initialization->initialize = initialize;
    initialization->deinitialize = deinitialize;
    return 1;
}
#endif
