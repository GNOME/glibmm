// Configuration-time test program, used in Meson build.
// Check whether the compiler allows us to use a non-extern "C" function,
// such as a static member function, to an extern "C" function pointer,
// such as a GTK callback.
// Corresponds to the M4 macro GLIBMM_CXX_CAN_ASSIGN_NON_EXTERN_C_FUNCTIONS_TO_EXTERN_C_CALLBACKS.

extern "C"
{
struct somestruct
{
  void (*callback) (int);
};
} // extern "C"

void somefunction(int) {}

int main()
{
  somestruct something;
  something.callback = &somefunction;
  return 0;
}
