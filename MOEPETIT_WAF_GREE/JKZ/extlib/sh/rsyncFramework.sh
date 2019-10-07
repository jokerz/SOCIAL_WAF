#!/bin/sh

#########################
# @desc		BackUp this Framework by rsync Program
#			JKZ
#			cms.up-stair.jp
#			hp01.1mp.jp
#			homepage.1mp.jp
#			omp.1mp.jp
#			To Server uptsr030
# @author	Ryo Iwahaes
# @create	2008/10/27
########################


rsync -auvz -e "ssh -i /home/vhosts/.ssh/upstr_rsync_rsa -p 2022" --exclude '*~' --delete /home/vhosts/JKZ 192.168.10.30:/home/backup_upstr010/vhosts/

rsync -auvz -e "ssh -i /home/vhosts/.ssh/upstr_rsync_rsa -p 2022" --exclude '*~' --delete /home/vhosts/cms.up-stair.jp 192.168.10.30:/home/backup_upstr010/vhosts/

rsync -auvz -e "ssh -i /home/vhosts/.ssh/upstr_rsync_rsa -p 2022" --exclude '*~' --delete /home/vhosts/hp01.1mp.jp 192.168.10.30:/home/backup_upstr010/vhosts/

rsync -auvz -e "ssh -i /home/vhosts/.ssh/upstr_rsync_rsa -p 2022" --exclude '*~' --delete /home/vhosts/homepage.1mp.jp 192.168.10.30:/home/backup_upstr010/vhosts/

rsync -auvz -e "ssh -i /home/vhosts/.ssh/upstr_rsync_rsa -p 2022" --exclude '*~' --delete /home/vhosts/omp.1mp.jp 192.168.10.30:/home/backup_upstr010/vhosts/

