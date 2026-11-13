#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Centers |window| on the work area of the display under the cursor. The
// window is still hidden (it is shown after the first frame), so it does not
// visibly jump.
void CenterOnCursorDisplay(HWND window) {
  POINT cursor;
  if (!::GetCursorPos(&cursor)) {
    return;
  }
  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  if (!::GetMonitorInfo(::MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST),
                        &info)) {
    return;
  }
  const RECT& area = info.rcWork;
  const UINT flags = SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE;

  // Move onto that display first: on a display with another scale the window
  // gets WM_DPICHANGED and resizes, so it is centered with its final size.
  ::SetWindowPos(window, nullptr, area.left, area.top, 0, 0, flags);

  RECT frame;
  if (!::GetWindowRect(window, &frame)) {
    return;
  }
  const LONG width = frame.right - frame.left;
  const LONG height = frame.bottom - frame.top;
  ::SetWindowPos(window, nullptr,
                 area.left + (area.right - area.left - width) / 2,
                 area.top + (area.bottom - area.top - height) / 2, 0, 0, flags);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnPlatformThread);

  // 1050 x 750, centered; the minimum size is in FlutterWindow. macOS sets the
  // same in macos/Runner/MainFlutterWindow.swift.
  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1050, 750);
  if (!window.Create(L"Arber", origin, size)) {
    return EXIT_FAILURE;
  }
  CenterOnCursorDisplay(window.GetHandle());
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
