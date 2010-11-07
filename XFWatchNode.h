//
//  XFWatchNode.h
//  watch
//

#import <Foundation/Foundation.h>



@interface XFWatchNode : NSObject 
{
	NSString *_path;
	BOOL _isDirectory;
	XFWatchNode *_parent;
	NSMutableArray *_childNodes;
	NSArray *_directoryEntries;
	BOOL _isValid;
	
	uintptr_t _descriptor;
	dispatch_source_t _source;

	NSMutableDictionary *_pathToNodeMap;
	
	NSInteger _depth;
	NSInteger _maxDepth;
}

+ (dispatch_queue_t)watchQueue;
+ (id)nodeWithPath:(NSString *)path;

- (id)initWithPath:(NSString *)path; 
- (void)addChild:(XFWatchNode *)child;
- (void)removeChild:(XFWatchNode *)child;

@property (readonly) NSString *path;
@property (readonly) BOOL isDirectory;
@property (assign) BOOL isValid;
@property (assign) NSInteger depth;
@property (assign) NSInteger maxDepth;
@property (assign) XFWatchNode *parent;

@end
