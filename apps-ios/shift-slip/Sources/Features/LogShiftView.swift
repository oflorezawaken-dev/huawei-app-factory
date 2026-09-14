import PhotosUI
import SwiftData
import SwiftUI

/// The core loop (F002): one screen, no modal chains besides the optional
/// tip-out split. Saving writes to SwiftData first and only then navigates to
/// the summary -- an ad can never sit between the user and a recorded number.
struct LogShiftView: View {
    let existingShift: Shift?
    var onSaved: (Shift) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Job.createdAt) private var jobs: [Job]

    @State private var date = Date.now
    @State private var selectedJob: Job?
    @State private var entryMode: ShiftEntryMode = .times
    @State private var startTimeOfDay = Date.now
    @State private var endTimeOfDay = Date.now
    @State private var hoursText = ""
    @State private var cashTipsText = ""
    @State private var chargeTipsText = ""
    @State private var noncashTipsText = ""
    @State private var serviceChargesText = ""
    @State private var salesText = ""
    @State private var showSalesField = false
    @State private var recipients: [TipOutRecipientRule] = []
    @State private var tipOutIsManual = false
    @State private var manualTipOutText = ""
    @State private var showingTipOutSplit = false
    @State private var saveAsJobDefault = false
    @State private var photoItem: PhotosPickerItem?
    @State private var photoFileName: String?
    @State private var calendar = Calendar.current

    init(existingShift: Shift? = nil, onSaved: @escaping (Shift) -> Void = { _ in }) {
        self.existingShift = existingShift
        self.onSaved = onSaved
    }

    private var cashTips: Decimal { DecimalParsing.parse(cashTipsText) ?? 0 }
    private var chargeTips: Decimal { DecimalParsing.parse(chargeTipsText) ?? 0 }
    private var noncashTips: Decimal { DecimalParsing.parse(noncashTipsText) ?? 0 }
    private var serviceCharges: Decimal { DecimalParsing.parse(serviceChargesText) ?? 0 }
    private var sales: Decimal? { showSalesField ? DecimalParsing.parse(salesText) : nil }
    private var voluntaryTips: Decimal { cashTips + chargeTips }

    private var hours: Decimal {
        switch entryMode {
        case .times:
            let start = combine(date: date, timeOfDay: startTimeOfDay)
            var end = combine(date: date, timeOfDay: endTimeOfDay)
            if end <= start { end = calendar.date(byAdding: .day, value: 1, to: end)! }
            return EarningsEngine.hoursBetween(start, end)
        case .hours:
            return DecimalParsing.parse(hoursText) ?? 0
        }
    }

    private var tipOutTotal: Decimal {
        if tipOutIsManual { return DecimalParsing.parse(manualTipOutText) ?? 0 }
        return TipOutEngine.resolve(recipients: recipients, voluntaryTips: voluntaryTips, sales: sales ?? 0)
            .reduce(Decimal(0)) { $0 + $1.resolvedAmount }
    }

    private var liveFigures: ShiftFigures {
        ShiftFigures(hours: hours, baseRate: selectedJob?.baseRate ?? 0, cashTips: cashTips,
                     chargeTips: chargeTips, tipOutTotal: tipOutTotal, sales: sales)
    }

    private var isValid: Bool { selectedJob != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("logshift.date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("logshift.date")
                    Picker("logshift.job", selection: $selectedJob) {
                        ForEach(jobs) { job in
                            Text(job.name).tag(Optional(job))
                        }
                    }
                    .accessibilityIdentifier("logshift.job")
                    .onChange(of: selectedJob) { _, newJob in applyJobDefaults(newJob) }
                }

                Section("logshift.section.hours") {
                    Picker("logshift.entrymode", selection: $entryMode) {
                        Text("logshift.entrymode.times").tag(ShiftEntryMode.times)
                        Text("logshift.entrymode.hours").tag(ShiftEntryMode.hours)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("logshift.entrymode")

                    if entryMode == .times {
                        DatePicker("logshift.starttime", selection: $startTimeOfDay, displayedComponents: .hourAndMinute)
                            .accessibilityIdentifier("logshift.starttime")
                        DatePicker("logshift.endtime", selection: $endTimeOfDay, displayedComponents: .hourAndMinute)
                            .accessibilityIdentifier("logshift.endtime")
                    } else {
                        TextField("logshift.hours", text: $hoursText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("logshift.hours")
                    }
                }

                Section("logshift.section.tips") {
                    TextField("logshift.cashtips", text: $cashTipsText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("logshift.cashtips")
                    TextField("logshift.chargetips", text: $chargeTipsText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("logshift.chargetips")
                    TextField("logshift.noncashtips", text: $noncashTipsText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("logshift.noncashtips")
                    TextField("logshift.servicecharges", text: $serviceChargesText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("logshift.servicecharges")
                    Text("logshift.servicecharges.footnote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("logshift.showsales", isOn: $showSalesField)
                        .accessibilityIdentifier("logshift.showsales")
                    if showSalesField {
                        TextField("logshift.sales", text: $salesText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("logshift.sales")
                    }
                }

                Section("logshift.section.tipout") {
                    Button {
                        showingTipOutSplit = true
                    } label: {
                        HStack {
                            Text("logshift.tipout")
                            Spacer()
                            Text(CurrencyFormatting.string(tipOutTotal, currencyCode: selectedJob?.currencyCode ?? "USD"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("logshift.tipout.button")
                }

                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoFileName == nil ? "logshift.photo.add" : "logshift.photo.replace", systemImage: "photo")
                    }
                    .accessibilityIdentifier("logshift.photo.picker")
                    .onChange(of: photoItem) { _, newItem in Task { await loadPhoto(newItem) } }
                } header: {
                    Text("logshift.section.photo")
                }

                Section("logshift.section.live") {
                    LabeledContent("logshift.live.tipskept",
                                    value: CurrencyFormatting.string(EarningsEngine.tipsKept(liveFigures),
                                                                      currencyCode: selectedJob?.currencyCode ?? "USD"))
                        .accessibilityIdentifier("logshift.live.tipskept")
                    LabeledContent("logshift.live.effectivehourly",
                                    value: CurrencyFormatting.stringOrDash(EarningsEngine.effectiveHourly(liveFigures),
                                                                            currencyCode: selectedJob?.currencyCode ?? "USD"))
                        .accessibilityIdentifier("logshift.live.effectivehourly")
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(existingShift == nil ? "logshift.title.new" : "logshift.title.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .accessibilityIdentifier("logshift.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
                        .disabled(!isValid)
                        .accessibilityIdentifier("logshift.save")
                }
            }
            .sheet(isPresented: $showingTipOutSplit) {
                TipOutSplitView(recipients: $recipients, tipOutIsManual: $tipOutIsManual,
                                 manualAmountText: $manualTipOutText, saveAsJobDefault: $saveAsJobDefault,
                                 voluntaryTips: voluntaryTips, sales: sales ?? 0,
                                 currencyCode: selectedJob?.currencyCode ?? "USD")
            }
            .onAppear(perform: load)
        }
    }

    private func combine(date: Date, timeOfDay: Date) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOfDay)
        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        return calendar.date(from: merged)!
    }

    private func applyJobDefaults(_ job: Job?) {
        guard let job, existingShift == nil else { return }
        entryMode = job.lastEntryMode
        recipients = job.defaultTipOutRule
        if let typical = job.lastTypicalHours {
            let end = calendar.date(byAdding: .minute, value: Int(truncating: (typical * 60) as NSNumber),
                                     to: startTimeOfDay)
            if let end { endTimeOfDay = end }
        }
    }

    private func load() {
        // Default job: the most recently used one, per F002.
        if selectedJob == nil {
            selectedJob = jobs.max { ($0.lastUsedAt ?? .distantPast) < ($1.lastUsedAt ?? .distantPast) }
        }
        entryMode = selectedJob?.lastEntryMode ?? settings.defaultEntryMode
        recipients = selectedJob?.defaultTipOutRule ?? []

        guard let shift = existingShift else { return }
        date = shift.assignedDate
        selectedJob = shift.job
        entryMode = shift.entryMode
        if let start = shift.startTime as Date?, shift.entryMode == .times {
            startTimeOfDay = start
            endTimeOfDay = shift.endTime ?? start
        }
        if let manual = shift.manualHoursValue { hoursText = manual.fixedPointString }
        cashTipsText = shift.cashTips == 0 ? "" : shift.cashTips.fixedPointString
        chargeTipsText = shift.chargeTips == 0 ? "" : shift.chargeTips.fixedPointString
        noncashTipsText = shift.noncashTips == 0 ? "" : shift.noncashTips.fixedPointString
        serviceChargesText = shift.serviceCharges == 0 ? "" : shift.serviceCharges.fixedPointString
        if let sales = shift.sales { showSalesField = true; salesText = sales.fixedPointString }
        recipients = shift.tipOutShares.map { TipOutRecipientRule(id: $0.id, name: $0.name, type: $0.type, value: $0.value) }
        tipOutIsManual = shift.tipOutIsManual
        if let manualAmount = shift.tipOutManualAmount { manualTipOutText = manualAmount.fixedPointString }
        photoFileName = shift.closeoutPhotoFileName
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        let fileName = "\(UUID().uuidString).jpg"
        let url = ClosoutPhotoStorage.url(for: fileName)
        try? data.write(to: url)
        photoFileName = fileName
    }

    private func save() {
        guard let selectedJob else { return }
        let shift: Shift
        if let existingShift {
            shift = existingShift
            shift.job = selectedJob
            shift.entryMode = entryMode
        } else {
            let start: Date
            let end: Date?
            switch entryMode {
            case .times:
                start = combine(date: date, timeOfDay: startTimeOfDay)
                var computedEnd = combine(date: date, timeOfDay: endTimeOfDay)
                if computedEnd <= start { computedEnd = calendar.date(byAdding: .day, value: 1, to: computedEnd)! }
                end = computedEnd
            case .hours:
                start = calendar.startOfDay(for: date)
                end = nil
            }
            shift = Shift(job: selectedJob, entryMode: entryMode, startTime: start, endTime: end,
                          manualHoursValue: entryMode == .hours ? DecimalParsing.parse(hoursText) : nil,
                          calendar: calendar)
            context.insert(shift)
        }

        switch entryMode {
        case .times:
            let start = combine(date: date, timeOfDay: startTimeOfDay)
            var end = combine(date: date, timeOfDay: endTimeOfDay)
            if end <= start { end = calendar.date(byAdding: .day, value: 1, to: end)! }
            shift.startTime = start
            shift.endTime = end
            shift.assignedDate = calendar.startOfDay(for: start)
        case .hours:
            shift.manualHoursValue = DecimalParsing.parse(hoursText)
            shift.startTime = calendar.startOfDay(for: date)
            shift.assignedDate = calendar.startOfDay(for: date)
        }

        shift.cashTips = cashTips
        shift.chargeTips = chargeTips
        shift.noncashTips = noncashTips
        shift.serviceCharges = serviceCharges
        shift.sales = sales
        shift.tipOutIsManual = tipOutIsManual
        shift.tipOutManualAmount = tipOutIsManual ? DecimalParsing.parse(manualTipOutText) : nil
        if !tipOutIsManual {
            shift.tipOutShares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: voluntaryTips, sales: sales ?? 0)
        } else {
            shift.tipOutShares = []
        }
        shift.closeoutPhotoFileName = photoFileName

        selectedJob.lastUsedAt = .now
        selectedJob.lastEntryMode = entryMode
        if entryMode == .times { selectedJob.lastTypicalHours = hours }
        if saveAsJobDefault { selectedJob.defaultTipOutRule = recipients }

        if existingShift == nil {
            settings.recordShiftSaved()
            if settings.savedShiftCount == 1 { settings.hasSavedFirstShift = true }
        }

        onSaved(shift)
        dismiss()
    }
}

enum ClosoutPhotoStorage {
    static func url(for fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "ClosoutPhotos", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: fileName)
    }

    static func delete(fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
