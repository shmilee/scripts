#!/bin/bash
# Copyright (C) 2021 shmilee

#1)控制视频帧率
# -r fps 帧率，可以指定两个帧率，输入帧率，输出帧率； 
# 输入帧率：-i之前，设定读入帧率，比如 -r 0.5 ,也就是说1秒要播0.5个图片，那么一个图也就是要播2s
# 输出频率：-i之后，真正的输出视频播放帧率，不写话，是默认和输入频率一样。
# 比如设 -r 30 ,对应上面的设定，一个图播2s，那么输出文件播放时，这2s内，都是这张图，但是播放了6

#2)输出的视频画质下降，原因:影响视频质量的最重要因素是视频码率，输出视频的码率是默认的，只有200kbits/s
# 解决方案:修改默认的视频码率属性-b:v -bufsize
# 注意：当不清楚输出码率应该设置为多少，可以指定一个比较大的数字

#3)其他参数
# -f image2 指定fmt
# -start_number 500 指定从拿一张图片开始合成视频
# -threads 2 以两个线程进行运行，加快处理的速度。
# -y 对输出文件进行覆盖
# -vcodec libx264； -vcodec mpeg4 指定视频解码器
# -i image-%04d.jpg 输入文件格式，0001, 0002 ...

#4)加字幕解说
# -vf subtitles=./xxx.ass
# -b:a 160k
echo "example: ffmpeg -f image2 -r 5 -i "./%06d.jpg" -vcodec libx264 -r 5 -b:v 2000k -bufsize 2000k out.mp4"

out="${2:-out.mp4}"
ffmpeg -f image2 -r 5 -i "$1" -vcodec libx264 -r 5 -b:v 2000k -bufsize 2000k $out
