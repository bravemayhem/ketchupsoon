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
    typealias UIViewControllerType = UINavigationController

    let contact: CNContact
    let position: String  // To track where the view is being shown from
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = true
        contactVC.allowsActions = true
        contactVC.contactStore = ContactsManager.shared.contactStore
        contactVC.delegate = context.coordinator
        
        let navController = UINavigationController(rootViewController: contactVC)
        navController.modalPresentationStyle = .formSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.detents = [.large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = 12
        }
        
        // Add a done button
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismiss)
        )
        
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
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
        
        @objc func dismiss() {
            parent.isPresented = false
        }
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.isPresented = false
        }
        
        func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
            return true
        }
    }
}
