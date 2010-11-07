//
//  XFWatchNode.m
//  watch
//

#import "XFWatchNode.h"


@implementation XFWatchNode

@synthesize path = _path;
@synthesize isDirectory = _isDirectory;
@synthesize isValid = _isValid;
@synthesize depth = _depth;
@synthesize maxDepth = _maxDepth;
@synthesize parent = _parent;

+ (dispatch_queue_t)watchQueue
{
	static dispatch_queue_t queue = nil;
	
	if(!queue)
	{
		queue = dispatch_queue_create("com.crcunningham.watch", NULL);
	}
	
	return queue;
}

+ (id)nodeWithPath:(NSString *)path
{
	return [[[self alloc] initWithPath:path] autorelease];
}

- (id)initWithPath:(NSString *)path
{
	BOOL dir;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir])
	{
		self = [super init];
		
		if(self)
		{
			_path = [path copy];
			_isDirectory = dir;
			_isValid = YES;
			_childNodes = dir ? [[NSMutableArray alloc] init] : nil;
			_parent = nil;
			
			_descriptor = open([_path UTF8String], O_EVTONLY);
			_source =  dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, _descriptor, DISPATCH_VNODE_LINK|DISPATCH_VNODE_WRITE|DISPATCH_VNODE_REVOKE|DISPATCH_VNODE_RENAME|DISPATCH_VNODE_DELETE|DISPATCH_VNODE_ATTRIB|DISPATCH_VNODE_EXTEND, [XFWatchNode watchQueue]);

			_pathToNodeMap = [[NSMutableDictionary alloc] init];
			
			if(_isDirectory)
			{
				NSError *error = nil;
				NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:&error];
				
				if(entries)
				{
					_directoryEntries = [entries retain];
				}
				else
				{
					NSLog(@"Error getting contents of path: %@\n%@", _path, error);
				}
			}
			else
			{
				_directoryEntries = nil;
			}
			
			
			dispatch_source_set_event_handler(_source, ^{

				if(_isDirectory)
				{
					NSError *error = nil;
					NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:&error];
					
					if(entries)
					{
						// Enumerate the new entries... 
						// ... see what is in the new that's not in the old
						// ... 
						
						for(NSString *entry in entries)
						{
							if(![_directoryEntries containsObject:entry])
							{
								// Added
								printf("[%s] Added: %s\n", [[[NSDate date] description] UTF8String], [[_path stringByAppendingPathComponent:entry] UTF8String]);

								// If the node being created is within the allowed depth create a new watch node
								if(_depth+1 <= _maxDepth)
								{
									XFWatchNode *child = [XFWatchNode nodeWithPath:[_path stringByAppendingPathComponent:entry]];
									[child setDepth:_depth+1];
									[child setMaxDepth:_maxDepth];
									[child setParent:self];
									[self addChild:child];
								}
							}
						}
						
						for(NSString *entry in _directoryEntries)
						{
							if(![entries containsObject:entry])
							{
								// Removed
								printf("[%s] Removed: %s\n", [[[NSDate date] description] UTF8String], [[_path stringByAppendingPathComponent:entry] UTF8String]);
								
								if(_depth+1 <= _maxDepth)
								{								
									XFWatchNode *child = [_pathToNodeMap objectForKey:[_path stringByAppendingPathComponent:entry]];
									[self removeChild:child];
								}
							}
						}
						
						[entries retain];
						[_directoryEntries release];
						_directoryEntries = entries;
						
						
					}
				}
				
				printf("[%s] Changed: %s\n", [[[NSDate date] description] UTF8String], [_path UTF8String]);
				
			});
			
			dispatch_source_set_cancel_handler(_source, ^{ close(_descriptor); });
			dispatch_resume(_source);
		}
	}
	
	return self;
}

- (void)dealloc
{
	dispatch_source_cancel(_source);
	dispatch_release(_source);
	
	[_path release];
	[_childNodes release];
	[_pathToNodeMap release];
	[_directoryEntries release];

	
	[super dealloc];
}

- (void)addChild:(XFWatchNode *)child
{
	[child setParent:self];
	[_childNodes addObject:child];
	
	[_pathToNodeMap setObject:child forKey:[child path]];
}

- (void)removeChild:(XFWatchNode *)child
{
	[_pathToNodeMap removeObjectForKey:[child path]];
	[_childNodes removeObject:child];	
}


@end
