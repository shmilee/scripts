#!/bin/bash
# Copyright (C) 2024 shmilee

TEST_DIR='/tmp/py3.12-logging-queue-fdjsa'
mkdir -v $TEST_DIR
cd $TEST_DIR/

wget -c https://github.com/python/cpython/pull/120030.patch
filterdiff --include=a/Lib/logging/config.py ./120030.patch > ./120030-part.patch

cat > ./test-mp.py <<EOF
import logging.config
import multiprocessing as mp

def main(q):
    config = {
        'version': 1,
        'handlers': {
            'sink': {
                'class': 'logging.handlers.QueueHandler',
                'queue': q,
            },
        },
        'root': {
            'handlers': ['sink'],
        },
    }
    logging.config.dictConfig(config)

if __name__ == '__main__':
    main(mp.Manager().Queue())
    print('===> PASS. Manager().Queue()')
    #print('-'*20)
    #main(mp.Manager().JoinableQueue())
    #print('===> PASS. Manager().JoinableQueue()')
EOF

echo -e '\n--------before and test--------\n'
python3.12 $TEST_DIR/test-mp.py

echo -e '\n--------patch and test--------\n'
md5sum /usr/lib/python3.12/logging/*.py
sudo cp -iv /usr/lib/python3.12/logging/config.py /usr/lib/python3.12/logging/config.py-backup
sudo patch -p3 -i  $TEST_DIR/120030-part.patch -d /usr/lib/python3.12/logging
diff -Nur /usr/lib/python3.12/logging/config.py-backup /usr/lib/python3.12/logging/config.py
python3.12 $TEST_DIR/test-mp.py

echo -e '\n--------back--------\n'
sudo mv -iv /usr/lib/python3.12/logging/config.py-backup /usr/lib/python3.12/logging/config.py
sudo rm -iv /usr/lib/python3.12/logging/config.py.orig
md5sum /usr/lib/python3.12/logging/*.py
