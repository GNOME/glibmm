// Configuration-time test program, used in Meson build.
// Check for thread_local support.
// Corresponds to the M4 macro GLIBMM_CXX_CAN_USE_THREAD_LOCAL.

thread_local int i = 0;
