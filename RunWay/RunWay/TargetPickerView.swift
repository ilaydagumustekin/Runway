//
//  TargetPickerView.swift
//  RunWay
//
//  Created by İlayda Gümüştekin on 22.02.2026.
//

import SwiftUI

struct TargetPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    let popular = ["Merkez", "Modernevler", "Fatih Mahallesi", "Çünür", "Bahçelievler"]
    @State private var selectedTarget: String? = nil

    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                TextField("Hedef ara (mahalle/konum)", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 8)

                Text("Popüler Mahalleler")
                    .font(.headline)

                LazyVStack(spacing: 10) {
                    ForEach(popular.filter { searchText.isEmpty ? true : $0.localizedCaseInsensitiveContains(searchText) }, id: \.self) { item in
                        Button {
                            selectedTarget = item
                        } label: {
                            HStack {
                                Text(item)
                                Spacer()
                                if selectedTarget == item {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Button {
                    if let selectedTarget {
                        onSelect(selectedTarget)
                        dismiss()
                    }
                } label: {
                    Text("Devam")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTarget == nil ? Color.gray.opacity(0.3) : Color.green)
                        .foregroundStyle(selectedTarget == nil ? Color.gray : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedTarget == nil)
            }
            .padding()
            .navigationTitle("Hedef Seç")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
