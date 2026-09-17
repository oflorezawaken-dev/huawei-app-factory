import SwiftData
import SwiftUI

/// S003, the second tab: the four solvers, one tap away. No advertising of
/// any kind on this screen.
struct SolversHubView: View {
    @Query(sort: \SiteJob.updatedAt, order: .reverse) private var jobs: [SiteJob]

    private var recentResults: [(job: SiteJob, result: SavedSolverResult)] {
        let all: [(job: SiteJob, result: SavedSolverResult)] = jobs.flatMap { job in
            job.solverResults.map { (job: job, result: $0) }
        }
        return Array(all.sorted { $0.result.createdAt > $1.result.createdAt }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: RoofSolverView()) {
                        Label("solvers.roof", systemImage: "triangle")
                    }
                    .accessibilityIdentifier("solvers.roof")
                    NavigationLink(destination: StairSolverView()) {
                        Label("solvers.stair", systemImage: "stairs")
                    }
                    .accessibilityIdentifier("solvers.stair")
                    NavigationLink(destination: AreaVolumeView()) {
                        Label("solvers.areaVolume", systemImage: "square.on.square")
                    }
                    .accessibilityIdentifier("solvers.areaVolume")
                    NavigationLink(destination: MaterialEstimatorView()) {
                        Label("solvers.materials", systemImage: "shippingbox")
                    }
                    .accessibilityIdentifier("solvers.materials")
                }

                if !recentResults.isEmpty {
                    Section("solvers.recent") {
                        ForEach(recentResults, id: \.result.id) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.result.title)
                                Text(entry.job.name).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("tab.solvers")
        }
    }
}
