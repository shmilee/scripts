#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import cv2
import numpy as np


class IDphoto(object):
    '''Convert photo'''
    # ref: https://blog.csdn.net/pythonlaodi/article/details/110188261

    def __init__(self, path, resize_kwargs=None):
        self.path = path
        photo = cv2.imread(path)
        if resize_kwargs:
            photo = cv2.resize(photo, **resize_kwargs)
        rows, cols, channels = photo.shape
        print('Photo shape: %dx%d, channels=%d' % (rows, cols, channels))
        self.photo = photo
        self.rows = rows
        self.cols = cols

    def select(self, lower, upper, iterations):
        # 图片转换为灰度图
        hsv = cv2.cvtColor(self.photo, cv2.COLOR_BGR2HSV)
        # 图片的二值化处理
        # 将在两个阈值内的像素值设置为白色 255, 不在阈值区间内的像素值设置为黑色 0
        mask = cv2.inRange(hsv, np.array(lower), np.array(upper))
        # 腐蚀膨胀 若是腐蚀膨胀后仍有白色噪点，可以增加iterations的值
        erode = cv2.erode(mask, None, iterations=iterations)
        self.dilate = cv2.dilate(erode, None, iterations=iterations)

    def cover(self, new_BGR):
        # BGR通道, 蓝 (255,0,0), 红 (0,0,255), 白 (255,255,255)
        for i in range(self.rows):
            for j in range(self.cols):
                if self.dilate[i, j] == 255:  # 像素点255表示白色
                    self.photo[i, j] = new_BGR  # 替换颜色, BGR通道

    def save(self, path):
        cv2.imwrite(path, self.photo)

    def show(self):
        cv2.imshow('IDphoto', self.photo)

    def _A2B(self, path, lower, upper, new, iterations):
        self.select(lower, upper, iterations)
        self.cover(new)
        self.save(path)

    def blue2red(self, path, lower_blue=(90, 70, 70), upper_blue=(110, 255, 255), iterations=2):
        self._A2B(path, lower_blue, upper_blue, (0, 0, 255), iterations)

    def blue2white(self, path, lower_blue=(90, 70, 70), upper_blue=(110, 255, 255), iterations=2):
        self._A2B(path, lower_blue, upper_blue, (255, 255, 255), iterations)

    def red2blue(self, path, lower_red=(0, 135, 135), upper_red=(180, 245, 230), iterations=2):
        self._A2B(path, lower_red, upper_red, (255, 0, 0), iterations)

    def red2white(self, path, lower_red=(0, 135, 135), upper_red=(180, 245, 230), iterations=2):
        self._A2B(path, lower_red, upper_red, (255, 255, 255), iterations)


if __name__ == '__main__':
    idphoto = IDphoto('./test.jpg')
    idphoto.blue2red('./test-out.jpg')
