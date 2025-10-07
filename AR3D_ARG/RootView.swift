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
                        if !selected.isEmpty {
                            path.append(.configure(dataSets: selected, index: 0, accumulated: []))
                        }
                    }

                case .fetch:
                    FetchDataSetView { selected in
                        if !selected.isEmpty {
                            path.append(.configure(dataSets: selected, index: 0, accumulated: []))
                        }
                    }

                case .configure(let dataSets, let index, let accumulated):
                    ConfigureGraphingView(
                        dataSet: dataSets[index],
                        currentIndex: index,
                        totalCount: dataSets.count,
                        accumulated: accumulated,
                        navigateToNext: { nextIndex, updated in
                            path.append(.configure(dataSets: dataSets, index: nextIndex, accumulated: updated))
                        },
                        navigateToVirtualise: { finalConfigs in
                            path.append(.virtualise(configurations: finalConfigs))
                        }
                    )

                case .virtualise(let configurations):
                    VirtualiseView(configuration: configurations)
                }
            }
        }
    }
}
