import SwiftData
import SwiftUI

/// S008, the third tab: every saved job, newest first. Carries the banner
/// (one of only three screens allowed to).
struct JobsListView: View {
    @Query(sort: \SiteJob.updatedAt, order: .reverse) private var jobs: [SiteJob]
    @Environment(\.modelContext) private var context
    @State private var newJobName = ""
    @State private var showingNewJob = false
    @State private var pendingDelete: SiteJob?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if jobs.isEmpty {
                        ContentUnavailableView("jobs.empty.title", systemImage: "folder",
                                                description: Text("jobs.empty.body"))
                            .accessibilityIdentifier("jobs.empty")
                    } else {
                        List {
                            ForEach(jobs) { job in
                                NavigationLink(value: job) {
                                    JobRow(job: job)
                                }
                                .accessibilityIdentifier("jobs.row.\(job.name)")
                            }
                            .onDelete { offsets in
                                pendingDelete = offsets.first.map { jobs[$0] }
                            }
                        }
                        .accessibilityIdentifier("jobs.list")
                    }
                }
                .frame(maxHeight: .infinity)
                AdBannerFooter()
            }
            .navigationTitle("tab.jobs")
            .navigationDestination(for: SiteJob.self) { job in
                JobDetailView(job: job)
            }
            .toolbar {
                Button { showingNewJob = true } label: { Label("jobs.new", systemImage: "plus") }
                    .accessibilityIdentifier("jobs.new")
            }
            .sheet(isPresented: $showingNewJob) {
                NewJobSheet { name in
                    context.insert(SiteJob(name: name))
                }
            }
            .alert("jobs.delete.title", isPresented: .constant(pendingDelete != nil), presenting: pendingDelete) { job in
                Button("jobs.delete.confirm", role: .destructive) {
                    context.delete(job)
                    pendingDelete = nil
                }
                Button("edit.cancel", role: .cancel) { pendingDelete = nil }
            } message: { job in
                Text(localized("jobs.delete.message", "\(job.lineCount)"))
            }
        }
    }
}

private struct JobRow: View {
    let job: SiteJob
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(job.name).font(.headline)
                    if job.isSample {
                        Text("jobs.sampleBadge")
                            .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.yellow.opacity(0.3)).clipShape(Capsule())
                            .accessibilityIdentifier("jobs.sampleBadge.\(job.name)")
                    }
                }
                Text(job.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(verbatim: "\(job.lineCount)").foregroundStyle(.secondary)
        }
    }
}

private struct NewJobSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("job.name", text: $name).accessibilityIdentifier("jobs.newName")
            }
            .navigationTitle("jobs.new")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("edit.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("edit.save") {
                        onCreate(name.isEmpty ? "job.untitled".localized : name)
                        dismiss()
                    }
                    .accessibilityIdentifier("jobs.newSave")
                }
            }
        }
    }
}
