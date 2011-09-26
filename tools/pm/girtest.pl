#!/usr/bin/env perl

use strict;
use warnings;

push (@INC, '.');

#require Gir::Handlers::Generated::Alias;
#require Gir::Handlers::Generated::CInclude;
#require Gir::Handlers::Generated::Constructor;
#require Gir::Handlers::Generated::Function;
#require Gir::Handlers::Generated::Interface;
#require Gir::Handlers::Generated::Package;
#require Gir::Handlers::Generated::Property;
#require Gir::Handlers::Generated::Type;
#require Gir::Handlers::Generated::Array;
#require Gir::Handlers::Generated::Class;
#require Gir::Handlers::Generated::Doc;
#require Gir::Handlers::Generated::GlibSignal;
#require Gir::Handlers::Generated::Member;
#require Gir::Handlers::Generated::Parameter;
#require Gir::Handlers::Generated::Record;
#require Gir::Handlers::Generated::Union;
#require Gir::Handlers::Generated::Bitfield;
#require Gir::Handlers::Generated::Enumeration;
#require Gir::Handlers::Generated::Implements;
#require Gir::Handlers::Generated::Method;
#require Gir::Handlers::Generated::Parameters;
#require Gir::Handlers::Generated::Repository;
#require Gir::Handlers::Generated::Varargs;
#require Gir::Handlers::Generated::Callback;
#require Gir::Handlers::Generated::Constant;
#require Gir::Handlers::Generated::Field;
#require Gir::Handlers::Generated::Include;
#require Gir::Handlers::Generated::Namespace;
#require Gir::Handlers::Generated::Prerequisite;
#require Gir::Handlers::Generated::ReturnValue;
#require Gir::Handlers::Generated::VirtualMethod;

require Gir::Parser;

my $gir_parser = Gir::Parser->new ();

$gir_parser->parse_file ('GtkSource-3.0.gir')
