#!/bin/bash

trap 'echo signal is 1' 1
trap 'echo signal is 2' 2
trap 'echo signal is 9' 9
trap 'echo signal is 15' 15
trap 'echo signal is 29' 29

read in

echo "\$in  is $in"

