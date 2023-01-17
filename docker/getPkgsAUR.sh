#!/bin/bash

# Config global proxy
configProxy () {
  if [[ -e /usr/bin/proxychains ]]; then
    PROXY_CMD_PREFIX="proxychains -q"
    echo "Proxychains detected, defaults to using this"
  else
    PROXY_CMD_PREFIX=""
    echo "Proxychains undetected"
  fi
}

# get PKGBUILD, obtain and pack source tarball
getAURPkgBuilds () {
  for pkgName in $1; do
    # first, try searching in Arch Official repository
    git clone https://aur.archlinux.org/${pkgName}.git
    if [[ -d "${pkgName}" ]]; then
      pushd "${pkgName}"
      ${PROXY_CMD_PREFIX} makepkg --allsource --skippgpcheck
      cp -v ${pkgName}-*.src.tar.gz ../sources/ 
      popd
    else
      echo "Package ${pkgName} clone failed"
    fi
  done
}

main () {
  configProxy

  [[ -d sources ]] || mkdir sources/
  
  for cmdPkgName in $@; do
    echo "-> Processing AUR package ${cmdPkgName}"

    getAURPkgBuilds "${cmdPkgName}"
  done

}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 aur_package_names..."
  echo "This script will exclude base packages"
    
  echo "Other useful environments: "
  echo "- CURL_PROXY_SETTINGS"

  exit 1
fi

main $@