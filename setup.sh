#!/bin/bash
#simple script to install deps

PIP=pip3

if [ ! -d ./data  ]
	then 
		mkdir ./data
fi

gksudo $PIP install twython
gksudo $PIP install nltk
