#!/usr/bin/env bash

aws ec2 describe-images \
  --owners self \
  --filters "Name=name,Values=*" \
  --query "Images | sort_by(@, &CreationDate) | reverse(@) | [].{ID:ImageId, Name:Name, Created:CreationDate}" \
  --output table

