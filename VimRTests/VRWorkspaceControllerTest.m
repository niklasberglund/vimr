/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRMainWindowController.h"
#import "VRWorkspaceController.h"
#import "VRWorkspace.h"
#import "VRWorkspaceFactory.h"
#import "VRUtils.h"


@interface VRWorkspaceControllerTest : VRBaseTestCase

@end

@implementation VRWorkspaceControllerTest {
  VRWorkspaceController *workspaceController;

  MMVimManager *vimManager;
  MMVimController *vimController;

  VRWorkspace *workspace;
  VRWorkspaceFactory *workspaceFactory;
  NSArray *urls;
}

- (void)setUp {
  [super setUp];

  vimManager = mock([MMVimManager class]);
  [given([vimManager pidOfNewVimControllerWithArgs:anything()]) willReturnInt:123];

  vimController = mock([MMVimController class]);
  [given([vimController pid]) willReturnInt:123];

  workspace = mock([VRWorkspace class]);
  workspaceFactory = mock([VRWorkspaceFactory class]);

  workspaceController = [[VRWorkspaceController alloc] init];
  workspaceController.vimManager = vimManager;
  workspaceController.workspaceFactory = workspaceFactory;

  urls = @[
      [NSURL URLWithString:@"file:///some/folder/is/1.txt"],
      [NSURL URLWithString:@"file:///some/folder/2.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/there/3.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/not/there/4.txt"],
  ];
}

- (void)testSelectBufferWithUrl {
  [given([workspaceFactory newWorkspaceWithWorkingDir:instanceOf([NSURL class])]) willReturn:workspace];
  [workspaceController openFilesInNewWorkspace:urls];

  [given([workspace openedUrls]) willReturn:urls];

  [workspaceController selectBufferWithUrl:urls[2]];
  [verify(workspace) selectBufferWithUrl:urls[2]];
}

- (void)testNewWorkspace {
  [given([workspaceFactory newWorkspaceWithWorkingDir:[NSURL fileURLWithPath:NSHomeDirectory()]]) willReturn:workspace];

  [workspaceController newWorkspace];
  (workspaceController.workspaces, consistsOf(workspace));
}

- (void)testOpenFilesInNewWorkspace {
  [given([workspaceFactory newWorkspaceWithWorkingDir:common_parent_url(urls)]) willReturn:workspace];

  [workspaceController openFilesInNewWorkspace:urls];

  [verify(vimManager) pidOfNewVimControllerWithArgs:@{
      qVimArgFileNamesToOpen : @[
          @"/some/folder/is/1.txt",
          @"/some/folder/2.txt",
          @"/some/folder/is/there/3.txt",
          @"/some/folder/is/not/there/4.txt",
      ],
      qVimArgOpenFilesLayout : @(MMLayoutTabs)
  }];
  (workspaceController.workspaces, consistsOf(workspace));
}

- (void)testCleanup {
  [workspaceController cleanUp];
  [verify(vimManager) terminateAllVimProcesses];
}

- (void)testHasDirtyBuffers {
  [given([workspaceFactory newWorkspaceWithWorkingDir:instanceOf([NSURL class])]) willReturn:workspace];
  [workspaceController openFilesInNewWorkspace:urls];

  [given([workspace hasModifiedBuffer]) willReturnBool:YES];
  (@([workspaceController hasDirtyBuffers]), isYes);
}

- (void)testManagerVimControllerCreated {
  [given([workspaceFactory newWorkspaceWithWorkingDir:instanceOf([NSURL class])]) willReturn:workspace];
  [workspaceController openFilesInNewWorkspace:urls];

  [workspaceController manager:vimManager vimControllerCreated:vimController];
  [verify(workspace) setUpWithVimController:vimController];
}

- (void)testManagerVimControllerRemovedWithControllerIdPid {
  [given([workspaceFactory newWorkspaceWithWorkingDir:instanceOf([NSURL class])]) willReturn:mock([VRWorkspace class])];

  [workspaceController newWorkspace];
  [workspaceController manager:vimManager vimControllerRemovedWithControllerId:456 pid:123];

  (workspaceController.workspaces, isEmpty());
}

- (void)testMenuItemTemplateForManager {
  ([workspaceController menuItemTemplateForManager:vimManager], isNot(nilValue()));
}

@end
