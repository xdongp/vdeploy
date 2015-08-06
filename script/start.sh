killall -9 uwsgi 
#uwsgi -x /home/work/xnet/app_config.xml --gevent 2000 -d /home/work/xnet/uwsgi.log
uwsgi -x /home/work/xnet/app_config.xml  -d /home/work/xnet/uwsgi.log
service nginx restart
