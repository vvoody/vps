# notify user login event
if [ -x ~/bin/vps-login-notifier.py ]; then
    ~/bin/vps-login-notifier.py ~/.vps-login-notifier.conf.json
fi
# import all setting from .bashrc
if [ -r ~/.bashrc ]; then
    . ~/.bashrc
fi
