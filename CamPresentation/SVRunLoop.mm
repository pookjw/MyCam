//
//  SVRunLoop.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <CamPresentation/SVRunLoop.hpp>
#import <CoreFoundation/CoreFoundation.h>
#import <os/lock.h>
#import <objc/objc-sync.h>
#import <objc/runtime.h>

namespace ns_SVRunLoop {
    void performCallout(void *info) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        auto dictionary = static_cast<NSMutableDictionary *>(info);
        
        auto lockValue = static_cast<NSValue *>(dictionary[@"lock"]);
        auto lockPtr = reinterpret_cast<os_unfair_lock *>(object_getIndexedIvars(lockValue));
        
        os_unfair_lock_lock(lockPtr);
        
        auto blocks = static_cast<NSMutableArray *>(dictionary[@"blocks"]);
        
        // autoreleasepool 제공됨
        [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((void (^)())(obj))();
        }];
        [blocks removeAllObjects];
        
        os_unfair_lock_unlock(lockPtr);
        [pool release];
    }
}

__attribute__((objc_direct_members))
@interface SVRunLoop ()
@property (copy, readonly, nonatomic) NSString * _Nullable threadName;
@property (retain, readonly, nonatomic) NSThread *thread;
@end

@implementation SVRunLoop

@synthesize thread = _thread;

+ (SVRunLoop *)globalRenderRunLoop {
    static dispatch_once_t onceToken;
    static SVRunLoop *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [[SVRunLoop alloc] initWithThreadName:@"SVRunLoop.globalRenderRunLoop"];
    });
    
    return instance;
}

+ (SVRunLoop *)globalTimerRunLoop {
    static dispatch_once_t onceToken;
    static SVRunLoop *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [[SVRunLoop alloc] initWithThreadName:@"SVRunLoop.globalTimerRunLoop"];
    });
    
    return instance;
}

- (instancetype)initWithThreadName:(NSString *)threadName {
    if (self = [self init]) {
        _threadName = [threadName copy];
    }
    
    return self;
}

- (void)dealloc {
    [_threadName release];
    
    // 여기서 _thread를 가져올 때는 lock을 할 필요가 없음. -thread가 돌아가고 있다면 self를 retain한 상태이기 때문에 -dealloc이 불릴 일이 없음.
    if (auto thread = _thread) {
        NSMutableDictionary *dictionary = thread.threadDictionary[@"dictionary"];
        
        auto lockValue = static_cast<NSValue *>(dictionary[@"lock"]);
        auto lockPtr = reinterpret_cast<os_unfair_lock *>(object_getIndexedIvars(lockValue));
        
        os_unfair_lock_lock(lockPtr);
        
        if (auto runLoop = reinterpret_cast<CFRunLoopRef _Nullable>(dictionary[@"runLoop"])) {
            // 이미 RunLoop가 돌아가고 있다면 중단
            CFRunLoopStop(runLoop);
        }
        
        // Thread는 생성되었는데 아직 start가 안 되었거나 start하던 도중 RunLoop을 설정하기 이전에 이 코드가 불려서 lock이 걸릴 경우, 중단하라는 flag 추가
        dictionary[@"needsStop"] = @YES;
        
        objc_sync_exit(self);
        
        [_thread release]; 
    }
    
    [super dealloc];
}

- (NSThread *)thread {
    objc_sync_enter(self);
    
    if (auto thread = _thread) {
        objc_sync_exit(self);
        return thread;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    NSValue *lockValue = [NSValue valueWithBytes:&lock objCType:@encode(os_unfair_lock)];
    
    dictionary[@"lock"] = lockValue;
    
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        CFRunLoopSourceContext context = {
            0,
            dictionary,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            ns_SVRunLoop::performCallout
        };
        
        CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault,
                                                          0,
                                                          &context);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        
        auto lockValue = static_cast<NSValue *>(dictionary[@"lock"]);
        auto lockPtr = reinterpret_cast<os_unfair_lock *>(object_getIndexedIvars(lockValue));
        
        os_unfair_lock_lock(lockPtr);
        
        auto needsStopNumber = static_cast<NSNumber * _Nullable>(dictionary[@"needsStop"]);
        if (needsStopNumber.boolValue) {
            return;
        }
        
        dictionary[@"runLoop"] = static_cast<id>(CFRunLoopGetCurrent());
        dictionary[@"source"] = static_cast<id>(source);
        
        if (NSMutableArray *blocks = dictionary[@"blocks"]) {
            // autoreleasepool 제공됨
            [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ((void (^)())(obj))();
            }];
            [blocks removeAllObjects];
        } else {
            dictionary[@"blocks"] = [NSMutableArray array];
        }
        
        os_unfair_lock_unlock(lockPtr);
        
        CFRelease(source);
        
        [pool release];
        
        CFRunLoopRun();
    }];
    
    thread.threadDictionary[@"dictionary"] = dictionary;
    thread.name = _threadName;
    
    _thread = [thread retain];
    objc_sync_exit(self);
    
    [thread start];
    return thread;
}

- (void)runBlock:(void (^)())block {
    NSThread *thread = self.thread;
    NSMutableDictionary *dictionary = thread.threadDictionary[@"dictionary"];
    
    auto lockValue = static_cast<NSValue *>(dictionary[@"lock"]);
    auto lockPtr = reinterpret_cast<os_unfair_lock *>(object_getIndexedIvars(lockValue));
    
    os_unfair_lock_lock(lockPtr);
    
    auto runLoop = reinterpret_cast<CFRunLoopRef _Nullable>(dictionary[@"runLoop"]);
    auto source = reinterpret_cast<CFRunLoopSourceRef _Nullable>(dictionary[@"source"]);
    
    NSMutableArray *blocks;
    if (NSMutableArray *_blocks = dictionary[@"blocks"]) {
        blocks = _blocks;
    } else {
        blocks = [NSMutableArray array];
        dictionary[@"blocks"] = blocks;
    }
    
    id copiedBlock = [block copy];
    [blocks addObject:copiedBlock];
    [copiedBlock release];
    
    os_unfair_lock_unlock(lockPtr);
    
    if (source) {
        CFRunLoopSourceSignal(source);
    }
    
    if (runLoop) {
        CFRunLoopWakeUp(runLoop);
    }
}

@end
