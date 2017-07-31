#!/bin/bash

REDIS_MASTER_UUID=$(curl -s http://rancher-metadata/latest/self/stack/services/redis-master/uuid)

if [ $REDIS_MASTER_UUID = 'Not found' ]; then
	# Should create master.
else
	read service_id project_id <<< $(curl "${CATTLE_URL}/services?uuid=${REDIS_MASTER_UUID}" -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].id,.data[0].accountId')
	curl "${CATTLE_URL}/projects/${project_id}/externalservices/${service_id}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -H 'Content-Type: application/json' -X PUT -d '{"externalIpAddresses":["$6"]}'
fi