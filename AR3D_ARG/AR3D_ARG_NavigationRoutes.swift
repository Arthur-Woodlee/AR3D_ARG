//
//  AR3D_ARG_Navigation_Routes.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
enum Screen: Hashable {
    case select
    case fetch
    case configure(dataSets: [DataSet], index: Int, accumulated: [GraphingConfiguration])
    case virtualise(configurations: [GraphingConfiguration])
}
