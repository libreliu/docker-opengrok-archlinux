#!/bin/bash

[[ -d extracted/ ]] && rm -rf extracted/ 

mkdir -p extracted/
for tarName in sources/*.src.tar.gz; do
  echo "Extracting ${tarName}..."

  cd extracted/
  tar -xf ../${tarName} --force-local

  cd ..
done

for dirName in extracted/*; do
  echo "Processing ${dirName}..."
  pushd ${dirName}
  makepkg --nobuild --holdver --skippgpcheck -s
  popd
done