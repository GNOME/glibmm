/*******************************************************************************
 *
 *  Copyright (c) 2009 Jonathon Jongsma
 *
 *  This file is part of glibmm
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, see <http://www.gnu.org/licenses/>
 *
 *******************************************************************************/
#include <giomm.h>
#include <list>
#include <iostream>

typedef std::list<Glib::RefPtr<Gio::InetAddress> > addr_list_t;
int main(int argc, char** argv)
{
    if (argc <= 1) {
        std::cerr << "Usage: " << argv[0] << " <hostname>" << std::endl;
        return 1;
    }

    Gio::init ();

    Glib::RefPtr<Gio::Resolver> resolver = Gio::Resolver::get_default ();
    try {
        // NOTE: in any real-world application you should probably use the
        // _async() version.  here we use the sync version for simplicity
        addr_list_t addresses =
            resolver->lookup_by_name (argv[1]);

        addr_list_t::iterator i, end = addresses.end ();
        for (i = addresses.begin (); i != end; ++i)
        {
            std::cout << "Address Candidate: " << (*i)->to_string () << std::endl;
        }
    } catch (const Glib::Error& error)
    {
        std::cerr << "Unable to lookup hostname: " << error.what () << std::endl;
    }
}
