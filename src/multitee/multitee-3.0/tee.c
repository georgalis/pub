/* tee.c: clone of tee program
Daniel J. Bernstein, brnstnd@nyu.edu.
Depends on getopt.h, ralloc.h, fmt.h, sod.h.
Requires multitee. Otherwise portable to any UNIX system.
7/22/91: Baseline. tee 1.0, public domain.
No known patent problems.

Documentation in tee.1.

XXX: should use optprogname for program name
*/

#include <stdio.h> /* for fprintf(stderr,...) */
#include <signal.h> /* for SIGINT */
#include <sys/file.h>
#ifndef O_WRONLY
#define O_WRONLY 1 /* XXX: aargh */
#endif
#include "getopt.h"
#include "ralloc.h"
#include "fmt.h"
#include "sod.h"

SODdecl(argstack,char *);

main(argc,argv,envp)
int argc;
char *argv[];
char *envp[];
{
 int opt;
 int flagappend;
 int flagign;
 argstack arghead;
 argstack arg;
 char *t;
 int fd;
 unsigned int numargs;
 static char problem[1024];

 flagappend = 0;
 flagign = 0;
 while ((opt = getopt(argc,argv,"ai")) != opteof)
   switch(opt)
    {
     case 'a':
       flagappend = 1;
       break;
     case 'i':
       flagign = 1;
       break;
     case '?':
     default:
       exit(1);
    }
 argc -= optind;
 argv += optind;
 arghead = 0;

 if (flagign)
   signal(SIGINT,SIG_IGN);

 numargs = 2;
 while (*argv)
  {
   fd = open(*argv,O_WRONLY | O_CREAT | (flagappend ? O_APPEND : O_TRUNC),0666);
   if (fd == -1)
    {
     t = problem;
     t += fmt_strncpy(t,"tee: warning: cannot open ",0);
     t += fmt_strncpy(t,*argv,(problem + sizeof(problem)) - t - 3);
     *t = 0;
     perror(problem);
    }
   else
    {
     arg = SODalloc(argstack,arg,ralloc);
     if (!arg)
      {
       fprintf(stderr,"tee: fatal: out of memory\n");
       exit(3);
      }
     SODdata(arg) = ralloc(3 + fmt_uint(FMT_LEN,fd));
     if (!SODdata(arg))
      {
       fprintf(stderr,"tee: fatal: out of memory\n");
       exit(3);
      }
     t = SODdata(arg);
     t += fmt_strncpy(t,"0:",2); t += fmt_uint(t,fd); *t = 0;
     SODpush(arghead,arg);
     ++numargs;
    }
   ++argv;
  }

 argv = RALLOC(char *,numargs + 1);
 if (!argv)
  {
   fprintf(stderr,"tee: fatal: out of memory\n");
   exit(3);
  }

 argv[numargs] = 0;
 while (arghead)
  {
   SODpop(arghead,arg);
   argv[--numargs] = SODdata(arg);
   SODfree(arg,rfree);
  }
 argv[--numargs] = "0:1";
 argv[--numargs] = "multitee";
 /* numargs is now 0 */

 execvp(argv[0],argv);
 t = problem;
 t += fmt_strncpy(t,"tee: fatal: cannot execute ",0);
 t += fmt_strncpy(t,*argv,(problem + sizeof(problem)) - t - 3);
 *t = 0;
 perror(problem);
 exit(4);
}
