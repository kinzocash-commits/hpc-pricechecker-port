#include "my_application.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

MyApplication::MyApplication(flutter::DartProject project)
    : project_(std::move(project)) {}

MyApplication::~MyApplication() {}

bool MyApplication::OnCreate() {
  // The Flutter instance must be created and run on the main (UI) thread; it
  // is not safe to construct or run it on a separate thread. Additionally, it
  // may not be safe to be on the Flutter thread if a message is dispatched to
  // the standard Windows UI thread (the CMMessageOnUIThread callback applies
  // to this).
  view_controller_ = std::make_unique<flutter::FlutterViewController>(
      project_.GetWindowDimensions(), project_);
  // Ensure that basic setup of the window has been completed before calling
  // RunTaskOnCurrentThread.
  if (!view_controller_->IsRunning()) {
    return false;
  }
  return true;
}

MyApplication::ASCIIResult MyApplication::GetProject(const std::string& project_name) const {
  return ToASCII(project_.GetDartEntrypointArguments());
}
