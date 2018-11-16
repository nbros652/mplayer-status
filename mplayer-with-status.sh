#!/bin/bash
# mplayer-with-query.sh

# if you're even considering this, you probably also want to control mplayer 
# from another application, so lets make a pipe for that
mplayerCmds="/tmp/mplayerCmds"
mplayerDump="/tmp/mplayerDump"
[ ! -e "$mplayerCmds" ] && mkfifo "$mplayerCmds"
defaultVolume=50

playMediaFile() {
	(mplayer -slave -input file="$mplayerCmds" -volume $defaultVolume "$1" < /dev/null 2> /dev/null & echo "PID: $!") > "$mplayerDump"
}

getPID() {
	if [ -e "$mplayerDump" ]; then
		grep PID: "$mplayerDump" | awk '{print $2}'
	else
		echo "mplayer not started!" >&2
	fi
}

searchDump() {
	tr [:cntrl:] '\n' < "$mplayerDump" | grep -oP "$1"
}

getMediaFileName() {
	searchDump "Playing .+[^.]" | sed 's/Playing //' | tail -n1
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
getElapsedTimestamp() {
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
		retval="100"
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
# there is a near zero probability that this function returns a false positive. For 
# it to be incorrect, a new mplayer instance would need to be created without 
# my playMediaFile function, AND that instance would have to be assigned the
#same PID as the last terminated instance of mplayer that was started with the
#playMediaFile function.
isFinishedPlaying() {
	[[ $(pidof mplayer) =~ $(getPID) ]] && return 1 || return 0
}