#!/bin/bash

function print_usage 
{
    echo ''
    echo "Usage: [BASE_PATH=<path>] $(basename $0) <OS.ARCH.BUILD> [options]"
    echo ''
    echo 'Typical sample:'
    echo '  --coreClrBinDir="coreclr/bin/Product/Linux.x64.Debug"'
    echo '  --coreFxBinDir="corefx/bin/Linux.AnyCPU.Debug;corefx/bin/Unix.AnyCPU.Debug;corefx/bin/AnyOS.AnyCPU.Debug"'
    echo '  --coreFxNativeBinDir="corefx/bin/Linux.x64.Debug"'
    echo ''
    echo 'Optional arguments:'
    echo '  --coreClrBinDir=<path>           : Directory of the CoreCLR build.'
    echo '  --coreFxBinDir="<path>[;<path>]" : List of one or more directories with CoreFX build outputs (semicolon-delimited)'
    echo '                                     If files with the same name are present in multiple directories, the first one wins.'
    echo '  --coreFxNativeBinDir=<path>      : Directory of the CoreFX native build.'
    echo '  --mscorlibDir=<path>             : Directory containing the built mscorlib.dll. If not specified, it is expected to be'
    echo '                                     in the directory specified by --coreClrBinDir.'
    echo ''
    echo '  --crossgen                       : Precompile any assembly to NI image.'
    echo ''
}

TARGET=(${1//./ })

OS=${TARGET[0]}
ARCHITECTURE=${TARGET[1]}
BUILD=${TARGET[2]}
shift

if [ -z "$OS" ] || [ -z "$ARCHITECTURE" ] || [ -z "$BUILD" ]
then
    print_usage
    exit 0
else
    echo ""
    echo "OS=$OS"
    echo "ARCHITECTURE=$ARCHITECTURE"
    echo "BUILD=$BUILD"
    echo ""
fi

if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

# libExtension determines extension for dynamic library files
OSName=$(uname -s)
libExtension=
case $OSName in
    Darwin)
        libExtension="dylib"
        ;;
    Linux|NetBSD)
        libExtension="so"
        ;;
    *)
        echo "Unsupported OS $OSName detected, configuring as if for Linux"
        libExtension="so"
        ;;
esac

function create_core_overlay 
{
    if [ -z "$coreClrBinDir" ] || [ ! -d "$coreClrBinDir" ]; then
        echo "ERROR: --coreClrBinDir must be specified & exist."
        exit 1
    fi
    if [ ! -f "$mscorlibDir/mscorlib.dll" ]; then
        echo "ERROR: mscorlib.dll was not found in: $mscorlibDir"
        exit 1
    fi
    if [ -z "$coreFxBinDir" ]; then
        echo "ERROR: --coreFxBinDir must be specified."
        exit 1
    fi
    if [ -z "$coreFxNativeBinDir" ]; then
        echo "ERROR: --coreFxNativeBinDir must be specified."
        exit 1
    fi
    if [ ! -d "$coreFxNativeBinDir/Native" ]; then
        echo "ERROR: Directory specified by --coreNativeFxBinDir does not exist: $coreFxNativeBinDir/Native"
        exit 1
    fi

    # Create the overlay
    if [ -e "$coreOverlayDir" ]; then
        rm -f -r "$coreOverlayDir"
    fi
    mkdir "$coreOverlayDir"

    while IFS=';' read -ra coreFxBinDirectories
    do
        for currDir in "${coreFxBinDirectories[@]}"
        do
            if [ ! -d "$currDir" ]
            then
                echo "ERROR: Directory specified in --coreFxBinDir does not exist: $currDir"
            fi
            pushd $currDir > /dev/null
            for dirName in $(find . -iname '*.dll' \! -iwholename '*test*' \! -iwholename '*/ToolRuntime/*' \! -iwholename '*/RemoteExecutorConsoleApp/*' \! -iwholename '*/net*' \! -iwholename '*aot*' -exec dirname {} \; | uniq | sed 's/\.\/\(.*\)/\1/g')
            do
                #cp -n -v "$currDir/$dirName/$dirName.dll" "$coreOverlayDir/"
                cp -n -v "$dirName/$dirName.dll" "$coreOverlayDir/"
            done
            popd $currDur > /dev/null
        done
    done <<< $coreFxBinDir

    cp -f -v "$coreFxNativeBinDir/Native/"*."$libExtension" "$coreOverlayDir/" 2>/dev/null
    cp -f -v "$coreClrBinDir/"* "$coreOverlayDir/" 2>/dev/null
    #    cp -f -v "$coreClrBinDir/bin/"* "$coreOverlayDir/" 2>/dev/null
    cp -f -v "$mscorlibDir/mscorlib.dll" "$coreOverlayDir/"

    #    cp -n -v "$testDependenciesDir"/* "$coreOverlayDir/" 2>/dev/null
    #    if [ -f "$coreOverlayDir/mscorlib.ni.dll" ]; then
    #        # Test dependencies come from a Windows build, and mscorlib.ni.dll would be the one from Windows
    #        rm -f "$coreOverlayDir/mscorlib.ni.dll"
    #    fi
}

function precompile_overlay_assemblies 
{
    filesToPrecompile=$(ls -trh $overlayDir/*.dll)
    for fileToPrecompile in ${filesToPrecompile}
    do
        local filename=${fileToPrecompile}
        # Precompile any assembly except mscorlib since we already have its NI image available.
        if [[ "$filename" != *"mscorlib.dll"* ]]; then
            if [[ "$filename" != *"mscorlib.ni.dll"* ]]; then
                echo Precompiling $filename
                $overlayDir/crossgen /Platform_Assemblies_Paths $overlayDir $filename 2>/dev/null
                local exitCode=$?
                if [ $exitCode == -2146230517 ]; then
                    echo $filename is not a managed assembly.
                elif [ $exitCode != 0 ]; then
                    echo Unable to precompile $filename.
                else
                    echo Successfully precompiled $filename
                fi
            fi
        fi
    done
}

coreOverlayDir="${BASE_PATH}/dotnet-overlay-${OS}.${ARCHITECTURE}.${BUILD}"
coreClrBinDir="coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}"
mscorlibDir="coreclr/bin/Product/${OS}.${ARCHITECTURE}.${BUILD}"
coreFxBinDir="corefx/bin/${OS}.${ARCHITECTURE}.${BUILD};corefx/bin/${OS}.AnyCPU.${BUILD};corefx/bin/Unix.AnyCPU.${BUILD};corefx/bin/AnyOS.AnyCPU.${BUILD};"
coreFxNativeBinDir="corefx/bin/${OS}.${ARCHITECTURE}.${BUILD}"

for i in "$@"
do
    case $i in
        -h|--help)
            print_usage
            exit 0
            ;;
        --crossgen)
            precompile_overlay_assemblies 
            exit 0;
            ;;
        --coreClrBinDir=*)
            coreClrBinDir=${i#*=}
            ;;
        --mscorlibDir=*)
            mscorlibDir=${i#*=}
            ;;
        --coreFxBinDir=*)
            coreFxBinDir=${i#*=}
            ;;
        --coreFxNativeBinDir=*)
            coreFxNativeBinDir=${i#*=}
            ;;
        *)
            print_usage
            exit 0
            ;;
    esac
done

if [ -z "$mscorlibDir" ]; then
    mscorlibDir=$coreClrBinDir
fi

create_core_overlay

exit 0
