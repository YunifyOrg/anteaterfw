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
VERSION=0.1
AUTHOR="Ashlee Young"
MODIFIED="January 18, 2017"
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
export REPOSDIR="$ANTEATERBUILD"/repos
##### End Settings #####

##### Version #####
# Simply function to display versioning information
display_version() {
    clear
    printf "You are running run_scan.sh script Version: %s \n" "$VERSION"
    printf "Last modified on %s, by %s. \n\n" "$MODIFIED" "$AUTHOR"
    sleep 1
    printf "Checking build environment dependencies... \n\n"
}
##### End Version #####

##### Get repo #####
scan_repo() {
    url="$1"
    cd "$ANTEATERBUILD"
    if [ ! -d "$REPOSDIR" ]; then
        mkdir "$REPOSDIR"
    fi
    # if [ -z "$1" ]; then
    #     printf "Please enter the URL for the repo to scan! \n"
    # else
        cd "$REPOSDIR"
        #echo "$url" > "$ANTEATERBUILD"/reponame.txt
        cat ../reponame.txt | xargs git clone
        cd "$ANTEATERBUILD"
        source env/bin/activate
        anteater scan all
    # fi
}
##### End Get repo #####


main() {
    display_version
    scan_repo
    
}
main
