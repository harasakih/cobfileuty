#!/bin/sh

/bin/echo -n "continue Y/N :"
read DMY
if [ "$DMY" = "Y" -o "$DMY" = "y" ] ; then
	exit 0
else
	exit 1
fi
