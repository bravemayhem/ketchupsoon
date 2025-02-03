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
                    showingContactView = true
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
                    showingContactView = true
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
        .sheet(isPresented: $showingContactView) {
            if let identifier = friend.contactIdentifier {
                ContactViewController(contactIdentifier: identifier, isPresented: $showingContactView)
            }
        }
        .sheet(isPresented: $showingAddEmailAlert) {
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
                            showingAddEmailAlert = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addNewEmail(newEmailInput)
                            showingAddEmailAlert = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .overlay {
            if isUpdatingContact {
                ProgressView()
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
            }
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
                showingAddEmailAlert = true
            } label: {
                Label("Add New Email", systemImage: "plus")
            }
        } label: {
            HStack {
                Text("Email")
                    .foregroundColor(AppColors.label)
                Spacer()
                if isUpdatingContact {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let primaryEmail = friend.email {
                    Text(primaryEmail)
                        .foregroundColor(AppColors.accent)
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
                showingAddEmailAlert = true
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
    
    func makeUIViewController(context: Context) -> UIViewController {
        let contactVC = UIViewController()
        return contactVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented else {
            // If not presented, make sure any presented view controller is dismissed
            uiViewController.presentedViewController?.dismiss(animated: true)
            return
        }
        
        // Don't try to present if we already have a presented view controller
        guard uiViewController.presentedViewController == nil else { return }
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
                return
            }
            
            do {
                let predicate = CNContact.predicateForContacts(withIdentifiers: [contactIdentifier])
                let baseKeys = [
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactPhoneNumbersKey,
                    CNContactImageDataKey,
                    CNContactThumbnailImageDataKey,
                    CNContactPostalAddressesKey,
                    CNContactIdentifierKey
                ] as [CNKeyDescriptor]
                
                let keys = baseKeys + [CNContactViewController.descriptorForRequiredKeys()]
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                
                guard let contact = contacts.first else {
                    DispatchQueue.main.async {
                        self.isPresented = false
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    // Create and configure the contact view controller
                    let contactVC = CNContactViewController(for: contact)
                    contactVC.allowsEditing = true
                    contactVC.allowsActions = true
                    contactVC.delegate = context.coordinator
                    
                    // Create and configure the navigation controller
                    let navController = UINavigationController(rootViewController: contactVC)
                    navController.modalPresentationStyle = .pageSheet
                    
                    if let sheet = navController.sheetPresentationController {
                        sheet.prefersGrabberVisible = true
                        sheet.detents = [.large()]
                        sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                        sheet.preferredCornerRadius = 12
                    }
                    
                    // Store the navigation controller in the coordinator
                    context.coordinator.currentNavController = navController
                    
                    // Present only if the view is in the window hierarchy
                    if uiViewController.view.window != nil {
                        uiViewController.present(navController, animated: true)
                    } else {
                        self.isPresented = false
                    }
                }
            } catch {
                print("Error fetching contact: \(error)")
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactViewController
        var currentNavController: UINavigationController?
        
        init(parent: ContactViewController) {
            self.parent = parent
            super.init()
        }
        
        @objc func dismissContactVC() {
            Task { @MainActor in
                // Dismiss the current navigation controller if it exists
                if let navController = currentNavController {
                    navController.dismiss(animated: true)
                }
                
                // Get the friend and sync contact info
                let identifier = parent.contactIdentifier
                let descriptor = FetchDescriptor<Friend>(
                    predicate: #Predicate<Friend> { friend in
                        friend.contactIdentifier == identifier
                    }
                )
                
                if let friend = try? parent.modelContext.fetch(descriptor).first {
                    if await ContactsManager.shared.syncContactInfo(for: friend) {
                        print("Successfully synced contact info for \(friend.name)")
                    } else {
                        print("Failed to sync contact info for \(friend.name)")
                    }
                }
                
                // Update the presentation state
                parent.isPresented = false
            }
        }
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            dismissContactVC()
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

