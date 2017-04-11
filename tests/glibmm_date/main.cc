#include <glibmm.h>
#include <iostream>

// Use this line if you want debug output:
// std::ostream& ostr = std::cout;

// This seems nicer and more useful than putting an ifdef around the use of ostr:
std::stringstream debug;
std::ostream& ostr = debug;

int
main(int, char**)
{
  Glib::Date date;
  date.set_time_current();
  date.add_months(1);
  date.subtract_days(1);
  date.add_years(1);

  ostr << "The date a year and a month from yesterday will be: " << date.get_month_as_int() << "/"
       << (int)date.get_day() << "/" << date.get_year() << "." << std::endl;

  Glib::Date copy_date(date);
  Glib::Date assigned_date;

  assigned_date = copy_date;

  ostr << "The copied date is: " << copy_date.get_month_as_int() << "/" << (int)copy_date.get_day() << "/"
       << copy_date.get_year() << "." << std::endl;

  return EXIT_SUCCESS;
}
