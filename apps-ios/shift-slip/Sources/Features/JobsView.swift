import SwiftData
import SwiftUI

struct JobsView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Environment(\.modelContext) private var context
    // One sheet per view: JobEditView covers both "new" and "existing".
    @State private var target: JobEditTarget?
    @State private var jobPendingDeletion: Job?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if jobs.isEmpty {
                        ContentUnavailableView {
                            Label("jobs.empty.title", systemImage: "briefcase")
                        } description: {
                            Text("jobs.empty.body")
                        }
                        .accessibilityIdentifier("jobs.empty")
                    } else {
                        List {
                            ForEach(jobs) { job in
                                Button { target = .existing(job) } label: {
                                    JobRow(job: job)
                                }
                                .accessibilityIdentifier("jobs.row.\(job.name)")
                            }
                            .onDelete { offsets in
                                if let index = offsets.first { jobPendingDeletion = jobs[index] }
                            }
                        }
                        .accessibilityIdentifier("jobs.list")
                    }
                }
                .frame(maxHeight: .infinity)
                TabRootBanner()
            }
            .navigationTitle("tab.jobs")
            .toolbar {
                Button { target = .new } label: { Label("jobs.add", systemImage: "plus") }
                    .accessibilityIdentifier("jobs.add")
            }
            .sheet(item: $target) { target in
                JobEditView(job: target.job)
            }
            .confirmationDialog(
                "jobs.delete.confirm.title",
                isPresented: Binding(get: { jobPendingDeletion != nil }, set: { if !$0 { jobPendingDeletion = nil } }),
                presenting: jobPendingDeletion
            ) { job in
                Button("jobs.delete.confirm.action", role: .destructive) {
                    for shift in job.shifts ?? [] {
                        ClosoutPhotoStorage.delete(fileName: shift.closeoutPhotoFileName)
                    }
                    context.delete(job)
                    jobPendingDeletion = nil
                }
                Button("common.cancel", role: .cancel) { jobPendingDeletion = nil }
            } message: { job in
                Text("jobs.delete.confirm.message \(String(job.nonSampleShiftCount))")
            }
        }
    }
}

private struct JobRow: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(job.name).font(.headline)
                if job.isSample {
                    Text("common.sample.badge")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.yellow.opacity(0.3), in: Capsule())
                        .accessibilityIdentifier("jobs.row.sample.\(job.name)")
                }
            }
            Text(LocalizedStringKey(job.payType.localizationKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("jobs.row.shiftcount \(String((job.shifts ?? []).count))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private enum JobEditTarget: Identifiable {
    case new
    case existing(Job)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let job): return job.persistentModelID.storeIdentifier ?? job.name
        }
    }

    var job: Job? {
        switch self {
        case .new: return nil
        case .existing(let job): return job
        }
    }
}
