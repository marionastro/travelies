//
//  AlertDataHandler.swift
//  mockup
//
//  Created by Studente on 01/09/24.
//

import Foundation

class AlertDataHandler : ObservableObject {
    static let shared = AlertDataHandler()
    
    // Presentation
    @Published var infoAlertPresented: Bool = false
    @Published var inputAlertPresented: Bool = false
    @Published var confirmationAlertPresented: Bool = false
    
    // Common
    @Published var alertTitle: String = ""
    @Published var alertMessage: String? = nil
    
    //Callbacks
    @Published var alertOkCallback: () -> Void = {}
    @Published var alertCancelCallback: () -> Void = {}
    
    //Input
    @Published var alertInput: String = ""
    
    public func showInfoAlert(title: String, message: String?, onOk: @escaping () -> Void) {
        alertTitle = title
        alertMessage = message
        alertOkCallback = onOk
        inputAlertPresented = false
        confirmationAlertPresented = false
        infoAlertPresented = true
    }
    
    public func showInputAlert(title: String, input: String = "") {
        alertTitle = title
        alertInput = input
        confirmationAlertPresented = false
        infoAlertPresented = false
        inputAlertPresented = true
    }
    
    public func showConfirmationAlert(title: String, message: String?, onOk: @escaping () -> Void, onCancel: @escaping () -> Void) {
        alertTitle = title
        alertMessage = message
        alertOkCallback = onOk
        alertCancelCallback = onCancel
        inputAlertPresented = false
        infoAlertPresented = false
        confirmationAlertPresented = true
    }
    
    public func hideAlert() {
        inputAlertPresented = false
        infoAlertPresented = false
        confirmationAlertPresented = false
    }
}
