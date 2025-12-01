#include "my_application.h"
#include <gdk/gdk.h>

int main(int argc, char** argv) {
  // Set program name for desktop integration (matches StartupWMClass in .desktop)
  g_set_prgname("ree");
  gdk_set_program_class("ree");
  
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
