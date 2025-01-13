//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if compiler(>=6)
public import LanguageServerProtocol
#else
import LanguageServerProtocol
#endif

fileprivate let requestTypes: [_RequestType.Type] = [
  BuildShutdownRequest.self,
  BuildTargetPrepareRequest.self,
  BuildTargetSourcesRequest.self,
  CreateWorkDoneProgressRequest.self,
  InitializeBuildRequest.self,
  RegisterForChanges.self,
  TextDocumentSourceKitOptionsRequest.self,
  WorkspaceBuildTargetsRequest.self,
  WorkspaceWaitForBuildSystemUpdatesRequest.self,
]

fileprivate let notificationTypes: [NotificationType.Type] = [
  FileOptionsChangedNotification.self,
  OnBuildExitNotification.self,
  OnBuildInitializedNotification.self,
  OnBuildLogMessageNotification.self,
  OnBuildTargetDidChangeNotification.self,
  OnWatchedFilesDidChangeNotification.self,
  TaskFinishNotification.self,
  TaskProgressNotification.self,
  TaskStartNotification.self,
]

public let bspRegistry = MessageRegistry(requests: requestTypes, notifications: notificationTypes)
