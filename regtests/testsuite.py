#!/usr/bin/env python
#                              Ada Web Server
#
#                     Copyright (C) 2003-2010, AdaCore
#
#  This library is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or (at
#  your option) any later version.
#
#  This library is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this library; if not, write to the Free Software Foundation,
#  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  As a special exception, if other files instantiate generics from this
#  unit, or you link this unit with other files to produce an executable,
#  this  unit  does not  by itself cause  the resulting executable to be
#  covered by the GNU General Public License. This exception does not
#  however invalidate any other reasons why the executable file  might be
#  covered by the  GNU Public License.

"""
./testsuite.py [OPTIONS] [TEST_NAME]

This module is the main driver for AWS testsuite
"""
import logging
import os
import sys

from glob import glob
from makevar import MakeVar

from gnatpython.env import Env
from gnatpython.fileutils import mkdir, rm
from gnatpython.main import Main
from gnatpython.mainloop import (MainLoop, add_mainloop_options,
                                 generate_collect_result,
                                 generate_run_testcase)
from gnatpython.testdriver import add_run_test_options
from gnatpython.reports import ReportDiff


class Runner(object):
    """Run the testsuite

    Build a list of all subdirectories containing test.py then, for
    each test, parse the test.opt file (if exists) and run the test
    (by spawning a python process).
    """

    def __init__(self, options):
        """Fill the test lists"""

        # Various files needed or created by the testsuite
        self.result_dir = options.output_dir
        mkdir(self.result_dir)
        self.results_file = self.result_dir + '/results'
        self.report_file = self.result_dir + '/report'

        # Remove old results and report
        rm(self.results_file)
        rm(self.report_file)

        # Always add ALL and target info
        self.discs = ['ALL'] + Env().discriminants
        if Env().target.os.name == 'vxworks6':
            self.discs.append('vxworks')

        if options.discs:
            self.discs += options.discs.split(',')

        if options.with_gdb:
            # Serialize runs and disable gprof
            options.mainloop_jobs = 1
            options.with_gprof = False

        # Read discriminants from testsuite.tags
        # The file testsuite.tags should have been generated by
        # AWS 'make setup'
        try:
            with open('testsuite.tags') as tags_file:
                self.discs += tags_file.read().strip().split()
        except IOError:
            sys.exit("Cannot find testsuite.tags. Please run make setup")

        if options.from_build_dir:
            os.environ["ADA_PROJECT_PATH"] = os.getcwd()
            # Read makefile.setup to set proper build environment
            c = MakeVar('../makefile.setup')
            os.environ["PRJ_BUILD"] = c.get(
                "DEBUG", "true", "Debug", "Release")
            os.environ["PRJ_XMLADA"] = c.get(
                "XMLADA", "true", "Installed", "Disabled")
            os.environ["PRJ_ASIS"] = c.get(
                "ASIS", "true", "Installed", "Disabled")
            os.environ["PRJ_LDAP"] = c.get(
                "LDAP", "true", "Installed", "Disabled")
            os.environ["PRJ_SOCKLIB"] = c.get(
                "IPv6", "true", "IPv6", "GNAT")
            os.environ["SOCKET"] = c.get("SOCKET")
            os.environ["LIBRARY_TYPE"] = "static"
            # from-build-dir only supported on native platforms
            os.environ["PLATFORM"] = "native"
            # Add current tools in from of PATH
            os.environ["PATH"] = os.getcwd() + os.sep + ".." + os.sep \
              + ".build" + os.sep + os.environ["PLATFORM"] \
              + os.sep + os.environ["PRJ_BUILD"].lower() \
              + os.sep + "static" + os.sep + "tools" \
              + os.pathsep + os.environ["PATH"]

        logging.debug(
            "Running the testsuite with the following discriminants: %s"
            % ", ".join(self.discs))

        # Add current directory in PYTHONPATH (to find test_support.py)
        Env().add_search_path('PYTHONPATH', os.getcwd())
        os.environ["TEST_CONFIG"] = os.path.join(os.getcwd(), 'env.dump')

        Env().testsuite_config = options
        Env().store(os.environ["TEST_CONFIG"])

        # Save discriminants
        with open(self.result_dir + "/discs", "w") as discs_f:
            discs_f.write(" ".join(self.discs))

    def start(self, tests, show_diffs=False, old_result_dir=None):
        """Start the testsuite"""
        # Generate the testcases list
        if tests:
            # tests parameter can be a file containing a list of tests
            if len(tests) == 1 and os.path.isfile(tests[0]):
                with open(tests[0]) as _list:
                    tests = [t.strip().split(':')[0] for t in _list]
            else:
                # user list of tests, ignore tailing / to be able to use
                # file completion
                tests = [t.rstrip('/') for t in tests]
        else:
            # Get all tests.py
            tests = [os.path.dirname(t) for t in sorted(glob('*/test.py'))]

        if not Env().testsuite_config.with_Z999:
            # Do not run Z999 test
            tests = [t for t in tests if t != 'Z999_xfail']

        # Run the main loop
        collect_result = generate_collect_result(
            self.result_dir, self.results_file,
            show_diffs)
        run_testcase = generate_run_testcase('run-test', self.discs,
                                             Env().testsuite_config)
        MainLoop(tests, run_testcase, collect_result,
                 Env().testsuite_config.mainloop_jobs)
        # Write report
        ReportDiff(self.result_dir,
                   old_result_dir).txt_image(self.report_file)


def run_testsuite():
    """Main: parse command line and run the testsuite"""
    main = Main(formatter='%(message)s', add_targets_options=True)
    add_mainloop_options(main)
    add_run_test_options(main)
    main.add_option("--with-Z999", dest="with_Z999",
                    action="store_true", default=False,
                    help="Add a test that always fail")
    main.add_option("--view-diffs", dest="view_diffs", action="store_true",
                    default=False, help="show diffs on stdout")
    main.add_option("--diffs", dest="view_diffs", action="store_true",
                    default=False, help="Alias for --view-diffs")
    main.add_option("--with-gprof", dest="with_gprof", action="store_true",
                    default=False, help="Generate profiling reports")
    main.add_option("--with-gdb", dest="with_gdb", action="store_true",
                    default=False, help="Run with gdb")
    main.add_option("--with-valgrind", dest="with_valgrind",
                    action="store_true", default=False,
                    help="Run with valgrind")
    main.add_option("--with-gnatmake", dest="with_gprbuild",
                    action="store_false", default=False,
                    help="Compile with gnatmake")
    main.add_option("--with-gprbuild", dest="with_gprbuild",
                    action="store_true", default=False,
                    help="Compile with gprbuild (default is gnatmake)")
    main.add_option("--old-result-dir", type="string",
                    help="Old result dir")
    main.add_option("--from-build-dir", dest="from_build_dir",
                    action="store_true", default=False,
                    help="Run testsuite from local build (in repository)")
    main.parse_args()

    run = Runner(main.options)
    run.start(main.args, show_diffs=main.options.view_diffs,
              old_result_dir=main.options.old_result_dir)

if __name__ == "__main__":
    # Run the testsuite
    run_testsuite()
