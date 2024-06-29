/*
 * timeout.c
 * 
 * This program executes a given command with a specified timeout.
 * If the command doesn't complete within the timeout period, it is terminated.
 * 
 * Usage: ./timeout <timeout_in_seconds> <command> [args...]
 * 
 * Example: ./timeout 5 sleep 10
 *          This will try to run "sleep 10", but will terminate it after 5 seconds.
 *
 * (c) 2024 Gen AI for Public Domain
 */

/* _GNU_SOURCE is defined to enable certain GNU/Linux-specific features */
#define _GNU_SOURCE

/* Include necessary header files */
#include <stdio.h>    /* For input/output functions like printf */
#include <stdlib.h>   /* For general functions like exit */
#include <string.h>   /* For string manipulation functions like memset */
#include <unistd.h>   /* For POSIX operating system API */
#include <signal.h>   /* For signal handling */
#include <sys/types.h>/* For pid_t and other type definitions */
#include <sys/wait.h> /* For waitpid function */
#include <errno.h>    /* For errno variable and related constants */

/* Define a constant for the exit code when a timeout occurs */
#define TIMEOUT_EXIT_CODE 124

/* 
 * Signal handler for SIGALRM
 * This function is called when the alarm signal (SIGALRM) is received.
 * It doesn't need to do anything; its purpose is to interrupt the waitpid call.
 */
void sigalrm_handler(int signum) {
    // Do nothing, just interrupt the wait
}

/* Main function - entry point of the program */
int main(int argc, char *argv[]) {
    /* Check if the correct number of arguments is provided */
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <timeout_in_seconds> <command> [args...]\n", argv[0]);
        exit(1);
    }

    /* Convert the timeout argument from string to integer */
    int timeout = atoi(argv[1]);
    if (timeout <= 0) {
        fprintf(stderr, "Invalid timeout value\n");
        exit(1);
    }

    /* Create a new process */
    pid_t pid = fork();
    if (pid < 0) {
        /* Fork failed */
        perror("fork");
        exit(1);
    }

    if (pid == 0) {  // Child process
        /* Set the process group ID to its own PID */
        if (setpgid(0, 0) < 0) {
            perror("setpgid");
            exit(1);
        }
        /* Replace the current process image with a new process image */
        execvp(argv[2], &argv[2]);
        /* If execvp returns, it must have failed */
        perror("execvp");
        exit(1);
    }

    /* Parent process continues here */
    
    /* Set the process group ID of the child. This is done in both parent and child
     * to avoid a race condition. EACCES error is ignored as it indicates the child
     * has already performed an exec. */
    if (setpgid(pid, pid) < 0 && errno != EACCES) {
        perror("setpgid");
        kill(pid, SIGTERM);
        exit(1);
    }

    /* Set up the signal handler for SIGALRM */
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sigalrm_handler;
    sigaction(SIGALRM, &sa, NULL);

    /* Set an alarm for the specified timeout */
    alarm(timeout);

    /* Wait for the child process to complete */
    int status;
    pid_t result = waitpid(pid, &status, 0);

    /* Cancel the alarm */
    alarm(0);

    if (result == -1) {
        if (errno == EINTR) {
            /* Timeout occurred */
            fprintf(stderr, "Command timed out after %d seconds\n", timeout);
            /* Send SIGTERM to the entire process group */
            killpg(pid, SIGTERM);
            /* Give processes 100ms to terminate gracefully */
            usleep(100000);
            /* If still alive, send SIGKILL */
            killpg(pid, SIGKILL);
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
