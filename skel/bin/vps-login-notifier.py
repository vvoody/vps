#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This is a notifier program which sends email to admin when
# anybody logins to your remote machine via SSH.
#
# Requirements:
# - Python(of course);
# - An email account which has enabled SMTP(recommend Gmail);
# - A remote machine like VPS;
#
# Usage:
# put following instructions to ~/.bash_profile (if you use bash):
#
#     if [ -r vps-login-notifier.py]; then
#         python vps-login-notifier.python
#     fi
#
# Then you will receive an email when anybody logins to your site.
# The default log file is at /tmp/vps-login-notifier.log

import os
import sys

# An example setting for Gmail
me = {"LOGIN": "blablabla@gmail.com",
      "PASSWD": "cptbtptpbcptdtptp",
      "SMTP": "smtp.gmail.com:587",
      "SSL": True}
toaddrs = ["yadayadayada@gmail.com"]
logfile = '/tmp/vps-login-notifier.log'
# setting end.

def make_msg(fromaddr, toaddrs, subject, body):
    msg = ("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s" %
           (fromaddr, ", ".join(toaddrs), subject, body))
    return msg

def mail(fromaddr, toaddrs, msg):
    global me

    server = smtplib.SMTP(me['SMTP'])
    if me['SSL']: server.starttls()
    server.login(me['LOGIN'], me['PASSWD'])
    server.sendmail(fromaddr, toaddrs, msg)
    server.quit()

def get_ssh_login_info():
    return os.environ['SSH_CONNECTION'] if 'SSH_CONNECTION' in os.environ else 'No any ssh connection info found!'

if __name__ == "__main__":
    try:
        pid = os.fork()
        if pid > 0:
            print "Welcome aboard."
            sys.exit(0)
    except OSError, e:
        print >> sys.stderr, "fork #1 failed: %d (%s)" % (e.errno, e.strerror)
        sys.exit(1)

    import smtplib
    import logging
    logging.basicConfig(filename=logfile,
                        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                        level=logging.INFO)

    ssh_info = get_ssh_login_info()
    login_ip = ssh_info.split()[0]
    msg_body = "%s\nhttp://www.ip138.com/ips.asp?ip=%s&action=2" % (ssh_info, login_ip)
    msg = make_msg(me['LOGIN'],
                   toaddrs,
                   'VPS Login Notification',
                   msg_body)

    try:
        mail(me['LOGIN'], toaddrs, msg)
    except Exception, e:
        logging.error(e)
    else:
        logging.info('login notification email sent OK.')
