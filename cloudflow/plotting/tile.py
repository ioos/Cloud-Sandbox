import abc
import itertools
import functools
import math
import numpy as np
import os.path

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

def _qkx(qk):
    """ integer representation of quadkey x positon) """
    return functools.reduce(lambda a, b: (a << 1) | b, [int(c) % 2 for c in qk])


class TileBase(abc.ABC):
    """
    Abstract Base for Tile objects. Operations on Tiles utilize quadtree math,
    allowing quick zooming ability inside square spaces.

    """

    def __init__(self):
        pass

    def nudge(self, b, EPS=1.0e-3):
        if b[0] != b[2] and b[1] != b[3]:
            b = list(sum(x) for x in zip(b, (EPS, EPS, -EPS, -EPS)))
        return b

    def buffer(self, b):
        b = self.nudge(b)
        x, y, z = self.bounding_tile(*b)
        tiles = [(x + dx, y + dy, z) for dy in range(-1, 2) for dx in range(-1, 2)]
        return list(map(lambda l: self.bounds(*l), tiles))

    def quadkey(self, x, y, z):
        """ tile to quadkey

        Args:
            x (int): tile x coordinate.
            y (int): tile y coordinate.
            z (int): zoom level.

        Returns:
            str: The quadkey.

        """
        qk = []
        for _z in range(z, 0, -1):
            digit = 0
            mask = 1 << (_z - 1)
            if x & mask:
                digit += 1
            if y & mask:
                digit += 2
            qk.append(str(digit))
        return ''.join(qk)

    def quadkey_to_tile(self, qk):  # from mercantile source
        """Compute the tile for a given quadkey.
        :param str qk: quadkey
        :return tuple (x, y, i+1)"""

        x, y, i = 0, 0, 0
        for digit in reversed(qk):
            mask = 1 << i  # byte shift left by i
            if digit == '1':
                x = x | mask  # bitwise or
            elif digit == '2':
                y = y | mask
            elif digit == '3':
                x = x | mask
                y = y | mask
            elif digit != '0':
                raise ValueError('Unexpected quadkey digit: {}'.format(digit))
            i += 1
        return (x, y, i)

    def tile_ij(self, x, y, z, p):
        """ pixel offset within containing tile

        Args:
            x (int): tile x coordinate.
            y (int): tile y coordinate.
            z (int): zoom level.
            p (int): relative parent level. positive is zoom out.

        Returns:
            str: The quadkey.

        (i, j) offset in pixels
        """
        _qk = self.quadkey(x, y, z)
        i, j = 0, 0
        ij = [
            [0, 0], [1, 0],
            [0, 1], [1, 1]
        ]
        # index qk to get quadrants after zoom, enumerate
        for l, q in enumerate(map(int, _qk[-p:])):
            i += (128 // 2 ** l) * ij[q][0]  # offset pixel * quadrant
            j += (128 // 2 ** l) * ij[q][1]
        qx, qy, qz = self.quadkey_to_tile(_qk[:-p])
        return qx, qy, qz, i, j  # the offset in pixels in each direction

    def parent_tile(self, lonlats, MAX_ZOOM=32):
        """ common parent of a list of lon/lat pairs
        """
        return self.quadkey_to_tile(os.path.commonprefix([
            self.quadkey(*tile) for tile in [
                self.tile(*lonlat, MAX_ZOOM) for lonlat in lonlats
            ]
        ]))

    def bounding_tile(self, west, south, east, north):
        lons = [west, east]
        lats = [south, north]
        lonlats = itertools.product(lons, lats)
        return self.parent_tile(lonlats)

    def zoomout(self, b, nz=0):
        b = self.nudge(b)
        x, y, z = self.bounding_tile(*b)
        # don't zoom out past zero
        nz = min(z, nz)
        # use quadtree to zoom out
        px, py, pz, i, j = self.tile_ij(x, y, z, nz)
        return self.bounds(px, py, pz), i, j, nz

    def viewport(self, bbox, width, height, MAX_ZOOM=32):
        b = self.nudge(bbox)
        ulqk = self.quadkey(*self.tile(b[0], b[3], MAX_ZOOM))
        lrqk = self.quadkey(*self.tile(b[2], b[1], MAX_ZOOM))
        i = [c for c in range(len(ulqk)) if ulqk[c] != lrqk[c]][0]  # index of first difference
        for z in range(i, MAX_ZOOM):
            ulx, uly, ulz, uli, ulj = self.tile_ij(*self.quadkey_to_tile(ulqk[:z + 8]), 8)
            if _qkx(ulqk) > _qkx(lrqk):  # check ulx < lrx (by quadkey)
                ulx -= 2 ** z  # make negative (we've crossed the IDL)
            lrx, lry, lrz, lri, lrj = self.tile_ij(*self.quadkey_to_tile(lrqk[:z + 8]), 8)
            ni = (lrx - ulx) * 256 + lri - uli + 1  # full between tiles + pixels in last - pixels unused in first
            nj = (lry - uly) * 256 + lrj - ulj + 1
            if (ni >= width) and (nj >= height):  # plus 1 to include pixel offset zero
                x, y = np.meshgrid(range(ulx, lrx + 1), range(uly, lry + 1))
                x[x < 0] = x[x < 0] + 2 ** z  # adjust negative x tile values
                tiles = np.dstack((x, y, np.ones_like(x) * z))  # put the z in there
                box = (uli, ulj, uli + ni, ulj + nj)
                return tiles, box

    # abstract methods
    @abc.abstractmethod
    def tile(self):
        return NotImplemented

    @abc.abstractmethod
    def bounds(self):
        return NotImplemented


class Tile4326(TileBase):
    """EPSG:4326 implementation of TileBase for tile operations

    Notes
    -----
    For tests:
        - sum of first two digits of quadtree should NEVER be less than 2 or greater than 4
           +--------+--------+
           |xxxxxxxx|xxxxxxxx| (x) denotes tiles/pixels out of EPSG:4326 space
           |xxxxxxxx|xxxxxxxx|
           | 0[2|3] | 1[2|3] |
           |        |        |
           +--------+--------+
           |        |        |
           | 2[0|1] | 3[0|1] |
           |xxxxxxxx|xxxxxxxx|
           |xxxxxxxx|xxxxxxxx|
           +--------+--------+
    """

    def __init__(self):
        self.r = 360. / 256.  # initial resolution

    def _resolution(self, z):
        return self.r / 2. ** z

    def tile(self, lon, lat, z):
        """Compute the (x,y,z) coords for a EPSG:4326 (WGS:84) lon-lat.

        :param float lat: latitude in decimal degrees
        :param float lon: longitude in decimal degrees
        :param int     z: zoom level
        """
        i, j = [(180. + l) / self._resolution(z) for l in [lon, lat]]
        x = int(math.ceil(i / 256.)) - 1
        y = 2 ** z - int(math.ceil((j / 256.)))
        return x, y, z

    def bounds(self, x, y, z):
        """ Return the lon/lat bbox of a tile with x,y,z coords.
        NOTE:
        x varies left to right
        y varies top to bottom
        """
        _d = self._resolution(z) * 256.  # distance per pixel
        return (x * _d - 180., 180. - (y + 1) * _d, (x + 1) * _d - 180., 180. - y * _d)


class Tile3857(TileBase):
    """ EPSG:3857 implementation
    """

    def __init__(self):
        a = 6378137.0  # semi-major axis
        self.r = 2. * math.pi * a / 256.  # initial resolution: 156543.03392804062 for 256x256
        self.o = 2. * math.pi * a / 2.  # origin: 20037508.342789244

    def _resolution(self, z):
        return self.r / 2. ** z

    def tile(self, easting, northing, z):
        i, j = [(self.o + x) / self._resolution(z) for x in [easting, northing]]
        x = int(math.ceil(i / 256.)) - 1
        if x < 0:
            x = 2 ** z + x
        y = 2 ** z - int(math.ceil((j / 256.)))
        if y < 0:
            y = 2 ** z + y
        return x, y, z

    def bounds(self, x, y, z):
        _d = self._resolution(z) * 256.  # distance per pixel
        return (x * _d - self.o, self.o - (y + 1) * _d, (x + 1) * _d - self.o, self.o - y * _d)
