#!/bin/bash

USER=${MONGODB_USER:-"admin"}
DATABASE=${MONGODB_DATABASE:-"admin"}

if [ -z ${MONGODB_PASS+x} ] && [ -z ${MONGODB_PASS_FILE+x} ]; then
    PASS=$(pwgen -s 12 1)
    _word="random"
elif [ "$MONGODB_PASS" ]; then
    PASS="$MONGODB_PASS"
    _word="preset"
elif [ "$MONGODB_PASS_FILE" ]; then
    PASS="$(< "${MONGODB_PASS_FILE}")"
    _word="preset (from secret)"
fi

RET=1
while [[ RET -ne 0 ]]; do
    echo "\n\n=> Waiting for confirmation of MongoDB service startup\n\n"
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

echo "\n\n=> Creating the ${USER} user with a ${_word} password in MongoDB\n\n"
mongo admin --eval "db.createUser({user: '$USER', pwd: '$PASS', roles:[{role:'root',db:'admin'}]});"

if [ "$DATABASE" != "admin" ]; then
    echo "\n\n=> Creating the ${USER} user with a ${_word} password in MongoDB\n\n"
    mongo admin -u $USER -p $PASS << EOF
use $DATABASE
db.createUser({user: '$USER', pwd: '$PASS', roles:[{role:'dbOwner',db:'$DATABASE'}]})
EOF
fi

echo "\n\n=> Done!"
touch /data/db/mongodb_password_set

echo "========================================================================"
echo "You can now connect to this MongoDB server using:"
echo ""
echo "    mongo $DATABASE -u $USER -p $PASS --host <host> --port <port>"
echo ""
echo "Please remember to change the above password as soon as possible!"
echo "========================================================================\n\n"
