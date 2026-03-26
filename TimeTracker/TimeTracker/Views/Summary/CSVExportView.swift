//
//  CSVExportView.swift
//  TimeTracker
//
//  CSV 数据导出（F-35）
//  支持按日期范围导出所有时间记录
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVExportView: View {
    @Bindable var viewModel: TimeTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var isExporting = false
    @State private var csvDocument: CSVDocument?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("导出范围") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    let entries = viewModel.fetchEntries(from: startDate, to: endDate)
                    HStack {
                        Text("符合条件的记录")
                        Spacer()
                        Text("\(entries.count) 条")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("预览")
                } footer: {
                    Text("导出的 CSV 文件包含：日期、开始时间、结束时间、时长（分钟）、分类、子分类、标签、备注、来源、是否深度工作")
                }

                Section {
                    Button {
                        generateCSV()
                    } label: {
                        Label("生成 CSV 文件", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(endDate < startDate)
                }

                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: csvFilename
            ) { result in
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    exportError = "导出失败: \(error.localizedDescription)"
                }
            }
        }
    }

    private var csvFilename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        return "TimeTracker_\(start)_\(end)"
    }

    private func generateCSV() {
        let entries = viewModel.fetchEntries(from: startDate, to: endDate)
        let csv = CSVExporter.export(entries: entries)
        csvDocument = CSVDocument(content: csv)
        isExporting = true
    }
}

// MARK: - CSV Document
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(data: data, encoding: .utf8) ?? ""
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - CSV Exporter
enum CSVExporter {
    static func export(entries: [TimeEntry]) -> String {
        var lines: [String] = []

        // BOM + Header
        let header = "日期,星期,开始时间,结束时间,时长(分钟),分类,子分类,标签,备注,来源,深度工作"
        lines.append(header)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "zh_CN")
        weekdayFormatter.dateFormat = "EEEE"

        let sorted = entries.sorted { $0.startTime < $1.startTime }

        for entry in sorted {
            let date = dateFormatter.string(from: entry.startTime)
            let weekday = weekdayFormatter.string(from: entry.startTime)
            let start = timeFormatter.string(from: entry.startTime)
            let end = entry.endTime.map { timeFormatter.string(from: $0) } ?? "进行中"
            let duration = Int(entry.duration / 60)
            let category = entry.category.displayName
            let subCat = escapeCSV(entry.subCategory ?? "")
            let tags = escapeCSV(entry.tags.joined(separator: "; "))
            let notes = escapeCSV(entry.notes ?? "")
            let source = entry.source.displayName
            let deepWork = entry.isDeepWork ? "是" : "否"

            let line = "\(date),\(weekday),\(start),\(end),\(duration),\(category),\(subCat),\(tags),\(notes),\(source),\(deepWork)"
            lines.append(line)
        }

        return "\u{FEFF}" + lines.joined(separator: "\n")
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
