##!/bin/bash



echo "Provide a number as input :"

read n



arr[0]=2

x=${#arr[@]}



for (( i=3; i<$n; i++ ))

do

for (( j=0; j<$x; j++ ))

do

if [ `expr $i % ${arr[j]}` -eq 0 ]; then break; fi

y=`expr $j + 1`

if [ $y -eq $x ]; then arr=("${arr[@]}" "$i"); ((x++)); fi

done

done



echo "Printing number of elements in array:"

echo ${#arr[@]}

echo "Printing elements in array:"

echo ${arr[@]}
