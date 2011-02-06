#!/usr/bin/perl -w

use strict;
use warnings;

push (@INC, '.');

require Base::Entity;
require Base::Enum;
require Base::Function;
require Base::Object;
require Base::Property;

require Defs::Common;
require Defs::Enum;
require Defs::Function;
require Defs::Named;
require Defs::Object;
require Defs::Property;
require Defs::Signal;
require Defs::Backend;

require Common::Api;
