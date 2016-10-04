//
//  GITreeNode.m
//  dictionary
//
//  Created by Enriquez Gutierrez Guillermo Ignacio on 1/9/11.
//  Copyright 2011 Nacho4D. All rights reserved.
//  See the file license.txt for copying permission.
//


#import "GITreeNode.h"

@interface GITreeNode ()

/// redefining exposed parentPath property as retain
@property (nonatomic, strong) NSString *parentPath;

/// internal property, lazy loaded
@property (nonatomic, strong, readonly) NSDictionary *properties;

///  internal property, always reads properties from disk
@property (nonatomic, unsafe_unretained, readonly) NSDictionary *nonCashedProperties;


@end


@interface GITreeNode (privates)

/// Logical, simply adds a new child to current directory node, should this be private?
- (void) _appendChild:(GITreeNode *)newChild;


/// loads children (retains it, so children must be released later)
- (void) _loadChildren;

@end


@implementation GITreeNode


//#define GIASSERT(error, method) 
#define GIASSERT(error, method) if ((error)) NSLog(@"ERROR: %s: %@", (method), [(error) localizedDescription]);

#pragma mark -
#pragma mark properties

- (NSDictionary *) nonCashedProperties{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSString *path = self.absolutePath;
	NSDictionary *props = [fm attributesOfItemAtPath:path error:&error];
	//GIASSERT(error, _cmd);
	return props;
}

- (NSDictionary *)properties{
	if (!_properties) {
		_properties = [self nonCashedProperties];
	}
	return _properties;
}

@synthesize filename = _name;

- (NSString *)absolutePath{
	return (self.parent)?
	[self.parent.absolutePath stringByAppendingPathComponent:self.filename]:
	[self.parentPath stringByAppendingPathComponent:self.filename];
}

- (NSString *)fileExtension{
	return [[self.filename lastPathComponent] pathExtension];
}

- (BOOL) isDirectory{
	return [NSFileTypeDirectory isEqualToString:[self.properties fileType]];
}

//- (BOOL) directoryIsExpanded{
//	return (self.isDirectory && _children);
//}

- (void) _loadChildren{ 
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *paths = [fm contentsOfDirectoryAtPath:self.absolutePath error:&error];
	//GIASSERT(error, _cmd);
	_children = [[NSMutableArray alloc] init];
	for (NSString *path in paths) {
		GITreeNode *childNode = [[GITreeNode alloc] initWithName:path parent:self];
		[_children addObject:childNode];
	}
	
}

- (NSMutableArray *) children{
	if (self.isDirectory && !_children) {
		[self _loadChildren]; //_children is alloc/init must be released later
	}
	return _children;
}

-(void)reloadChildren;
{
    _children = nil;
}

@synthesize parent = _parent;
@synthesize parentPath = _parentPath;

- (NSDate *) creationDate{
	return [self.properties fileCreationDate]; //cashed properties
}
- (NSDate *) modificationDate{
	return [self.properties fileModificationDate];
}
- (void) setModificationDate:(NSDate *)date{
	//to do this _properties has to be mutable or create a new object _properties
}

- (NSInteger) depth{
	if (_depth == -1) {
		_depth = self.parent.depth + 1;
	}
	return _depth;
}

@synthesize directoryIsExpanded = _expanded;

#pragma mark -
#pragma mark Life Cicle 

- (void) dealloc{
	_parent = nil;
}

- (id) initWithName:(NSString *)name parent:(GITreeNode *)aParent{
	if ((self = [super init])){
		_name = name;
		_parent = aParent;
		_parentPath = nil;	
		_properties = nil;
		_children = nil;
		_depth = -1;
		_expanded = NO;
	}
	return self;
}

- (id) initWithName:(NSString *)name parentPath:(NSString *)aParentPath{
	if ((self = [super init])){
		_name = name;
		_parent = nil;
		_parentPath = aParentPath;	
		_properties = nil;
		_children = nil;
		_depth = 0;
		_expanded = NO;
	}
	return self;
}

#pragma mark -
#pragma mark public methods

- (void) appendChild:(GITreeNode *)newChild{
	[self.children addObject:newChild];
	
}

- (void) changeParent:(GITreeNode *)newParent{

	NSString *oldPath = self.absolutePath;
	[newParent appendChild:self];
	[self.parent.children removeObject:self];
	_parent = newParent;
	NSString *newPath = self.absolutePath;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	[fm moveItemAtPath:oldPath toPath:newPath error:&error];
	//GIASSERT(error, _cmd);
		
}


- (void) expand{
	if (self.isDirectory && !self.directoryIsExpanded){
		if (!_children)	[self _loadChildren];
		_expanded = YES;
	}
}
- (void) collapse{
	_expanded = NO; //objects will be released when memory is needed
}

- (void) flushCache{
	if (!self.directoryIsExpanded) {
		_children = nil;
	}
	
	_properties = nil;
}

NSString *space(int x){
	NSMutableString *res = [NSMutableString string];
	for (int i =0; i<x; i++) {
		[res appendString:@" "];
	}
	return res;
}

- (NSString *) description{
	
	return [NSString stringWithFormat:@"%@%@ %@", space((int)self.depth),self.isDirectory?@"D":@"F", self.filename];
}

-(NSInteger)fileSize;
{
    NSInteger fileSize = [[self.properties objectForKey:NSFileSize] intValue];
    return fileSize;
}

- (NSString *)formattedFileSize:(unsigned long long)size;
{
	NSString *formattedStr = nil;
    if (size == 0) 
		formattedStr = @"Empty";
	else 
		if (size > 0 && size < 1024) 
			formattedStr = [NSString stringWithFormat:@"%qu bytes", size];
        else 
            if (size >= 1024 && size < pow(1024, 2)) 
                formattedStr = [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
            else 
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedStr = [NSString stringWithFormat:@"%.2f MB", (size / pow(1024, 2))];
                else 
                    if (size >= pow(1024, 3)) 
                        formattedStr = [NSString stringWithFormat:@"%.3f GB", (size / pow(1024, 3))];
	
	return formattedStr;
}

-(UIImage *)iconForTreeNode
{
    UIImage *iconImage;
    if ([self isDirectory]) {
        iconImage = [UIImage imageNamed:@"folder"];
    } else {
        NSString *extension = [self fileExtension];
        if ([extension isEqualToString:@"html"]) {
            iconImage = [UIImage imageNamed:@"file_extension_html"];
        }
        else if ([extension isEqualToString:@"pdf"]) {
            iconImage = [UIImage imageNamed:@"file_extension_pdf"];
        }
        else if ([extension isEqualToString:@"csv"]) {
            iconImage = [UIImage imageNamed:@"file_extension_csv"];
        }
        else if ([extension isEqualToString:@"png"]) {
            iconImage = [UIImage imageNamed:@"file_extension_png"];
        }
        else if ([extension isEqualToString:@"sqlite"]) {
            iconImage = [UIImage imageNamed:@"database_key"];
        }        
        else if ([extension isEqualToString:@"zip"]) {
            iconImage = [UIImage imageNamed:@"file_extension_zip"];
        }
        else {
            iconImage = [UIImage imageNamed:@"page_white"];
        }
    }
    return iconImage;
}

-(NSString *)mimeTypeForTreeNode
{
    NSString *mimeTypeCode;
    if ([self isDirectory]) {
        mimeTypeCode = @"";
    } else {
        NSString *extension = [self fileExtension];
        if ([extension isEqualToString:@"html"]) {
            mimeTypeCode = @"text/html";
        }
        else if ([extension isEqualToString:@"pdf"]) {
            mimeTypeCode = @"application/pdf";
        }
        else if ([extension isEqualToString:@"csv"]) {
            mimeTypeCode = @"text/csv";
        }
        else if ([extension isEqualToString:@"png"]) {
            mimeTypeCode = @"image/png";
        }
        else if ([extension isEqualToString:@"sqlite"]) {
            mimeTypeCode = @"application/sqlite";
        }        
        else if ([extension isEqualToString:@"zip"]) {
            mimeTypeCode = @"application/zip";
        }
        else {
            mimeTypeCode = @"";
        }
    }
    return mimeTypeCode;

}

@end