#!/bin/sh
##################################################################
# remotebashrc.sh
# Created by: Justyn Shull <justyn@justynshull.com>
# Modified by: Gaurav Ghimire 
# For Updates, visit: http://www.justynshull.com/projects/remotebashrc.html
# Last Updated: 12/01/2009

# Usage: remotebashrc user port host
# ex: ./remotebashrc.sh root 22 10.0.0.2
# I have these aliases in my .bashrc:
# alias mst='~/remotebashrc.sh root 10222';
# alias root='~/remotebashrc.sh root 22';

##TODO
# get this script converted from svn to git and working
# random_file doesn't always work. $RANDOM returns nothing some times.
# check to see if it's a freebsd box before trying to ssh in.. /bin/bash doesn't seem to be installed by default
#[ $# = 0 ] && { sed -n -e '/^# Usage:/,/^$/ s/^# \?//p' < $0; exit; }
#debug=1 # debug on, to disable comment it out
ruser=$1
rport=$2
rhost=$3
# base bashrc file. Make your changes here
base_bashrc=~/.ssh/bashrc-remote
# making a copy of the base bashrc file, so the randomfile details could be appended 
bashrc_remote=/tmp/bashrc_remote.$rhost
cp $base_bashrc $bashrc_remote
# random_file, used openssl to generate more random characters
random_file=/tmp/rshrc-`date +%d%m%g%H%M%S`.`/usr/bin/openssl rand -base64 10 | awk -F= '{print $1}'`
# Appended random file details to the bashrc_remote to be uploaded to remote server
# The attached "rm $file" would remove the bashrc_remote file just after bash is spawned
# This is done so, because in case of network disconnects and when you don't get to logout
# the bashrc_remote file would still stay on the remote server, I did not want it happen as such
echo "\nrandom_file=$random_file\nrm -f $random_file" >> $bashrc_remote
f_debug() { [ $debug ] && echo "$1" && echo "hello"; }
f_debug "initiating master connection.."
#SSH in on server, my SSH ~/.ssh/config already has below in it, you might want to add in yours
# ControlMaster auto
# ControlPath ~/.ssh/ssh_master-%r_%h_%p
ssh -Nfn $ruser@$rhost -p $rport
f_debug "uploading $random_file to remote server..."
#scp using the same stream, mode changed to be quiet
scp -qo ControlPath=~/.ssh/ssh_master-%r_%h_%p -P $rport $bashrc_remote $ruser@$rhost:$random_file
# remove local copy of the bashrc_remote
f_debug "removing temp bashrc_remote"
rm -f $bashrc_remote
f_debug "Using --rcfile to have bashrc-remote automatically sourced"
ssh -t -S ~/.ssh/ssh_master-%r_%h_%p $ruser@$rhost -p $rport "bash --rcfile $random_file"
f_debug "shell's closed.. sending exit signal to ssh_master connection"
ssh -vO exit -S ~/.ssh/ssh_master-%r_%h_%p $ruser@$rhost -p $rport