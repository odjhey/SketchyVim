#include "workspace.h"
#include "buffer.h"
#include "event_tap.h"

void workspace_begin(void **context) {
    workspace_context *ws_context = [workspace_context alloc];
    *context = ws_context;

    [ws_context init];
}

@implementation workspace_context
- (id)init {
    if ((self = [super init])) {
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                selector:@selector(appSwitched:)
                name:NSWorkspaceDidActivateApplicationNotification
                object:nil];
        [self frontAppChanged:[[NSWorkspace sharedWorkspace] frontmostApplication]];
    }

    return self;
}

- (void)dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)appSwitched:(NSNotification *)notification {
    [self frontAppChanged:[notification.userInfo objectForKey:NSWorkspaceApplicationKey]];
}

- (void)frontAppChanged:(NSRunningApplication *)app {
    char* name = app ? (char*)[[app localizedName] UTF8String] : NULL;
    char* bundle_id = app ? (char*)[[app bundleIdentifier] UTF8String] : NULL;
    pid_t pid = app ? app.processIdentifier : 0;

    g_event_tap.front_app_ignored = !event_tap_check_allowlist(&g_event_tap,
                                                               name,
                                                               bundle_id    );
    ax_front_app_changed(&g_ax, pid);
}

@end
