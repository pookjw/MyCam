//
//  lock_private.h
//  MyCam
//
//  Created by Jinwoo Kim on 10/11/24.
//

#include <os/lock.h>
#import <CamPresentation/Extern.h>

OS_ASSUME_NONNULL_BEGIN

#define OS_UNFAIR_RECURSIVE_LOCK_AVAILABILITY \
        __OSX_AVAILABLE(10.14) __IOS_AVAILABLE(12.0) \
        __TVOS_AVAILABLE(12.0) __WATCHOS_AVAILABLE(5.0)

OS_UNFAIR_RECURSIVE_LOCK_AVAILABILITY
typedef struct os_unfair_recursive_lock_s {
    os_unfair_lock ourl_lock;
    uint32_t ourl_count;
} os_unfair_recursive_lock, *os_unfair_recursive_lock_t;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#define OS_UNFAIR_RECURSIVE_LOCK_INIT \
        ((os_unfair_recursive_lock){OS_UNFAIR_LOCK_INIT, 0})
#elif defined(__cplusplus) && __cplusplus >= 201103L
#define OS_UNFAIR_RECURSIVE_LOCK_INIT \
        (os_unfair_recursive_lock{OS_UNFAIR_LOCK_INIT, 0})
#elif defined(__cplusplus)
#define OS_UNFAIR_RECURSIVE_LOCK_INIT (os_unfair_recursive_lock(\
        (os_unfair_recursive_lock){OS_UNFAIR_LOCK_INIT, 0}))
#else
#define OS_UNFAIR_RECURSIVE_LOCK_INIT \
        {OS_UNFAIR_LOCK_INIT, 0}
#endif // OS_UNFAIR_RECURSIVE_LOCK_INIT

OS_REFINED_FOR_SWIFT
OS_OPTIONS(os_unfair_lock_options, uint32_t,
    OS_UNFAIR_LOCK_NONE OS_SWIFT_NAME(None)
        OS_UNFAIR_LOCK_AVAILABILITY = 0x00000000,
    OS_UNFAIR_LOCK_DATA_SYNCHRONIZATION OS_SWIFT_NAME(DataSynchronization)
        OS_UNFAIR_LOCK_AVAILABILITY = 0x00010000,
    OS_UNFAIR_LOCK_ADAPTIVE_SPIN OS_SWIFT_NAME(AdaptiveSpin)
        __API_AVAILABLE(macos(10.15), ios(13.0),
        tvos(13.0), watchos(6.0)) = 0x00040000,
    OS_UNFAIR_LOCK_DEADLINE OS_SWIFT_NAME(Deadline)
        __API_AVAILABLE(macos(14.3), ios(17.4),
        watchos(10.4), tvos(17.4)) = 0x02000000,
);

OS_UNFAIR_RECURSIVE_LOCK_AVAILABILITY
CP_EXTERN OS_NOTHROW OS_NONNULL_ALL
void os_unfair_recursive_lock_lock_with_options(os_unfair_recursive_lock_t lock, os_unfair_lock_options_t options);

OS_UNFAIR_RECURSIVE_LOCK_AVAILABILITY
CP_EXTERN OS_NOTHROW OS_WARN_RESULT OS_NONNULL_ALL
bool os_unfair_recursive_lock_trylock(os_unfair_recursive_lock_t lock);

OS_UNFAIR_RECURSIVE_LOCK_AVAILABILITY
CP_EXTERN OS_NOTHROW OS_NONNULL_ALL
void os_unfair_recursive_lock_unlock(os_unfair_recursive_lock_t lock);

OS_ASSUME_NONNULL_END
