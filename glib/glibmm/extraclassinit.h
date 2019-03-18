#ifndef _GLIBMM_EXTRACLASSINIT_H
#define _GLIBMM_EXTRACLASSINIT_H
/* Copyright (C) 2017 The glibmm Development Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include <glibmm/objectbase.h>

namespace Glib
{

/** A convenience class for named custom types.
 *
 * Use it if you need to add code to GType's class init function and/or
 * need an instance init function.
 * Example:
 * @code
 * #include <glibmm/extraclassinit.h>
 *
 * class MyExtraInit : public Glib::ExtraClassInit
 * {
 * public:
 *   MyExtraInit(const Glib::ustring& css_name)
 *   :
 *   Glib::ExtraClassInit(my_extra_class_init_function, &m_css_name, my_instance_init_function),
 *   m_css_name(css_name)
 *   { }
 *
 * private:
 *   static void my_extra_class_init_function(void* g_class, void* class_data)
 *   {
 *     const auto klass = static_cast<GtkWidgetClass*>(g_class);
 *     const auto css_name = static_cast<Glib::ustring*>(class_data);
 *     gtk_widget_class_set_css_name(klass, css_name->c_str());
 *   }
 *   static void my_instance_init_function(GTypeInstance* instance, void* g_class)
 *   {
 *     gtk_widget_set_has_surface(GTK_WIDGET(instance), true);
 *   }
 *
 *   Glib::ustring m_css_name;
 * };
 *
 * class MyWidget : public MyExtraInit, public Gtk::Widget
 * {
 * public:
 *   MyWidget()
 *   :
 *   // The GType name will be gtkmm__CustomObject_MyWidget
 *   Glib::ObjectBase("MyWidget"), // Unique class name
 *   MyExtraInit("my-widget"),
 *   Gtk::Widget()
 *   {
 *     // ...
 *   }
 *   // ...
 * };
 * @endcode
 *
 * @note Classes derived from %ExtraClassInit (MyExtraInit in the example)
 * must be listed before Glib::Object or a class derived from
 * %Glib::Object (Gtk::Widget in the example) in the list of base classes.
 *
 * @newin{2,60}
 */
class ExtraClassInit : virtual public ObjectBase
{
protected:
  /** Constructor.
   *
   * @param class_init_func Pointer to an extra class init function.
   *        nullptr, if no extra class init function is needed.
   * @param class_data Class data pointer, passed to the class init function.
   *        Can be nullptr, if the class init function does not need it.
   * @param instance_init_func Pointer to an instance init function.
   *        nullptr, if no instance init function is needed.
   */
  explicit ExtraClassInit(GClassInitFunc class_init_func, void* class_data = nullptr,
    GInstanceInitFunc instance_init_func = nullptr);
};

} // namespace Glib

#endif /* _GLIBMM_EXTRACLASSINIT_H */
