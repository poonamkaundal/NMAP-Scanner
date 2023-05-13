path="$(pwd)"
TODAY_DATE="$(/bin/date +"%m-%d-%Y")"
Env=$1

echo $TODAY_DATE
/bin/mkdir -p "$path/S3/Result/nmap/$Env/$TODAY_DATE/results"

#Copy report to current days results dir
/bin/cp -avr $path/HTMLFiles/$TODAY_DATE/*.html $path/S3/Result/nmap/$Env/$TODAY_DATE/results
/bin/echo "reports copied along with html report"

/bin/sleep 3
  aws s3 sync $path/S3/Result/nmap/$Env/$TODAY_DATE s3://ph-qa-automation-results/security-automation-results/API_Security/$Env/NMAP/$TODAY_DATE
echo "results uploaded to s3"
