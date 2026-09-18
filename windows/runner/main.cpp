#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "my_application.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when running via "flutter run" or a prefixed
  // "flutter run" tool. It is intended to be run from a script, e.g. as part
  // of a GitHub action.
  if (AttachConsole(ATTACH_PARENT_PROCESS)) {
    freopen("CON", "w", stdout);
    freopen("CON", "w", stderr);
  }

  // Initialize COM.
  CoInitializeEx(nullptr, COINIT_MULTITHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  MyApplication app(std::move(project));
  std::vector<std::string> run_arguments;

  int exit_code = app.Run();

  CoUninitialize();
  return exit_code;
}