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

# https://superuser.com/questions/513149/how-can-i-get-the-unique-items-in-a-bash-list
listDedup () {
  local result=$(echo "$1" | tr ' ' '\n' | sort -u | tr '\n' ' ' | awk '{$1=$1};1')
  echo -n "${result}"
}

listMinus () {
  local result="";
  for elem in $1; do
    local found="no";
    for delElem in $2; do
      if [[ "${elem}" == "${delElem}" ]]; then
        found="yes";
        break;
      fi
    done
    if [[ ${found} == "no" ]]; then
      result="${result} ${elem}";
    fi
  done
  echo -n "${result}";
}

# Arguments:
# - name: name of the package
# - indentLevel
# Globals:
# - EXCLUDE_LIST: stop traversing inside; will modify
# - (OUTPUT) OUTPUT_LIST: all nodes traversed
EXCLUDE_LIST="";
OUTPUT_LIST="";
printDepTree () {
#   echo "printDepTree: called with $1 $2"
  for excludePkg in ${EXCLUDE_LIST}; do
    # echo "DEDUP $excludePkg"
    if [[ "${excludePkg}" == "$1" ]]; then
      local PREFIX='';
      for ((i = 0 ; i < $2 ; i++)); do
        PREFIX="${PREFIX}-";
      done

      echo "${PREFIX} $1 (duplicate)"
      return;
    fi
  done

  # add myself
  EXCLUDE_LIST=$(listDedup "${EXCLUDE_LIST} $1");

  local PKG_DEPS=`expac '%E' $1`;
  local PREFIX='';
  for ((i = 0 ; i < $2 ; i++)); do
    PREFIX="${PREFIX}-";
  done

  echo "${PREFIX} $1"
  OUTPUT_LIST="${OUTPUT_LIST} $1";

  for dep in ${PKG_DEPS}; do
    printDepTree ${dep} $(($2 + 1));
  done
}

preparePkgBuilds () {
  if [[ -d svntogit-packages/ ]]; then
    ${PROXY_CMD_PREFIX} git clone https://github.com/archlinux/svntogit-packages.git --depth=1
  else
    pushd svntogit-packages/
    ${PROXY_CMD_PREFIX} git pull
    popd
  fi

  if [[ -d svntogit-community/ ]]; then
    ${PROXY_CMD_PREFIX} git clone https://github.com/archlinux/svntogit-community.git --depth=1
  else
    pushd svntogit-community/
    ${PROXY_CMD_PREFIX} git pull
    popd
  fi

  [[ -d sources ]] || mkdir sources/
}

# get PKGBUILD, obtain and pack source tarball
getPkgBuilds () {
  for pkgName in $1; do
    # first, try searching in Arch Official repository
    if [[ -d "svntogit-packages/${pkgName}/trunk" ]]; then
      pushd "svntogit-packages/${pkgName}/trunk"
      ${PROXY_CMD_PREFIX} makepkg --allsource --skippgpcheck
      cp -v ${pkgName}-*.src.tar.gz ../../../sources/ 
      popd
    elif [[ -d "svntogit-community/${pkgName}/trunk" ]]; then
      pushd "svntogit-community/${pkgName}/trunk"
      ${PROXY_CMD_PREFIX} makepkg --allsource --skippgpcheck
      cp -v ${pkgName}-*.src.tar.gz ../../../sources/ 
      popd
    else
      echo "Package ${pkgName} not found in package or community, ignore"
    fi
  done
}

getBasePkgs () {
  EXCLUDE_LIST='';
  printDepTree base 0 > /dev/null
  BASE_PKGS=`echo ${OUTPUT_LIST}`
}

main () {
  configProxy

  # CURL_PROXY_SETTINGS="--proxy socks5://127.0.0.1:7890/"  

  getBasePkgs
  preparePkgBuilds
  echo "Arch basic packages: ${BASE_PKGS}"

  EXCLUDE_LIST="${BASE_PKGS}"
  for cmdPkgName in $@; do
    echo "-> Processing package ${cmdPkgName}"
    EXCLUDE_LIST_BEGIN="${EXCLUDE_LIST}"
    printDepTree ${cmdPkgName} 0 > /dev/null
    RELATED_PKGS=$(listMinus "${OUTPUT_LIST}" "${EXCLUDE_LIST_BEGIN}");
    echo "${cmdPkgName} associated additional packages: ${RELATED_PKGS}"

    getPkgBuilds "${RELATED_PKGS}"
  done

}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 package_names..."
  echo "This script will exclude base packages"
    
  echo "Other useful environments: "
  echo "- CURL_PROXY_SETTINGS"

  exit 1
fi

main $@