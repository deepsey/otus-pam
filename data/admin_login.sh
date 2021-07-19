#!/bin/bash

if [ $(date +%u) -eq 6 -o $(date +%u) -eq 7 ]; then
  id -nG "$PAM_USER" | grep -qw admin
  return_code=$?
  if [ $return_code -eq 0 ]; then
     exit 0
    else
     exit 1
  fi
else
  exit 0
fi
