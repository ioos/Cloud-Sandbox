buckets='
'

declare -a projects

projects=(
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

 
