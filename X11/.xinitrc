urxvtd -o -q -f
xrdb -merge ~/.config/X11/.Xresources

# This must be at the end of the file because i3 is mean to replace the shell process that gets started after login
exec i3
