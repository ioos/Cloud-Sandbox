buckets='
apptio-eds-108193140983
eds-master
eds-snowball
edsapilogs
hycomglobal
radials
rpsgfs
'

declare -a projects

projects=(
EDS
EDS
EDS
EDS
EDS
EDS/OTT-RADIALS
EDS
)

index=0

for bucket in $buckets
do

  project=${projects[$index]}
  #echo "bucket: $bucket  Project: $project"

  key=$bucket
  val=$project

  echo "'$key':'$val', \\"
  ((index += 1))
done

 
