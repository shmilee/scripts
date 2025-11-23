# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

from . import IspDetector, APISpeed


def main():
    ispdetector = IspDetector(
        qqKey='your-Key',
        baiduAK='your-AK',
    )
    config_bakcup = './api-configs/api-sites-config-backup.json'
    speed_logfile = './api-configs/api-sites-speed-logs.json'
    sites_speed = APISpeed(config_bakcup, speed_logfile, ispdetector)

    # update
    collection_confs = [
        './api-configs/moon-config-collections/senshinya-gistfile.txt',
        './api-configs/moon-config-collections/hafrey1-LunaTV-config.txt',
    ]
    count = 0
    for conf in collection_confs:
        count += sites_speed.add_moon_config(conf)
    if count > 0:
        sites_speed.check_http_to_https()

    # backup config
    sites_speed.reorder_sites()
    sites_speed.save_json_backup()

    # test speed
    sites_speed.test_speed()
    sites_speed.save_json_logs()

    # save summary
    sites_speed.summary_speedlogs(
        shownum=0,
        output='./api-configs/api-sites-summary.txt'
    )

    # select TV-
    def filterout(api, info):
        for nam in ['TV-CK']:
            if nam in info['common_name']:
                return True
    apis = sites_speed.select_apis(
        rate_limit=0.9, nameprefix='TV-', filterout=filterout)
    # create MoonTV config
    sites_speed.dump_moon_config(
        apis,
        './api-configs/api-sites-moontv-config.json',
    )


if __name__ == '__main__':
    main()
