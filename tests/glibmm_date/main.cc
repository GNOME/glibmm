#include <glibmm.h>
#include <iostream>

int main(int, char**)
{
  Glib::Date date;
  date.set_time_current();
  date.add_months(1);
  date.subtract_days(1);
  date.add_years(1);

  std::cout << "The date a year and a month from yesterday will be: " <<
    date.get_month() << "/" << (int) date.get_day() << "/" << date.get_year() <<
      "." << std::endl;


  Glib::Date copy_date(date);
  Glib::Date assigned_date;

  assigned_date = copy_date;

  std::cout << "The copied date is: " << copy_date.get_month() << "/" <<
    (int) copy_date.get_day() << "/" << copy_date.get_year() << "." <<
      std::endl;

  return 0;
}
