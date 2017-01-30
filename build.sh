#!/bin/bash

# Cross platform build environment to run Anteater
#
# Copyright 2016-2017, Ashlee Young. All rights reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##### Settings #####
VERSION=0.9
AUTHOR="Ashlee Young"
MODIFIED="January 30, 2017"
JAVA_VERSION=1.7 #PMD will not currently build with Java version other than 1.7
ANT_VERSION=1.9.8 #Ant version 1.10.0 and above does not appear to work with Java 1.7
MAVEN_VERSION=3.3.9
MAVENURL="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-src.tar.gz"
PMD_VERSION=5.5.2
EXPAT_VERSION=2.0.1
RATS_VERSION=2.4
export PROJECTROOT=$(pwd)
export BUILDROOT="$PROJECTROOT"/build
export BINROOT="$PROJECTROOT"/bin
export SRCROOT="$PROJECTROOT"/src
export PATCHROOT="$PROJECTROOT"/patches
export CONFIGSROOT="$PROJECTROOT"/configs
export ANTROOT="$BUILDROOT"/ant
export ANT_HOME="$ANTROOT"/apache-ant-$ANT_VERSION
export MAVENROOT="$BUILDROOT"/maven
export M2_HOME=$BUILDROOT/maven/build
export M2=$M2_HOME/bin
export PMDSRC="$SRCROOT"/pmd
export PMDBUILD="$BUILDROOT"/pmd
export ANTEATERSRC="$SRCROOT"/anteater
export ANTEATERBUILD="$BUILDROOT"/anteater
export RATSSRC="$SRCROOT"/rats-"$RATS_VERSION".tgz
export EXPATSRC="$SRCROOT"/expat-"$EXPAT_VERSION".tar.gz
export RATSBUILD="$BUILDROOT"/rats-"$RATS_VERSION"
export EXPATBUILD="$BUILDROOT"/expat-"$EXPAT_VERSION"
export VENVSRC="$SRCROOT"/virtualenv
export VENVBUILD="$BUILDROOT"/virtualenv
##### End Settings #####

##### Version #####
# Simply function to display versioning information
display_version() {
    clear
    printf "You are running installer script Version: %s \n" "$VERSION"
    printf "Last modified on %s, by %s. \n\n" "$MODIFIED" "$AUTHOR"
    sleep 1
    printf "Checking build environment dependencies... \n\n"
}
##### End Version #####

##### Platform detection #####
# Some things are OS platform dependent, especially when it comes to using 
# installable packages
detect_os() {
    get_os_name=$(hostnamectl | grep Operating\ System \
        | awk {'print $3'})
    if [ "$get_os_name" = "SUSE" ]; then
        echo - OS is SLES 
        export JAVA_HOME=/usr/lib64/jvm/java
        export TOOLXML=toolchains.xml.suse
    elif [ "$get_os_name" = "openSUSE" ]; then
        echo - OS is openSUSE 
        export JAVA_HOME=/usr/lib64/jvm/java
        export TOOLXML=toolchains.xml.suse
    elif [ "$get_os_name" = "Red" ]; then
        echo - OS is Red Hat Enterprise Linux 
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.121-2.6.8.0.el7_3.x86_64
        export TOOLXML=toolchains.xml.centos
    elif [ "$get_os_name" = "CentOS" ]; then
        echo - OS is CentOS 
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.121-2.6.8.0.el7_3.x86_64
        export TOOLXML=toolchains.xml.centos
    elif [ "$get_os_name" = "Ubuntu" ]; then
        echo - OS is Ubuntu 
        java_jdk="openjdk-8-jdk"
    else
        echo - OS is unknown
    fi
    export PATH=$PATH:$ANT_HOME/bin:$M2:$JAVA_HOME/bin
}
##### End Platform detection #####

##### File structures #####
# Since our build environment can use previously built artifacts, we need
# to check before just blowing things away. 
check_directories() {
    if [ ! -d "$PROJECTROOT/build" ]; then
        mkdir "$PROJECTROOT"/build
        echo - \"build\" directory was created successfully
    fi
    if [ ! -d "$PROJECTROOT/src" ]; then
        mkdir "$PROJECTROOT"/src
        echo - \"src\" directory was created successfully
    fi
    if [ ! -d "$PROJECTROOT/bin" ]; then
        mkdir "$PROJECTROOT"/bin
        echo - \"bin\" directory was created successfully
    fi
    if [ ! -d "$PROJECTROOT/patches" ]; then
        mkdir "$PROJECTROOT"/patches
        echo - \"patches\" directory was created successfully
    fi
}
##### End File structures #####

##### Ask Function #####
# This is a common function I use for prompting a yes/no response
ask() {
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
        # Ask the question
        if [ "$MODE" = "auto" ]; then
            REPLY="Y"
        else
            read -p "$1 [$prompt] " REPLY
        fi
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}
##### End Ask Function #####

##### Check Java Environment #####
# We need to ensure both JRE and JDK are up to the right version, 
# but this can get hairy as some might have multiple java versions
# installed. 
check_java_version() {
    required_java=$JAVA_VERSION
    echo - Checking for Java...
    if type -p java; then
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        _java="$JAVA_HOME/bin/java"
    else
        echo No java found
        exit
    fi

    if [[ "$_java" ]]; then
        java_version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo Java version is "$java_version"
        if [[ "$java_version" < "$required_java" ]]; then
            echo Java version is less than "$required_java". Please install the minimum version.
            exit
        fi
    fi
}

check_for_jdk() {
    echo - Checking for appropriate JDK...
    if type -p javac; then
        _javac=javac
    else
        echo No JDK found. Please install required version.
        exit
    fi

    if [[ "$_javac" ]]; then
        version=$("$_javac" -version 2>&1 | awk '{print $2}')
        echo JDK version "$version"
        if [[ "$version" < "$required_java" ]]; then
            echo JDK version is less than "$required_java". Please install the minimum version.
            exit
        fi
    fi
}
##### End Check Java Environment #####

##### Install Ant #####
install_ant() {
    if [ ! -d "$ANT_HOME/bin" ]; then 
        printf "You may have Ant installed on your system, but to avoid build issues, we'd like \n"
        printf "to use our own. It will be installed at $ANT_HOME. \n"
        if ask "May we proceed with installing ant here?"; then
            if [ ! -d "$ANT_HOME" ]; then
                if [ ! -d "$ANTROOT" ]; then
                    mkdir -p "$ANTROOT"
                fi
                cd "$ANTROOT"
                if [ ! -f "$SRCROOT"/apache-ant-$ANT_VERSION-src.tar.gz ]; then
                    wget -P "$SRCROOT" https://archive.apache.org/dist/ant/source/apache-ant-$ANT_VERSION-src.tar.gz
                fi
                if [ ! -d "$ANT_HOME" ]; then
                    tar xzvf "$SRCROOT"/apache-ant-$ANT_VERSION-src.tar.gz
                fi
            fi
            cd $ANT_HOME
            sh build.sh install
            cd "$PROJECTROOT"
            echo - Ant has been installed in:
            echo "$ANT_HOME"
        fi
    else
        echo - Ant looks to be properly installed at: 
        echo "$ANT_HOME"
    fi
}
##### Install Ant #####

##### Install Maven #####
install_maven() {
    if [ ! -d $M2_HOME ]; then
        printf "While you may or may not have Maven installed, our supported version is not yet installed.\n"
        if ask "May we install it?"; then
            if [ ! -d "$MAVENROOT" ]; then
                mkdir -p "$MAVENROOT"
            fi
            cd "$MAVENROOT"
            printf "Maven version $MAVEN_VERSION is being installed in: \n"
            printf "$MAVENROOT \n\n"
            sleep 3
            if [ ! -f "$SRCROOT/apache-maven-$MAVEN_VERSION-src.tar.gz" ]; then
                wget -P "$SRCROOT" "$MAVENURL"
            fi
            tar xzvf "$SRCROOT"/apache-maven-$MAVEN_VERSION-src.tar.gz
            cd "$MAVENROOT"/apache-maven-$MAVEN_VERSION
            ant
            cd "$PROJECTROOT" 
            echo - Maven has been installed in:
            echo "$M2_HOME"
        fi
    else
        echo - Maven looks to be properly installed at: 
        echo "$M2_HOME"
    fi       
}
##### End Install Maven #####

##### Install PMD #####
install_pmd() {
    if [ ! -f "$PMDBUILD"/pmd-dist/target/pmd-bin-"$PMD_VERSION".zip ]; then
        printf "While you may or may not have PMD installed, our supported version is not yet installed.\n"         
        if ask "May we install it?"; then
            if [ ! -d "$PMDSRC" ]; then
                cd "$SRCROOT"
                git clone https://github.com/pmd/pmd
                cd "$PMDSRC"
                git checkout tags/pmd_releases/"$PMD_VERSION"
            fi
            if [ ! -d "$PMDBUILD" ]; then
                cp -r "$PMDSRC" "$BUILDROOT"/.
            fi
            if [ ! -f ~/.m2/toolchains.xml ]; then
                cp -v "$PROJECTROOT"/configs/"$TOOLXML" ~/.m2/toolchains.xml
            fi
            cd "$PMDBUILD"
            mvn clean install 
            cd "$PMDBUILD"/pmd-dist/target
            if [ -f pmd-bin-"$PMD_VERSION".zip ]; then
                unzip pmd-bin-"$PMD_VERSION".zip
                cd pmd-bin-"$PMD_VERSION"/bin
                export PATH="$PATH":"$(pwd)"
            fi
            echo - PMD version "$PMD_VERSION" has been built at:
            echo "$PMDBUILD"/pmd-dist/target/
        fi
    else
        echo - PMD version "$PMD_VERSION" has been built at:
        echo "$PMDBUILD"/pmd-dist/target/
    fi
}
##### End Install PMD #####

##### Install RATS #####
install_expat() {
    if [ ! -f "$EXPATSRC" ]; then
        wget -P "$SRCROOT" http://downloads.sourceforge.net/project/expat/expat/"$EXPAT_VERSION"/expat-"$EXPAT_VERSION".tar.gz
    fi
    if [ ! -d "$EXPATBUILD" ]; then
        printf "While you may or may not have expat installed, our supported version is not yet installed.\n"         
        if ask "May we install it?"; then
            cd "$BUILDROOT"
            tar -xvf "$EXPATSRC"
            cd "$EXPATBUILD"
            ./configure --prefix="$PROJECTROOT" && make && make install
            export PATH="$PATH":"$PROJECTROOT"/bin
            echo - expat version "$EXPAT_VERSION" has been built at:
            echo "$PROJECTROOT"
        fi
    fi
}

install_rats() {
    if [ ! -f "$RATSSRC" ]; then
        wget -P "$SRCROOT" https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-"$RATS_VERSION".tgz
    fi
    if [ ! -d "$RATSBUILD" ]; then
        printf "While you may or may not have RATS installed, our supported version is not yet installed.\n"         
        if ask "May we install it?"; then
            cd "$BUILDROOT"
            tar -xvf "$RATSSRC"
            cd "$RATSBUILD"
            ./configure --prefix="$PROJECTROOT" && make && make install
            export PATH="$PATH":"$PROJECTROOT"/bin
            echo - RATS version "$RATS_VERSION" has been built at:
            echo "$PROJECTROOT"
        fi
    fi
}
##### End Install RATS #####

##### Install PIP #####
install_pip() { #Needs to be installed as Root, so it's not called by default
    if type -p pip; then
        _pip=pip
    else
        printf "While you may or may not have Python-pip installed, our supported version is not yet installed.\n"
        if ask "May we install it?"; then
            wget -P "$SRCROOT" https://bootstrap.pypa.io/get-pip.py
            cd "$SRCROOT"
            sudo python get-pip.py
        fi
    fi
}
##### End Install PIP #####

##### Install Virtualenv #####
install_virtualenv() { #Needs to be installed as Root, so it's not called by default
    if type -p virtualenv; then
        _virtualenv=virtualenv
    else
        printf "While you may or may not have virtualenv installed, our supported version is not yet installed.\n"
        if ask "May we install it?"; then
            cd "$SRCROOT"
            git clone https://github.com/pypa/virtualenv
            cd "$VENVSRC"
            git checkout c1ef9e29bfda9f5b128476d0c6d865ffe681b3fb
            cp -r "$VENVSRC" "$BUILDROOT"
            cd "$VENVBUILD"
            sudo python setup.py install
        fi
    fi
}
##### End Install Virtualenv #####

##### Install Anteater #####
install_anteater() {
    if [ ! -d "$ANTEATERSRC" ]; then
        cd "$SRCROOT"
        git clone https://github.com/lukehinds/anteater
        cd anteater
        git checkout 134759d5345c3cf239a1f418c61fb80436badc4e
    fi
    if [ ! -d "$ANTEATERBUILD" ]; then
        printf "While you may or may not have Anteater installed, our supported version is not yet installed.\n" 
        if ask "May we install it?"; then
            cp -r "$ANTEATERSRC" "$BUILDROOT"/.
            cd "$ANTEATERBUILD"
            cp "$CONFIGSROOT"/anteater.conf "$ANTEATERBUILD"
            # sudo pip install virtualenv ## This is a sudo prerequisite 
            virtualenv env
            source env/bin/activate
            pip install -r requirements.txt
            pip install bandit
            python setup.py install
        fi
    fi
}
##### End Install Anteater #####


main() {
    display_version
    detect_os
    check_java_version
    check_for_jdk
    check_directories
    install_ant
    install_maven
    install_pmd
    install_anteater
}
main
