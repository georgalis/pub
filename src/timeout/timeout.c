/*
 * command_with_timeout.c
 * 
 * This program executes a given command with a specified timeout.
 * If the command doesn't complete within the timeout period, it is terminated.
 * 
 * Usage: ./command_with_timeout [options] <timeout> -- <command> [args...]
 * 
 * Options:
 *   -s, --signal <signal>  Specify the signal to send when timeout occurs (default: SIGTERM)
 *   -k, --kill-after <duration>  Send SIGKILL signal if command is still running this long after the initial signal
 * 
 * Timeout format:
 *   <number>[unit]
 *   where unit can be:
 *     s - seconds (default)
 *     m - minutes
 *     h - hours
 *     d - days
 * 
 * Examples:
 *   ./command_with_timeout 5.5 -- sleep 10
 *   ./command_with_timeout -s SIGKILL 2m -- ls -R /
 *   ./command_with_timeout --signal 9 --kill-after 30s 1.5h -- long_running_command -q
 */

/* _GNU_SOURCE is defined to enable certain GNU/Linux-specific features */
#define _GNU_SOURCE

/* Include necessary header files */
#include <stdio.h>    /* For input/output functions like printf */
#include <stdlib.h>   /* For general functions like exit, atoi */
#include <string.h>   /* For string manipulation functions like strcasecmp */
#include <unistd.h>   /* For POSIX operating system API like fork, exec */
#include <signal.h>   /* For signal handling functions */
#include <sys/types.h>/* For pid_t and other type definitions */
#include <sys/wait.h> /* For waitpid function */
#include <errno.h>    /* For errno variable and related constants */
#include <getopt.h>   /* For getopt_long function to parse command-line options */
#include <math.h>     /* For floor function */

/* Define a constant for the exit code when a timeout occurs */
#define TIMEOUT_EXIT_CODE 124

/* Global variables */
int g_timeout_signal = SIGTERM;  /* Default signal to send on timeout */
double g_kill_after = -1;        /* Time to wait before sending SIGKILL, -1 means disabled */

/* Function prototypes */
void print_usage(const char *program_name);
double parse_timeout(const char *timeout_str);
int parse_signal(const char *signal_str);
void sigalrm_handler(int signum);

/*
 * Main function - entry point of the program
 *
 * Parameters:
 *   argc: (int) The number of command-line arguments
 *   argv: (char **) An array of strings containing the command-line arguments
 *     argv[0] is the name of the program
 *     argv[1] to argv[argc-1] are the arguments passed to the program
 *
 * Returns:
 *   An integer indicating the exit status of the program
 */
int main(int argc, char *argv[]) {
    int opt;
    double timeout;
    int timeout_arg_index;
    char **command_argv;  /* Pointer to store the command and its arguments */

    /*
     * Define long options for getopt_long
     * This is an array of struct option, where each element represents a long option
     * 
     * struct option {
     *     const char *name;     // Name of the long option
     *     int has_arg;          // 0: no argument, 1: required argument, 2: optional argument
     *     int *flag;            // Used for setting a variable to indicate the option was present
     *     int val;              // The value to return, or to put in 'flag'
     * };
     */
    static struct option long_options[] = {
        {"signal", required_argument, 0, 's'},
        {"kill-after", required_argument, 0, 'k'},
        {0, 0, 0, 0}  /* This last element is required to mark the end of the array */
    };

    /* 
     * Parse command line options using getopt_long
     * 
     * The while loop continues as long as getopt_long returns a valid option
     * getopt_long returns -1 when it reaches the end of the options
     *
     * The "+" at the start of the short options string prevents permutation of arguments
     */
    while ((opt = getopt_long(argc, argv, "+s:k:", long_options, NULL)) != -1) {
        switch (opt) {
            case 's':
                /* 
                 * Parse the signal option
                 * optarg is a pointer to the argument for this option
                 */
                g_timeout_signal = parse_signal(optarg);
                if (g_timeout_signal == -1) {
                    fprintf(stderr, "Invalid signal specified\n");
                    exit(1);
                }
                break;
            case 'k':
                /* Parse the kill-after option */
                g_kill_after = parse_timeout(optarg);
                if (g_kill_after <= 0) {
                    fprintf(stderr, "Invalid kill-after value\n");
                    exit(1);
                }
                break;
            default:
                /* If an unknown option is found, print usage and exit */
                print_usage(argv[0]);
                exit(1);
        }
    }

    /* 
     * Find the index of the timeout argument
     * optind is the index of the next argument to be processed
     */
    timeout_arg_index = optind;

    /* Ensure we have at least a timeout value and a command */
    if (argc - timeout_arg_index < 2) {
        print_usage(argv[0]);
        exit(1);
    }

    /* Parse the timeout value */
    timeout = parse_timeout(argv[timeout_arg_index]);
    if (timeout <= 0) {
        fprintf(stderr, "Invalid timeout value\n");
        exit(1);
    }

    /* Find the '--' separator */
    int command_start = timeout_arg_index + 1;
    while (command_start < argc && strcmp(argv[command_start], "--") != 0) {
        command_start++;
    }

    if (command_start == argc) {
        fprintf(stderr, "Error: Missing '--' separator before command\n");
        print_usage(argv[0]);
        exit(1);
    }

    /* Ensure there's a command after the '--' */
    if (command_start == argc - 1) {
        fprintf(stderr, "Error: No command specified after '--'\n");
        print_usage(argv[0]);
        exit(1);
    }

    /* Store the pointer to the command and its arguments */
    command_argv = &argv[command_start + 1];

    /* 
     * Create a new process using fork()
     * fork() creates an exact copy of the parent process
     * It returns:
     *   - a negative value if the fork failed
     *   - 0 to the child process
     *   - the PID of the child to the parent process
     */
    pid_t pid = fork();
    if (pid < 0) {
        /* Fork failed */
        perror("fork");
        exit(1);
    }

    if (pid == 0) {  /* Child process */
        /* 
         * Set the process group ID to its own PID
         * This allows us to send signals to the entire process group later
         * 
         * setpgid(pid_t pid, pid_t pgid)
         * If pid is 0, it uses the calling process's PID
         * If pgid is 0, the process specified by pid becomes a process group leader
         */
        if (setpgid(0, 0) < 0) {
            perror("setpgid");
            exit(1);
        }
        /* 
         * Execute the command, skipping the '--' separator
         * execvp searches for the command in the PATH and passes the entire argument list
         * 
         * &argv[command_start + 1] is a pointer to the first element of the array
         * starting from the command (skipping the '--' separator)
         */
        execvp(argv[command_start + 1], &argv[command_start + 1]);
        /* If execvp returns, it must have failed */
        perror("execvp");
        exit(1);
    }

    /* Parent process continues here */
    
    /* 
     * Set the process group ID of the child
     * This is done in both parent and child to avoid a race condition
     * We ignore EACCES error as it indicates the child has already performed an exec
     */
    if (setpgid(pid, pid) < 0 && errno != EACCES) {
        perror("setpgid");
        kill(pid, SIGTERM);
        exit(1);
    }

    /* Set up the signal handler for SIGALRM */
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));  /* Initialize the struct to all zeros */
    sa.sa_handler = sigalrm_handler;  /* Set the signal handler function */
    sigaction(SIGALRM, &sa, NULL);  /* Install the signal handler */

    /* 
     * Set an alarm for the specified timeout
     * alarm() returns the number of seconds remaining in any previous alarm
     * We're not using the return value here
     */
    alarm((unsigned int)timeout);

    /* 
     * Wait for the child process to complete
     * 
     * waitpid() suspends the calling process until the specified child changes state
     * Parameters:
     *   pid: The PID of the child process to wait for
     *   &status: A pointer to an int where the exit status will be stored
     *   0: Options (0 means no options)
     */
    int status;
    pid_t result = waitpid(pid, &status, 0);

    /* Cancel the alarm */
    alarm(0);

    if (result == -1) {
        if (errno == EINTR) {
            /* Timeout occurred */
            fprintf(stderr, "Command timed out after %.2f seconds:\n", timeout);
            
            /* Print the command that timed out */
            for (char **arg = command_argv; *arg != NULL; arg++) {
                fprintf(stderr, "%s ", *arg);
            }
            fprintf(stderr, "\n");
            
            
            /* 
             * Send the specified signal to the entire process group
             * killpg() sends a signal to a process group
             */
            killpg(pid, g_timeout_signal);
            
            if (g_kill_after > 0) {
                /* 
                 * If kill-after is specified, wait and then send SIGKILL if necessary
                 * usleep() suspends execution for microsecond intervals
                 * We multiply by 1e6 to convert seconds to microseconds
                 */
                usleep((useconds_t)(g_kill_after * 1e6));
                killpg(pid, SIGKILL);
            }
            
            exit(TIMEOUT_EXIT_CODE);
        } else {
            /* Some other error occurred */
            perror("waitpid");
            exit(1);
        }
    }

    /* 
     * Check how the child process terminated
     * WIFEXITED checks if the child terminated normally
     * WIFSIGNALED checks if the child was terminated by a signal
     */
    if (WIFEXITED(status)) {
        /* 
         * Child exited normally, return its exit status
         * WEXITSTATUS extracts the exit status from the status value
         */
        exit(WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
        /* 
         * Child was terminated by a signal
         * We return 128 + signal number, which is a common convention
         * WTERMSIG extracts the signal number from the status value
         */
        exit(128 + WTERMSIG(status));
    }

    /* Should never reach here, but exit with error if we do */
    exit(1);
}

/*
 * Function to print usage information
 *
 * Parameters:
 *   program_name: A pointer to a string containing the name of the program
 *
 * This function doesn't return a value (void)
 */
void print_usage(const char *program_name) {
    /* 
     * fprintf is used to print to a specified stream (in this case, stderr)
     * stderr is the standard error output stream
     */
    fprintf(stderr, "Usage: %s [options] <timeout> -- <command> [args...]\n", program_name);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -s, --signal <signal>  Specify the signal to send when timeout occurs (default: SIGTERM)\n");
    fprintf(stderr, "  -k, --kill-after <duration>  Send SIGKILL signal if command is still running this long after the initial signal\n");
    fprintf(stderr, "Timeout format: <number>[unit]\n");
    fprintf(stderr, "  where unit can be: s - seconds (default), m - minutes, h - hours, d - days\n");
    fprintf(stderr, "Note: Use '--' to separate timeout_command's options from the command to be run\n");
}

/*
 * Function to parse the timeout string and convert it to seconds
 *
 * Parameters:
 *   timeout_str: A pointer to a string containing the timeout value and optional unit
 *
 * Returns:
 *   A double representing the timeout in seconds, or -1 if parsing failed
 */
double parse_timeout(const char *timeout_str) {
    char *endptr;
    /* 
     * strtod converts string to double
     * It sets endptr to point to the first character after the number
     *
     * Parameters:
     *   timeout_str: The string to convert
     *   &endptr: A pointer to a char pointer, which will be updated to point to the first non-converted character
     */
    double value = strtod(timeout_str, &endptr);
    
    if (endptr == timeout_str) {
        return -1;  /* Conversion failed */
    }
    
    /* Check the unit and convert to seconds if necessary */
    switch (*endptr) {
        case 's':
        case '\0':
            return value;
        case 'm':
            return value * 60;
        case 'h':
            return value * 3600;
        case 'd':
            return value * 86400;
        default:
            return -1;  /* Invalid unit */
    }
}

/*
 * Function to parse the signal string and convert it to signal number
 *
 * Parameters:
 *   signal_str: A pointer to a string containing the signal name or number
 *
 * Returns:
 *   An integer representing the signal number, or -1 if parsing failed
 */
int parse_signal(const char *signal_str) {
    /* Check if the signal is specified by number */
    char *endptr;
    /* 
     * strtol converts string to long integer
     * It sets endptr to point to the first character after the number
     *
     * Parameters:
     *   signal_str: The string to convert
     *   &endptr: A pointer to a char pointer, which will be updated to point to the first non-converted character
     *   10: The base of the number in the string (10 for decimal)
     */
    long sig_num = strtol(signal_str, &endptr, 10);
    if (*endptr == '\0') {
        return (int)sig_num;
    }
    
    /* 
     * If not a number, try to parse it as a signal name
     * strncmp compares up to n characters of two strings
     * If the first 3 characters are "SIG", we skip them
     */
    if (strncmp(signal_str, "SIG", 3) == 0) {
        signal_str += 3;  /* Pointer arithmetic: move the pointer 3 characters forward */
    }
    
    /* 
     * Compare with known signal names
     * strcasecmp performs case-insensitive string comparison
     */
    if (strcasecmp(signal_str, "TERM") == 0) return SIGTERM;
    if (strcasecmp(signal_str, "KILL") == 0) return SIGKILL;
    if (strcasecmp(signal_str, "INT") == 0) return SIGINT;
    if (strcasecmp(signal_str, "HUP") == 0) return SIGHUP;
    if (strcasecmp(signal_str, "QUIT") == 0) return SIGQUIT;
    
    return -1;  /* Unknown signal */
}

/*
 * Signal handler for SIGALRM
 * This function is called when the alarm signal (SIGALRM) is received.
 * It doesn't need to do anything; its purpose is to interrupt the waitpid call.
 *
 * Parameters:
 *   signum: The signal number (unused in this function)
 *
 * Returns: void
 */
void sigalrm_handler(int signum) {
    /* Do nothing, just interrupt the wait */
    (void)signum;  /* Cast to void to suppress "unused parameter" warnings */
}
