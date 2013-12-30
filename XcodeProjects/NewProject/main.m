//
//  main.m
//  NewProject
//
//  Created by Mike Fullerton on 12/30/13.
//  Copyright (c) 2013 FishLamp. All rights reserved.
//

#import <Foundation/Foundation.h>


//void CopyFolder(NSString* fromFolder, NSString* toFolder) {
//// move visible contents of folder to archive folder
//// we can't just move the folder because of the hidden .svn folder.
//
//	NSError* err = nil;
//	NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fromFolder error:&err];
//    if(err) {
////       FLThrowIfError(err);
//    }
//	
//	for(NSString* item in contents) {
//		if([item characterAtIndex:0] == '.') {// invisible file or folder
//			continue;
//		}
//	
//		NSString* srcPath = [fromFolder stringByAppendingPathComponent:item];
//		NSString* destPath = [toFolder stringByAppendingPathComponent:item];
//	
//		[[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:destPath error:&err];
//        if(err) {
//           FLThrowIfError(err);
//        }
//	}
//}


BOOL CheckFileAtPath(NSString* path) {

    CFStringRef fileExtension = (__bridge CFStringRef) [path pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

    BOOL checkFile = NO;

    if (UTTypeConformsTo(fileUTI, kUTTypeText)) {
        checkFile = YES;
    }

    CFRelease(fileUTI);

    return checkFile;

}

BOOL RenameFolders(NSString* path, NSString* toName, NSError** error) {

    NSError* aError = nil;

    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&aError];

    if(aError) {

        if(error) {
            *error = aError;
        }

        return NO;
    }

    for(NSString* item in contents) {

        if([item characterAtIndex:0] == '.') {
            continue;
        }

        NSString* fullSubPath = [path stringByAppendingPathComponent:item];

        BOOL isDir = NO;
        if( [[NSFileManager defaultManager] fileExistsAtPath:fullSubPath isDirectory:&isDir] && isDir) {
            if(!RenameFolders(fullSubPath, toName, error)) {
                return NO;
            }
        }
        else if(CheckFileAtPath(fullSubPath)) {

            NSString* contents = [NSString stringWithContentsOfFile:fullSubPath encoding:NSUTF8StringEncoding error:&aError];


            if(aError) {

                if(error) {
                    *error = aError;
                }

                return NO;
            }

            NSString* newContents = [contents stringByReplacingOccurrencesOfString:@"TEMPLATE" withString:toName];

            if( ![newContents isEqualToString:contents]) {

                [newContents writeToFile:fullSubPath atomically:YES encoding:NSUTF8StringEncoding error:&aError];

                if(aError) {

                    if(error) {
                        *error = aError;
                    }

                    return NO;
                }

                NSLog(@"Updated file %@", fullSubPath);
            }
        }

        if([item rangeOfString:@"TEMPLATE"].length > 0) {

            NSString* newName = [item stringByReplacingOccurrencesOfString:@"TEMPLATE" withString:toName];

            NSString* newPath = [path stringByAppendingPathComponent:newName];

            [[NSFileManager defaultManager] moveItemAtPath:fullSubPath toPath:newPath error:&aError];

            if(aError) {

                if(error) {
                    *error = aError;
                }

                return NO;
            }

            NSLog(@"Renamed:\n%@\n%@\n", fullSubPath, newPath);

        }
    }

    return YES;
}

BOOL RemoveExtras(NSString* fromPath, NSError** error) {

    static NSString* const extras[] = {
        @"update-link.sh",
        @"XcodeBuildSupportConfigs"
    };

    for(int i = 0; i < (sizeof(NSString*) * sizeof(extras)); i++) {

        NSError* aError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[fromPath stringByAppendingPathComponent:extras[i]] error:&aError];

        if(aError) {

            if(error) {
                *error = aError;
            }

            return NO;
        }

    }

    return YES;
}

BOOL CopyTemplate(NSString* from, NSString* name, NSError** error) {


    NSString* newPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:name];

    NSError* aError = nil;
    [[NSFileManager defaultManager] copyItemAtPath:from toPath:newPath error:&aError];

    if(aError) {

        if(error) {
            *error = aError;
        }

        return NO;
    }

    if(!RenameFolders(newPath, name, error)) {
        return NO;
    }

    if(!RemoveExtras(from, error)) {
        return NO;
    }

    return NO;
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {

        NSString* workingDir = [[NSFileManager defaultManager] currentDirectoryPath];

        NSString* pathToSelf = [workingDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%s", argv[0]]];

        NSString* templatesPath = [[pathToSelf stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ProjectTemplate"];

        NSLog(@"path to templates: %@", templatesPath);

        if(argc < 2) {
            NSLog(@"Expecting name as parameter");
            return 1;
        }

        NSString* newName = [NSString stringWithFormat:@"%s", argv[1]];

        NSError* error = nil;
        if(CopyTemplate(templatesPath, newName, &error)) {

            NSString* settingsPath = [[pathToSelf stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"XcodeBuildSupportConfigs"];

            NSString* newSettingsPath = [workingDir stringByAppendingPathComponent:@"XcodeBuildBuildSupportConfigs"];

            [[NSFileManager defaultManager] copyItemAtPath:settingsPath toPath:newSettingsPath error:&error];
        }

        if(error) {
            NSLog(@"%@", error.localizedDescription);
            return 1;
        }

    }
    return 0;
}

