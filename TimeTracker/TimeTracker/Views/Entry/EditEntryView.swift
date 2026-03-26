//
//  EditEntryView.swift
//  TimeTracker
//
//  编辑已有时间记录（F-04）
//

import SwiftUI

struct EditEntryView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    let entry: TimeEntry
    @Environment(\.dismiss) private var dismiss

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedCategory: TimeCategory
    @State private var subCategory: String
    @State private var notes: String
    @State private var tags: String
    @State private var isDeepWork: Bool

    init(viewModel: TimeTrackingViewModel, entry: TimeEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _startTime = State(initialValue: entry.startTime)
        _endTime = State(initialValue: entry.endTime ?? Date())
        _selectedCategory = State(initialValue: entry.category)
        _subCategory = State(initialValue: entry.subCategory ?? "")
        _notes = State(initialValue: entry.notes ?? "")
        _tags = State(initialValue: entry.tags.joined(separator: ", "))
        _isDeepWork = State(initialValue: entry.isDeepWork)
    }

    private var isRunning: Bool { entry.endTime == nil }
    private var isValid: Bool { isRunning || endTime > startTime }

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

                    TextField("子分类（可选）", text: $subCategory)
                }

                // MARK: - 时间调整
                Section("时间") {
                    DatePicker("开始时间", selection: $startTime)

                    if !isRunning {
                        DatePicker("结束时间", selection: $endTime)

                        if endTime > startTime {
                            HStack {
                                Text("时长")
                                Spacer()
                                Text(endTime.timeIntervalSince(startTime).shortFormatted)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Text("状态")
                            Spacer()
                            Text("进行中")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // MARK: - 备注 & 标签
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("标签（逗号分隔）", text: $tags)
                }

                // MARK: - 选项
                Section("选项") {
                    Toggle("深度工作 🔥", isOn: $isDeepWork)
                }

                // MARK: - 来源信息
                Section {
                    HStack {
                        Text("来源")
                        Spacer()
                        Text(entry.source.displayName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(DateHelper.shortDateTimeString(entry.createdAt))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveChanges() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.updateEntry(
            entry,
            startTime: startTime,
            endTime: isRunning ? nil : endTime,
            category: selectedCategory,
            subCategory: subCategory.isEmpty ? nil : subCategory,
            notes: notes.isEmpty ? nil : notes,
            tags: parsedTags,
            isDeepWork: isDeepWork
        )
        dismiss()
    }
}
