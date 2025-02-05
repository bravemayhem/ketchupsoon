import SwiftUI
import SwiftData
import ContactsUI

// MARK: - CURRENTLY USED FOR NEW FRIENDS
//USED FOR IMPORTING NEW CONTACTS NAMES FROM THE CONTACT LIST OR MANUALLY FOR THE FIRST TIME
struct FriendNameSection: View {
    let isFromContacts: Bool
    let contactName: String?
    @Binding var manualName: String
    
    var body: some View {
        Section("Name") {
            if isFromContacts {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    Text(contactName ?? "")
                        .foregroundColor(AppColors.secondaryLabel)
                }
            } else {
                TextField("Name", text: $manualName)
                    .foregroundColor(AppColors.label)
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// MARK: - City Selection Section
struct FriendCitySection: View {
    @Bindable var cityService: CitySearchService
    
    var body: some View {
        Section("Location") {
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// MARK: - Friend Details Section for Onboarding
struct FriendOnboardingDetailsSection: View {
    let isFromContacts: Bool
    let contact: FriendDetail.NewFriendInput?
    @Binding var manualName: String
    @Binding var phoneNumber: String
    @Binding var email: String
    @Bindable var cityService: CitySearchService
    @State private var showingContactView = false
    
    var body: some View {
        Section("Friend Details") {
            if !isFromContacts {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $manualName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                HStack {
                    Text("Email")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $email)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            } else if let contact = contact {
                if contact.identifier != nil {
                    Button {
                        showingContactView = true
                    } label: {
                        HStack {
                            Text("Name")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Text(contact.name)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    
                    if let phone = contact.phoneNumber {
                        Button {
                            showingContactView = true
                        } label: {
                            HStack {
                                Text("Phone")
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                Text(phone)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    
                    if let email = contact.email {
                        Button {
                            showingContactView = true
                        } label: {
                            HStack {
                                Text("Email")
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                Text(email)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                }
            }
            
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .sheet(isPresented: $showingContactView) {
            if let identifier = contact?.identifier {
                ContactViewController(contactIdentifier: identifier, isPresented: $showingContactView)
            }
        }
    }
}

//USED FOR SETTING UP ADDING SOMEONE TO THE "WISH LIST" FOR THE FIRST TIME
struct FriendConnectSection: View {
    @Binding var wantToConnectSoon: Bool
    
    var body: some View {
        Section("Connect Soon") {
            Toggle("Want to connect soon?", isOn: $wantToConnectSoon)
                .foregroundColor(AppColors.label)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

//USED FOR SETTING UP CATCH UP FREQUENCY FOR THE FIRST TIME
struct FriendCatchUpSection: View {
    @Binding var hasCatchUpFrequency: Bool
    @Binding var selectedFrequency: CatchUpFrequency
    
    var body: some View {
        Section("Catch Up Frequency") {
            Toggle("Set catch up goal?", isOn: $hasCatchUpFrequency)
                .foregroundColor(AppColors.label)
            
            if hasCatchUpFrequency {
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayText)
                            .foregroundColor(AppColors.label)
                            .tag(frequency)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Select Date",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(AppColors.accent)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.systemBackground)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}

//USED FOR SETTING UP LAST SEEN DATE FOR THE FIRST TIME
struct FriendLastSeenSection: View {
    @Binding var hasLastSeen: Bool
    @Binding var lastSeenDate: Date
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        Section("Last Seen") {
            Toggle("Add last seen date?", isOn: $hasLastSeen)
                .foregroundColor(AppColors.label)
                .onChange(of: hasLastSeen) { _, newValue in
                    print("DEBUG: Last seen toggle changed to \(newValue)")
                }
            
            if hasLastSeen {
                Button {
                    print("DEBUG: Last seen date button tapped")
                    showingDatePicker = true
                } label: {
                    HStack {
                        Text("Last Seen Date")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        Text(lastSeenDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .onChange(of: showingDatePicker) { _, newValue in
            print("DEBUG: showingDatePicker changed to \(newValue)")
        }
        .onChange(of: lastSeenDate) { oldValue, newValue in
            print("DEBUG: lastSeenDate changed from \(oldValue) to \(newValue)")
        }
        .onAppear {
            print("DEBUG: FriendLastSeenSection appeared")
        }
        .onDisappear {
            print("DEBUG: FriendLastSeenSection disappeared")
        }
    }
}

// MARK: - CURRENTLY USED FOR EXISTING FRIENDS

struct FriendInfoSection: View {
    let friend: Friend
    @Bindable var cityService: CitySearchService
    @State private var showingContactView = false
    @State private var editableName: String
    @State private var editablePhone: String
    @State private var editableEmail: String
    @State private var showingAddEmailAlert = false
    @State private var newEmailInput = ""
    @State private var isUpdatingContact = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var activeSheet: ActiveSheet?
    
    private enum ActiveSheet: Identifiable {
        case contact
        case addEmail
        
        var id: Int {
            switch self {
            case .contact: return 1
            case .addEmail: return 2
            }
        }
    }
    
    init(friend: Friend, cityService: CitySearchService) {
        self.friend = friend
        self._cityService = Bindable(wrappedValue: cityService)
        self._editableName = State(initialValue: friend.name)
        self._editablePhone = State(initialValue: friend.phoneNumber ?? "")
        self._editableEmail = State(initialValue: friend.email ?? "")
    }
    
    var body: some View {
        Section("Friend Details") {
            // Name
            if friend.contactIdentifier != nil {
                Button {
                    activeSheet = .contact
                } label: {
                    HStack {
                        Text("Name")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        Text(friend.name)
                            .foregroundColor(AppColors.accent)
                    }
                }
            } else {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $editableName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                        .onChange(of: editableName) { _, newValue in
                            friend.name = newValue
                        }
                }
            }
            
            // Phone
            if friend.contactIdentifier != nil {
                Button {
                    activeSheet = .contact
                } label: {
                    HStack {
                        Text("Phone")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        if let phone = friend.phoneNumber {
                            Text(phone)
                                .foregroundColor(AppColors.accent)
                        } else {
                            Text("Not set")
                                .foregroundColor(AppColors.tertiaryLabel)
                        }
                    }
                }
            } else {
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $editablePhone)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                        .onChange(of: editablePhone) { _, newValue in
                            friend.phoneNumber = newValue.isEmpty ? nil : newValue
                        }
                }
            }
            
            // Email
            if friend.contactIdentifier != nil {
                emailMenuView
            } else {
                manualEmailView
            }
            
            // City
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .contact:
                if let identifier = friend.contactIdentifier {
                    ContactViewController(contactIdentifier: identifier, isPresented: .constant(true))
                        .onDisappear {
                            activeSheet = nil
                        }
                }
            case .addEmail:
                NavigationStack {
                    Form {
                        Section {
                            TextField("Email Address", text: $newEmailInput)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        } footer: {
                            if friend.contactIdentifier != nil {
                                Text("This email will be saved to the contact")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.systemBackground)
                    .navigationTitle("Add New Email")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newEmailInput = ""
                                activeSheet = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addNewEmail(newEmailInput)
                                activeSheet = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var emailMenuView: some View {
        Menu {
            // Primary email
            if let primaryEmail = friend.email {
                Button {
                    // No action needed, it's already primary
                } label: {
                    HStack {
                        Text(primaryEmail)
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            // Additional emails
            ForEach(friend.additionalEmails, id: \.self) { email in
                Button {
                    Task {
                        await setPrimaryEmail(email)
                    }
                } label: {
                    Text(email)
                }
            }
            
            Divider()
            
            // Add new email option
            Button {
                activeSheet = .addEmail
            } label: {
                Label("Add New Email", systemImage: "plus")
            }
        } label: {
            HStack {
                Text("Email")
                    .foregroundColor(AppColors.label)
                Spacer()
                if let primaryEmail = friend.email {
                    HStack(spacing: 4) {
                        Text(primaryEmail)
                            .foregroundColor(AppColors.accent)
                        if isUpdatingContact {
                            ProgressView()
                                .scaleEffect(0.5)
                                .tint(AppColors.accent)
                        }
                    }
                } else {
                    Text("Not set")
                        .foregroundColor(AppColors.tertiaryLabel)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.caption)
            }
        }
        .task {
            // Sync contact info when menu is opened
            if friend.contactIdentifier != nil {
                await MainActor.run { isUpdatingContact = true }
                let success = await ContactsManager.shared.syncContactInfo(for: friend)
                if !success {
                    await MainActor.run {
                        errorMessage = "Failed to sync contact information"
                        showingError = true
                    }
                }
                await MainActor.run { isUpdatingContact = false }
            }
        }
        .disabled(isUpdatingContact)
    }
    
    private var manualEmailView: some View {
        Menu {
            // Primary email
            if let primaryEmail = friend.email {
                Button {
                    // No action needed, it's already primary
                } label: {
                    HStack {
                        Text(primaryEmail)
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            // Additional emails
            ForEach(friend.additionalEmails, id: \.self) { email in
                Button {
                    setPrimaryEmailLocally(email)
                } label: {
                    Text(email)
                }
            }
            
            Divider()
            
            // Add new email option
            Button {
                activeSheet = .addEmail
            } label: {
                Label("Add New Email", systemImage: "plus")
            }
        } label: {
            HStack {
                Text("Email")
                    .foregroundColor(AppColors.label)
                Spacer()
                if let primaryEmail = friend.email {
                    Text(primaryEmail)
                        .foregroundColor(AppColors.secondaryLabel)
                } else {
                    Text("Not set")
                        .foregroundColor(AppColors.tertiaryLabel)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.caption)
            }
        }
    }
    
    private func addNewEmail(_ email: String) {
        guard !email.isEmpty else { return }
        
        // Add to additional emails if we already have a primary
        if friend.email != nil {
            var currentAdditional = friend.additionalEmails
            currentAdditional.append(email)
            friend.additionalEmails = currentAdditional
        } else {
            // Set as primary if we don't have one
            friend.email = email
        }
        
        // If this is a contact-imported friend, sync with Contacts
        if let identifier = friend.contactIdentifier {
            Task {
                await updateContactWithEmails(identifier: identifier)
            }
        }
        
        newEmailInput = ""
    }
    
    private func setPrimaryEmail(_ email: String) async {
        guard let identifier = friend.contactIdentifier else { return }
        
        // Update local state
        if let currentPrimary = friend.email {
            var additional = friend.additionalEmails
            additional.append(currentPrimary)
            additional.removeAll { $0 == email }
            friend.additionalEmails = additional
        }
        friend.email = email
        
        // Update contact
        await updateContactWithEmails(identifier: identifier)
    }
    
    private func setPrimaryEmailLocally(_ email: String) {
        if let currentPrimary = friend.email {
            var additional = friend.additionalEmails
            additional.append(currentPrimary)
            additional.removeAll { $0 == email }
            friend.additionalEmails = additional
        }
        friend.email = email
    }
    
    private func updateContactWithEmails(identifier: String) async {
        await MainActor.run {
            isUpdatingContact = true
        }
        
        do {
            try await ContactsManager.shared.updateContactEmails(
                identifier: identifier,
                primaryEmail: friend.email,
                additionalEmails: friend.additionalEmails
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        
        await MainActor.run {
            isUpdatingContact = false
        }
    }
}

struct FriendKetchupSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    let onFrequencyTap: () -> Void
    
    var body: some View {
        Section("Ketchup Details") {
            // Last Seen
            Button {
                onLastSeenTap()
            } label: {
                HStack {
                    Text("Last Seen")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if friend.lastSeen == nil {
                        Text("Not set")
                            .foregroundColor(AppColors.tertiaryLabel)
                            .multilineTextAlignment(.trailing)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                            Text(friend.lastSeenText)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                }
            }
            .buttonStyle(.borderless)
            
            // Catch Up Frequency
            Button(action: onFrequencyTap) {
                HStack {
                    Text("Catch Up Frequency")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if let frequency = friend.catchUpFrequency {
                        Text(frequency.displayText)
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text("Not set")
                            .foregroundColor(AppColors.tertiaryLabel)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .buttonStyle(.borderless)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

struct FriendActionSection: View {
    @Bindable var friend: Friend
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    
    var body: some View {
        Section("Actions") {
            Button(action: onMessageTap) {
                Label("Send Message", systemImage: "message.fill")
                    .actionLabelStyle()
            }
            
            Button(action: onScheduleTap) {
                Label("Schedule Hangout", systemImage: "calendar")
                    .actionLabelStyle()
            }
            
            Button(action: onMarkSeenTap) {
                Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                    .actionLabelStyle()
            }
            
            Button {
                friend.needsToConnectFlag.toggle()
            } label: {
                HStack {
                    Label(friend.needsToConnectFlag ? "Remove from Wishlist" : "Add to Wishlist",
                          systemImage: friend.needsToConnectFlag ? "star.slash" : "star")
                        .actionLabelStyle()
                    Spacer()
                    Toggle("", isOn: $friend.needsToConnectFlag)
                        .labelsHidden()
                        .tint(AppColors.accent)
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}


struct FriendHangoutsSection: View {
    let hangouts: [Hangout]
    
    var body: some View {
        if !hangouts.isEmpty {
            Section("Upcoming Hangouts") {
                ForEach(hangouts) { hangout in
                    VStack(alignment: .leading, spacing: AppTheme.spacingTiny) {
                        Text(hangout.activity)
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                        Text(hangout.location)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(hangout.formattedDate)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppTheme.spacingTiny)
                }
            }
            .listRowBackground(AppColors.secondarySystemBackground)
        }
    }
}

// MARK: - USED FOR BOTH EXISTING AND NEW FRIENDS
struct FriendTagsSection: View {
    private var displayTags: [Tag]  // Store the tags directly
    let onManageTags: () -> Void
    
    // Init for existing friends
    init(friend: Friend, onManageTags: @escaping () -> Void) {
        self.displayTags = friend.tags
        self.onManageTags = onManageTags
    }
    
    // Init for new friends (onboarding)
    init(tags: Set<Tag>, onManageTags: @escaping () -> Void) {
        self.displayTags = Array(tags)
        self.onManageTags = onManageTags
    }
    
    private var tagsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayTags) { tag in
                    TagView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var manageTags: some View {
        Button(action: onManageTags) {
            Label("Manage Tags", systemImage: "tag")
                .actionLabelStyle()
        }
    }
    
    var body: some View {
        Section("Tags") {
            if displayTags.isEmpty {
                Text("No tags added")
                    .foregroundColor(AppColors.secondaryLabel)
            } else {
                tagsContent
            }
            manageTags
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// Helper view for individual tags
struct TagView: View {
    let tag: Tag
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag.name)")
                .font(AppTheme.captionFont)
                .foregroundColor(AppColors.label)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.systemBackground)  // Changed to systemBackground (F2F2F7)
        .clipShape(Capsule())
    }
}

// Add ContactViewController
struct ContactViewController: UIViewControllerRepresentable {
    let contactIdentifier: String
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    func makeCoordinator() -> Coordinator {
        print("DEBUG: Creating coordinator")
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        print("DEBUG: makeUIViewController called")
        let navController = UINavigationController()
        navController.modalPresentationStyle = .pageSheet
        navController.isModalInPresentation = true
        
        if let sheet = navController.sheetPresentationController {
            print("DEBUG: Configuring initial sheet presentation")
            sheet.prefersGrabberVisible = true
            sheet.detents = [.large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = 12
        }
        
        // Add a loading view controller initially
        let loadingVC = UIHostingController(rootView: 
            ProgressView("Loading Contact...")
                .progressViewStyle(.circular)
        )
        navController.setViewControllers([loadingVC], animated: false)
        
        // Load contact after ensuring view is ready
        Task { @MainActor in
            // Small delay to ensure view hierarchy is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if context.coordinator.isLoadingContact == false {
                loadContact(into: navController, context: context)
            }
        }
        
        return navController
    }
    
    private func loadContact(into navController: UINavigationController, context: Context) {
        // Prevent multiple simultaneous loads
        guard !context.coordinator.isLoadingContact else {
            print("DEBUG: Already loading contact, skipping")
            return
        }
        
        context.coordinator.isLoadingContact = true
        
        Task {
            do {
                print("DEBUG: Requesting contacts access")
                let granted = await ContactsManager.shared.requestAccess()
                guard granted else {
                    print("DEBUG: Contacts access denied")
                    await MainActor.run {
                        context.coordinator.isLoadingContact = false
                        context.coordinator.showAlert(
                            title: "Contacts Access Required",
                            message: "Please enable contacts access in Settings to view contact details."
                        ) {
                            self.isPresented = false
                        }
                    }
                    return
                }
                
                print("DEBUG: Fetching contact for identifier: \(contactIdentifier)")
                let contact = try await ContactsManager.shared.getContactViewController(for: contactIdentifier)
                
                await MainActor.run {
                    guard isPresented else {
                        context.coordinator.isLoadingContact = false
                        return
                    }
                    
                    print("DEBUG: Setting up CNContactViewController")
                    let contactVC = CNContactViewController(for: contact)
                    contactVC.allowsEditing = true
                    contactVC.allowsActions = true
                    // Use context.coordinator directly instead of storing it
                    contactVC.delegate = context.coordinator
                    
                    context.coordinator.contactIdentifier = contactIdentifier
                    
                    // Only set view controllers if we're still meant to be presented
                    if isPresented {
                        print("DEBUG: Setting view controllers")
                        // Use animated: false to prevent potential race conditions
                        navController.setViewControllers([contactVC], animated: false)
                    }
                    
                    context.coordinator.isLoadingContact = false
                }
            } catch {
                print("DEBUG: Error loading contact: \(error.localizedDescription)")
                await MainActor.run {
                    context.coordinator.isLoadingContact = false
                    context.coordinator.showAlert(
                        title: "Error Loading Contact",
                        message: error.localizedDescription
                    ) {
                        self.isPresented = false
                    }
                }
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        print("DEBUG: updateUIViewController called, isPresented: \(isPresented)")
        
        // Only handle dismissal when explicitly set to false and there's a presented view controller
        if !isPresented && uiViewController.presentedViewController != nil {
            print("DEBUG: Dismissing view controller due to isPresented = false")
            context.coordinator.cleanupPresentation()
            
            // Ensure we're on the main thread for dismissal
            Task { @MainActor in
                uiViewController.dismiss(animated: true)
            }
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        print("DEBUG: Dismantling view controller")
        coordinator.cleanupPresentation()
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactViewController
        var contactIdentifier: String?
        var isLoadingContact = false
        
        init(parent: ContactViewController) {
            print("DEBUG: Initializing coordinator")
            self.parent = parent
            super.init()
        }
        
        func cleanupPresentation() {
            print("DEBUG: Cleaning up presentation, clearing contactIdentifier")
            contactIdentifier = nil
            isLoadingContact = false
        }
        
        func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
            Task { @MainActor in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let viewController = windowScene.windows.first?.rootViewController {
                    let alert = UIAlertController(
                        title: title,
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        completion?()
                    })
                    viewController.present(alert, animated: true)
                } else {
                    completion?()
                }
            }
        }
        
        // MARK: - CNContactViewControllerDelegate
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            print("DEBUG: Contact view controller did complete, contact: \(contact != nil)")
            Task { @MainActor in
                if let identifier = contactIdentifier,
                   let friend = try? parent.modelContext.fetch(FetchDescriptor<Friend>(
                    predicate: #Predicate<Friend> { friend in
                        friend.contactIdentifier == identifier
                    }
                   )).first {
                    if await ContactsManager.shared.handleContactChange(for: friend) {
                        print("DEBUG: Successfully synced contact info for \(friend.name)")
                    } else {
                        print("DEBUG: Failed to sync contact info for \(friend.name)")
                        showAlert(
                            title: "Sync Error",
                            message: "Failed to sync contact information. Please try again."
                        )
                    }
                }
                
                print("DEBUG: Setting isPresented to false and cleaning up")
                parent.isPresented = false
                cleanupPresentation()
            }
        }
        
        func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
            print("DEBUG: Should perform default action for property: \(property.key)")
            return true
        }
        
        func contactViewController(_ viewController: CNContactViewController, shouldShowLinkedContacts contact: CNContact) -> Bool {
            print("DEBUG: Should show linked contacts")
            return true
        }
    }
}

// MARK: - PREVIEW SECTION

#Preview("FriendActionSectionExisting") {
    NavigationStack {
        List {
            FriendActionSection(
                friend: Friend(
                    name: "John Doe",
                    lastSeen: Date(),
                    location: "New York",
                    needsToConnectFlag: true,
                    phoneNumber: "(212) 555-0123",
                    catchUpFrequency: .weekly
                ),
                onMessageTap: {},
                onScheduleTap: {},
                onMarkSeenTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}


#Preview("FriendInfoSection") {
    NavigationStack {
        List {
            FriendInfoSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                cityService: {
                    let service = CitySearchService()
                    service.selectedCity = "San Francisco"
                    return service
                }()
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

#Preview("FriendKetchupSection") {
    NavigationStack {
        List {
            FriendKetchupSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                onLastSeenTap: {},
                onFrequencyTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

#Preview("FriendActionSection") {
    NavigationStack {
        List {
            FriendActionSection(
                friend: Friend(
                    name: "John Doe",
                    lastSeen: Date(),
                    location: "New York",
                    needsToConnectFlag: true,
                    phoneNumber: "(212) 555-0123",
                    catchUpFrequency: .weekly
                ),
                onMessageTap: {},
                onScheduleTap: {},
                onMarkSeenTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

#Preview("FriendHangoutsSection - With Hangouts") {
    let container: ModelContainer = {
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let friend = Friend(
            name: "Alice Smith",
            lastSeen: Date(),
            location: "Local",
            phoneNumber: "(555) 123-4567"
        )
        context.insert(friend)
        
        let hangouts = [
            Hangout(
                date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                activity: "Coffee",
                location: "Starbucks",
                isScheduled: true,
                friends: [friend]
            ),
            Hangout(
                date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                activity: "Lunch",
                location: "Italian Restaurant",
                isScheduled: true,
                friends: [friend]
            )
        ]
        hangouts.forEach { context.insert($0) }
        
        return container
    }()
    
    let hangouts = try! container.mainContext.fetch(FetchDescriptor<Hangout>())
    
    return NavigationStack {
        List {
            FriendHangoutsSection(hangouts: hangouts)
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
}

#Preview("FriendTagsSection") {
    let schema = Schema([Friend.self, Tag.self, Hangout.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    let friend = Friend(
        name: "Bob Wilson",
        lastSeen: Date(),
        location: "Remote"
    )
    
    let tags = [
        Tag(name: "college"),
        Tag(name: "book club"),
        Tag(name: "hiking")
    ]
    tags.forEach { context.insert($0) }
    friend.tags = tags
    context.insert(friend)
    
    return NavigationStack {
        List {
            FriendTagsSection(
                friend: friend,
                onManageTags: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
}

#Preview("TagView") {
    HStack {
        TagView(tag: Tag(name: "college"))
        TagView(tag: Tag(name: "book club"))
        TagView(tag: Tag(name: "hiking"))
    }
    .padding()
    .background(AppColors.secondarySystemBackground)
    .modelContainer(for: [Tag.self])
}

#Preview("FriendOnboardingDetailsSection") {
    NavigationStack {
        List {
            // Contact Import Scenario
            FriendOnboardingDetailsSection(
                isFromContacts: true,
                contact: FriendDetail.NewFriendInput(
                    name: "John Smith",
                    identifier: "123",
                    phoneNumber: "(555) 123-4567",
                    email: "john.smith@email.com",
                    imageData: nil,
                    city: "San Francisco"
                ),
                manualName: .constant(""),
                phoneNumber: .constant(""),
                email: .constant(""),
                cityService: CitySearchService()
            )
            
            // Manual Entry Scenario
            FriendOnboardingDetailsSection(
                isFromContacts: false,
                contact: nil,
                manualName: .constant("Jane Doe"),
                phoneNumber: .constant("(555) 987-6543"),
                email: .constant(""),
                cityService: {
                    let service = CitySearchService()
                    service.selectedCity = "New York"
                    return service
                }()
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

