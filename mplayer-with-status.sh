#!/bin/bash
# mplayer-with-query.sh

# if you're even considering this, you probably also want to control mplayer 
# from another application, so lets make a pipe for that
mplayerCmds="/tmp/mplayerCmds"
mplayerDump="/tmp/mplayerDump"
[ ! -e "$mplayerCmds" ] && mkfifo "$mplayerCmds"
defaultVolume=50

playMediaFile() {
	mplayer -slave -input file="$mplayerCmds" -volume $defaultVolume "$1" 2> /dev/null | tee "$mplayerDump"
}

searchDump() {
	tr [:cntrl:] '\n' < "$mplayerDump" | grep -oP "$1"
}

getMediaFileName() {
	searchDump "Playing .+[^.]" | sed 's/Playing //'
}

# get information about the codecs playing everything
getCodecInfo() {
	searchDump ".*codec.*"
}

# get a string with playback time information
getPlaybackPos() {
	searchDump "A: +\d+\.\d.+" | tail -n1
}

# get the total elapsed seconds
getElapsedSeconds() {
	getPlaybackPos | awk '{print $2}'
}

# get the timestamp for the current playback position
getPlaybackTimestamp() {
	getPlaybackPos | awk '{print $3}' | tr -d '()'
}

# get the current volume level
getVolume() {
	vol=$(searchDump "Volume: .+")
	if [ -z "$vol" ]; then
		retval="${defaultVolume}%"
	else
		retval=$(tail -n1 <<< "$vol" | awk '{print $2$3}')
	fi
	echo $retval
}

# get the current playback speed as a percentage
getSpeed() {
	speed=$(searchDump "Speed: .+")
	if [ -z "$speed" ]; then
		retval="100%"
	else
		curSpeed=$(tail -n1 <<< "$speed" | awk '{print $3}')
		retval=$(bc <<< "$curSpeed * 100")
	fi
	echo $retval
}

# this function evaluates as a boolean
isMuted() {
	mute=$(searchDump "Mute: .+" | tail -n1 | awk '{print $2}')
	if [ "$mute" == "enabled" ]; then
		return 0
	else
		return 1
	fi
}

# this function evaluates as a boolean
isPaused() {
	searchDump ".+" | tail -n2 | grep -q "PAUSE" && return 0 || return 1
}

# this function evaluates as a boolean
isFinishedPlaying() {
	searchDump "Exiting..." > /dev/null && return 0 || return 1
}