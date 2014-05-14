#!/usr/bin/env sh

GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py
MACPYTHON_PREFIX=/Library/Frameworks/Python.framework/Versions
NIPY_PIP_URL=https://nipy.bic.berkeley.edu/scipy_installers
SCIPY_STACK_REQ=scipy-stack-1.0-plus.txt
MACPORTS="MacPorts-2.2.1"

function require_success {
    STATUS=$?
    MESSAGE=$1
    if [ "$STATUS" != "0" ]; then
        echo $MESSAGE
        exit $STATUS
    fi
}


function delete_compiler {
    sudo rm /usr/bin/clang
    sudo rm /usr/bin/gcc
}


function install_macports {
    PREFIX=/opt/local
    curl https://distfiles.macports.org/MacPorts/$MACPORTS.tar.gz > $MACPORTS.tar.gz --insecure
    require_success "failed to download macports"

    tar -xzf $MACPORTS.tar.gz

    cd $MACPORTS
    ./configure --prefix=$PREFIX
    make
    sudo make install
    cd ..

    export PATH=$PREFIX/bin:$PATH
    sudo port -v selfupdate
    sudo port install pkgconfig libpng freetype
    require_success "Failed to install matplotlib dependencies"
}


function install_scipy_stack {
    delete_compiler
    $PIP install -r ${NIPY_PIP_URL}/${SCIPY_STACK_REQ}
    require_success "Failed to install scipy stack"
}


function install_macports_python {
    #major.minor version
    M_dot_m=$1
    Mm=`echo $M_dot_m | tr -d '.'`
    PY="py$Mm"
    FORCE=$2

    if [ "$FORCE" == "noforce" ]; then
        FORCE=""
    elif [ "$FORCE" == "force" ]; then
        FORCE="-f"
    else
        exit "weird force option"
    fi

    sudo port install $FORCE python$Mm
    require_success "Failed to install python"

    if [ -z "$3" ]; then
        VENV=0
    elif [ "$3" == "venv" ]; then
        VENV=1
    fi

    if [ "$VENV" == 0 ]; then
        sudo port install $PY-pip

        export PYTHON=/opt/local/bin/python$M_dot_m
        export SUDO="sudo"
        export PIP="$SUDO /opt/local/bin/pip-$M_dot_m"
    elif [ "$VENV" == 1 ]; then
        sudo port install $PY-virtualenv
        virtualenv-$M_dot_m $HOME/venv --system-site-packages
        source $HOME/venv/bin/activate

        export PYTHON=$HOME/venv/bin/python
        export SUDO=""
        export PIP=$HOME/venv/bin/pip
    fi
}


function install_tkl_85 {
    TCL_VERSION="8.5.14.0"
    curl http://downloads.activestate.com/ActiveTcl/releases/$TCL_VERSION/ActiveTcl$TCL_VERSION.296777-macosx10.5-i386-x86_64-threaded.dmg > ActiveTCL.dmg
    require_success "Failed to download TCL $TCL_VERSION"

    hdiutil attach ActiveTCL.dmg -mountpoint /Volumes/ActiveTcl
    sudo installer -pkg /Volumes/ActiveTcl/ActiveTcl-8.5.pkg -target /
    require_success "Failed to install ActiveTcl $TCL_VERSION"
}


function install_mac_python {
    PY_VERSION=$1
    PY_DMG=python-$PY_VERSION-macosx10.6.dmg
    curl https://www.python.org/ftp/python/$PY_VERSION/${PY_DMG} > $PY_DMG
    require_success "Failed to download mac python $PY_VERSION"

    hdiutil attach $PY_DMG -mountpoint /Volumes/Python
    sudo installer -pkg /Volumes/Python/Python.mpkg -target /
    require_success "Failed to install Python.org Python $PY_VERSION"
    M_dot_m=${PY_VERSION:0:3}
    export PYTHON=/usr/local/bin/python$M_dot_m
}


function get_pip {
    PYTHON=$1

    curl -O $GET_PIP_URL > get-pip.py
    require_success "failed to download get-pip"

    sudo $PYTHON get-pip.py
    require_success "Failed to install pip"
}


if [ "$TEST" == "brew_system" ] ; then

    brew update
    sudo easy_install pip

    if [ -z "$VENV" ]; then
        export PIP="sudo pip"
        export PYTHON=/usr/bin/python2.7
        export SUDO="sudo"
    else
        sudo pip install virtualenv
        virtualenv $HOME/venv --system-site-packages
        source $HOME/venv/bin/activate
        export PIP=$HOME/venv/bin/pip
        export PYTHON=$HOME/venv/bin/python
        export SUDO=""
    fi

    install_scipy_stack

elif [ "$TEST" == "brew_py" ] ; then
    brew update

    if [[ ${PY:0:1} == "2" ]] ; then
        brew install python
    else
        brew install python3
    fi
    require_success "Failed to install python"

    if [ -z "$VENV" ] ; then
        export PIP=/usr/local/bin/pip${PY}
        export PYTHON=/usr/local/bin/python${PY}
    else
        /usr/local/bin/pip3 install virtualenv
        /usr/local/bin/virtualenv${PY} $HOME/venv
        source $HOME/venv/bin/activate

        export PIP=$HOME/venv/bin/pip
        export PYTHON=$HOME/venv/bin/python
    fi

    install_scipy_stack

elif [ "$TEST" == "macports" ] ; then

    install_macports
    install_macports_python $PY noforce $VENV
    install_scipy_stack

elif [ "$TEST" == "macpython_10.9" ] ; then

    install_mac_python $PY_VERSION
    PY=${PY_VERSION:0:3}
    get_pip $PYTHON
    export PIP="sudo $MACPYTHON_PREFIX/$PY/bin/pip$PY"
    install_scipy_stack

else
    echo "Unknown test setting ($TEST)"
    exit -1
fi
