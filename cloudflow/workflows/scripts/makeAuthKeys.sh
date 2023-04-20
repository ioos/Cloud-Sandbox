#!/bin/bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


key=""

hostprint=""

#"ip-10-0-0-14.ec2.internal,10.0.0.14"

iplist="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"


for ip in $iplist
do
  #mach="centos@ip-10-0-0-${ip}.ec2.internal"
  #echo "$key $mach" >> ~/.ssh/authorized_keys

  host="ip-10-0-0-${ip}.ec2.internal,10.0.0.${ip}"
  echo "$host $hostprint" >> ~/.ssh/known_hosts
done

