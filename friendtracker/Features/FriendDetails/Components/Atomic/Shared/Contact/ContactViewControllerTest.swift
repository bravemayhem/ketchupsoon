//
//  ContactViewControllerTest.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/6/25.
//
import SwiftUI
import Foundation
import ContactsUI


struct ContactView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CNContactViewController

    let contact: CNContact
    let position: String  // To track where the view is being shown from
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CNContactViewController {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = true
        contactVC.allowsActions = true
        contactVC.contactStore = ContactsManager.shared.contactStore
        contactVC.delegate = context.coordinator
        return contactVC
    }

    func updateUIViewController(_ uiViewController: CNContactViewController, context: Context) {
        // Update as needed.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactView
        
        init(parent: ContactView) {
            self.parent = parent
        }
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.isPresented = false
        }
    }
}
