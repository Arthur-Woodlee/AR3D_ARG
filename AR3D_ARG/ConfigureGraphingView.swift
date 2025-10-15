//
//  ConfigureGraphingView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 5/9/2025.
//
import SwiftUI

struct ConfigureGraphingView: View {
    let dataSet: DataSet
    let currentIndex: Int
    let totalCount: Int
    let accumulated: [GraphingConfiguration]
    let navigateToNext: (_ nextIndex: Int, _ updated: [GraphingConfiguration]) -> Void
    let navigateToVirtualise: ([GraphingConfiguration]) -> Void

    @State private var selectedGraph: GraphType?
    @State private var selectedFeatures: [String] = []
    @State private var numericFeatures: [String] = []
    @State private var categoricalFeatures: [String] = []
    @State private var selectedThemeID: UUID = ThemeRegistry.all.first?.id ?? UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                featureSelectionSection
                ChartTypePickerView(selectedGraph: $selectedGraph)
                ThemePickerView(selectedThemeID: $selectedThemeID)
                    .padding(.bottom, 16)
                navigationButton
            }
            .padding()
        }
        .onAppear {
            if numericFeatures.isEmpty || categoricalFeatures.isEmpty {
                numericFeatures = GraphingDataUtils.extractNumericFeatureKeys(from: dataSet) ?? []
                categoricalFeatures = ["category"]
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Configure Graphing (\(currentIndex + 1) of \(totalCount))")
                .font(.largeTitle)
                .bold()
            Text(dataSet.name)
                .font(.headline)
            Text(dataSet.description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var featureSelectionSection: some View {
        Group {
            if numericFeatures.count >= 3 {
                VStack {
                    Text("Select 2 or 3 Data Points")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal)

                    FeatureSelectorView(
                        numericFeatures: numericFeatures,
                        categoricalFeatures: categoricalFeatures,
                        selectedFeatures: $selectedFeatures,
                        maxSelection: 3
                    )
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }

    private var navigationButton: some View {
        Button(currentIndex < totalCount - 1 ? "Next Dataset" : "Visualise All") {
            let axisCount = selectedFeatures.filter { !categoricalFeatures.contains($0) }.count
            guard let graph = selectedGraph, (2...3).contains(axisCount),
                  let selectedTheme = ThemeRegistry.all.first(where: { $0.id == selectedThemeID })?.theme else {
                return
            }

            let config = GraphingConfiguration(
                dataSet: dataSet,
                selectedGraph: graph,
                selectedFeatures: selectedFeatures,
                themeID: selectedThemeID
            )

            let updatedConfigs = accumulated + [config]

            if currentIndex < totalCount - 1 {
                navigateToNext(currentIndex + 1, updatedConfigs)
            } else {
                navigateToVirtualise(updatedConfigs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(selectedGraph == nil || !(2...3).contains(selectedFeatures.filter({ !categoricalFeatures.contains($0) }).count))
    }
}

struct ChartTypePickerView: View {
    @Binding var selectedGraph: GraphType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart Types")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            ForEach(GraphType.allCases) { graph in
                Button(action: {
                    selectedGraph = graph
                }) {
                    HStack {
                        Image(systemName: selectedGraph == graph ? "checkmark.square" : "square")
                            .foregroundColor(.accentColor)
                        Text(graph.rawValue)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct ThemeRowView: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.square" : "square")
                .foregroundColor(.accentColor)
            Text(name)
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ThemePickerView: View {
    @Binding var selectedThemeID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Theme")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            ForEach(ThemeRegistry.all) { viewModel in
                let isSelected = selectedThemeID == viewModel.id

                Button(action: {
                    selectedThemeID = viewModel.id
                }) {
                    ThemeRowView(name: viewModel.name, isSelected: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct ThemeViewModel: Identifiable, Equatable {
    let id: UUID
    let name: String
    let theme: any ColorTheme

    init(theme: any ColorTheme) {
        guard let uuid = theme.id as? UUID else {
            fatalError("ColorTheme.id must be UUID")
        }
        self.id = uuid
        self.name = theme.name
        self.theme = theme
    }

    static func == (lhs: ThemeViewModel, rhs: ThemeViewModel) -> Bool {
        lhs.id == rhs.id
    }
}


struct ThemeWrapper: Identifiable, Equatable {
    let id: UUID
    let theme: any ColorTheme

    init(_ theme: any ColorTheme) {
        guard let uuid = theme.id as? UUID else {
            fatalError("ColorTheme.id must be UUID")
        }
        self.id = uuid
        self.theme = theme
    }

    static func == (lhs: ThemeWrapper, rhs: ThemeWrapper) -> Bool {
        lhs.id == rhs.id
    }
}


struct FeatureSelectorView: View {
    let numericFeatures: [String]
    let categoricalFeatures: [String]
    @Binding var selectedFeatures: [String]
    let maxSelection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Categorical Feature Section
            if !categoricalFeatures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category (Optional)")
                        .font(.subheadline)

                    ForEach(categoricalFeatures, id: \.self) { feature in
                        let isSelected = selectedFeatures.contains(feature)
                        let selectedCategorical = selectedFeatures.filter { categoricalFeatures.contains($0) }
                        let isDisabled = !isSelected && !selectedCategorical.isEmpty

                        FeatureRowView(
                            label: feature,
                            isSelected: isSelected,
                            isDisabled: isDisabled,
                            bold: true
                        ) {
                            if isSelected {
                                selectedFeatures.removeAll { $0 == feature }
                            } else {
                                selectedFeatures.removeAll { categoricalFeatures.contains($0) }
                                selectedFeatures.append(feature)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            }

            // Numeric Feature Section
            VStack(alignment: .leading, spacing: 8) {
                let selectedNumericCount = selectedFeatures.filter { !categoricalFeatures.contains($0) }.count

                ForEach(numericFeatures, id: \.self) { feature in
                    let isSelected = selectedFeatures.contains(feature)
                    let isDisabled = !isSelected && selectedNumericCount >= maxSelection

                    FeatureRowView(
                        label: feature,
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        bold: false
                    ) {
                        if isSelected {
                            selectedFeatures.removeAll { $0 == feature }
                        } else if selectedNumericCount < maxSelection {
                            selectedFeatures.append(feature)
                        }
                    }
                }

                if selectedNumericCount < 2 {
                    HStack {
                        Spacer()
                        Text("⚠️\nPlease select at least 2 numeric features.\nYou may select up to \(maxSelection).")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding()
    }
}
struct FeatureRowView: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    let bold: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isDisabled ? .gray : .accentColor)
                Text(label)
                    .font(bold ? .body.bold() : .body)
                    .foregroundColor(isDisabled ? .gray : .primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle()) // Ensures full tap area
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
