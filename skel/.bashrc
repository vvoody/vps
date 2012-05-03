# main bash configurations
if [ -r ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

echo $PATH | grep -q "~/bin"
if [ $? -ne 0 ]; then
    export PATH="$PATH:~/bin"
fi

if [ -r ~/bin/core-functions.sh ]; then
    . ~/bin/core-functions.sh
fi
