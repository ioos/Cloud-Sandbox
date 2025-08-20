Hotstart file needs to be combined:

IMPORTANT NOTE: 

https://schism-dev.github.io/schism/master/getting-started/post-processing.html

combine_hotstart7.f90 is used combine process-specific hotstart outputs (outputs/hotstart_0*.nc) into hotstart.nc. This is required even if you used scribed I/O (as hotstart outputs are still be emitted per MPI process).

It is built with the schism code build.
ex: /save/patrick/schism/bin/combine_hotstart7

Usage example, 720 is first day, 1440 is day 2, 2160 is day 3 etc: 
   module load intel_x86_64
   cd /com/patrick/secofs/20171201
   /save/patrick/schism/bin/combine_hotstart7 -i 720

If there is not enough memory on the head node, you will see this error:
Allocation error (7) 
You need large enough machine

