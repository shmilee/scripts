#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import time
import itertools
import numpy as np
from collections import Counter
from skimage import io

import matplotlib.pyplot as plt
import csv


class RiverConverter(object):
    '''
    Converter for river location, direction, tributaries, etc.
    '''
    __slots__ = ['tifs', 'river_arr', 'direct_arr', 'dem_arr',
                 'grid_size', 'Ngrids', 'top_left_X', 'top_left_Y',
                 'river_value', 'direct_dict']

    default_invalid_direction_key = 255
    default_direct_dict = {default_invalid_direction_key: None,
                           1: [0, 1],  # [y,x]
                           2: [1, 1],
                           4: [1, 0],
                           8: [1, -1],
                           16: [0, -1],
                           32: [-1, -1],
                           64: [-1, 0],
                           128: [-1, 1]}

    def __init__(self, river_tif, direction_tif, dem_tif,
                 grid_size=33, top_left_X=0, top_left_Y=0,
                 river_value=1, direct_dict=None):
        # read tif
        img_river = io.imread(river_tif)
        img_direct = io.imread(direction_tif)
        img_dem = io.imread(dem_tif)
        img_river[img_river < 0] = 0
        img_river[img_river > 0] = river_value
        assert img_direct.shape == img_river.shape
        self.tifs = '%s' % [river_tif, direction_tif]
        self.river_arr = img_river
        self.direct_arr = img_direct
        self.dem_arr = img_dem
        self.grid_size = grid_size
        self.Ngrids = img_river.sum()//river_value
        self.top_left_X = top_left_X
        self.top_left_Y = top_left_Y
        # print('N river grids:', self.Ngrids)
        self.river_value = river_value
        if isinstance(direct_dict, dict):
            self.direct_dict = direct_dict
        else:
            self.direct_dict = self.default_direct_dict

    def __repr__(self):
        return '<{0} object at {1} for TIFS {2}>'.format(
            type(self).__name__, hex(id(self)), self.tifs)

    @staticmethod
    def _updown_range(start, stop0, stop1, step=1):
        '''
        Generate a sequence from start to stop0,stop1(exclusive) together.
        stop0 < start < stop1, step is positive.
        '''
        i = start
        j = start + step
        while i > stop0 or j < stop1:
            if i > stop0:
                yield i
                i = i - step
            if j < stop1:
                yield j
                j = j + step

    def find_near_channel(self, point, axis=0):
        '''
        Start from point to search the near channel point over a given axis.
        Return a channel point or None.

        Parameters
        ----------
        point: tuple (yindex, xindex)
        axis: int
            0 for y or 1 for x
        '''
        yindex, xindex = point
        y, x = self.river_arr.shape
        if axis == 0:
            for i in self._updown_range(yindex, -1, y):
                if self.river_arr[i, xindex] == self.river_value:
                    return i, xindex
        else:
            for i in self._updown_range(xindex, -1, x):
                if self.river_arr[yindex, i] == self.river_value:
                    return yindex, i
        return None

    def find_downstream_point(self, point, use='Direction',
                              check=True, in_channel=True):
        '''
        Return the downstream point or None.

        Parameters
        ----------
        point: tuple (yindex, xindex)
            point in channel
        use: 'DEM' or 'Direction'
        check: bool
            check if input point is in channel
        in_channel: bool
            downstream point must be in channel or not
        '''
        yindex, xindex = point
        if check and self.river_arr[yindex, xindex] != self.river_value:
            print('This point%s not in channel!' % (point,))
            return None
        if use == 'Direction':
            key = self.direct_arr[yindex, xindex]
            if key not in self.direct_dict:
                print('Invalid direction key: %d! Use %d instead!'
                      % (key, self.default_invalid_direction_key))
                key = self.default_invalid_direction_key
            direct = self.direct_dict[key]
            if direct is None:
                return None
            yidx, xidx = yindex+direct[0], xindex+direct[1]
            if yidx < 0 or yidx >= self.river_arr.shape[0]:
                return None
            if xidx < 0 or xidx >= self.river_arr.shape[1]:
                return None
            if in_channel and self.river_arr[yidx, xidx] != self.river_value:
                return None
            return yidx, xidx
        elif use == 'DEM':
            raise NotImplementedError("Use DEM is not implemented!")

    def find_end_point(self, point, trace=False, end_in_channel=False):
        """
        Return the end point of river.

        Parameters
        ----------
        point: tuple (yindex, xindex)
            point in channel
        trace: bool
            also return trace points or not.
        end_in_channel: bool
            end point must be in channel or not
        """
        trace_points = [point]
        for i in range(self.Ngrids):
            dpt = self.find_downstream_point(point, in_channel=True)
            if dpt is None:
                if end_in_channel is False:
                    dpt = self.find_downstream_point(point, in_channel=False)
                    if dpt is not None:
                        print('Set end point(not in channel): %s, DEM: %s'
                              % (dpt, self.dem_arr[dpt[0], dpt[1]]))
                        point = dpt
                        if trace:
                            trace_points.append(point)
                break
            point = dpt
            if trace:
                trace_points.append(point)
        if trace:
            return point, trace_points
        else:
            return point

    def _old_find_all_source_join_points(self):
        y, x = self.river_arr.shape
        sum_filter = np.ones((3, 3), dtype='int')
        source = []
        join, ijoin = [], 0
        for r in range(1, y - 1):
            for c in range(1, x - 1):
                if self.river_arr[r, c] == self.river_value:
                    cur_input = self.river_arr[r-1:r + 2, c-1:c + 2]
                    cur_output = np.sum(cur_input * sum_filter)
                    if cur_output == 2:
                        source.append((r, c))
                        print('Source %d index: %s, %s' %
                              (len(source)-1, r, c))
                    if cur_output == 4:
                        print('Join point candidate %d index: %s, %s' %
                              (ijoin, r, c))
                        print(self.river_arr[r-2:r+3, c-2:c+3])
                        add = input('Add join point %s [y/n]: ' % ijoin)
                        if add == 'y' or add == 'Y':
                            join.append((r, c))
                        ijoin += 1
        return source, join

    D8_offsets = [v for v in default_direct_dict.values() if v is not None]

    def find_upstream_points(self, point, use='Direction', in_channel=True):
        '''
        Return the upstream points list.

        Parameters
        ----------
        point: tuple (yindex, xindex)
        use: 'DEM' or 'Direction'
        in_channel: bool
            upstream points in channel or not
        '''
        yindex, xindex = point
        if self.river_arr[yindex, xindex] != self.river_value:
            print('Find upstreams of point%s (not in channel)...' % (point,))
            this_in_channel = False
        else:
            this_in_channel = True
        up_points = []
        if use == 'Direction':
            for yoff, xoff in self.D8_offsets:
                yidx, xidx = yindex + yoff, xindex + xoff
                if yidx < 0 or yidx >= self.river_arr.shape[0]:
                    continue
                if xidx < 0 or xidx >= self.river_arr.shape[1]:
                    continue
                if in_channel:
                    if self.river_arr[yidx, xidx] != self.river_value:
                        continue
                    dpt = self.find_downstream_point(
                        (yidx, xidx), check=True, in_channel=this_in_channel)
                else:
                    if self.river_arr[yidx, xidx] == self.river_value:
                        continue
                    dpt = self.find_downstream_point(
                        (yidx, xidx), check=False, in_channel=this_in_channel)
                if dpt == point:
                    up_points.append((yidx, xidx))
            return up_points
        elif use == 'DEM':
            raise NotImplementedError("Use DEM is not implemented!")

    def find_source_join_points(self, point):
        """
        Return the source, join and trace points in upstreams of input point.

        Parameters
        ----------
        point: tuple (yindex, xindex)
            point in channel, end point not in channel is also allowed.
            recommand using end point.

        Notes
        -----
        The trace points are in a tree list.
        .. code::

            all_trace = [trace0_arr, trib_trace1, trib_trace2, ...]
            trib_trace1 = [trace1_arr, trib_trace11, ...}]
            ... ...
            trib_traceiii = [trib_traceiii_arr] # END

        """
        source_points = []
        join_points = []
        trace_points = [point]
        all_trace_points = [trace_points]
        for i in range(self.Ngrids):
            up_points = self.find_upstream_points(point)
            if len(up_points) == 0:
                source_points.append(point)
                break  # stop at source
            if len(up_points) == 1:
                trace_points.append(up_points[0])
                point = up_points[0]  # go on
            elif len(up_points) > 1:
                join_points.append(point)
                for up in up_points:
                    res = self.find_source_join_points(up)
                    source_points.extend(res[0])
                    join_points.extend(res[1])
                    all_trace_points.append(res[2])
                break  # stop at join point
        return source_points, join_points, all_trace_points

    def _combine_trace_points_by_length(self, trace_points):
        '''
        Combine the trace points to generate river tributaries.
        Longest trunk channel.
        '''
        if len(trace_points) == 1:
            # reverse
            return [trace_points[0][::-1], []]
        elif len(trace_points) > 1:
            tribs = []
            idx, length = None, -1
            for i in range(1, len(trace_points)):
                sub = self._combine_trace_points_by_length(trace_points[i])
                if len(sub[0]) > length:
                    length = len(sub[0])
                    idx = i - 1
                tribs.append(sub)
            # idx[0] => trunk
            trunk = tribs[idx][0] + trace_points[0][::-1]
            # idx's tribs [1] -> trunk's tribs, orignal join index
            if tribs[idx][1]:
                trunktribs = tribs[idx][1].copy()
            else:
                trunktribs = []
            # add other tribs to trunk's, join index is length, = len(idx[0])
            trunktribs.extend([
                (length, tribs[i]) for i in range(len(tribs)) if i != idx])
            return [trunk, trunktribs]

    def _index_tribs(self, tribs, count, pidx):
        '''Add index for each river tributaries, trunk's is 0'''
        idx = next(count)
        return [
            (idx, pidx, tribs[0]),
            [
                (jidx, self._index_tribs(subtrib, count, pidx=idx))
                for jidx, subtrib in tribs[1]
            ]
        ]

    def _search_fill_tribs(self, tribs, search, kws={}):
        '''
        Read values from search array or returned by search function.
        Then fill them to each river tributaries.
        '''
        points = tribs[0][2]
        if callable(search):
            res = [search(p, **kws) for p in points]
        else:
            res = [search[p[0], p[1]] for p in points]
        return [
            tribs[0] + (res,),
            [
                (jidx, self._search_fill_tribs(subtrib, search, kws=kws))
                for jidx, subtrib in tribs[1]
            ]
        ]

    def _interp_tribs(self, tribs, startv, endv, known=None):
        '''
        Add linear interpolant values for each river tributaries.
        '''
        points = tribs[0][2]
        N = len(points)
        xp, fp = [], []
        for i, p in enumerate(points):
            if known and p in known:
                xp.append(i)
                fp.append(known[p])
        if 0 not in xp:
            xp.insert(0, 0)
            fp.insert(0, startv)
        if N-1 not in xp:
            xp.append(N-1)
            fp.append(endv)
        res = np.interp(range(N), xp, fp)
        return [
            tribs[0] + (res,),
            [
                (jidx, self._interp_tribs(
                    subtrib, startv, endv=res[jidx-1], known=known))
                for jidx, subtrib in tribs[1]
            ]
        ]

    def get_river_tribs(self, point, end_in_channel=False, mode='length',
                        add_info=[('width', 2.0, 10.0, {}), ]):
        """
        Return the river tributaries, its number
        and infor of source/join/end points in a dict.

        Parameters
        ----------
        point: tuple (yindex, xindex)
            point near river
        end_in_channel: bool
            end point must be in channel or not
        mode: str, 'length' or 'height'
            how to select trunk channel
        add_info: list
            each quantity's input is (label, startv, endv, known dict)
            or (label, search_arr) or (label, search_fun, kwargs).
            known dict's keys are the river points.
            search_arr's shape is equal to :attr:`river_arr`.
            search_fun's input is each point.
            For lisflood-fp outputs, should add 'width', 'manning n',
            'bed DE', 'dh'. 'upstream side points' is optional.
        Notes
        -----
        The tributaries is a tree list like this.
        .. code::

            # trunk = trib0_arr
            trib0 = [(0, None, trib0_arr, add_arrs ...), [
                (join_index1, trib1), (join_index2, trib2),
                # same index for trib3, trib4
                (join_index3, trib3), (join_index3, trib4), ...],]
            # same structure for all trunk tribs
            trib1 = [(index1, parent's index, trib1_arr, add_arrs ...), [
                (join_index11, trib11), ...],]
            ... ...
            tribi = [(indexi, parent's index, tribi_arr, add_arrs), []] # END
        """
        start_time0 = time.time()
        print('\nStart point:', point)
        p1 = self.find_near_channel(point)
        print('Start channel point:', p1)
        kw = dict(trace=True, end_in_channel=end_in_channel)
        p2, t_p = self.find_end_point(p1, **kw)
        print('End point:', p2)
        s_p, j_p, all_trace = self.find_source_join_points(p2)
        print('Source points: ', s_p)
        print('Join points: ', j_p)
        print(' -> Split time cost: %.2fs\n' % (time.time()-start_time0))
        start_time1 = time.time()
        if mode == 'length':
            tribs = self._combine_trace_points_by_length(all_trace)
        else:
            raise NotImplementedError("Mode %s is not implemented!" % mode)
        print(' -> Combine time cost: %.2fs\n' % (time.time()-start_time1))
        start_time2 = time.time()
        count = itertools.count(0)
        tribs = self._index_tribs(tribs, count, pidx=None)
        Ntribs = next(count)
        print('Tributaries number: ', Ntribs)
        for info in add_info:
            print('Add quantity: %s' % info[0])
            if len(info) == 2:
                tribs = self._search_fill_tribs(tribs, info[1])
            elif len(info) == 3:
                tribs = self._search_fill_tribs(tribs, info[1], info[2])
            elif len(info) == 4:
                a, b, c = info[1:]
                tribs = self._interp_tribs(tribs, startv=a, endv=b, known=c)
            else:
                print('Warnning: ignore info of %s!' % info[0])
        print(' -> Add quantities time cost: %.2fs\n' %
              (time.time()-start_time2))
        print(' -> All Time cost: %.2fs\n' % (time.time()-start_time0))
        return tribs, Ntribs, dict(
            seed=point, start=p1, end=p2, end_trace=t_p,
            source=s_p, join=j_p, trace=all_trace)

    def loc(self, point):
        '''Return location(Y,X) of point(y,x).'''
        Y = (point[0]-0.5)*self.grid_size
        X = (point[1]-0.5)*self.grid_size
        return -Y + self.top_left_Y, X + self.top_left_X

    @staticmethod
    def point_list2str(plist):
        '''[(a,b), (x,y)] -> ab_xy'''
        return '_'.join(['%d%d' % p for p in plist])

    def _save_tribs_lisflood(self, tribs, fo, sqvar, qvar, ehvar):
        '''
        Write each tributaries' info line by line to opend file object.
        '''
        idx, pidx, points = tribs[0][:3]
        # 'width', 'manning n', 'DE', 'dh'
        w_arr, n_arr, DE_arr, dh_arr = tribs[0][3:7]
        # optional side points
        if len(tribs[0]) > 7:
            side_points = tribs[0][7]
        else:
            side_points = None
        join_indexs = [i for i, subt in tribs[1]]
        join_subtribs = [subt[0][0] for i, subt in tribs[1]]
        N = len(points)
        print("Writting trib: %d, pidx=%s, with %d sub tribs."
              % (idx, pidx, len(join_indexs)))
        err_p = []
        for i, c in Counter(join_indexs).items():
            if c > 1:
                print("ERROR: Point %s has more than 1 trib!" % (points[i],))
                err_p.append(points[i])
        if N-1 in join_indexs:
            print("ERROR: Last point %s is also join point!" % (points[N-1],))
            err_p.append(points[N-1])
        if err_p:
            return err_p
        # write this trib
        fo.write('%d\n' % N)
        for i, p in enumerate(points):
            Y, X = self.loc(p)
            w, n, de, h = w_arr[i], n_arr[i], DE_arr[i], dh_arr[i]
            if i == 0:
                # source point line
                fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tQVAR %s%d%d\n'
                         % (X, Y, w, n, de-h, sqvar, p[0], p[1]))
            elif i == N-1:
                if pidx is None:
                    assert idx == 0
                    # trunk last line
                    if ehvar == 'hvar':
                        bcstr = 'HVAR hvar%d%d' %(p[0], p[1])
                    else:
                        bcstr = 'FREE'
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\t%s\n'
                             % (X, Y, w, n, de-h, bcstr))
                else:
                    # tributaries' last line
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tQOUT %d\n'
                             % (X, Y, w, n, de-h, pidx))
            elif i in join_indexs:
                _index = join_indexs.index(i)
                # tributaries join to trunk line
                fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tTRIB %d\n'
                         % (X, Y, w, n, de-h, join_subtribs[_index]))
            else:
                if side_points and side_points[i]:
                    # has upstream side points
                    # river, bdy should use same idstr
                    idstr = self.point_list2str(side_points[i])
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tQVAR %s%s\n'
                             % (X, Y, w, n, de-h, qvar, idstr))
                else:
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\n'
                             % (X, Y, w, n, de-h))
        # write its subtrib
        for jidx, subtrib in tribs[1]:
            self._save_tribs_lisflood(subtrib, fo, sqvar, qvar, ehvar)

    def save_tribs(self, tribs, Ntribs, outfile, fmt='lisflood',
            fmt_kws=dict(sqvar='sqvar', qvar='qvar', ehvar='free')):
        '''
        Save one river's tributaries to a file.

        Parameters
        ----------
        tribs: list
            river tributaries' tree
        Ntribs: int
            number of tributaries
        outfile: path
        fmt: str, only 'lisflood' supported
        fmt_kws: dict
            example, keys for lisflood,
            sqvar for source inflow identifier, QVAR sqvar***
            qvar for lateral inflow identifier, QVAR qvar***
            ehvar for end point Boundary Condition, 'free' or 'hvar'

        Notes
        -----
        1. lisflood add_info: 'w', 'n', 'DE', 'h'
        '''
        with open(outfile, 'w+t') as fo:
            if fmt == 'lisflood':
                sqvar = fmt_kws.get('sqvar', 'sqvar')
                qvar = fmt_kws.get('qvar', 'qvar')
                ehvar = fmt_kws.get('ehvar', 'free')
                fo.write('Tribs %d\n' % Ntribs)
                self._save_tribs_lisflood(tribs, fo, sqvar, qvar, ehvar)
            else:
                raise NotImplementedError('%s is not implemented!' % fmt)

    def extract_all_channel_points(self, tribs, index=2):
        '''Return all channel points in a list'''
        res = []
        if len(tribs[0]) > index:
            res.extend(tribs[0][index])
            for jidx, subtrib in tribs[1]:
                subres = self.extract_all_channel_points(subtrib)
                res.extend(subres)
            return res
        else:
            print("Warnning: No channel points found in tribs!")
            return []

    def extract_all_upstream_side_points(self, tribs, index=7,
            channel_index=2):
        '''
        Return all upstream side points in dict. Its keys are channel points.
        '''
        res = {}
        if len(tribs[0]) > index:
            for cp, plist in zip(tribs[0][channel_index], tribs[0][index]):
                res[cp] = plist
            for jidx, subtrib in tribs[1]:
                res.update(self.extract_all_upstream_side_points(
                    subtrib, index=index, channel_index=channel_index))
            return res
        else:
            print("Warnning: No upstream side points found in tribs!")
            return {}

    # plot, show, check
    def __plot_upstream_side_points(self, tribs, index, channel_index):
        if len(tribs[0]) > index:
            for i, plist in enumerate(tribs[0][index]):
                ch_p = tribs[0][channel_index][i]
                for j, p in enumerate(plist):
                    plt.annotate(
                        "%d" % j,
                        xy=(ch_p[1], ch_p[0]), xytext=(p[1], p[0]),
                        arrowprops=dict(arrowstyle="->", color="r"))
            for jidx, subtrib in tribs[1]:
                self.__plot_upstream_side_points(
                    subtrib, index=index, channel_index=channel_index)
        else:
            print("Warnning: No upstream side points found in tribs!")

    def plot_upstream_side_points(self, tribs, index=7, channel_index=2):
        '''Plot and check all upstream side points with arrow.'''
        plt.imshow(self.river_arr)
        self.__plot_upstream_side_points(
            tribs, index=index, channel_index=channel_index)
        plt.grid()
        plt.show()

    def plot_river_tribs(self, tribs, N, dinfo):
        '''Plot and check tributaries infor.'''
        p0 = dinfo['seed']
        p1, p2, t_p = dinfo['start'], dinfo['end'], dinfo['end_trace']
        s_p, j_p, all_trace = dinfo['source'], dinfo['join'], dinfo['trace']

        # fig 1
        plt.imshow(self.river_arr)
        line = np.array(t_p)
        plt.plot(line[:, 1], line[:, 0], marker='.', markersize=3, color='c')
        plt.plot(p0[1], p0[0], marker='*', markersize=10, label='Start')
        plt.plot(p1[1], p1[0], marker='*',
                 markersize=10, label='Start in channel')
        plt.plot(p2[1], p2[0], marker='s', markersize=10, label='End')
        plt.legend()
        plt.show()

        # fig 2
        def plot_source_join(s_p, j_p, end):
            plt.plot(end[1], end[0], 'sb', markersize=10, label='End')
            py, px = s_p[0]
            plt.plot(px, py, 'ok', markersize=10, label='Source')
            for py, px in s_p[1:]:
                plt.plot(px, py, 'ok', markersize=10)
            if len(j_p) > 0:
                py, px = j_p[0]
                plt.plot(px, py, 'pr', markersize=10, label='Join')
                for py, px in j_p[1:]:
                    plt.plot(px, py, 'pr', markersize=10)

        c_cycle = itertools.cycle(['c', 'm', 'y', 'g'])

        def plot_all_trace(allt):
            c = next(c_cycle)
            line = np.array(allt[0])
            x, y = line[:, 1], line[:, 0]
            plt.plot(x, y, marker='.', markersize=3, color=c)
            for subt in allt[1:]:
                plot_all_trace(subt)

        plt.imshow(self.river_arr)
        plot_all_trace(all_trace)
        plot_source_join(s_p, j_p, p2)
        plt.legend()
        plt.show()

        # fig 3
        mlc_cycle = itertools.cycle(['%s%s%s' % (m, l, c)
                                     for m in '.,*x'
                                     for l in ['-', '--', '-.', ':']
                                     for c in 'cmyg'])

        def plot_tribs(tribs, skipc='k'):
            mlc = next(mlc_cycle)
            while mlc[-1] == skipc:
                mlc = next(mlc_cycle)
            line = np.array(tribs[0][2])
            plt.plot(line[:, 1], line[:, 0], mlc, markersize=5,
                     label='index %d' % tribs[0][0])
            for i, subt in tribs[1]:
                plot_tribs(subt, skipc=mlc[-1])

        plt.imshow(rc.river_arr)
        plot_source_join(s_p, j_p, p2)
        plot_tribs(tribs)
        plt.legend()
        plt.show()



class BDYConverter(object):
    '''
    Converter for time varying boundary conditions.
    '''
    __slots__ = ['comment', 'results']

    def __init__(self, comment='BDY for test'):
        self.comment = comment
        self.results = {}

    def add_result(self, identifier, time, value, tunit):
        self.results[identifier] = dict(
            time=time, value=value, tunit=tunit)

    def save_bdy(self, outfile):
        with open(outfile, 'w+t') as f:
            f.write('%s\n' % self.comment)
            for identifier in self.results:
                print("Writting %s" % identifier)
                res = self.results[identifier]
                time, value, tunit = res['time'], res['value'], res['tunit']
                assert len(time) == len(value)
                f.write('%s\n%d\t%s\n' % (identifier, len(time), tunit))
                Tisint = isinstance(time[0], (int,np.int_))
                fmt = '%f\t%d\n' if Tisint else '%f\t%f\n'
                for v, t in zip(value, time):
                    f.write(fmt % (v, t))

    def read_lbx_csv(self, csvfile, need_points='all',
            start_time=0, dtime=300):
        '''
        Read values of *need_points* from csvfile.
        Return values' dict whose key is point (y, x) and time list.
        
        Parameters
        ----------
        csvfile: file path
        need_points: 'all' or points list
        start_time: number, time of first value
        dtime: number, interval time
        '''
        Q_res, N = {}, None
        with open(csvfile, 'r') as f:
            data = csv.reader(f)
            desc = next(data) # rm first line
            for line in data:
                y, x = line[1][1:-1].split(',')
                y, x = int(y), int(x)
                if need_points == 'all' or (y,x) in need_points:
                    Q_res[(y,x)] = np.array([float(q) for q in line[2:]])
                if N is None:
                    N = len(line[2:])
        return Q_res, np.array([start_time + dtime*i for i in range(N)])

    def merge_point_values(self, group_points, values_dict,
            time, tunit="seconds", idstrfun=None, weights=None):
        '''
        The results saved in :attr:`results`

        Parameters
        ----------
        group_points: list of grouped points (y, x)
            [[(y1, x1), (y2, x2)], [(y3, x3)], [], ...]
        values_dict: dict
            key is each point, value is a array.
            {(y1, x1): np.array([1,2,3,...]), ...}
        time: time array
        idstrfun: function
            fotmat group points to idstr, as identifier in outfile
        weights: 2D array_like, optional
            weights[y,x] for each point
        '''
        for group in group_points:
            if not group:
                continue # skip []
            if callable(idstrfun):
                idstr = idstrfun(group)
            else:
                idstr = 'bc' + '_'.join(['%d%d' % p for p in group])
            if len(group) == 1:
                p =group[0]
                value = values_dict[p]
                if weights:
                    value = value*weights[p[0], p[1]]
            else:
                value = np.array([values_dict[p] for p in group])
                if weights:
                    w = np.array([weights[p[0], p[1]] for p in group])
                    value = (value.T*w).T
                value = value.sum(axis=0)
            self.add_result(idstr, time, value, tunit=tunit)

def plot_wd(file, dt=5, show=True,
        zlim=[0,2], limto=[0, 2],
        rc=None, cmaps=['gist_gray','gist_earth'], dpi=500):
    import matplotlib.pyplot as plt
    with open(file) as f:
        data = f.readlines()
        wd = [[float(p) for p in d.split()] for d in data[6:]]
    wd_arr = np.array(wd)
    wd_arr[np.isnan(wd_arr)] = 0.0
    wd_arr[wd_arr<0] = 0.0
    wd_A = (wd_arr>0).sum()
    if zlim[0] > 0:
        wd_lim0 = (wd_arr>=zlim[0]).sum()
    else:
        wd_lim0 = (wd_arr>zlim[0]).sum()
    wd_lim1 = (wd_arr>zlim[1]).sum()
    perc = (wd_lim0-wd_lim1)/wd_A*100
    wd_arr[wd_arr<zlim[0]] = limto[0]
    wd_arr[wd_arr>zlim[1]] = limto[1]
    wd_arr[0,0] = zlim[1] # for colorbar
    if rc:
        plt.imshow(rc.river_arr, cmap=cmaps[0], alpha=0.3)
    plt.imshow(wd_arr, cmap=cmaps[1], alpha=0.8)
    N = int(file.split('-')[-1].split('.')[0])
    print('T= %smin, A= %d*%.2f%%' % (N*dt, wd_A, perc))
    plt.title("Time = %smin, A=%d*%.2f%%" % (N*dt, wd_A, perc))
    plt.colorbar()
    plt.savefig(file+'.jpg', dpi=dpi)
    if show:
        plt.show()
    else:
        plt.close('all')
    return wd_A


def plot_all_wd(pre='./results_DSZ/res_DSZ-', N=300, dt=5,
        zlim=[0,2], limto=[0, 2],
        rc=None, cmaps=['gist_gray','gist_earth'], dpi=500):
    import matplotlib.pyplot as plt
    import os
    dirname = os.path.dirname(pre)
    for idx in ['%04d' % i for i in range(0, N+1)]:
        if not os.path.exists(pre+idx+'.wd'):
            continue
        A = plot_wd(pre+idx+'.wd', dt=dt, show=False,
                    zlim=zlim, limto=limto, rc=rc, cmaps=cmaps, dpi=dpi)

def plot_A_t(pre='./results_DSZ/res_DSZ-', N=300, dt=5,
        hs=[0.0, 2, 5, 10, 20]):
    import matplotlib.pyplot as plt
    import os
    dirname = os.path.dirname(pre)

    As = []
    for idx in ['%04d' % i for i in range(0, N+1)]:
        if not os.path.exists(pre+idx+'.wd'):
            break
        with open(pre+idx+'.wd') as f:
            data = f.readlines()
            wd = [[float(p) for p in d.split()] for d in data[6:]]
        wd_arr = np.array(wd)
        wd_arr[np.isnan(wd_arr)] = 0.0
        wd_arr[np.isinf(wd_arr)] = 0.0
        As.append([
            (wd_arr>h).sum() for h in hs
        ])
    t = np.array(range(0, len(As))) * dt
    As = np.array(As)
    for i, h in enumerate(hs):
        plt.plot(t, As[:,i], label='wd>%sm' % h)
    plt.legend()
    plt.xlabel('Time(min)')
    plt.ylabel('Area(grids)')
    plt.xlim([0,t.max()])
    plt.ylim([0,As.max()])
    plt.savefig(dirname + '/res_A-t.jpg')
    plt.close('all')


if __name__ == '__main__':
    dsz_kws = dict(river_tif='./dsz_river.tif',
                   direction_tif='./dszliuxiang.tif',
                   dem_tif='./dsz_demr.tif')
    rc = RiverConverter(**dsz_kws)
    p0 = (80, 100)
    width_arr = io.imread('./dsz_riverwidth.tif')
    add_info = [('width', width_arr),
                ('manning n', 0.32, 0.32, {}),
                ('bed DE', rc.dem_arr),
                ('dh', 1.0, 3.0, {}),]
    #add_info.append(('USPs', rc.find_upstream_points, dict(in_channel=False)))
    tribs, N, d = rc.get_river_tribs(
        p0, end_in_channel=True, add_info=add_info)
    rc.save_tribs(tribs, N, './DSZ-out-0.river')
    #rc.plot_river_tribs(tribs, N, d)
    p2, s_p = d['end'], d['source']
    CPs = rc.extract_all_channel_points(tribs)
    USPs = rc.extract_all_upstream_side_points(tribs)
    flat_USPs = []
    for l in USPs.values():
        flat_USPs.extend(l)
    print(len(flat_USPs), 'vs', len(CPs))

    #    for p in USPs:
    #        f.write('%s\n' % (p,))
    with open('DSZ-need-points.py', 'w+t') as f:
        f.write('end_point = %s\n' % (p2,))
        f.write('source_points = [\n')
        for p in s_p:
            f.write('%s,\n' % (p,))
        f.write(']\n')
        f.write('upstream_side_points = [\n')
        for p in flat_USPs:
            f.write('%s,\n' % (p,))
        f.write(']\n')        
        f.write('upstream_side_points_dict = {\n')
        for k in USPs:
            f.write('%s: %s,\n' % (k,USPs[k]))
        f.write('}\n')

    bdy = BDYConverter(comment='BDY for DSZ test')
    res, tarr = bdy.read_lbx_csv('./river_Q_dsz_shengming.csv')
    bdy.merge_point_values([[p] for p in s_p], res, tarr,
        idstrfun=lambda group: 'sqvar' + '_'.join(['%d%d' % p for p in group]))
    bdy.save_bdy('only-source-DSZ.bdy')
    bdy.merge_point_values(USPs.values(), res, tarr,
        idstrfun=lambda group: 'qvar' + '_'.join(['%d%d' % p for p in group]))
    #bdy.merge_point_values([p2], res, tarr)
    bdy.save_bdy('source-lateral-DSZ.bdy')





    ws1_kws = dict(river_tif='./WS1-river.tif',
                   direction_tif='./WS1-Direction.tif',
                   dem_tif='./WS1-DEM.tif')
    rc = RiverConverter(**ws1_kws)
    p0 = (80, 100)
    add_info = [('width', 2, 10, {}),
                ('manning n', 0.32, 0.32, {}),
                ('bed DE', rc.dem_arr),
                ('dh', 1.0, 3.0, {})]
    #add_info.append(('USPs', rc.find_upstream_points, dict(in_channel=False)))
    tribs, N, d = rc.get_river_tribs(
        p0, end_in_channel=True, add_info=add_info)
    rc.save_tribs(tribs, N, './WS1-out-0.river')
    #rc.plot_river_tribs(tribs, N, d)
    p2 = d['end']
    s_p = d['source']

    CPs = rc.extract_all_channel_points(tribs)
    USPs = rc.extract_all_upstream_side_points(tribs)
    with open('WS1-need-points.py', 'w+t') as f:
        f.write('end_point = %s\n' % (p2,))
        f.write('source_points = [\n')
        for p in s_p:
            f.write('%s,\n' % (p,))
        f.write(']\n')
        f.write('upstream_side_points = {\n')
        for k in USPs:
            f.write('%s: %s,\n' % (k,USPs[k]))
        f.write('}\n')
    flat_USPs = []
    for l in USPs.values():
        flat_USPs.extend(l)
    print(len(flat_USPs), 'vs', len(CPs))
    #rc.plot_upstream_side_points(tribs)

    bdy = BDYConverter(comment='BDY for WS1 test')
    res, tarr = bdy.read_lbx_csv('./WS1_all_river_Q-for-test.csv')
    bdy.merge_point_values([[p] for p in s_p], res, tarr,
        idstrfun=lambda group: 'sqvar' + '_'.join(['%d%d' % p for p in group]))
    bdy.save_bdy('only-source-WS1.bdy')
    bdy.merge_point_values(USPs.values(), res, tarr,
        idstrfun=lambda group: 'qvar' + '_'.join(['%d%d' % p for p in group]))
    #bdy.merge_point_values([p2], res, tarr)
    bdy.save_bdy('source-lateral-WS1.bdy')
