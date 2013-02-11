#include <stdlib.h>
#include <sched.h>
#include <stdio.h>

#include "dl_syscalls.h"

static int get_dl(int pid)
{
  struct sched_param2 sp;
  int res, policy;

  policy = sched_getscheduler(pid);
  if (policy < 0) {
    perror("Sched GetScheduler");

    return policy;
  }
  printf("Policy: %d\n", policy);

  if (policy != SCHED_DEADLINE) {
    return 0;
  }

  res = sched_getparam2(pid, &sp);
  if (res < 0) {
    perror("Sched GetParam2");

    return res;
  }

  printf("Q: %llu T: %llu\n", sp.sched_runtime, sp.sched_deadline);

  return res;
}

static int set_dl(int pid, int q, int t)
{
  struct sched_param2 sp;
  int res;

  sp.sched_priority = 0;
  sp.sched_flags = 0;
  sp.sched_runtime = q * 1000;
  sp.sched_deadline = sp.sched_period = t * 1000;

  res = sched_setscheduler2(pid, SCHED_DEADLINE, &sp);
  if (res < 0) {
    perror("Sched SetScheduler2");
  }

  return res;
}

int main(int argc, char *argv[])
{
  int pid, q, t;

  if ((argc != 2) && (argc != 4)) {
    fprintf(stderr, "Usage: %s <pid> [<q> <t>]\n", argv[0]);

    return -1;
  }

  pid = atoi(argv[1]);
  if (argc == 4) {
    q   = atoi(argv[2]);
    t   = atoi(argv[3]);

    return set_dl(pid, q, t);
  }

  return get_dl(pid);
}
