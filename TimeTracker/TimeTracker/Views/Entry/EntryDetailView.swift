//
//  EntryDetailView.swift
//  TimeTracker
//
//  时间记录详情视图
//

import SwiftUI

struct EntryDetailView: View {
    let entry: TimeEntry
    @Bindable var viewModel: TimeTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label(entry.category.displayName, systemImage: entry.category.icon)
                        .foregroundStyle(entry.category.color)
                    Spacer()
                    Text(entry.category.subtitle)
                        .foregroundStyle(.secondary)
                }

                if let sub = entry.subCategory {
                    HStack {
                        Text("子分类")
                        Spacer()
                        Text(sub)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("时间") {
                HStack {
                    Text("开始")
                    Spacer()
                    Text(DateHelper.timeString(entry.startTime))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("结束")
                    Spacer()
                    if let end = entry.endTime {
                        Text(DateHelper.timeString(end))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("进行中")
                            .foregroundStyle(.orange)
                    }
                }
                HStack {
                    Text("时长")
                    Spacer()
                    Text(entry.formattedDuration)
                        .font(.headline)
                        .foregroundStyle(entry.category.color)
                }
            }

            if let notes = entry.notes, !notes.isEmpty {
                Section("备注") {
                    Text(notes)
                }
            }

            if !entry.tags.isEmpty {
                Section("标签") {
                    FlowLayout(spacing: 8) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("来源")
                    Spacer()
                    Text(entry.source.displayName)
                        .foregroundStyle(.secondary)
                }
                if entry.isDeepWork {
                    Label("深度工作", systemImage: "brain.head.profile")
                        .foregroundStyle(.blue)
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("删除记录", systemImage: "trash")
                }
            }
        }
        .navigationTitle(DateHelper.shortDateString(entry.startTime))
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                viewModel.deleteEntry(entry)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复")
        }
    }
}

// MARK: - FlowLayout（标签流式布局）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}
