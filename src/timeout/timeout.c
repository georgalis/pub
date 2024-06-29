/*
 * command_with_timeout.c
 * 
 * This program executes a given command with a specified timeout.
 * If the command doesn't complete within the timeout period, it is terminated.
 * 
 * Usage: ./command_with_timeout [options] <timeout> <command> [args...]
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
 *   ./command_with_timeout 5.5 sleep 10
 *   ./command_with_timeout -s SIGKILL 2m ls -R /
 *   ./command_with_timeout --signal 9 --kill-after 30s 1.5h long_running_command
 *
 * (c) 2024 Gen AI for Public Domain
 */

/* _GNU_SOURCE is defined to enable certain GNU/Linux-specific features */
#define _GNU_SOURCE

/* Include necessary header files */
#include <stdio.h>    /* For input/output functions like printf */
#include <stdlib.h>   /* For general functions like exit, atoi */
#include <string.h>   /* For string manipulation functions like strcasecmp, memset */
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

/*
 * Signal handler for SIGALRM
 * This function is called when the alarm signal (SIGALRM) is received.
 * It doesn't need to do anything; its purpose is to interrupt the waitpid call.
 *
 * Parameters:
 *   signum: The signal number (unused in this function)
 */
void sigalrm_handler(int signum) {
    /* Do nothing, just interrupt the wait */
}

/* Main function - entry point of the program */
int main(int argc, char *argv[]) {
    int opt;
    double timeout;
    
    /*
     * Define long options for getopt_long
     * Each struct option has four fields:
     * 1. name: the option name
     * 2. has_arg: 1 if the option takes an argument, 0 otherwise
     * 3. flag: usually set to 0
     * 4. val: the character to use as a short option
     */
    static struct option long_options[] = {
        {"signal", required_argument, 0, 's'},
        {"kill-after", required_argument, 0, 'k'},
        {0, 0, 0, 0}  /* This last element is required to mark the end of the array */
    };

    /* Parse command line options */
    while ((opt = getopt_long(argc, argv, "s:k:", long_options, NULL)) != -1) {
        switch (opt) {
            case 's':
                /* Parse the signal option */
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

    /* Check if we have enough arguments after option parsing */
    if (argc - optind < 2) {
        print_usage(argv[0]);
        exit(1);
    }

    /* Parse the timeout value */
    timeout = parse_timeout(argv[optind]);
    if (timeout <= 0) {
        fprintf(stderr, "Invalid timeout value\n");
        exit(1);
    }

    /* Create a new process using fork()
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
        /* Set the process group ID to its own PID
         * This allows us to send signals to the entire process group later
         */
        if (setpgid(0, 0) < 0) {
            perror("setpgid");
            exit(1);
        }
        /* Execute the command
         * execvp searches for the command in the PATH and passes the entire argument list
         */
        execvp(argv[optind + 1], &argv[optind + 1]);
        /* If execvp returns, it must have failed */
        perror("execvp");
        exit(1);
    }

    /* Parent process continues here */
    
    /* Set the process group ID of the child
     * This is done in both parent and child to avoid a race condition
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

    /* Set an alarm for the specified timeout */
    alarm((unsigned int)timeout);

    /* Wait for the child process to complete */
    int status;
    pid_t result = waitpid(pid, &status, 0);

    /* Cancel the alarm */
    alarm(0);

    if (result == -1) {
        if (errno == EINTR) {
            /* Timeout occurred */
            fprintf(stderr, "Command timed out after %.2f seconds\n", timeout);
            
            /* Send the specified signal to the entire process group */
            killpg(pid, g_timeout_signal);
            
            if (g_kill_after > 0) {
                /* If kill-after is specified, wait and then send SIGKILL if necessary */
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

    /* Check how the child process terminated */
    if (WIFEXITED(status)) {
        /* Child exited normally, return its exit status */
        exit(WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
        /* Child was terminated by a signal, return 128 + signal number */
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
 */
void print_usage(const char *program_name) {
    fprintf(stderr, "Usage: %s [options] <timeout> <command> [args...]\n", program_name);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -s, --signal <signal>  Specify the signal to send when timeout occurs (default: SIGTERM)\n");
    fprintf(stderr, "  -k, --kill-after <duration>  Send SIGKILL signal if command is still running this long after the initial signal\n");
    fprintf(stderr, "Timeout format: <number>[unit]\n");
    fprintf(stderr, "  where unit can be: s - seconds (default), m - minutes, h - hours, d - days\n");
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
    /* strtod converts string to double
     * It sets endptr to point to the first character after the number
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
    /* strtol converts string to long integer
     * It sets endptr to point to the first character after the number
     */
    long sig_num = strtol(signal_str, &endptr, 10);
    if (*endptr == '\0') {
        return (int)sig_num;
    }
    
    /* If not a number, try to parse it as a signal name */
    if (strncmp(signal_str, "SIG", 3) == 0) {
        signal_str += 3;  /* Skip "SIG" prefix */
    }
    
    /* Compare with known signal names
     * strcasecmp performs case-insensitive string comparison
     */
    if (strcasecmp(signal_str, "TERM") == 0) return SIGTERM;
    if (strcasecmp(signal_str, "KILL") == 0) return SIGKILL;
    if (strcasecmp(signal_str, "INT") == 0) return SIGINT;
    if (strcasecmp(signal_str, "HUP") == 0) return SIGHUP;
    if (strcasecmp(signal_str, "QUIT") == 0) return SIGQUIT;
    
    return -1;  /* Unknown signal */
}

