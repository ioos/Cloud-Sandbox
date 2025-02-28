#!/usr/bin/python3

import modelUtil as utils

def test_get_baseline_lo():

    cdate = "20200527"
    vdir = "/com/liveocean-uw/f2020.05.27"
    sshuser = "ptripp@boiler.ocean.washington.edu"

    utils.get_baseline_lo(cdate, vdir, sshuser)


#def get_baseline_lo(cdate, vdir, sshuser):

def main():
 
    #vdir = vdir[0:-11]
    #vdir = vdir.split('/')[0:-1]
    #vdir = '/'.join(vdir)
    #localpath = '/'.join(vdir.split('/')[0:-1])
    #print(localpath)
    test_get_baseline_lo()


if __name__ == '__main__':
    main()

