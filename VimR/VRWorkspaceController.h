/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <MacVimFramework/MacVimFramework.h>


extern NSString *const qVimArgFileNamesToOpen;
extern NSString *const qVimArgOpenFilesLayout;


@class VRMainWindowController;
@class VRFileItemManager;
@class VROpenQuicklyWindowController;
@class VRWorkspaceFactory;


@interface VRWorkspaceController : NSObject <MMVimManagerDelegateProtocol>

@property (nonatomic, weak) MMVimManager *vimManager;
@property (nonatomic, weak) VRWorkspaceFactory *workspaceFactory;

@property (nonatomic, readonly) NSArray *workspaces;

#pragma mark Public
- (void)newWorkspace;
- (void)openFilesInNewWorkspace:(NSArray *)fileUrls;
- (void)cleanUp;
- (BOOL)hasDirtyBuffers;
- (void)selectBufferWithUrl:(NSURL *)url;

#pragma mark NSObject
- (id)init;

#pragma mark MMVimManagerDelegate
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)vimController;
- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)controllerId pid:(int)pid;
- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager;

@end
