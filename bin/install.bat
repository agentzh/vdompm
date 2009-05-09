@echo off
cd ..
perl Makefile.PL && nmake && nmake install && perl -MVDOM -e "print 'VDOM.pm ', $VDOM::VERSION, \" successfully installed.\n\""
pause

