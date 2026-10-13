# Process Substitution and Command Substitution in bash

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

`$(cmd)` and `<(cmd)` both run a command for its output, and both look
like a way to get a value without a pipeline. They differ in how the
output reaches the shell, in whether the shell waits for the command to
finish, and therefore in what each costs. This note explains the
mechanism for a reader comfortable with bash but new to process
substitution and to file descriptors, then measures where each form is
faster and why.

<!--contents 2 3 pre="## Contents" post="---"-->

## File descriptors and pipes, briefly

A process does all of its I/O through small integers called file
descriptors (fds). By convention 0 is standard input, 1 standard
output, 2 standard error; anything a process opens gets the next free
number. A redirection such as `< file` or `2>&1` is the shell arranging
which open file sits behind which number before a command runs.

A pipe is a kernel buffer with two fds: whatever is written to one end
can be read from the other. `a | b` creates a pipe, makes it `a`'s fd 1
and `b`'s fd 0, and runs both at once. Reading an empty pipe blocks
until data arrives; reading returns end of file (EOF) only after every
writer has closed its end, which normally happens when the writing
process exits.

On Linux and macOS each process can also name its own open fds as
files: `/dev/fd/3` means "my fd 3" (on Linux a view of
`/proc/self/fd`). Process substitution depends on this.[^1]

## Command substitution: `$(cmd)`

`x=$(cmd)` runs in this order:[^2]

1. bash creates a pipe and forks a child process;
2. the child runs `cmd` with its fd 1 on the pipe (an external command
   is exec'd in the child, replacing the forked shell);
3. the parent reads the pipe in blocks until EOF, that is, until `cmd`
   and anything it started have closed the pipe, usually by exiting;
4. the parent reaps the child and sets `$?` to its exit status;
5. trailing newlines are removed and the text is substituted.

The parent waits through all of it. Whatever `cmd` does after its last
useful byte, such as flushing, freeing, unmapping libraries or
finishing a loop, is paid for before the next line of the script runs.

## Process substitution: `<(cmd)`

`<(cmd)` is replaced by a filename. Running `read -r x < <(cmd)`:[^3]

1. bash creates a pipe and forks a child to run `cmd`, asynchronously,
   with its fd 1 on the write end;
2. the parent keeps the read end open as some fd, say 63, and
   substitutes the name `/dev/fd/63`;
3. the redirection `< /dev/fd/63` opens that name as the stdin of
   `read`, which runs in the current shell;
4. `read` returns as soon as it has a line; the parent continues while
   the child may still be running, and bash reaps it later;
5. `$!` holds the child's pid, and `wait $!` (bash 4.4 and later) can
   collect its exit status if that matters; `$?` after the line is
   `read`'s status, not `cmd`'s.

The two `<` in `< <(cmd)` are separate: the first is an ordinary input
redirection, the second begins the substitution. They need the space
between them. Where `/dev/fd` is missing, bash falls back to a named
pipe (FIFO) created in `$TMPDIR`, which means a file is written there.

`>(cmd)` is the mirror image: a filename whose writes become `cmd`'s
stdin, as in `tee >(gzip >log.gz)`.

## Both fork: `$$` and `$BASHPID`

Neither form runs in the shell's own process; each child has its own
pid. This is easy to miss because `$$` is fixed when the shell starts
and inherited unchanged by every subshell, so `echo $$` prints the
parent's pid inside `$( )`, `<( )` and `( )` alike. `$BASHPID`
reports the pid of the process actually running:[^4]

    $ bash -c 'read -r a < <(echo "$BASHPID") ; echo "shell $BASHPID, inside <( ) $a"'
    shell 199, inside <( ) 200

The practical rule: expand anything that must name the current
process in the current shell, and pass the value in.

    me=$BASHPID ; read -r t < <(ps -o lstart= -p "$me")   # correct
    read -r t < <(ps -o lstart= -p "$BASHPID")           # names the child

## What `read x < <(cmd)` saves, and why

It does not save the fork. Both forms fork once (plus an exec for an
external command). The savings are elsewhere, and they apply only in
particular shapes of use.

### It does not wait for the producer to finish

`$(cmd)` cannot finish until the pipe reaches EOF, so it always waits
for the producer's last write and, in practice, its exit. `read`
returns at the first newline. If the line you want comes early, the
rest of the producer's life, including its remaining output, its exit
and its teardown, is taken off the script's critical path.

If the producer keeps writing after `read` has returned, the pipe's
read end is closed when the redirection ends, and the producer's next
write fails with `SIGPIPE`. A long listing whose first line is all you
need is therefore cut short instead of read to the end.

### The leftover work runs on another CPU

The producer's remaining work does not disappear; it runs concurrently
with the script. With more than one CPU it runs in parallel, which is
where the gain comes from. On one CPU it competes for the same core and
the gain largely vanishes. The measurement below shows this directly.

### The consumer runs in the current shell

`cmd | read x` looks equivalent but is not: each part of a pipeline
runs in a subshell, so `x` is set in a child and lost when it exits
(unless `shopt -s lastpipe` is in effect, which works only when job
control is off). With `read x < <(cmd)` the builtin runs in the current
shell and the assignment persists. This is a matter of correctness, not
speed, and it is the main reason to prefer the form over a pipeline
that ends in `read`, `mapfile` or a `while read` loop that sets
variables.

## Where it is slower

`read` on a pipe reads one byte per system call. The fd it reads may be
shared with later commands (it is stdin), so `read` must not consume
past its delimiter, and on a pipe it cannot seek back over extra bytes.
On a regular file it reads in blocks and seeks back; on a pipe it can
only take one byte at a time:

    read(0, "a", 1) = 1
    read(0, "b", 1) = 1
    read(0, "c", 1) = 1
    read(0, "\n", 1) = 1

That cost is negligible for a line and large for a document. `$(cmd)`
reads in blocks and is far faster for capturing everything. `mapfile`
from a pipe showed the same cost as `read` in the measurements below.
Process substitution also adds a few system calls (opening
`/dev/fd/N`, duplicating fds), which can make it slightly slower than
`$( )` for a trivial producer.

## Measurements

These are from GNU bash 5.2.21 on Linux x86_64 with two virtual CPUs.
"One CPU" means the same script pinned with `taskset -c 0`. Times are
seconds for the whole loop.

| case | loop | 2 CPUs | 1 CPU |
|---|---|---|---|
| `x=$(date +%s)` | 2000 | 3.17 | 2.79 |
| `read -r x < <(date +%s)` | 2000 | 3.27 | 3.03 |
| `x=$(echo hi)` | 2000 | 0.78 | 0.47 |
| `read -r x < <(echo hi)` | 2000 | 0.92 | 0.92 |
| `x=$(echo hi ; tail_work)` | 300 | 7.31 | 7.62 |
| `read -r x < <(echo hi ; tail_work)` | 300 | 3.60 | 7.34 |
| `x=$(seq 200000)` | 20 | 0.27 | 0.25 |
| `read -r -d '' x < <(seq 200000)` | 20 | 5.19 | 5.23 |
| `mapfile -t a < <(seq 200000)` | 20 | 5.76 | 5.57 |
| `read -r x < <(seq 200000)`, first line | 20 | 0.04 | 0.04 |

`tail_work` is a CPU-bound loop the producer runs after printing its
line. Four findings follow:

- For a trivial producer, `$( )` is as fast or slightly faster.
- When the producer has work left after the needed line, process
  substitution halves the time on two CPUs and gains nothing on one.
  This is the parallelism described above.
- When the whole output is needed, `$( )` is about twenty times faster
  than reading it from a process substitution.
- When only the first line is needed from a long output, process
  substitution wins outright, because the producer is stopped by
  `SIGPIPE`.

## Does it vary by machine

Yes, along three lines; the processor architecture by itself matters
less than these:

- **CPU count and load.** The overlap gain needs a free core. On a
  single core, or a machine already busy, it shrinks toward zero, as
  the one-CPU column shows.
- **Operating system process costs.** What `$( )` waits through, chiefly
  process exit and teardown, is more expensive on some systems than
  others. macOS is generally reported to have costlier process creation
  and exit than Linux, so taking exit off the critical path should
  matter more there. That is a likely explanation when process
  substitution benchmarks faster on a Mac even for small producers, but
  the measurements above are Linux only and do not confirm it.
- **The producer.** A command with a heavy shutdown (many shared
  libraries, buffered output, cleanup handlers) gives `<( )` more to
  hide. A builtin that exits instantly gives it nothing.

To test a given machine, time both forms in a loop with the producers
you actually use, and on Linux compare against a run under
`taskset -c 0`:

    N=2000
    time for ((i=0;i<N;i++)); do x=$(date +%s); done
    time for ((i=0;i<N;i++)); do read -r x < <(date +%s); done

## Choosing between them

- Use `read -r x < <(cmd)` when you want the first line or first
  record, when the producer may have work left after it, or when a
  builtin consuming the output must set variables in the current shell.
- Use `x=$(cmd)` when you want the whole output, when you need `cmd`'s
  exit status in `$?`, or for a trivial producer where either form is
  fine.
- Use a plain pipeline when every stage is an external command and no
  variable needs to survive; the shell stays out of the data path
  entirely.
- When the producer's status matters after `read < <(cmd)`, check it
  with `wait $!` (bash 4.4 and later), or test the value that was read.
- Bash 5.3 adds `${ cmd; }`, a command substitution that runs in the
  current shell without forking.[^5]

## Who waits for the producer

Every difference above comes from one question: who waits for the
producer, and for how long. `$(cmd)` takes the whole of the producer's
life onto the script's own clock, because its result is defined only at
EOF. That is the price of having every byte and the exit status, and
it is why `$( )` is the right tool for a whole output. `<(cmd)` turns
the producer into a file the shell reads only as far as it needs. What
the script never reads, it never waits for. What the producer still has
to do happens beside the script on another core, and is cut off by
`SIGPIPE` when nobody will read it. A process substitution is faster
exactly when there is something the script can decline to wait for. On
a machine with no spare core, or with a producer that has nothing left
to do, that something is gone and the two forms cost about the same.

[^1]: Bash Reference Manual, Process Substitution: "Process substitution is supported on systems that support named pipes (FIFOs) or the /dev/fd method of naming open files." <https://www.gnu.org/software/bash/manual/bash.html#Process-Substitution>
[^2]: Bash Reference Manual, Command Substitution. <https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution>
[^3]: Bash Reference Manual, Process Substitution (asynchronous execution, filename substitution). <https://www.gnu.org/software/bash/manual/bash.html#Process-Substitution>
[^4]: Bash Reference Manual, Bash Variables, `BASHPID` and `$`. <https://www.gnu.org/software/bash/manual/bash.html#Bash-Variables>
[^5]: Bash 5.3 release notes (NEWS), new form of command substitution executed in the current shell context. <https://git.savannah.gnu.org/cgit/bash.git/tree/NEWS>
