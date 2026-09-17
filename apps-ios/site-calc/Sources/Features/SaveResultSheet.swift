import SwiftData
import SwiftUI

/// Shared "save this into a job" sheet used by every solver screen (S004-S007):
/// pick an existing job, or start a new one by name.
struct SaveResultSheet: View {
    @Query(sort: \SiteJob.updatedAt, order: .reverse) private var jobs: [SiteJob]
    @Environment(\.dismiss) private var dismiss
    @State private var newJobName = ""

    let onSaveNew: (String) -> Void
    let onSaveExisting: (SiteJob) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("saveResult.newJob") {
                    TextField("job.name", text: $newJobName)
                        .accessibilityIdentifier("saveResult.newJobName")
                    Button("saveResult.saveAsNew") {
                        onSaveNew(newJobName.isEmpty ? "job.untitled".localized : newJobName)
                        dismiss()
                    }
                    .accessibilityIdentifier("saveResult.saveAsNewButton")
                }
                if !jobs.isEmpty {
                    Section("saveResult.existingJob") {
                        ForEach(jobs) { job in
                            Button(job.name) {
                                onSaveExisting(job)
                                dismiss()
                            }
                            .accessibilityIdentifier("saveResult.job.\(job.name)")
                        }
                    }
                }
            }
            .navigationTitle("saveResult.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                }
            }
        }
    }
}
