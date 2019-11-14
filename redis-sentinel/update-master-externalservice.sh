#!/bin/bash

echo "Reconfiguring..."
echo $@

REDIS_MASTER_UUID=$(curl -s http://rancher-metadata/latest/self/stack/services/redis-master/uuid)

if [ "${REDIS_MASTER_UUID}" = 'Not found' ]; then
	# Should create master.
	echo "Creating master record"
	STACK_UUID=$(curl -s http://rancher-metadata/latest/self/stack/uuid)

	STACK_ID=$(curl -k "${CATTLE_URL}/stacks?uuid=${STACK_UUID}" -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].id')
	curl -k "${CATTLE_URL}/externalservices" -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -H 'Content-Type: application/json' -X POST -d "{
		\"name\": \"redis-master\",
		\"externalIpAddresses\": [\"$6\"],
		\"stackId\": \"${STACK_ID}\",
		\"startOnCreate\": true
	}" 
else
	echo "Updating record"
	REDIS_MASTER_SERVICE_URL=$(curl -k "${CATTLE_URL}/services?uuid=${REDIS_MASTER_UUID}" -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].links.self')
	curl -k "${REDIS_MASTER_SERVICE_URL}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -H 'Content-Type: application/json' -X PUT -d "{\"externalIpAddresses\":[\"$6\"]}"
fi