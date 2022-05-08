#!/bin/bash

# !! Please enter update-check script here
# It should return the code of latest version, e.g. 5.17.6
# The result will be the value of pkgver and can be reused below.
latest_version=$(\
    curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/Nriver/trilium-translation/releases |\
    grep "tag_name" | awk -F': ' '{print $2}' | sed 's/[",v]//g' | sed -n '1p')

# !! Please enter the filename of upstream update
# If the filename is dynamic, you can leave it blank
# and reassign it in the _fetch_upstream function
upstream_filename="trilium-cn-linux-x64.zip"

# This function is used to fetch update from upstream.
# Default is to download using cUrl.
# You can modify it if you want rsync or anything else you like.
# !! REMEMBER it should return true (or 0) when completed successfully.
upstream_link="https://github.com/Nriver/trilium-translation/releases/download/v${latest_version}/${upstream_filename}"
_fetch_upstream() {
    curl ${upstream_link} -LOC -
    #upstream_filename=
}

###############################################################
# Don't edit the following unless you know what you are doing.#
###############################################################

# Usage: _error return_code error_msg
_error() {
    echo -e "\e[31mERROR\e[0m: ${2}"
    if [[ -n ${ACTION_WORKSPACE} ]]; then
        echo -e "\e[31mERROR\e[0m: ${2}" >> ${ACTION_WORKSPACE}/message
    fi
    exit ${1}
}

# Usage: _log log_msg
_log() {
    echo -e "${1}"
    if [[ -n ${ACTION_WORKSPACE} ]]; then
        echo -e "${1}" >> ${ACTION_WORKSPACE}/message
    fi
}

rm -f message

[[ -z ${latest_version} ]] && _error 1 "Get latest version failed. cUrl returned nothing."

last_version=$(cat LATEST)

_log "\e[32mLATEST VERSION\e[0m: ${latest_version}"
_log "\e[33mLAST VERSION\e[0m: ${last_version}"

if [[ ${latest_version} = ${last_version} ]]; then
    _log "\e[34m ==========>\e[0m Package is up-to-date."
    _log "\e[34m ==========>\e[0m Nothing to do today."
    exit
fi

mkdir workdir && cd workdir

_fetch_upstream || _error 2 "Failed to fetch update from upstream."
# Generate SHA256SUM
[[ -f ${upstream_filename} ]] || _error 3 "No source file found. Please check your _fetch_upstream function and try again."
sha256sum=$(sha256sum ${upstream_filename} | awk -F'  ' '{print $1}')

# Edit PKGBUILD template
cp ../PKGBUILD.templete ./PKGBUILD
[[ $? != 0 ]] && _error 4 "PKGBUILD template does not exist."
sed "s/%%pkgver%%/${latest_version}/g" PKGBUILD -i
[[ $? != 0 ]] && _error 5 "No placeholder of latest version in PKGBUILD template. Please check and try again."
sed "s/%%sha256sum%%/${sha256sum}/g" PKGBUILD -i
[[ $? != 0 ]] && _error 6 "No placeholder of sha256sum in PKGBUILD template. Please check and try again."
cp ../SRCINFO.templete ./.SRCINFO
[[ $? != 0 ]] && _error 7 "SRCINFO template does not exist."
sed "s/%%pkgver%%/${latest_version}/g" .SRCINFO -i
[[ $? != 0 ]] && _error 8 "No placeholder of latest version in SRCINFO template. Please check and try again."
sed "s/%%sha256sum%%/${sha256sum}/g" .SRCINFO -i
[[ $? != 0 ]] && _error 9 "No placeholder of sha256sum in SRCINFO template. Please check and try again."

if [[ -n ${ACTION_WORKSPACE} ]]; then
    # Push update to AUR repo
    git clone aur@aur.archlinux.org:${AUR_REPO}.git repo-aur
    [[ $? != 0 ]] && _error 10 "Failed to clone AUR repository. Have you pushed the first version to AUR repo?"
    cd repo-aur
    cp -f ../PKGBUILD ./PKGBUILD
    cp -f ../.SRCINFO ./.SRCINFO
    git add PKGBUILD .SRCINFO
    git config user.name ${AUR_NAME} && git config user.email ${AUR_EMAIL}
    [[ $? != 0 ]] && _error 11 "You forgot to set your AUR username or email or both."
    git commit -m "Update ${latest_version}"
    git push origin master
    [[ $? != 0 ]] && _error 12 "Failed to push PKGBUILD update to AUR. Have you set the secret of AUR private key correctly?"
    cd -

    # Update latest version stored in github repo
    git clone https://${REPO} repo
    [[ $? != 0 ]] && _error 13 "Failed to clone Github repository. It doesn't make sense."
    cd repo
    echo ${latest_version} > LATEST
    git add LATEST
    git config user.name ${GH_NAME}
    git config user.email ${GH_EMAIL}
    git commit -m "New Version ${latest_version}"
    git push "https://${GITHUB_TOKEN}@${REPO}" main:main
    [[ $? != 0 ]] && _error 14 "Failed to push version update to Github. It doesn't make sense."
    cd -
fi

# Clean up
if [[ -n ${ACTION_WORKSPACE} ]]; then
    cd ${ACTION_WORKSPACE}
else
    cd -
fi
_log "\e[32m ==========>\e[0m Package has been updated."
rm -rf workdir
