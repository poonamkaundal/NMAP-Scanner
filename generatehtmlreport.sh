#!/bin/bash
ENV=$1
path="$(pwd)"
TODAY_DATE="$(/bin/date +"%m-%d-%Y")"
FILETYPE=$2

rm -rf HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
sleep 1
echo "Generating html file : $path"

echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<html xmlns=\"http://www.w3.org/1999/xhtml\">" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<head>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<title>NMAP Report</title>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<style type=\"text/css\">" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "table {margin-bottom:10px;border-collapse:collapse;empty-cells:show}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "td,th {border:1px solid #009;padding:.25em .5em}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".result th {vertical-align:bottom}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".param th {padding-left:1em;padding-right:1em}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".param td {padding-left:.5em;padding-right:2em}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".stripe td,.stripe th {background-color: #E6EBF9}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".numi,.numi_attn {text-align:right}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".total td {font-weight:bold}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".passedodd td {background-color: #00e600}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".passedeven td {background-color: #80ff80}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".skippedodd td {background-color: #CCC}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".skippedodd td {background-color: #DDD}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".failedodd td,.numi_attn {background-color:  #ffb3b3}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".failedeven td,.stripe .numi_attn {background-color: #ff8080}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".stacktrace {white-space:pre;font-family:monospace}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo ".totop {font-size:85%;text-align:center;border-bottom:2px solid #000}" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</style>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</head>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<body>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<center><img src=\"https://static-qa.peoplehum.com/static_resources/manage-ui/img/ph-logo-black-full.png\" width=\"220\" height=\"60\"></center>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<center>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<h1>NMAP Scan Report</h1>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</center>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<center><table cellspacing=\"0\" cellpadding=\"0\" class=\"testOverview\" style=\"margin-bottom: 10px;border-collapse: collapse;empty-cells: show;\">" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html

echo "<tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<th style=\"border: 1px solid #009;padding: .25em .5em;background-color: #AEB6B6;\">IP Address</th>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<th style=\"border: 1px solid #009;padding: .25em .5em;background-color: #AEB6B6;\">SCAN Policy</th>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "<th style=\"border: 1px solid #009;padding: .25em .5em;background-color: #AEB6B6;\">Scan Report</th>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html

declare -a array=("HSTSPolicy" "Network" "Port" "WeakCiphers" "Full" "UDPScan" "vulns" "Version")

if [ $FILETYPE == "YES" ]
then
  if [ $ENV == "AWSQA" ]
  then
            FILENAME=IPAddressAWSQA.txt
          else
            FILENAME=IPAddress.txt
  fi

  while IFS= read -r IPAddress; do
    echo "$IPAddress"
    for Scan in "${array[@]}"; do
      echo $Scan
      ls $path/HTMLFiles/$TODAY_DATE/${Scan}_$IPAddress"_report.html"
      if [ -f $path/HTMLFiles/$TODAY_DATE/${Scan}_$IPAddress"_report.html" ];
      then
        echo "<tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<th style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><b>$IPAddress</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<td style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><b>$Scan</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<td style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><a href=\"https://ph-qa-automation-results.s3.ap-south-1.amazonaws.com/security-automation-results/API_Security/$ENV/NMAP/$TODAY_DATE/results/${Scan}_$IPAddress"_report.html"\"><b>https://ph-qa-automation-results.s3.ap-south-1.amazonaws.com/security-automation-results/API_Security/$ENV/NMAP/$TODAY_DATE/results/${Scan}_$IPAddress"_report.html"</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
      fi
  echo "</tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html

  done
  done < $FILENAME

else
  IPAddress=$3
  for Scan in "${array[@]}"; do
      #echo $Scan
      #ls $path/HTMLFiles/$TODAY_DATE/${Scan}_$IPAddress"_report.html"
      if [ -f $path/HTMLFiles/$TODAY_DATE/${Scan}_$IPAddress"_report.html" ];
      then
        echo "<tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<th style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><b>$IPAddress</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<td style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><b>$Scan</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
        echo "<td style=\"text-align: left;padding-right: 2em;border: 1px solid #009;padding: .25em .5em;\"><a href=\"https://ph-qa-automation-results.s3.ap-south-1.amazonaws.com/security-automation-results/API_Security/$ENV/NMAP/$TODAY_DATE/results/${Scan}_$IPAddress"_report.html"\"><b>https://ph-qa-automation-results.s3.ap-south-1.amazonaws.com/security-automation-results/API_Security/$ENV/NMAP/$TODAY_DATE/results/${Scan}_$IPAddress"_report.html"</b></a></td>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
      fi
    echo "</tr>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
    done
fi

echo "</table>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</center>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html

echo "<left>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</body>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
echo "</html>" >>HTMLFiles/$TODAY_DATE/MASTER_NMAP_REPORT.html
