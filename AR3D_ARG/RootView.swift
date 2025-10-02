//
//  RootView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 5/9/2025.
//
import SwiftUI

struct RootView: View {
    @State private var path: [Screen] = []

    var body: some View {
        NavigationStack(path: $path) {
            SplashScreenView(
                navigateToLocalFiles: {
                    path.append(.select)
                },
                navigateToAPI: {
                    path.append(.fetch)
                }
            )
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .select:
                    SelectDataSetsView { selected in
                        if let dataSet = selected.first {
                            path.append(.configure(dataSet: dataSet))
                        }
                    }

                case .fetch:
                    FetchDataSetView { selected in
                        if let dataSet = selected.first {
                            path.append(.configure(dataSet: dataSet))
                        }
                    }

                case .configure(let dataSet):
                    ConfigureGraphingView(
                        dataSet: dataSet,
                        navigateToVirtualise: { configuration in
                            path.append(.virtualise(configuration: configuration))
                        }
                    )

                case .virtualise(let configuration):
                    VirtualiseView(configuration: configuration)
                }
            }
        }
    }
}
