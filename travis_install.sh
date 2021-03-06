#!/usr/bin/env sh
# REQUIREMENTS_FILE (URL or filename for pip requirements file)
# INSTALL_TYPE (type of Python to install)
# VENV (defined if we should install and test in virtualenv)

source terryfy/travis_tools.sh


function delete_compiler {
    sudo rm -f /usr/bin/cc
    sudo rm -f /usr/bin/clang
    sudo rm -f /usr/bin/gcc
    sudo rm -f /usr/bin/c++
    sudo rm -f /usr/bin/clang++
    sudo rm -f /usr/bin/g++
}


# Remove travis installs of virtualenv and pip
sudo pip uninstall -y virtualenv
sudo pip uninstall -y pip

# Install Python and pip, maybe virtualenv
get_python_environment $INSTALL_TYPE $VERSION $VENV
delete_compiler
if [ -n "$NO_PRE" ]; then
    check_var $PRE_URL
    $PIP_CMD install -f $PRE_URL $NO_PRE
    require_success "Failed to install no-pre requirements"
fi
if [ -n "$PRE" ]; then
    check_var $PRE_URL
    $PIP_CMD install -f $PRE_URL --pre $PRE
    require_success "Failed to install pre requirements"
fi
$PIP_CMD install -q -r ${REQUIREMENTS_FILE}
require_success "Failed to install requirements"
# Show pip installations
$PIP_CMD freeze
