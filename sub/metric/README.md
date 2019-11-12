# Metric Reporting

###### Generate disk/cpu db, and metric graphs

* Auto probe disk partitions, setup tables, create disk/cpu graphics

[screenshot](5dcad60b-ScreenShot-20191112_075459.png)

Discover partitions and generate cpu / disk utilization graphics.
Notable, the cpu idle % graph is aligned with a 1/5/15 minute
load stacked graph (log scale) and a third cpu utilization graph
stacks interrupt, system, user and nice clocks, to analyze when
the "green" idle time goes away. In the disk usage, the red will
drop down as space is used up. Not enough inodes to see here, but
there is a gold line at the bottom of the disk graphs, this will
rise to the top, as 100% of them are consumed.

  * rrd-cpu.sh
  * rrd-disk.sh

