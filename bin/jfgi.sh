#! /bin/sh

printf "\033]0;jfgi\a"
exec $(dirname $0)/jfgi
