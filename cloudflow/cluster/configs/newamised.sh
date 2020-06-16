#!/bin/bash

newami='ami-0b1f32f8427ff563e'
oldami='ami-0da0626fd586c935c'


#for file in `ls -1 *ofs.config`
for file in `ls -1 *.config`
do
  echo $file
  sed -i "s/$oldami/$newami/g" $file
done

