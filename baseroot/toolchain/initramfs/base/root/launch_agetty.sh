
# Quick example to launch agetty
# it is needed to be able to connect with 'dropbearmulti dbclient'
exec setsid /sbin/agetty -L tty1 115200 vt100
