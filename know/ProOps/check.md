* [README](README.md) - ProOps Framework overview 
---
# Check

Implementation check, performance, monitoring and representational twin alignment.

## Monitoring and representational twin

Checks compare the implementation with a representational design
(digital twin or model). They are one of three types.
_Benchmark_ (quantitative analysis) provides specific metrics
which are comparable across platforms, software versions and
datasets. Bencharks provide overall performance data and include
generic CPU, Network and Memory USE (Utilization, Saturation and
Error) monitoring.
_Unit_ (functional analysis) testing insures
components are orchestrated according to the design
and interacting correctly.
_Profiling_ (qualitative analysis) of implementation, a break
out of components and system calls into relative ratios of time
and resource consumption. Profiling incurs a high overhead, skews
benchmark metrics, and only used as an analytic tool.

Identify how closely the implementation twins the [Design](design.md) plan.

### Benchmark - quantitative analysis

High level checks, basic operation checks and performance reporting.

* Performance [benchmark](check/benchmark.md), another example component.

### Unit - functional analysis

Compare the implementation primitive [Registration](exec.md#Registration) components with the
[Functional Plan](design.md#FunctionalPlan).

* Service [monitor](check/monitor.md) - example operational check.

### Profiling - qualitative analysis

General development resources, diagnostic software, analytic tools and component tutorials

  * [perf](https://perf.wiki.kernel.org/index.php/Main_Page) - Linux profiling with performance counters
    * [perf Examples](http://www.brendangregg.com/perf.html)
  * [FlemeGraph](https://github.com/brendangregg/FlameGraph) - Stack trace visualizer
    * [visualization of profiled software](http://www.brendangregg.com/flamegraphs.html) 
  * [flamescope](https://github.com/Netflix/flamescope) - exploring different time ranges as Flame Graphs.

