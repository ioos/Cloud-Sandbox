#!/usr/bin/python3

import os
import datetime
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

import utils.modelUtil as util


def templatetest():
    template = "../adnoc/ocean.in.template"
    outfile = "ocean.in"

    nodeCount = 1
    coresPN = 36

    tiles = util.getTiling(nodeCount * coresPN)

    # Just a dictionary
    # Could also read this in from a json file
    settings = {
        "__NTILEI__": tiles["NtileI"],
        "__NTILEJ__": tiles["NtileJ"],
        "__NTIMES__": 60,
        "__TIME_REF__": "20191212.00"
    }

    util.sedoceanin(template, outfile, settings)


def todaytest():
    CDATE = "today"

    if CDATE == "today":
        today = datetime.date.today().strftime("%Y%m%d")
        # print(f"today is: {today.year}{today.month}{today.day}")
        print(f"today is: {today}")


def pathsize():
    path = '/mnt/efs/com/liveocean/forcing/f2020.01.28'
    size = os.path.getsize(path)
    print(f"size is : {size}")


def ndaystest():
    # refdate = "2016010100"
    refdate = "20160101.0d0"

    cdate = "2020020512"
    # cdate - refdate
    days = util.ndays(cdate, refdate)
    # print ("ndays is", days)

    JAN1CURYR = f"{cdate[0:4]}010100"
    TIDE_START = util.ndays(JAN1CURYR, refdate)
    print(f"tide_start is : {TIDE_START}")

    DSTART = util.ndays(cdate, refdate)
    # DSTART = f"{'{:.4f}'.format(DSTART)}.d0"
    DSTART = f"{'{:.4f}'.format(float(DSTART))}d0"
    print(DSTART)


def ndate_hrs_test():
    cdate = "2020020500"
    hrs = -6

    print(f"cdate: {cdate}, hrs: {hrs}")
    date = util.ndate_hrs(cdate, hrs)
    print(date)


def ndate_test():
    cdate = "20200101"
    days = -1461

    print(f"cdate: {cdate}, days: {days}")
    newdate = util.ndate(cdate, days)
    print(newdate)


def getTilingTest():
    # totalCores = 144
    # ratio = 2.25
    # ratio = 4
    # ratio = 661/1300  # liveocean .50769 0.5625 9 x 16
    # ratio = 0.44444   # 8x18 (144)  12x18 (216)  12x24 (288)
    # totalCores = 216
    # ratio = 0.375     # 9x24 (216)
    # ratio = 1          # 18x12 (216)
    totalCores = 180
    ratio = .5  # 10x18 .5556 (180)
    ratio = .1  # 5x36 (180)
    ratio = .02222  # 2x90 (180)
    # totalCores = 288
    # totalCores = 72
    # ratio = 1.125 # 9 x 8
    # ratio = 1     # 8 x 9
    # dbofs 117 x 730
    # ratio=.16    # DBOFS
    # totalCores = 72
    # NtileI :  4  NtileJ  18
    # DEBUG: totalCores: 72 I*J: 72 ratio: 0.16 I/J: 0.2222222222222222

    util.getTiling(totalCores, ratio)


getTilingTest()
# ndate_hrs_test()
# ndate_test()
# ndaystest()
# todaytest()
# pathsize()
