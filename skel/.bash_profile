# notify user login event
if [ -x ~/bin/vps-login-notifier.py ]; then
    ~/bin/vps-login-notifier.py
fi
# import all setting from .bashrc
if [ -r ~/.bashrc ]; then
    . ~/.bashrc
fi
