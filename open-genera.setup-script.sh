# #!/bin/sh
# The Symbolics Lisp Machine on Linux
#
# Scriptification of:
# http://www.advogato.org/person/johnw/diary/12.html
#
# with bittorrent download links added.


# Out there on the Net somewhere (may Google be with you) there are
# binaries to be found for running a Symbolics Open Genera 2.0 Lisp
# Machine under Linux. I can’t quite tell you where to get these tasty
# binaries, but if you happen to find them, here are the steps you’ll
# need to get everything working. The HOWTOs that I read were a little
# sparse, so I’m hoping this will give a more complete summary of
# what’s needed.  Pick a Linux distribution

# Open Genera can be run on both CentOS 5 and Ubuntu. I recommend
# Ubuntu, since it aims at a better desktop experience (and its X
# server plays nicer with VMware Fusion).

# Ubuntu users will need a few extra tools installed. Just run this
# command:

# Actually you'll need to get the appropriate versions of these.
# Genera is too archaic for the most modern versions.  The safest way
# to do this in Ubuntu is to download the versions dependancies and
# compile and install locally.

# (TODO make sure you don't have a more recent (and therefor
# incompatable) version installed
sudo apt-get install nfs-utils
nfs-kernel-server xinetd
curl http://www.unlambda.com/download/genera/snap4.tar.gz



# I can't offer much help with Red Hat, but this might get you pointed
# in the right direction:

# sudo yum install nfs xinetd

# Turn on the time service Open Genera uses the TCP time service to
# set its clock. For RedHat users this is easy to enable:

# $ sudo chkconfig time on

# For Ubuntu users, you’ll need to 

# Could be dangerous, especiall on later versions.
# sed /etc/xinetd.d/time
# 
# disable = yes
# --> ” 
# disable = yes
# following (ony needed on Ubuntu):
sudo /etc/init.d/xinetd restart


# Now test it for both systems by typing the following: (TODO -- also
# check to make appropiat version or at least feature supported --
# Maybe autoconfig?)
telnet localhost 37

# If you cannot connect to port 37 using TCP, your xinetd is not
# configured correctly. The TCP time service needs to be running and
# available.  

# Create a lispm user

# For the upcoming steps you’re going to need a user named lispm, who
# will own the Open Genera files.  If user 5000 isn't available (you
# should get a warning/error if it's not) you might have some
# problems.  It's possibl open gener expect that to be available. 

sudo adduser -u 5000 -g 5000 lispm

# Don’t forget to set a password for this user. If you intend to never
# login as this user, disable the password entirely:

sudo usermod -L lispm


# You will still be able to start Open Genera as the lispm user, using
# the sudo command (see below).  

# Enable NFS

# Next you’ll need NFSv2 running, which Open Genera will use to access
# and write to its system files. Here’s what I have in my /etc/exports
# file on Ubuntu:

# sudo sed add below
# /       10.0.0.2(rw,all_squash,anonuid=5000,anongid=5000,sync,no_subtree_check)

# For CentOS, it was nearly the same:
# /       10.0.0.2(rw,all_squash,anonuid=5000,anongid=5000)

# Now restart the NFS server. On Ubuntu it’s:

sudo /etc/init.d/nfs-kernel-server start

# On CentOS it’s a bit friendly:
# $ sudo service nfs restart

# You should now be able to type showmount and see something like this:
sudo showmount -e localhost
# Export list for localhost: ????
# / 10.0.0.2

# Open your firewall

# When Open Genera runs, it will create a virtual TUN device to access
# the network stack. It’s very important that you have the tun module
# loaded into your kernel! Type this:

sudo grep CONFIG_TUN= /boot/config-$(uname -r) CONFIG_TUN=m

# This shows that on my system, TUN is a loaded module. I can ensure
# that it’s loaded by typing:

sudo modprobe tun
sudo lsmod | grep tun
# >tun 13824  0

# If your output from the first grep command said “CONFIG_TUN=y”, then
# your TUN module is always loaded.

# Now that we know TUN is avaible, grant full local access to the TUN
# device:

sudo iptables -A INPUT -i tun+ -j ACCEPT

# this will let Open Genera talk to your NFS server and your time
# server.  Letting Open Genera talk to the Internet

# If you want to give your Lisp Machine access to the Internet, add these commands:
# TODO -- Try to get active connection and update that.
sudo iptables -A FORWARD -i tun+ -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1

# If your Internet-connected interface is something other than eth0
# (it might be eth1, ppp0, br0, etc), just change that in the second
# command above.  Turn off SELinux

# In order to run on CentOS, SELinux will have to be disabled. Sorry I
# don’t have steps for how to run with SELinux type enforcement
# active:
# $ sudo setenforce 0

# Change to the lispm user

# For the rest of the commands in this section, make sure that you’ve
# moved the Open Genera source tarballs into the lispm user’s home
# directory. Then type this command:

sudo su - lispm

# After typing in your password to gain sudo access to the su command,
# you will now be the lispm user.  Untar 

* TODO get the actual file names
# tar xvf snap4.tar.gz
# tar xvf opengenera2.tar.gz

# You should have two compressed tarballs in the lispm user’s home
# directory at this point: one called snap4 and one called
# opengenera2. Untar these so you have the following directories:

# /home/lispm/og2       # contains all the opengenera2 files
# /home/lispm/snap4     # contains all the snap4 files

# Make sure that you have a directory now called /home/lispm/og2/sys.sct. This is very important! Go ahead and make a copy of it into snap4:

cp -R og2/sys.sct snap4

# Also, make a symbolic link in snap4 that points back to the whole of
# the og2 directory, named rel-8-5. You’ll need this for the Document
# Browser to work:

ln -s og2 snap/sys.sct

# Now the Open Genera files are in their right places.  Configure
# snap4

# In your snap4 directory there is a file called .VLM. This is not the
# same as dot.VLM! The .VLM file should contain the following lines
# (you can just overwrite your .VLM file with these lines in fact):

# use sed
# genera.network: 10.0.0.2;mask=255.255.255.0;gateway=10.0.0.1
# genera.virtualMemory: 512
# genera.world: MIT.vlod
# genera.debugger: VLM_debugger
# genera.coldLoad.geometry: 800x600

# Feel free to raise or lower the virtualMemory setting. Don’t let it
# exceed the amount of actual memory and swap you have, or else
# genera2 will fail to start due to a failed block allocation.

# You are now ready to run.
# Run Open Genera

# Run Open Genera the first time like this:

~/snap4/genera -w ~/snap4/Genera-8-5.vlod

# It will take some time to load up, and it first starts up a debugger
# window which it then minimizes. But after a while, you should be
# rewarded by a screen that says “Symbolics Open Genera 2.0”.

# The accuracy of these next steps is very important:

# TODO
# The following items should be scripted in lisp
#
#Type 
#
# define site genera-vlm
#
# Make sure there are two spaces in that sentence. Don’t be fooled by
# what the virtual machine is showing you, just hit space where I show
# a space. If you make a mistake, you may have to hit your Delete key
# instead of your Backspace key. If you hit Backspace and it moves
# your cursor, use Control-E to get back to the end of the line.
#
# You will words in italics that say “the name of the primary
# namespace server”. Click on this. Then in its place type “
# 
# genera-vlm
#
# Now you’ll see a bunch of new lines. Above five lines up from the
# bottom will be more italicized words, this time saying, “the name of
# the DEC-AXP host on which Open Genera is running”. Don’t be fooled
# though, it just wants the name of your Linux host. If you call your
# Linux machine “genera" then click on these words and type: 
#
# genera
#
# Another one of the lines now on your screen says “System File
# Directory”, with a long path next to it that starts “HOST”. Click on
# this pathname, and in its place type:
#
# genera:/home/lispm/snap4/sys.sct/site/
#
# You have to put your Linux hostname at the beginning of the string
# (if your hostname is other than “genera”, type it before colon
# instead). It is very important to put a forward slash at the end of
# this string! Hit return when you finish typing the new pathname.
# The next line says “Namespace Descriptor File” with another long
# path. Click on this path and in its place type,
#
# genera:/home/lispm/snap4/sys.sct/site/genera-vlm-namespace.text
# 
#  Then hit return.  You can leave the rest as it is. Click on the
# funny looking “
# 
# End
#
# button at the bottom now. It should take up to 10-20 seconds, but it
# will talk over NFS and create some new files in
#
# ~lispm/sys.sct/site/. 
#
# You can look there on the Linux side for a few files whose names
# begin with “genera-vlm”. 
#
# *** Note: If you ever need to redo this process, you will have to
# delete these files first ***
#
# Save the world
#
# The virtual machine is now ready for use. But to avoid having to do
# all of this every time, it’s easier to save the world as it stands
# so you can reload from this point later. So at the command prompt
# type:
#
# Reset Network
# 
# This takes a few moments, then gives harmless a warning
# message. Once you’ve done that, now save:
#
# Save World<SPACE><SPACE>
#
# By hitting your SPACE bar twice at the end of the Save World
# command, you will be provided with the pathname to your current
# world file. You’ll want to change this. One possibility is to make
# the basename of this file “Genera-8-5-1.vlod”.
#
# After you hit Return, wait a while. It make take up to a full minute
# or so, but then Open Genera should report to you that the world has
# been saved. You can now close the window and kill Open Genera.
# Restart the world
#
# To restart your Lisp Machine from now on, use the following command
# from your own user account:
#
# $ sudo -u lispm ~lispm/snap4/genera -w ~/lispm/snap4/Genera-8-5-1.vlod
#
# You should be rewarded by a functioning Lisp Machine. Just type
# “Login” followed by a return. Give the username “Lisp-Machine”, and
# hit return twice to login anonymously as that user. It will complain
# that it can’t find the home directory for the anonymous user, but
# that’s not a problem.

# You are now at the REPL and can start having some fun! Type F1-? for
# a quick list of places you can go next.

# Syndicated 2007-10-23 10:07:38 from johnw@newartisans.com
