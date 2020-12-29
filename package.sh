#!/usr/bin/env bash

function extract_path() {
    line=$1

    echo "${line}" | awk '{print $1}'
}

function modify_dylib_paths() {
    dylib=$1
    libpath=$2
    deppath=$3

    mapfile -t info < <(otool -L ${dylib})

    name=$(basename $(extract_path ${info[1]}))
    install_name_tool -id ${libpath}/${name} ${dylib}

    link=( "${info[@]:2}" )
    for line in "${link[@]}"; do
        path=$(extract_path ${line})

        if [[ "${path}" == /usr/lib/* ]]; then
            continue
        fi

        name=$(basename ${path})
        install_name_tool -change ${path} ${deppath}/${name} ${dylib}
    done
}

LY_FORMULA=lilypond
GS_FORMULA=ghostscript
GU_FORMULA=guile@1.8.8
RL_FORMULA=readline

LY_BINARY=lilypond
LY_WRAPPER=lilypond-env

LY_VERSION=$(brew info --json ${LY_FORMULA} | jq -r .[].versions.stable)
GS_VERSION=$(brew info --json ${GS_FORMULA} | jq -r .[].versions.stable)
GU_VERSION=$(brew info --json ${GU_FORMULA} | jq -r .[].versions.stable)
GU_VERSION=$(echo ${GU_VERSION} | sed 's/\./-/2')
GU_VERSION=${GU_VERSION%-*}

LY_PATH=$(readlink -f $(brew --prefix ${LY_FORMULA}))
GS_PATH=$(readlink -f $(brew --prefix ${GS_FORMULA}))
GU_PATH=$(readlink -f $(brew --prefix ${GU_FORMULA}))
RL_PATH=$(readlink -f $(brew --prefix ${RL_FORMULA}))

LY_PREFIX=./build

LY_APP=${LY_PREFIX}/LilyPond.app
LY_APP_CONTENT=${LY_APP}/Contents
LY_APP_BINARIES=${LY_APP_CONTENT}/MacOS
LY_APP_RESOURCES=${LY_APP_CONTENT}/Resources
LY_APP_FRAMEWORKS=${LY_APP_CONTENT}/Frameworks

LY_APP_RELPATH="@executable_path/../Frameworks"

# setup app bundle structure
mkdir -p ${LY_APP_CONTENT}
mkdir -p ${LY_APP_BINARIES} ${LY_APP_RESOURCES} ${LY_APP_FRAMEWORKS}

mkdir -p ${LY_APP_RESOURCES}/share
mkdir -p ${LY_APP_FRAMEWORKS}/${GU_FORMULA}

# copy binaries/executables
cp ${LY_PATH}/bin/* ${LY_APP_BINARIES}/

chmod 0755 ${LY_APP_BINARIES}/*

# copy guile dylibs, preserving symlinks
cp -P ${GU_PATH}/lib/libguile*-v-*.dylib ${LY_APP_FRAMEWORKS}/${GU_FORMULA}/

# copy readline dylib
cp ${RL_PATH}/lib/libreadline.8.dylib ${LY_APP_FRAMEWORKS}/${GU_FORMULA}/

chmod 0644 ${LY_APP_FRAMEWORKS}/${GU_FORMULA}/*.dylib

# modify dylib paths
for bin in $(find ${LY_APP_BINARIES}/* -type f); do
    dylibbundler -cd -b \
        -x ${bin} \
        -d ${LY_APP_FRAMEWORKS} \
        -p ${LY_APP_RELPATH}
done

# modify guile dylib paths
for dylib in $(find ${LY_APP_FRAMEWORKS}/${GU_FORMULA}/*.dylib -type f); do
    modify_dylib_paths \
        ${dylib} \
        ${LY_APP_RELPATH}/${GU_FORMULA} \
        ${LY_APP_RELPATH}
done

# copy other resources
cp -r ${GS_PATH}/share/ghostscript ${LT_APP_RESOURCES}/share/
cp -r ${GU_PATH}/share/guile ${LY_APP_RESOURCES}/share/
cp -r ${LY_PATH}/share/lilypond ${LY_APP_RESOURCES}/share/
cp -r ${LY_PATH}/share/locale ${LY_APP_RESOURCES}/share/

# copy miscellaneous assets (icons, etc..)
cp -r ./Contents ${LY_APP}/

# replace variables
sed -i '' "s/__LY_VERSION/${LY_VERSION}/g" ${LY_APP_CONTENT}/Info.plist
sed -i '' "s/__LY_WRAPPER/${LY_WRAPPER}/g" ${LY_APP_CONTENT}/Info.plist

sed -i '' "s/__LY_VERSION/${LY_VERSION}/g" ${LY_APP_BINARIES}/${LY_WRAPPER}

LY_APP_RELOCATE=${LY_APP_RESOURCES}/etc/relocate

sed -i '' "s/__GS_VERSION/${GS_VERSION}/g" ${LY_APP_RELOCATE}/gs.reloc
sed -i '' "s/__GU_VERSION/${GU_VERSION}/g" ${LY_APP_RELOCATE}/guile.reloc
sed -i '' "s/__LY_VERSION/${LY_VERSION}/g" ${LY_APP_RELOCATE}/guile.reloc
sed -i '' "s/__GU_FORMULA/${GU_FORMULA}/g" ${LY_APP_RELOCATE}/libtool.reloc
