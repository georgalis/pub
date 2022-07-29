/* multitee.c: send multiple inputs to multiple outputs
Daniel J. Bernstein, brnstnd@nyu.edu.
Depends on sigsched.h, sigdfl.h, getopt.h, ralloc.h, scan.h, fmt.h, sod.h.
Requires UNIX: read(), write(), perror().
7/22/91: Baseline. multitee 3.0, public domain.
No known patent problems.

This is a complete rewrite of multitee 2.0, as distributed in
comp.sources.unix volume 22.

Documentation in multitee.1.

XXX: should use optprogname
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include "sigsched.h"
#include "sigdfl.h"
#include "getopt.h"
#include "ralloc.h"
#include "scan.h"
#include "fmt.h"
#include "sod.h"
extern int errno;

#ifndef EWOULDBLOCK
#define EWOULDBLOCK 0
#endif
#ifndef EPIPE
#define EPIPE 0
#endif

static int bufsize = 8192;

/*
We take pains to avoid all I/O copies. Each live buffer has an ending
position; the buffer is read into as long as the ending position isn't
the actual end of the buffer. Each live buffer also has an output
schedule count, and each output descriptor for the buffer has a starting
position. As soon as data is read in, it's scheduled to be written out
on each of the output descriptors which isn't already scheduled. The
schedule count is checked at this time and whenever it is decremented;
if it is 0, the buffer is emptied, and all starting positions are set to
0. Upon an output scheduling, the buffer is written from the starting
position to the ending position. (If this produces an error, die, except
in cases like EINTR.) The starting position is incremented by the write
count. If this brings it to the ending position, the schedule count is
decremented. Otherwise the write is rescheduled.
*/

int flagverbose;

void outofmem()
{
 static char mfoom[] = "multitee: fatal: out of memory\n";
 if (flagverbose)
   write(2,mfoom,sizeof(mfoom));
   /* XXX: if it fails, tough luck */
 exit(3);
}

void readerr(fd)
int fd;
{
 static char mwre[100 + FMT_ULONG]; char *t;
 if (!flagverbose)
   return;
 t = mwre + fmt_strncpy(mwre,"multitee: warning: cannot read descriptor ");
 t += fmt_uint(t,fd);
 *t = 0;
 perror(mwre); /*XXX*/
}

void writeerr(fd)
int fd;
{
 static char mwwe[100 + FMT_ULONG]; char *t;
 if (!flagverbose)
   return;
 t = mwwe + fmt_strncpy(mwwe,"multitee: warning: cannot write descriptor ");
 t += fmt_uint(t,fd);
 *t = 0;
 perror(mwwe); /*XXX*/
}

struct iosc
 {
  int in;
  int out;
  int flagsched;
  int startpos;
  int breakpipe;
  int dead;
 }
;

SODdecl(intstack,int);
SODdecl(ioscstack,struct iosc);

ioscstack *fdio;
intstack *fdeof;
int *fdlive;
int *fdendpos;
int *fdschedcnt;
char **fdbuf;
int fdinmax;

void nomorewrite(fdout)
int fdout;
{
 int i;
 ioscstack iosc;
 for (i = 0;i <= fdinmax;++i)
   if (fdlive[i])
     for (iosc = fdio[i];iosc;iosc = SODnext(iosc))
       if (SODdata(iosc).out == fdout)
	 SODdata(iosc).dead = 1;
}

/* forward declarations of rescheduling routines */

extern void donoread();
extern void checksched();
extern void doeof();
extern void dowritesched();
extern void dowriteunsched();

/* I/O routines */

void readit(fd)
int fd;
{
 int r;
 int endpos;
 ioscstack iosc;

 endpos = fdendpos[fd];
 if (fdlive[fd])
  {
   r = read(fd,fdbuf[fd] + endpos,bufsize - endpos);
   /* XXX: this'll be slow if endpos is not aligned */
   if (r == -1)
    {
     if (errno == EWOULDBLOCK)
       return;
       /* sample case where this can happen: someone reads before we do */
     readerr(fd);
     r = 0;
    }
  }
 else
   r = 0;
 if (r == 0)
  {
   donoread(fd);
   doeof(fd);
   return;
  }
 fdendpos[fd] = endpos + r;
 if (fdio[fd])
  {
   for (iosc = fdio[fd];iosc;iosc = SODnext(iosc))
     if (SODdata(iosc).flagsched == 0)
       /* ``scheduled to be written out on each of the output descriptors'' */
       dowritesched(&(SODdata(iosc)));
   /* it says ``schedule count is checked at this time...'' */
   /* but as an optimization, since fdio[fd], schedcnt must be positive */
  }
 else
   fdendpos[fd] = 0; /* throwing it away immediately */
 if (fdendpos[fd] >= bufsize)
   donoread(fd); /* ``buffer is read into as long as...'' */
}

void writeit(p)
ss_idptr p;
{
 struct iosc *ioscp;
 int in;
 int w;

 ioscp = (ioscstack) p;
 in = ioscp->in;

 if (ioscp->dead)
   w = fdendpos[in] - ioscp->startpos;
 else
   w = write(ioscp->out,fdbuf[in] + ioscp->startpos,fdendpos[in] - ioscp->startpos);
 /*``buffer is written from the starting position to the ending position...''*/
 if (w == -1)
  {
   if (errno == EWOULDBLOCK)
     w = write(ioscp->out,fdbuf[in],1); /* XXX: kludge alert! */
   if (w == -1)
    {
     if ((errno == EPIPE) && ioscp->breakpipe)
       sigdfl(SIGPIPE);
     writeerr(ioscp->out);
     nomorewrite(ioscp->out);
     w = 0;
    }
  }
 if (w == 0)
   ; /* XXX: wtf? */
 ioscp->startpos += w; /* ``starting pos is incremented by write count'' */

 if (ioscp->startpos == fdendpos[in])
   /* ``if this brings it to the ending position, schedcnt is decremented'' */
   dowriteunsched(ioscp);
}

/* rescheduling routines */

void donoread(fd)
int fd;
{
 ss_unsched(ss_sigread(fd),readit,fd);
}

void checksched(fd)
int fd;
{
 ioscstack iosc;
 /* ``if it is 0, buffer is emptied, and all startpos are set to 0.'' */
 if (!fdschedcnt[fd])
  {
   if (fdendpos[fd] == bufsize)
     if (ss_schedwait(ss_sigread(fd),readit,fd,1) == -1)
       outofmem();
   fdendpos[fd] = 0;
   for (iosc = fdio[fd];iosc;iosc = SODnext(iosc))
     SODdata(iosc).startpos = 0; /* schedcnt must be 0 */
  }
}

void doeof(fd)
int fd;
{
 intstack eof;
 fdlive[fd] = 0; /* just in case */
 for (eof = fdeof[fd];eof;eof = SODnext(eof))
   if (fdlive[SODdata(eof)])
    {
     fdlive[SODdata(eof)] = 0;
     donoread(SODdata(eof));
     if (ss_schedonce(ss_asap(),readit,SODdata(eof)) == -1)
       outofmem();
    }
}

void dowritesched(ioscp)
struct iosc *ioscp;
{
 if (!ioscp->flagsched)
   ++fdschedcnt[ioscp->in];
 ioscp->flagsched = 1;

 if (ss_schedvwait(ss_sigwrite(ioscp->out),writeit,0,0,(ss_idptr) ioscp,1) == -1)
   outofmem();
 /* Exercise for the reader: Show that this ``works'' for signals but */
 /* can fail miserably with interrupts. This is one situation where */
 /* the behavior of multiple threads scheduled upon one signal is */
 /* very important. */
}

void dowriteunsched(ioscp)
struct iosc *ioscp;
{
 int in;

 ss_unschedv(ss_sigwrite(ioscp->out),writeit,0,0,(ss_idptr) ioscp);
 in = ioscp->in;
 ioscp->flagsched = 0;
 --fdschedcnt[in];
 checksched(in); /* ``schedule count is checked [when] decremented...'' */
}

/* and the function which pulls it all together */

SODdecl(opstack,struct { int fdin; int fd; int special; });

main(argc,argv)
int argc;
char *argv[];
{
 int opt;
 char ch;
 char *t;
 int fd;
 intstack fdinhead;
 intstack fdin;
 opstack iohead;
 opstack eofhead;
 opstack op;
 ioscstack iosc;

 /* XXXXXXXXX: set non-blocking I/O? */

 fdinhead = 0;
 iohead = 0;
 eofhead = 0;

 flagverbose = 1;

 while ((opt = getopt(argc,argv,"b:vqQ")) != opteof)
   switch(opt)
    {
     case 'b':
       if (optarg[scan_uint(optarg,&bufsize)])
	 ; /* extra chars; no meaning at this time */
       break;
     case 'v':
       flagverbose = 2;
       break;
     case 'q':
       flagverbose = 0;
       break;
     case 'Q':
       flagverbose = 1;
       break;
     case '?': /*XXX*/
     default:
       exit(1); /*XXX*/
    }
 argc -= optind;
 argv += optind;

 while (*argv)
  {
   fdin = SODalloc(intstack,fdin,ralloc);
   if (!fdin)
     outofmem();
   t = *argv;
   t += scan_uint(t,&(SODdata(fdin)));
   SODpush(fdinhead,fdin);
   while (ch = *t)
    {
     op = SODalloc(opstack,op,ralloc);
     if (!op)
       outofmem();
     SODdata(op).fdin = SODdata(fdin);
     SODdata(op).special = 0;
     ++t;
     t += scan_uint(t,&(SODdata(op).fd));
     switch(ch)
      {
       case ':':
	 SODdata(op).special = 1;
       case '-':
       case ',':
	 SODpush(iohead,op);
	 break;
       case 'e':
	 SODpush(eofhead,op);
	 break;
       /* XXX: here's the greatest possibilities for future development */
       default:
	 /* XXX: ? */
	 ;
      }
    }
   ++argv;
  }

 if (!fdinhead)
   exit(0); /* might as well take the easy way out */
 fdinmax = SODdata(fdinhead);
 for (fdin = fdinhead;fdin;fdin = SODnext(fdin))
  {
   fd = SODdata(fdin);
   if (fd > fdinmax)
     fdinmax = fd;
  }
 
 fdio = (ioscstack *) ralloc((fdinmax + 1) * sizeof(ioscstack));
 if (!fdio) outofmem();
 for (fd = 0;fd <= fdinmax;++fd) fdio[fd] = 0;
 fdeof = (intstack *) ralloc((fdinmax + 1) * sizeof(intstack));
 if (!fdeof) outofmem();
 for (fd = 0;fd <= fdinmax;++fd) fdeof[fd] = 0;
 fdlive = (int *) ralloc((fdinmax + 1) * sizeof(int));
 if (!fdlive) outofmem();
 for (fd = 0;fd <= fdinmax;++fd) fdlive[fd] = 0;
 fdendpos = (int *) ralloc((fdinmax + 1) * sizeof(int));
 if (!fdendpos) outofmem();
 for (fd = 0;fd <= fdinmax;++fd) fdendpos[fd] = 0;
 fdschedcnt = (int *) ralloc((fdinmax + 1) * sizeof(int));
 if (!fdschedcnt) outofmem();
 for (fd = 0;fd <= fdinmax;++fd) fdschedcnt[fd] = 0;
 fdbuf = (char **) ralloc((fdinmax + 1) * sizeof(char *));
 if (!fdbuf) outofmem();
 /* no fdbuf initialization needed */

 while (fdinhead)
  {
   SODpop(fdinhead,fdin);
   fdlive[SODdata(fdin)] = 1;
   SODfree(fdin,rfree);
  }

 for (fd = 0;fd <= fdinmax;++fd)
   if (fdlive[fd])
     if (!(fdbuf[fd] = ralloc(bufsize)))
       outofmem();

 while (iohead)
  {
   SODpop(iohead,op);
   iosc = SODalloc(ioscstack,iosc,ralloc);
   if (!iosc)
     outofmem();
   SODdata(iosc).in = SODdata(op).fdin;
   SODdata(iosc).out = SODdata(op).fd;
   SODdata(iosc).dead = 0;
   SODdata(iosc).breakpipe = SODdata(op).special; /*XXX*/
   SODdata(iosc).startpos = 0;
   SODdata(iosc).flagsched = 0;
   SODpush(fdio[SODdata(op).fdin],iosc);
   SODfree(op,rfree);
  }

 while (eofhead)
  {
   SODpop(eofhead,op);
   fdin = SODalloc(intstack,fdin,ralloc);
   if (!fdin)
     outofmem();
   SODdata(fdin) = SODdata(op).fd;
   SODpush(fdeof[SODdata(op).fdin],fdin);
   SODfree(op,rfree);
  }

 for (fd = 0;fd <= fdinmax;++fd)
   if (fdlive[fd])
     ss_schedwait(ss_sigread(fd),readit,fd,1);

 ss_addsig(SIGPIPE);

 if (ss_exec() == -1)
   outofmem();

 exit(0);
}
