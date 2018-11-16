# mplayer-status
This script came about because I had a need to be able to query mplayer for various playback information. It can be used to query mplayer for the following information:
 - mplayer process id (PID)
 - media file name
 - codec information
 - playback time (seconds elapsed or timestamp)
 - playback speed (as percentage)
 - volume level (as integer 0-100)
 - pause status
 - mute status
 - running status of mplayer (pauses or playing, is mplayer running with the media loaded)
 
Usage
-----
By default, the player starts with volume at 50%. This default can be changed by editing my script and changing the value for the `defaultVolume` variable.

To utilize this script, pull it into another bash script by running `eval $(cat /path/to/mplayer-with-status.sh)`. Then when you play a file from your main script, use the `playMediaFile` function to start mplayer.

Once playback of a media file has been started *using the `playMediaFile` function*, mplayer can be queried by issuing any of the following commands:
 - `getPID`
 - `getMediaFileName`
 - `getCodecInfo`
 - `getPlaybackTimestamp`
 - `getElapsedSeconds`
 - `getSpeed`
 - `getVolume`
 - `isPaused`
 - `isMuted`
 - `isFinishedPlaying`
 
 All of the functions that begin with `get` return a value. Functions that begin with `is` are intended to be executed as conditions (e.g. `if isPaused` or `if ! isMuted` or `isMuted && do something`).
