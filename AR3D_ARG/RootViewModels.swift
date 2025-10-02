//
//  RootViewModels.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 5/9/2025.
//
enum Screen: Hashable {
    case select
    case fetch
    case configure(dataSet: DataSet)
    case virtualise(configuration: GraphingConfiguration)
}




