#!/bin/bash

function leader_ip {
  echo -n $(curl -s http://rancher-metadata/latest/stacks/$1/services/$2/containers/0/primary_ip)
}

giddyup service wait scale --timeout 120
stack_name=`echo -n $(curl -s http://rancher-metadata/latest/self/stack/name)`
my_ip=`echo -n $(curl -s http://rancher-metadata/latest/self/container/primary_ip)`
master_ip=$(leader_ip $stack_name redis-server)

sed -i -E "s/^ *# *bind +.*$/bind 0.0.0.0/g" /usr/local/etc/redis/sentinel.conf
sed -i -E "s/^ *dir +.*$/dir .\//g" /usr/local/etc/redis/sentinel.conf
sed -i -E "\$s/^ *# *sentinel +announce-ip +.*$/sentinel announce-ip ${my_ip}/" /usr/local/etc/redis/sentinel.conf
sed -i -E "s/^ *sentinel +monitor +([A-z0-9._-]+) +[0-9.]+ +([0-9]+) +([0-9]+).*$/sentinel monitor \1 ${master_ip} \2 \3/g" /usr/local/etc/redis/sentinel.conf

if [ -n "${CATTLE_ACCESS_KEY}" ]; then
	sed -i -E "s/^[ #]*sentinel +client-reconfig-script +([A-z0-9._-]+).*$/sentinel client-reconfig-script \1 \/update-master-externalservice.sh/" /usr/local/etc/redis/sentinel.conf
else
	echo "*** WARNING: redis-master external service management disabled, add labels io.rancher.container.create_agent=true and io.rancher.container.agent.role=environment on redis-sentinel containers to enable it."
fi

if [ -z "${SENTINEL_DOWN_AFTER_MILLISECONDS}" ]; then
	sed -i -E "\$s/^[ #]*sentinel down-after-milliseconds ([A-z0-9._-]+) .*$/sentinel down-after-milliseconds \1 ${SENTINEL_DOWN_AFTER_MILLISECONDS}/" /usr/local/etc/redis/sentinel.conf
fi

if [ -z "${SENTINEL_FAILOVER_TIMEOUT}" ]; then
	sed -i -E "\$s/^[ #]*sentinel failover-timeout ([A-z0-9._-]+) .*$/sentinel failover-timeout \1 ${SENTINEL_FAILOVER_TIMEOUT}/" /usr/local/etc/redis/sentinel.conf
fi

exec docker-entrypoint.sh "$@"
