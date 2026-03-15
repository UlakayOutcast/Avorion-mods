#!/bin/bash

function convert {
	secname="$1mono.wav"
	
	echo "Converting file $1 to $secname" 
	
	if sox $1 $secname remix 1,2 ; then 
		mv $secname $1
	fi 
}

for file in ./*.wavmono.wav; do 
	rm $file
done 

for file in ./*/*.wavmono.wav; do 
	rm $file
done 

for file in ./*.wav; do 	
	convert $file
done 

for file in ./*/*.wav; do 
	convert $file
done 