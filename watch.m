#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#import <getopt.h>
#import "XFWatchNode.h"

// Update version with: agvtool new-version -all <new version number>

extern const double watchVersionNumber;

int 
main (int argc, char * argv[]) {
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSInteger maxDepth = 0;
	
	NSString *executablePath = nil;
	
	/* Parse options */
	char ch, *q;
	
	while( ( ch = getopt_long(argc, argv, "e:r:svh", NULL, NULL) ) != -1 ) {
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
			case 'e': 
				executablePath = [[NSString alloc] initWithUTF8String:optarg];
				break;
			case 's':
				[XFWatchNode setEventLoggingEnabled:NO];
				break;

			case 'h':
			default:
				fprintf(stderr,
						"watch [-h] [-r depth] [-e path_to_executable] [-v] [path path2 ...]\n");
				exit(1);
		}
	}
	
	if(!executablePath && ![XFWatchNode eventLoggingEnabled])
	{
		// Nothing for the tool to do, exit
		printf("watch called with -s and no executable path, nothing to do, exiting...\n");
		exit(0);
	}
	
	if(executablePath)
	{
		executablePath = [executablePath stringByResolvingSymlinksInPath];
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
		[node setExecutablePath:executablePath];
		
		[topLevelNodes addObject:node];
		
		[node createChildNodes];		
	}

	[[NSRunLoop mainRunLoop] run];

	[executablePath release];
	[topLevelNodes release];
	
    [pool drain];
    
	return 0;
}
