#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin #path i added idk if it did anything but better leave it here or maybe everything explodes
/usr/bin/salt-call --local state.apply sync 2>&1 >> /tmp/salt_cron_debug.txt #Runs sync/init.sls and puts the output in /tmp/salt_cron_debug.txt
echo "test1" >> /tmp/web3_test_file.txt #Debug option i used, can be deleted.
