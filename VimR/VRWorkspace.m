/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import <TBCacao/TBCacao.h>
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRMainWindow.h"
#import "VRMainWindowControllerFactory.h"
#import "VRWorkspaceController.h"


static CGPoint qDefaultOrigin = {242, 364};


@implementation VRWorkspace {
  MMVimController *_vimController;
  NSMutableArray *_openedBufferUrls;
}

#pragma mark Public
- (BOOL)isOnlyWorkspace {
  return _workspaceController.workspaces.count == 1;
}

- (void)selectBufferWithUrl:(NSURL *)url {
  [_vimController gotoBufferWithUrl:url];
  [_mainWindowController.window makeKeyAndOrderFront:self];
}

- (NSArray *)openedUrls {
  return _openedBufferUrls;
}

- (void)updateWorkingDirectory:(NSURL *)workingDir {
  [_fileItemManager unregisterUrl:_workingDirectory];
  [_fileItemManager registerUrl:workingDir];

  _workingDirectory = workingDir;
  [_mainWindowController updateWorkingDirectory];
}

- (void)openFilesWithUrls:(NSArray *)urls {
  [_mainWindowController openFilesWithUrls:urls];
}

- (BOOL)hasModifiedBuffer {
  return _mainWindowController.vimController.hasModifiedBuffer;
}

- (void)setUpWithVimController:(MMVimController *)vimController {
  [_fileItemManager registerUrl:_workingDirectory];

  _vimController = vimController;

  CGPoint origin= [self cascadedWindowOrigin];
  CGRect contentRect = rect_with_origin(origin, 480, 360);
  _mainWindowController = [_mainWindowControllerFactory newMainWindowControllerWithContentRect:contentRect workspace:self vimController:vimController];

  vimController.delegate = _mainWindowController;
}

- (void)setUpInitialBuffers {
  _openedBufferUrls = [self bufferUrlsFromVimBuffers:_vimController.buffers];
}

- (void)updateBuffers {
  NSMutableArray *bufferUrls = [self bufferUrlsFromVimBuffers:_vimController.buffers];

  NSMutableSet *bufferUrlsSet = [NSMutableSet setWithArray:bufferUrls];
  [bufferUrlsSet minusSet:[NSSet setWithArray:_openedBufferUrls]];
  if (bufferUrlsSet.count == 0) {
    return;
  }

  _openedBufferUrls = bufferUrls;
  NSURL *commonParent = common_parent_url(bufferUrls);
  if ([commonParent isEqualTo:_workingDirectory]) {
    return;
  }

  [self updateWorkingDirectory:commonParent];
}

- (void)cleanUpAndClose {
  [_mainWindowController cleanUpAndClose];
  [_fileItemManager unregisterUrl:self.workingDirectory];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _openedBufferUrls = [[NSMutableArray alloc] initWithCapacity:10];

  return self;
}

#pragma mark Private
- (CGPoint)cascadedWindowOrigin {
  CGPoint origin = qDefaultOrigin;

  NSWindow *curKeyWindow = [NSApp keyWindow];
  if ([curKeyWindow isKindOfClass:[VRMainWindow class]]) {
    origin = curKeyWindow.frame.origin;
    origin.x += 24;
    origin.y -= 48;

    CGSize curScreenSize = curKeyWindow.screen.visibleFrame.size;
    if (curScreenSize.width < origin.x + 500 || origin.y < 5) {
      origin = qDefaultOrigin;
    }
  }

  return origin;
}

- (NSMutableArray *)bufferUrlsFromVimBuffers:(NSArray *)vimBuffers {
  NSMutableArray *bufferUrls = [[NSMutableArray alloc] initWithCapacity:vimBuffers.count];
  for (MMBuffer *buffer in vimBuffers) {
    if (buffer.fileName) {
      [bufferUrls addObject:[NSURL fileURLWithPath:buffer.fileName]];
    }
  }

  return bufferUrls;
}

@end
