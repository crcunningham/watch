//
//  XFWatchNode.h
//  watch
//

#import <Foundation/Foundation.h>

@interface XFWatchNode : NSObject 
{
	
@private
	
	NSString *_path;
	BOOL _isDirectory;
	XFWatchNode *_parent;
	NSMutableArray *_childNodes;
	NSArray *_directoryEntries;
	BOOL _isValid;
	NSString *_executablePath;
	
	uintptr_t _descriptor;
	dispatch_source_t _source;

	NSMutableDictionary *_pathToNodeMap;
	
	NSInteger _depth;
	NSInteger _maxDepth;
	
}

+ (BOOL)eventLoggingEnabled;
+ (void)setEventLoggingEnabled:(BOOL)enabled;

+ (dispatch_queue_t)watchQueue;
+ (dispatch_queue_t)exectuteQueue;

+ (id)nodeWithPath:(NSString *)path;

- (id)initWithPath:(NSString *)path; 
- (void)addChild:(XFWatchNode *)child;
- (void)removeChild:(XFWatchNode *)child;
- (void)createChildNodes;

@property (readonly) NSString *path;
@property (readonly) BOOL isDirectory;
@property (assign) BOOL isValid;
@property (assign) NSInteger depth;
@property (assign) NSInteger maxDepth;
@property (assign) XFWatchNode *parent;
@property (copy) NSString *executablePath;

@end
