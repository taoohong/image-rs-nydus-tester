#!/bin/sh

list=("first" "second" "third")
test() {
	for var in ${list[@]}
	do
		echo $var
	done

	for (( i=0; i<${#list[@]}; i++ ))
	do
		echo ${list[i]}/2
	done

}

test
