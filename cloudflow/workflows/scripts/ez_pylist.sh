
list='
  c5.large,1
  c5.xlarge,2
  c5.2xlarge,4
  c5.4xlarge,8
  c5.9xlarge,18
  c5.18xlarge,36
  c5.24xlarge,48
  c5.metal,36
  c5n.large,1
  c5n.xlarge,2
  c5n.2xlarge,4
  c5n.4xlarge,8
  c5n.9xlarge,18
  c5n.18xlarge,36
  c5n.24xlarge,48
  c5n.metal,36
  t3.large,2
  t3.xlarge,4
  t3.2xlarge,8
'

for line in $list
do
  key=`echo $line | awk -F, '{print $1}'`
  val=`echo $line | awk -F, '{print $2}'`
  echo -n "'$key':$val, "
done
