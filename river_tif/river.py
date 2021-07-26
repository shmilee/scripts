#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import time
import itertools
import numpy as np
import matplotlib.pyplot as plt
from collections import Counter
from skimage import io


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

    def _search_fill_tribs(self, tribs, search_arr):
        '''
        Read values from search_arr and fill them to each river tributaries.
        '''
        points = tribs[0][2]
        res = [search_arr[p[0], p[1]] for p in points]
        return [
            tribs[0] + (res,),
            [
                (jidx, self._search_fill_tribs(subtrib, search_arr))
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
                        add_info=[('w', 2.0, 10.0, {}), ]):
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
            or (label, search_arr). known dict's keys are the river points.
            search_arr's shape is equal to :attr:`river_arr`.
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
            if len(info) == 2:
                print('Add quantity: %s' % info[0])
                tribs = self._search_fill_tribs(tribs, info[1])
            elif len(info) == 4:
                print('Add quantity: %s' % info[0])
                a, b, c = info[1:]
                tribs = self._interp_tribs(tribs, startv=a, endv=b, known=c)
            else:
                try:
                    print('Warnning: ignore info of %s!' % info[0])
                except Exception:
                    print('Warnning: ignore one info!')
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

    def _save_tribs_lisflood(self, tribs, fo):
        '''
        Write each tributaries' info line by line to opend file object.
        '''
        idx, pidx, points = tribs[0][:3]
        w_arr, n_arr, de_arr, h_arr = tribs[0][3:]
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
            w, n, de, h = w_arr[i], n_arr[i], de_arr[i], h_arr[i]
            if i == 0:
                fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tQVAR qvar%d%d\n'
                         % (X, Y, w, n, de-h, p[0], p[1]))
            elif i == N-1:
                if pidx is None:
                    assert idx == 0
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tHVAR hvar%d%d\n'
                             % (X, Y, w, n, de-h, p[0], p[1]))
                else:
                    fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tQOUT %d\n'
                             % (X, Y, w, n, de-h, pidx))
            elif i in join_indexs:
                _index = join_indexs.index(i)
                fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\tTRIB %d\n'
                         % (X, Y, w, n, de-h, join_subtribs[_index]))
            else:
                fo.write('%.1f\t%.1f\t%.4f\t%.5f\t%.6f\n'
                         % (X, Y, w, n, de-h))
        # write its subtrib
        for jidx, subtrib in tribs[1]:
            self._save_tribs_lisflood(subtrib, fo)

    def save_tribs(self, tribs, Ntribs, outfile, fmt='lisflood'):
        '''
        Save one river's tributaries to a file.

        Notes
        -----
        1. lisflood add_info: 'w', 'n', 'DE', 'h'
        '''
        with open(outfile, 'w+t') as fo:
            if fmt == 'lisflood':
                fo.write('Tribs %d\n' % Ntribs)
                self._save_tribs_lisflood(tribs, fo)
            else:
                raise NotImplementedError('%s is not implemented!' % fmt)

    # plot, show, check
    def plot_get_river_tribs(self, tribs, N, dinfo):
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


if __name__ == '__main__':
    dsz_kws = dict(river_tif='./dsz_river.tif',
                   direction_tif='./dszliuxiang.tif',
                   dem_tif='./dsz_demr.tif')
    add_info = [('w', 'TODO'),
                ('n', 0.32, 0.32, {}),
                ('de', 'TODO'),
                ('h', 2.0, 4.0, {})]
    rc = RiverConverter(**dsz_kws)
    p0 = (80, 100)
    tadd_info = add_info.copy()
    width_arr = io.imread('./dsz_riverwidth.tif')
    tadd_info[0] = ('w', width_arr)
    tadd_info[2] = ('de', rc.dem_arr)
    tribs, N, d = rc.get_river_tribs(
        p0, end_in_channel=True, add_info=tadd_info)
    rc.save_tribs(tribs, N, './DSZ-out-0.river')
    rc.plot_get_river_tribs(tribs, N, d)
