#!/bin/bash

# All output will be collected here
TESTSUNITPATH=$PWD

# "print_tests" returns relative paths to all the tests
TESTS=$(make -s -C ../.. print_tests)

# All relative paths are based on the tree's root
FSBASEDIR=$(realpath "$PWD/../../")

echo "-----------------------------------------------------------------";
echo "Starting tests";
echo "Tests found: ${TESTS}";
echo "-----------------------------------------------------------------";
for i in $TESTS
do
    echo "Testing $i" ;

    # Change folder to where the test is
    currenttestpath="$FSBASEDIR/$i"
    cd $(dirname "$currenttestpath")

    # Tests are unique per module, so need to distinguish them by their directory
    relativedir=$(dirname "$i")
    echo "Relative dir is $relativedir"

    file=$(basename -- "$currenttestpath")
    log="$TESTSUNITPATH/log_run-tests_${relativedir//\//!}!$file.html";

    # Execute the test
    $currenttestpath | tee >(ansi2html > $log) ;
    exitstatus=${PIPESTATUS[0]} ;

    if [ "0" -eq $exitstatus ] ; then
	rm $log ;
    else
	echo "*** ./$i exit status is $exitstatus" ;
	corefilesearch=/cores/core.*.!drone!src!${relativedir//\//!}!.libs!$file.* ;
	echo $corefilesearch ;
	if ls $corefilesearch 1> /dev/null 2>&1; then
	    echo "coredump found";
	    coredump=$(ls $corefilesearch) ;
	    echo $coredump;
	    echo "set logging file $TESTSUNITPATH/backtrace_${i//\//!}.txt" ;
	    gdb -ex "set logging file $TESTSUNITPATH/backtrace_${i//\//!}.txt" -ex "set logging on" -ex "set pagination off" -ex "bt full" -ex "bt" -ex "info threads" -ex "thread apply all bt" -ex "thread apply all bt full" -ex "quit" /drone/src/$relativedir/.libs/$file $coredump ;
	fi ;
	echo "*** $log was saved" ;
    fi ;
    echo "----------------" ;
done
