dnl                              $1                     $2                    $3                 $4                $5                  $6
dnl _SIGNAL_PROXY_CUSTOM(custom_signalproxy_name, c_return_type, `<c_arg_types_and_names>', cpp_return_type, `<cpp_arg_types>', `<c_args_to_cpp>')
dnl
define(`_SIGNAL_PROXY_CUSTOM',`dnl
_PUSH(SECTION_H_SIGNALPROXIES_CUSTOM)

#ifndef DOXYGEN_SHOULD_SKIP_THIS
namespace CustomSignalProxies
{

class SignalProxy_`'$1 : public Glib::SignalProxy`'_NUM($5)<$4`'_COMMA_PREFIX(`$5')`'>
{
public:
  typedef Glib::SignalProxy`'_NUM($5)<$4`'_COMMA_PREFIX(`$5')`'> type_base;

  SignalProxy_`'$1`'(Glib::ObjectBase* obj, const char* name);
  ~SignalProxy_`'$1();

  //Reimplement connect(), to use the new glib_callback:
  sigc::connection connect(const SlotType& s, bool after = true);
  sigc::connection connect_notify(const VoidSlotType& s, bool after = false);

protected:
  static $2 glib_callback(GObject* obj _COMMA_PREFIX(`$3'), void* data);
  static $2 glib_void_callback(GObject* obj _COMMA_PREFIX(`$3'), void* data);
};

} //namespace CustomSignalProxies
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

_POP()

_PUSH(SECTION_CC_SIGNALPROXIES_CUSTOM)

namespace CustomSignalProxies
{

SignalProxy_`'$1`'::SignalProxy_`'$1`'(Glib::ObjectBase* obj, const char* name)
 : type_base(obj, name)
{}

SignalProxy_`'$1`'::~SignalProxy_`'$1()
{}

//Reimplement connect(), to use the new glib_callback:
sigc::connection SignalProxy_`'$1`'::connect(const SlotType& s, bool after /* = true */)
{
  return sigc::connection(connect_((GCallback)&glib_callback, s, after));
}

sigc::connection SignalProxy_`'$1`'::connect_notify(const VoidSlotType& s, bool after /* = false */)
{
  return sigc::connection(connect_((GCallback)&glib_void_callback, s, after));
}


$2 SignalProxy_`'$1`'::glib_callback(GObject* obj _COMMA_PREFIX(`$3'), void* data) //static
{
  try
  {
    sigc::slot_base* slot = data_to_slot(data);
ifelse(`$2',void,`dnl
    (*static_cast<SlotType*>(slot))(`$6');
',`dnl
    $2 cresult = (*static_cast<SlotType*>(slot))(`$6');
    //Convert to the C++ type, and return:
    return _CONVERT($2,$4,`cresult');
')
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
    return $2`'(0);
  }
}

$2 SignalProxy_`'$1`'::glib_void_callback(GObject* obj _COMMA_PREFIX(`$3'), void* data) //static
{
  try
  {
    sigc::slot_base* slot = data_to_slot(data);
    (*static_cast<VoidSlotType*>(slot))(`$6');
  }
  catch (...)
  {
    Glib::exception_handlers_invoke();
  }

  return $2`'(0);
}


} //namespace CustomSignalProxies

_POP()
')

