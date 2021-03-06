#!/bin/bash
set -e -x

# Change into temporary directory since we want to be outside of git
cd /tmp

PROJECT="my_project"
# Delete old project if necessary
if [ -d ${PROJECT}  ]; then
    rm -rf ${PROJECT}
fi

function run_common_tasks {
    cd ${1}
    python setup.py test
    python setup.py doctest
    python setup.py docs
    python setup.py version
    python setup.py sdist
    python setup.py bdist
    cd ..
}

# Setup a test project
putup ${PROJECT}
# Run some common tasks
run_common_tasks ${PROJECT}
# Try updating
putup --update ${PROJECT}
cd ${PROJECT}
git_diff=`git diff`
test ! -n "$git_diff"
# Try changing the description
cd ..
DESCRIPTION="new_description"
putup --force --update ${PROJECT} -d ${DESCRIPTION}
cd ${PROJECT}
test "`python setup.py --description`" = ${DESCRIPTION}
cd ..
rm -rf ${PROJECT}
# Try different project name than package name
putup MY_COOL_PROJECT -p ${PROJECT}
run_common_tasks MY_COOL_PROJECT
rm -rf MY_COOL_PROJECT
# Try forcing overwrite
putup --force --with-tox ${PROJECT}
# Try running Tox
if [[ "${DISTRIB}" == "ubuntu" ]]; then
    cd ${PROJECT}
    tox -e py27
    cd ..
fi
# Try all kinds of --with options
rm -rf ${PROJECT}
if [[ "${DISTRIB}" == "ubuntu" ]]; then
    putup --with-numpydoc ${PROJECT}
    run_common_tasks ${PROJECT}
    rm -rf ${PROJECT}
fi
putup --with-django ${PROJECT}
run_common_tasks ${PROJECT}
rm -rf ${PROJECT}
putup --with-pre-commit ${PROJECT}
run_common_tasks ${PROJECT}
rm -rf ${PROJECT}
putup --with-travis ${PROJECT}
run_common_tasks ${PROJECT}
# Test update from PyScaffold version < 2.0
if [[ "${DISTRIB}" == "ubuntu" ]]; then
    TMPDIR=tmp
    mkdir ${TMPDIR}; cd ${TMPDIR}
    git clone --branch v1.4 https://github.com/blue-yonder/pyscaffold.git
    putup --update pyscaffold
    run_common_tasks pyscaffold
    cd ..
    rm -rf ${TMPDIR}
fi
# Test namespace package
PROJECT="nested_project"
# Delete old project if necessary
if [ -d ${PROJECT}  ]; then
    rm -rf ${PROJECT}
fi

putup ${PROJECT} -p my_package --with-namespace com.blue_yonder
run_common_tasks ${PROJECT}
rm -rf ${PROJECT}

echo "System test successful!"
