#!/bin/bash

#newami='ami-0b1f32f8427ff563e'
#oldami='ami-0da0626fd586c935c'

#oldami='ami-0b1f32f8427ff563e'
#newami='ami-0f3150c0c20b4cf29'
oldami='ami-0f3150c0c20b4cf29'
newami='ami-052f3e9220b9961dc'

for file in `ls -1 *.config`
do
  echo $file
  sed -i "s/$oldami/$newami/g" $file
done

