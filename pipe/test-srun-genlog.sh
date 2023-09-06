#!/bin/bash
# Copyright (C) 2023 shmilee

# 1. wandb finished, srun still write pipe
# => srun write part data in '.log'
# => BrokenPipeError: [Errno 32] Broken pipe
python test-srun-genlog.py flush \
    | tee /tmp/test-srun-genlog.log \
    | python ~/project/gtc-config/scripts/wandb-joblog.py \
        --dryrun

# 2. wandb finished, srun still write to buffer first, not pipe
# => srun write data, buffer lost in '.log'
python test-srun-genlog.py \
    | tee /tmp/test-srun-genlog.log \
    | python ~/project/gtc-config/scripts/wandb-joblog.py \
        --dryrun

# 3. wandb wait srun, untill genlog.py finished
# => ok, all saved in '.log'
# => best
python test-srun-genlog.py flush \
    | tee /tmp/test-srun-genlog.log \
    | python ~/project/gtc-config/scripts/wandb-joblog.py \
        --dryrun --eofstr 'EOF-BY-PIPE'

# 4. wandb wait srun, untill genlog.py finished and its buffer saved in '.log'
# => ok, all saved in '.log'
python test-srun-genlog.py \
    | tee /tmp/test-srun-genlog.log \
    | python ~/project/gtc-config/scripts/wandb-joblog.py \
        --dryrun --eofstr 'EOF-BY-PIPE'
