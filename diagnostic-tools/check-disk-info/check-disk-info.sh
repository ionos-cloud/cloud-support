#!/bin/bash

# Author: Dominik Bronischewski based on the script by Georg Schieche-Dirik
# Contact: dominik.bronischewski@ionos.com
# Organization: Ionos SE
# License: GPL3

# This script aims to help you collect basic system information about disk space,
# file systems, and disk partitioning on a Linux VM/system.
# It should be usable for any Linux installation.

function ShowHelp {
    if [[ $LANG =~ de ]] ; then
        echo
        echo "Anwendung:"
        echo
        echo "$0 [-p|--pause [Anhalten zwischen den einzelnen Kommandos]]"
        echo "[-h|--help [Anzeigen dieser Hilfe]]"
        echo
        echo "Die Option -p hält den Programmablauf an, damit die Ausgabe mittels Screenshot festgehalten werden kann."
        echo
    else 
        echo
        echo "Usage:"
        echo
        echo "$0 [-p|--pause [pause after each cammand execution]]" 
        echo "[-h|--help [print this help message]]"
        echo
        echo "The pause option -p pauses the command execution for taking screenshots" 
        echo "of each console output one after another."
        echo
    fi
}

ResultFile=/tmp/disk_support_$(hostname)_$(date +%s).log

while test $# -gt 0 ; do
    case "$1" in
        -p|--pause) 
            Pause="echo 'Please press Enter to continue' ; read";
            shift ;;
        -h|--help)
            ShowHelp;
            exit ;; 
        *) ShowHelp;
            exit 2 ;;
    esac
done

function CommandListDisk {
    CommandList=(
        "date"
        "uname -a"
        "cat /etc/os-release"
        
        "df -hT"
        "df -i"
        "mount"
        
        "lsblk -a"
        "fdisk -l"
        "parted -l"
        "cat /proc/partitions"
        
        "cat /proc/mdstat"
        
        "for d in /dev/[sv]d[a-z]; do echo "=== $d ===" ; if which smartctl > /dev/null; then smartctl -H $d ; else echo 'smartctl not installed. Skipping SMART check.'; break; fi ; done"
        
        "cat /etc/fstab"
    )
}

function CheckDiskInfo {
    CommandListDisk
    for i in $(seq 0 $((${#CommandList[*]}-1))) ; do 
        TopLine=$(echo ${CommandList[$i]} | tr '[:print:]' '=')
        echo
        echo "========${TopLine}========"
        echo "======= ${CommandList[$i]} ======= "
        echo
        eval ${CommandList[$i]} 
        ExitCode=$?
        
        if [ $ExitCode -ne 0 ]; then
             echo "--- PREVIOUS COMMAND terminated with error code $ExitCode (ignored because not all tools need to be present) ---"
        fi

        echo
        eval $Pause
    done
}

CheckDiskInfo 2>&1 | tee -a $ResultFile

echo 

if [[ $LANG =~ de ]] ; then
    echo "Die Festplatten- und Dateisysteminformationen wurden in der Datei ${ResultFile} gesammelt."
    echo "Wenn Sie ein Supportticket eröffnen möchten, senden Sie bitte eine E-Mail an support@cloud.ionos.com"
    echo "und hängen Sie die Datei ${ResultFile} oder Screenshots der Kommandoausgaben an die E-Mail."
else 
    echo "Disk and filesystem information has been collected in the file ${ResultFile}."
    echo "If you would like to open a ticket for the IONOS cloud support, please write an e-mail to support@cloud.ionos.com"
    echo "and attach the file ${ResultFile} or the screenshots of the command output to it."
fi

echo