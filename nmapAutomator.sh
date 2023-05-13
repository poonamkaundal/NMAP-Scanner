#!/bin/sh
#by @21y4d

# Define ANSI color variables
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
origIFS="${IFS}"

TODAY="$(date +"%m-%d-%Y")"
CURRENTDIR=${PWD}

# Start timer
elapsedStart="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"
REMOTE=false

# Parse flags
while [ $# -gt 0 ]; do
        key="$1"

        case "${key}" in
        -H | --host)
                HOST="$2"
                shift
                shift
                ;;
        -t | --type)
                TYPE="$2"
                shift
                shift
                ;;
        -d | --dns)
                DNS="$2"
                shift
                shift
                ;;
        -o | --output)
                OUTPUTDIR="$2"
                shift
                shift
                ;;
        -s | --static-nmap)
                NMAPPATH="$2"
                shift
                shift
                ;;
        -r | --remote)
                REMOTE=true
                shift
                ;;
        *)
                POSITIONAL="${POSITIONAL} $1"
                shift
                ;;
        esac
done
set -- ${POSITIONAL}


# Legacy flags support, if run without -H/-t
if [ -z "${HOST}" ]; then
        HOST="$1"
fi

if [ -z "${TYPE}" ]; then
        TYPE="$2"
fi

# Legacy types support, if quick/basic used
if expr "${TYPE}" : '^\([Qq]uick\)$' >/dev/null; then
        TYPE="Port"
elif expr "${TYPE}" : '^\([Bb]asic\)$' >/dev/null; then
        TYPE="Script"
fi

# Set DNS or default to system DNS
if [ -n "${DNS}" ]; then
        DNSSERVER="${DNS}"
        DNSSTRING="--dns-server=${DNSSERVER}"
else
        DNSSERVER="$(grep 'nameserver' /etc/resolv.conf | grep -v '#' | head -n 1 | awk {'print $NF'})"
        DNSSTRING="--system-dns"
fi

# Set output dir or default to host-based dir
if [ -z "${OUTPUTDIR}" ]; then
        OUTPUTDIR="${HOST}"
fi



# Nmap scan on all ports
fullScan() {
        printf "${GREEN}---------------------Starting Full Scan------------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                sudo nmap --script vuln --open -sV -O --osscan-limit -R -sS -T4 -Pn -oX ${TODAY}/Full_${HOST}.xml ${HOST}

               # Nmap version and default script scan on found ports if Script scan was not run yet
                sudo nmap -sCV --open -oX ${TODAY}/Full_Extra_${HOST}.xml ${HOST}

        else
                printf "${YELLOW}Full Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/Full_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/Full_${HOST}_report.html"
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/Full_Extra_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/Full_Extra_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}



# Nmap vulnerability detection script scan
vulnsScan() {
        printf "${GREEN}---------------------Starting Vulns Scan-----------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                # Ensure the vulners script is available, then run it with nmap
                if [ ! -f /usr/local/share/nmap/scripts/vulners.nse ]; then
                        printf "${RED}Please install 'vulners.nse' nmap script:\n"
                        printf "${RED}https://github.com/vulnersCom/nmap-vulners\n"
                        printf "${RED}\n"
                        printf "${RED}Skipping CVE scan!\n"
                        printf "${NC}\n"
                else
                        printf "${YELLOW}Running CVE scan on all ports\n"
                        printf "${NC}\n"
                        nmap -sV --script vulners --script-args mincvss=7.0 --open -oX ${TODAY}/vulns_${HOST}.xml ${HOST}
                        echo
                fi

                # Nmap vulnerability detection script scan
                echo
        fi

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/vulns_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/vulns_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}

# Nmap scan for live hosts
networkScan() {
        printf "${GREEN}---------------------Starting Network Scan---------------------\n"
        printf "${NC}\n"

        origHOST="${HOST}"
        HOST="${urlIP:-$HOST}"
        if [ $kernel = "Linux" ]; then TW="W"; else TW="t"; fi

        if ! $REMOTE; then
                # Discover live hosts with nmap
                nmap -T4 --max-retries 1 --max-scan-delay 20 -n -sn -oX ${TODAY}/Network_${HOST}.xml ${subnet}/24
                printf "${YELLOW}Found the following live hosts:${NC}\n\n"
                cat ${TODAY}/Network_${HOST}.nmap | grep -v '#' | grep "$(echo $subnet | sed 's/..$//')" | awk {'print $5'}
        elif $pingable; then
                # Discover live hosts with ping
                echo >"${TODAY}/Network_${HOST}.xml"
                for ip in $(seq 0 254); do
                        (ping -c 1 -${TW} 1 "$(echo $subnet | sed 's/..$//').$ip" 2>/dev/null | grep 'stat' -A1 | xargs | grep -v ', 0.*received' | awk {'print $2'} >>"nmap/${TODAY}/Network_${HOST}.xml") &
                done
                wait
                sed -i '/^$/d' "${TODAY}/Network_${HOST}.xml"
                sort -t . -k 3,3n -k 4,4n "${TODAY}/Network_${HOST}.xml"
        else
                printf "${YELLOW}No ping detected.. TCP Network Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        HOST="${origHOST}"

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/Network_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/Network_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}


HSTSPolicy(){
        printf "${GREEN}----------------------Starting HSTS Policy Scan------------------------\n"
        printf "${NC}\n"
        nmap --script $WORKSPACE/nmap/scripts/http-security-headers.nse -oX ${TODAY}/HSTSPolicy_${HOST}.xml ${HOST}

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/HSTSPolicy_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/HSTSPolicy_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}


WeakCiphers(){
        printf "${GREEN}----------------------Starting ssl-enum-ciphers  Scan------------------------\n"
        printf "${NC}\n"
        nmap -sV --script ssl-enum-ciphers -oX ${TODAY}/WeakCiphers_${HOST}.xml ${HOST}

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/WeakCiphers_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/WeakCiphers_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}


VersionDetection(){
        printf "${GREEN}----------------------Starting version  Scan------------------------\n"
        printf "${NC}\n"
        nmap -sV --script="version,discovery" -oX ${TODAY}/Version_${HOST}.xml ${HOST}

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/Version_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/Version_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}


# Nmap UDP scan
UDPScan() {
        printf "${GREEN}----------------------Starting UDP Scan------------------------\n"
        printf "${NC}\n"

        sudo nmap -sUV -T4 -F --version-intensity 0 -oX ${TODAY}/UDPScan_${HOST}.xml ${HOST}

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/UDPScan_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/UDPScan_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}



# Port Nmap port scan
portScan() {
        printf "${GREEN}---------------------Starting Port Scan-----------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                nmap -T4 --max-retries 1 --max-scan-delay 20 --open -oX ${TODAY}/Port_${HOST}.xml ${HOST}
        else
                printf "${YELLOW}Port Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        echo

        # Convert the result XML file into HTML file
        cd ${CURRENTDIR}/HTMLFiles
        mkdir -p ${TODAY}
        xsltproc ${CURRENTDIR}/${OUTPUTDIR}/nmap/${TODAY}/Port_${HOST}.xml -o "${CURRENTDIR}/HTMLFiles/${TODAY}/Port_${HOST}_report.html"

        cd ${CURRENTDIR}/HTMLFiles/${TODAY}/
        # Give proper permissions to be web-viewable
        chmod 775 ${CURRENTDIR}/HTMLFiles/${TODAY}/*
        cd $CURRENTDIR/${OUTPUTDIR}/nmap
}



# Print usage menu and exit. Used when issues are encountered
# No args needed
usage() {
        echo
        printf "${RED}Usage: $(basename $0) -H/--host ${NC}<TARGET-IP>${RED} -t/--type ${NC}<TYPE>${RED}\n"
        printf "${YELLOW}Optional: [-r/--remote ${NC}<REMOTE MODE>${YELLOW}] [-d/--dns ${NC}<DNS SERVER>${YELLOW}] [-o/--output ${NC}<OUTPUT DIRECTORY>${YELLOW}] [-s/--static-nmap ${NC}<STATIC NMAP PATH>${YELLOW}]\n\n"
        printf "Scan Types:\n"
        printf "${YELLOW}\tNetwork : ${NC}Shows all live hosts in the host's network ${YELLOW}(~15 seconds)\n"
        printf "${YELLOW}\tPort    : ${NC}Shows all open ports ${YELLOW}(~15 seconds)\n"
        printf "${YELLOW}\tScript  : ${NC}Runs a script scan on found ports ${YELLOW}(~5 minutes)\n"
        printf "${YELLOW}\tVersionDetection  : ${NC}Finds the version${YELLOW}(~5 minutes)\n"
        printf "${YELLOW}\tFull    : ${NC}Runs a full range port scan, then runs a script scan on new ports ${YELLOW}(~5-10 minutes)\n"
        printf "${YELLOW}\tUDP     : ${NC}Runs a UDP scan \"requires sudo\" ${YELLOW}(~5 minutes)\n"
        printf "${YELLOW}\tVulns   : ${NC}Runs CVE scan and nmap Vulns scan on all found ports ${YELLOW}(~5-15 minutes)\n"
        printf "${YELLOW}\tWeakCiphers   : ${NC}Runs WeakCiphers scan and nmap ${YELLOW}(~5-15 minutes)\n"
        printf "${YELLOW}\tHsts   : ${NC}Runs HSTS scan and nmap ${YELLOW}(~5-15 minutes)\n"
        printf "${YELLOW}\tAll     : ${NC}Runs all the scans ${YELLOW}(~20-30 minutes)\n"
        printf "${NC}\n"
        exit 1
}

# Print initial header and set initial variables before scans start
# No args needed
header() {
        echo

        # Print scan type
        if expr "${TYPE}" : '^\([Aa]ll\)$' >/dev/null; then
                printf "${YELLOW}Running all scans on ${NC}${HOST}"
        else
                printf "${YELLOW}Running a ${TYPE} scan on ${NC}${HOST}"
        fi

        if $REMOTE; then
                printf "${YELLOW}Running in Remote mode! Some scans will be limited.\n"
        fi

        # Set $subnet variable
        if expr "${HOST}" : '^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$' >/dev/null; then
                subnet="$(echo "${HOST}" | cut -d "." -f 1,2,3).0"
        fi

        echo
        echo
}

# Print footer with total elapsed time
footer() {

        printf "${GREEN}---------------------Finished all scans------------------------\n"
        printf "${NC}\n\n"

        elapsedEnd="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"
        elapsedSeconds=$((elapsedEnd - elapsedStart))

        if [ ${elapsedSeconds} -gt 3600 ]; then
                hours=$((elapsedSeconds / 3600))
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${YELLOW}Completed in ${hours} hour(s), ${minutes} minute(s) and ${seconds} second(s)\n"
        elif [ ${elapsedSeconds} -gt 60 ]; then
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${YELLOW}Completed in ${minutes} minute(s) and ${seconds} second(s)\n"
        else
                printf "${YELLOW}Completed in ${elapsedSeconds} seconds\n"
        fi
        printf "${NC}\n"
}

# Choose run type based on chosen flags
main() {

     header

     case "${TYPE}" in
        [Hh]sts)
          HSTSPolicy "${HOST}"
          ;;
        [Ww]eakCiphers)
          WeakCiphers "${HOST}"
          ;;
        [Nn]etwork)
              networkScan "${HOST}"
              ;;
        [Pp]ort)
                portScan "${HOST}"
                ;;
        [Vv]ersionDetection)
                VersionDetection "${HOST}"
                ;;
        [Uu]dp)
                UDPScan "${HOST}"
                ;;
        [Vv]ulns)
                vulnsScan "${HOST}"
                ;;
        [Aa]ll)
                portScan "${HOST}"
                fullScan "${HOST}"
                UDPScan "${HOST}"
                vulnsScan "${HOST}"
                WeakCiphers "${HOST}"
                Network "${HOST}"
                VersionDetection "${HOST}"
                ;;
        esac

        footer
}

# Ensure host and type are passed as arguments
if [ -z "${TYPE}" ] || [ -z "${HOST}" ]; then
        usage
fi

# Ensure $HOST is an IP or a URL
if ! expr "${HOST}" : '^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$' >/dev/null && ! expr "${HOST}" : '^\(\([[:alnum:]-]\{1,63\}\.\)*[[:alpha:]]\{2,6\}\)$' >/dev/null; then
        printf "${RED}\n"
        printf "${RED}Invalid IP or URL!\n"
        usage
fi

# Ensure selected scan type is among available choices, then run the selected scan
if ! case "${TYPE}" in [Ww]eakCiphers | [Vv]ersionDetection | [Hh]sts | [Nn]etwork | [Pp]ort | [Ss]cript | [Ff]ull | UDP | udp | [Vv]ulns | [Aa]ll) false ;; esac then
        mkdir -p HTMLFiles/ && mkdir -p "${OUTPUTDIR}" &&  cd "${OUTPUTDIR}" && mkdir -p nmap/ && cd "nmap" && mkdir -p ${TODAY} || usage
        main | tee "nmapAutomator_${HOST}_${TYPE}.txt"
else
        printf "${RED}\n"
        printf "${RED}Invalid Type!\n"
        usage
fi