#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#import <getopt.h>
#import "XFWatchNode.h"


extern const double watchVersionNumber;

void 
createChildNodesForNode(XFWatchNode *node, NSInteger maxDepth, NSInteger currentDepth)
{
	if(currentDepth >= maxDepth)
	{
		// Nodes for the max depth have been created, nothing left to do
		return;
	}
	
	
	BOOL needToProcessChildDirectories = (currentDepth == (maxDepth - 1));
	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[node path] error:&error];
	NSMutableArray *childrenToProcess = needToProcessChildDirectories ? [NSMutableArray array] : nil;

	// Create watch nodes for the current depth
	for(NSString *entry in contents)
	{
		NSString *path = [[node path] stringByAppendingPathComponent:entry];
		XFWatchNode *child = [XFWatchNode nodeWithPath:path];
		[child setDepth:currentDepth];
		[child setMaxDepth:maxDepth];
		[child setParent:node];
		[node addChild:child];
		
		if(needToProcessChildDirectories && [child isDirectory])
		{
			// Add the create child to the list of childrent to process
			[childrenToProcess addObject:child];
		}
	}
	
	if(needToProcessChildDirectories)
	{
		for(XFWatchNode *child in childrenToProcess)
		{
			// Create nodes for children
			createChildNodesForNode(child, maxDepth, currentDepth + 1);
		}
	}
}

int 
main (int argc, char * argv[]) {
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSInteger maxDepth = 0;
	
	/* Parse options */
	char ch, *q;
	
	while( ( ch = getopt_long(argc, argv, "r:vh", NULL, NULL) ) != -1 ) {
		switch(ch) {
			case 'r':
				maxDepth    = (NSInteger)strtol(optarg, &q, 10);
				/* If the string could be converted */
				if(*q == '\0' && maxDepth > 0) 
				{
					break;
				}
				break;
			case 'v':
				fprintf(stdout, "Version %d\n", (int)watchVersionNumber);
				exit(0);
			case 'h':
			default:
				fprintf(stderr,
						"watch [-h] [-r depth] [-v] [path path2 ...]\n");
				exit(1);
		}
	}
	
	NSMutableArray *directories = nil;
	NSString *currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
	
	
	// Decrement the count for the options
	argc -= optind;
	
	if(argc < 1)
	{
		directories = [NSMutableArray arrayWithObject:currentDirectory];
	}
	else 
	{
		directories = [NSMutableArray arrayWithCapacity:argc];
		
		int count = 0;
		
		while(count < argc)
		{
			[directories addObject:[NSString stringWithUTF8String:argv[optind+count++]]];
		}
	}
	
	NSMutableArray *filtedDirectories = [NSMutableArray arrayWithCapacity:[directories count]];
	
	for(NSString *directory in directories)
	{
		if([directory isAbsolutePath])
		{
			if(![[NSFileManager defaultManager] fileExistsAtPath:directory])
			{
				printf("Skipping invalid path: %s\n", [directory UTF8String]);
			}
			else
			{
				[filtedDirectories addObject:directory];
			}

		}
		else
		{
			NSString *fullPath = [currentDirectory stringByAppendingPathComponent:directory];
			
			if(![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
			{
				printf("Skipping invalid path: %s\n", [fullPath UTF8String]);
			}
			else
			{
				[filtedDirectories addObject:fullPath];
			}
		}

	}
	
	NSMutableArray *topLevelNodes = [[NSMutableArray alloc] initWithCapacity:[filtedDirectories count]];

	for(NSString *path in filtedDirectories)
	{
		NSInteger currentDepth = 0;
		
		printf("Watching: %s\n", [path UTF8String]);
		
		XFWatchNode *node = [XFWatchNode nodeWithPath:path];
		[node setDepth:currentDepth];
		[node setMaxDepth:maxDepth];
		[node setParent:nil];
		
		[topLevelNodes addObject:node];
		
		createChildNodesForNode(node, maxDepth, currentDepth);
		
	}

	[[NSRunLoop mainRunLoop] run];

	[topLevelNodes release];
	
    [pool drain];
    
	return 0;
}
