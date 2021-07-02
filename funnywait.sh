#!/bin/sh

# MIT License
# 
# Copyright (c) 2021 Mateusz Piwek
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 

COMMAND=$2
COMMENT=$1
WAIT_ARG=$3

# waiting time counter initiated with a default value
_WAIT_TIME=30

_FW_EXEC_NAME=$(basename $0)
_THISINSTANCE_PID=$$
_FW_PID=$(pgrep $_FW_EXEC_NAME | head -n 1)

if [ $# -eq 1 ] && [ $1 = 'status' ]; then 
	if [ $_FW_PID -ne $_THISINSTANCE_PID ]; then
		echo "$_FW_EXEC_NAME is running: "
		echo $(pgrep -a $_FW_EXEC_NAME | head -n 1)
	else
		echo "No $_FW_EXEC_NAME instance"
	fi

	exit 0
fi

if [ $# -eq 1 ] && [ $1 = 'break' ]; then
	echo  -n 'Breaking counting ... pid: '

	# make sure we don't kill ourslf
	if [ $_FW_PID -ne $_THISINSTANCE_PID ]; then
		echo $_FW_PID
		kill -9 $_FW_PID
	fi
	exit 0
fi


if [ $# -lt 2 ]; then
	echo "Usage: $0 'COMMENT' 'COMMAND ARG1, ARG2 ...' [wait time in sec.: 4 - 2592000]"
	echo "e.g.: $0 'Play Chopin' 'timidity /home/media/midi/mazrka08.mid' 74"
	echo "      $0 status - funnywait status"
	echo "      $0 break - to stop counting process"

	exit 1
fi

if [ $_FW_PID -ne $_THISINSTANCE_PID ]; then 
	echo "Looks like FUNNYWAIT is already launched, use break option to stop it: ";
	echo "    $0 break"
	exit 1
fi


IS_VALID_WAIT_TIME=$(echo $WAIT_ARG | egrep -q "^[0-9]+$" && \
	expr $WAIT_ARG ">" 3 "&" $WAIT_ARG "<" 2592001 | cat ||
	echo "0" )

if [ $IS_VALID_WAIT_TIME -eq "1" ]; then
	_WAIT_TIME=$WAIT_ARG
fi

_SEG_MARK=$([ $_WAIT_TIME -lt 64 ] && echo 64 || echo 128 );

echo -n "Launching '$COMMENT' in (sec.): "

_TICK=0


for _TMSQ in $(seq $_WAIT_TIME -0.25 1.25); do
	_FRACTION=$(expr $_TICK "%" $_SEG_MARK)

	if [ $_FRACTION -lt 1 ]; then
		echo -n "$_TMSQ  "
	elif [ $_FRACTION -lt 2 ]; then
		echo -n $_TMSQ
	elif [ $_FRACTION -lt 3 ]; then
		echo -n "."
	elif [ $_FRACTION -lt 4 ]; then
		echo -n ".. "
	fi

	_TICK=$(expr $_TICK + 1)

	sleep 0.25
done;

echo "now."
sleep 0.25

/bin/sh -c "$COMMAND"
