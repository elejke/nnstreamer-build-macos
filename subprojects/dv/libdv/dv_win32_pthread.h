/* libdv win32 pthread wrapper */
#ifndef _DV_WIN32_PTHREAD_H_INCLUDED_
#define _DV_WIN32_PTHREAD_H_INCLUDED_

#include <windows.h>

typedef struct {
  INIT_ONCE init_once;
  CRITICAL_SECTION mutex;
} pthread_mutex_t;

#define PTHREAD_MUTEX_INITIALIZER {INIT_ONCE_STATIC_INIT,}

#define pthread_mutex_lock(m) dv_win32_pthread_mutex_lock(m)
#define pthread_mutex_unlock(m) dv_win32_pthread_mutex_unlock(m)

static BOOL CALLBACK
dv_win32_init_mutex(PINIT_ONCE InitOnce, PVOID Parameter, PVOID *lpCtx)
{
  InitializeCriticalSection((CRITICAL_SECTION*)lpCtx);
  return TRUE;
}

static inline int
dv_win32_pthread_mutex_lock(pthread_mutex_t *m)
{
  InitOnceExecuteOnce(&m->init_once, dv_win32_init_mutex, NULL, (PVOID *)&m->mutex);
  EnterCriticalSection(&m->mutex);
  return 0;
}

static inline int
dv_win32_pthread_mutex_unlock(pthread_mutex_t *m)
{
  LeaveCriticalSection(&m->mutex);
  return 0;
}

#endif /* _DV_WIN32_PTHREAD_H_INCLUDED_ */
