#!/usr/bin/python

from subprocess import call
import sys

callback_name = sys.argv[1]
current_role = sys.argv[2]

with open('/home/postgres/notification.sh', 'rb') as file:
    script = file.read()
rc = call([script, current_role, callback_name], shell=True)