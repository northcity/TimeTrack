//
//  AddEntryView.swift
//  TimeTracker
//
//  添加/补记录视图
//

import SwiftUI

struct AddEntryView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var selectedCategory: TimeCategory = .output
    @State private var notes: String = ""
    @State private var tags: String = ""
    @State private var isDeepWork: Bool = false

    /// 如果提供了预设的时间段（用于空白时间补记录）
    var presetStart: Date?
    var presetEnd: Date?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 分类选择
                Section("分类") {
                    Picker("时间分类", selection: $selectedCategory) {
                        ForEach(TimeCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Image(systemName: selectedCategory.icon)
                            .foregroundStyle(selectedCategory.color)
                        Text(selectedCategory.subtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 时间选择
                Section("时间") {
                    DatePicker("开始时间", selection: $startTime)
                    DatePicker("结束时间", selection: $endTime)

                    if endTime > startTime {
                        HStack {
                            Text("时长")
                            Spacer()
                            Text(endTime.timeIntervalSince(startTime).shortFormatted)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - 备注
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(2...5)

                    TextField("标签（逗号分隔）", text: $tags)
                }

                // MARK: - 选项
                Section("选项") {
                    Toggle("深度工作", isOn: $isDeepWork)
                }
            }
            .navigationTitle("补记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEntry()
                    }
                    .disabled(endTime <= startTime)
                }
            }
            .onAppear {
                if let ps = presetStart { startTime = ps }
                if let pe = presetEnd { endTime = pe }
            }
        }
    }

    private func saveEntry() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.addBackfillEntry(
            startTime: startTime,
            endTime: endTime,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            tags: parsedTags
        )
        dismiss()
    }
}
