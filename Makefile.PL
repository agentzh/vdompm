use strict;
use lib '.';
use inc::Module::Install;

name                ('VDOM');
license             ('perl');
author              ('Agent Zhang <agentzh@yahoo.cn>');
perl_version        ('5.006001');
all_from            ('lib/VDOM.pm');

requires            ('Scalar::Util');
requires            ('JSON::XS');
requires            ('Class::XSAccessor');
requires            ('List::MoreUtils');
build_requires      ('Test::More');
no_index( directory => qw< t inc doc share demo > );

#install_script      ('script/xulapp');
#install_script      ('script/xml2td');
#install_share;

auto_install();
WriteAll();

