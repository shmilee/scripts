#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2023 shmilee

import sys
import time

N = 5

for i in range(N):
    print('#MONITOR-PARAMETER-GTC# {"istep": %d, "ETAh": %d}' %(i, N-i-1))
print('EMERGENCY-BREAK-EOF:', i)
sys.stdout.flush()

for j in range(N):
    print('writing %d/%d' % (j, N-1))
    if len(sys.argv) > 1 and sys.argv[1] == 'flush':
        sys.stdout.flush()
    time.sleep(j)
