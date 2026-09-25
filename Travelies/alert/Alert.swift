//
//  Alert.swift
//  mockup
//
//  Created by Studente on 03/08/24.
//

import Foundation
import SwiftUI

struct AlertButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let color = configuration.isPressed
            ? Color("ThemeGray").opacity(0.5)
            : Color("ThemeLightGray")
        
        configuration.label
            .background(color)
    }
}

struct CustomConfirmationAlert: View {
    @Binding var isPresented: Bool
    @State var isShowed: Bool = false
    var onOK: () -> Void
    var onCancel: () -> Void
    var title: String
    var message: String?

    var body: some View {
        if isPresented {
            ZStack {
                if isShowed {
                    ZStack {
                        VStack {
                            VStack(spacing: 16) {
                                Text(title)
                                    .font(.custom("DIN Alternate", size: 16))
                                    .foregroundColor(Color(UIColor.label))
                                    .padding()
                                if let message = message {
                                    Text(message)
                                        .multilineTextAlignment(.center)
                                        .font(.custom("DIN Alternate", size: 16))
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }
                            .padding(16)
                            VStack(spacing: 0) {
                                Button(
                                    action: {
                                        withAnimation(.easeInOut) {
                                            isShowed = false
                                            isPresented = false
                                        }
                                        
                                        onOK()
                                    },
                                    label: {
                                        Text("Ok")
                                            .foregroundColor(Color("CameraYellow"))
                                            .font(.custom("DIN Alternate", size: 18))
                                            .frame(maxWidth: 280)
                                            .padding(16)
                                            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(.gray.opacity(0.08)), alignment: .top)
                                    }
                                )
                                .buttonStyle(AlertButton())
                                Button(
                                    action: {
                                        withAnimation(.easeInOut) {
                                            isShowed = false
                                            isPresented = false
                                        }
                                        
                                        onCancel()
                                    },
                                    label: {
                                        Text("Annulla")
                                            .foregroundColor(Color(UIColor.label))
                                            .font(.custom("DIN Alternate", size: 18))
                                            .frame(maxWidth: 280)
                                            .padding(16)
                                            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(.gray.opacity(0.08)), alignment: .top)
                                    }
                                )
                                .buttonStyle(AlertButton())
                            }
                        }
                        .background(Color("ThemeLightGray"))
                        .cornerRadius(24)
                        .frame(width: 280)
                    }
                    .edgesIgnoringSafeArea(.all)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(.black.opacity(0.4))
                }
            }
            .onAppear() {
                withAnimation(.easeInOut) {
                    isShowed = true
                }
            }
        }
    }
}

struct CustomInfoAlert: View {
    @Binding var isPresented: Bool
    var onOK: () -> Void
    var title: String
    var message: String?

    var body: some View {
        if isPresented {
            ZStack {
                VStack {
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.custom("DIN Alternate", size: 16))
                            .foregroundColor(Color(UIColor.label))
                            .padding()
                        if let message = message {
                            Text(message)
                                .multilineTextAlignment(.center)
                                .font(.custom("DIN Alternate", size: 16))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    .padding(16)
                    Button(
                        action: {
                            withAnimation {
                                isPresented = false
                            }
                            
                            onOK()
                        },
                        label: {
                            Text("Ok")
                                .foregroundColor(Color("CameraYellow"))
                                .font(.custom("DIN Alternate", size: 18))
                                .frame(maxWidth: 280)
                                .padding(16)
                                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(.gray.opacity(0.08)), alignment: .top)
                        }
                    )
                    .buttonStyle(AlertButton())
                }
                .background(Color("ThemeLightGray"))
                .cornerRadius(24)
                .frame(width: 280)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(.black.opacity(0.4))
        }
    }
}

struct CustomInputAlert: View {
    @Binding var isPresented: Bool
    @Binding var input: String
    var title: String
    var onCancel: () -> Void
    var onOK: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                VStack {
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.custom("DIN Alternate", size: 16))
                            .foregroundColor(Color(UIColor.label))
                            .padding()
                        TextField("", text: $input, axis: .vertical)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .font(.custom("DIN Alternate", size: 18))
                            .lineLimit(1...3)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color("ThemeGray").opacity(0.5))
                            .cornerRadius(12)
                            .frame(maxWidth: 220)
                    }
                    .padding(16)
                    VStack(spacing: 0) {
                        Button(
                            action: {
                                withAnimation {
                                    isPresented = false
                                }
                                
                                onOK()
                            },
                            label: {
                                Text("Ok")
                                    .foregroundColor(Color("CameraYellow"))
                                    .font(.custom("DIN Alternate", size: 18))
                                    .frame(maxWidth: 280)
                                    .padding(16)
                                    .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(.gray.opacity(0.08)), alignment: .top)
                            }
                        )
                        .buttonStyle(AlertButton())
                        Button(
                            action: {
                                withAnimation {
                                    isPresented = false
                                }
                                
                                onCancel()
                            },
                            label: {
                                Text("Annulla")
                                    .foregroundColor(Color(UIColor.label))
                                    .font(.custom("DIN Alternate", size: 18))
                                    .frame(maxWidth: 280)
                                    .padding(16)
                                    .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(.gray.opacity(0.08)), alignment: .top)
                            }
                        )
                        .buttonStyle(AlertButton())
                    }
                }
                .background(Color("ThemeLightGray"))
                .cornerRadius(24)
                .frame(width: 280)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }
}

extension View {
    func customInputAlert(
        isPresented: Binding<Bool>,
        input: Binding<String>,
        title: Binding<String>,
        onCancel: @escaping () -> Void = {},
        onOK: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(CustomInputAlertModifier(isPresented: isPresented, input: input, title: title, onCancel: onCancel, onOK: onOK))
    }
    
    func customConfirmationAlert(
        isPresented: Binding<Bool>,
        title: Binding<String>,
        message: Binding<String?>,
        onCancel: @escaping () -> Void = {},
        onOK: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(CustomConfirmationAlertModifier(isPresented: isPresented, title: title, message: message, onCancel: onCancel, onOK: onOK))
    }
    
    func customInfoAlert(
        isPresented: Binding<Bool>,
        title: Binding<String>,
        message: Binding<String?>,
        onOK: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(CustomInfoAlertModifier(isPresented: isPresented, title: title, message: message, onOK: onOK))
    }
    
}

struct CustomInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var input: String
    @Binding var title: String
    var onCancel: () -> Void
    var onOK: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            CustomInputAlert(isPresented: $isPresented, input: $input, title: title, onCancel: onCancel, onOK: onOK)
                .zIndex(1)
        }
    }
}

struct CustomConfirmationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var message: String?
    var onCancel: () -> Void
    var onOK: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            CustomConfirmationAlert(isPresented: $isPresented, onOK: onOK, onCancel: onCancel, title: title, message: message)
                .zIndex(1)
        }
    }
}

struct CustomInfoAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var message: String?
    var onOK: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            CustomInfoAlert(isPresented: $isPresented, onOK: onOK, title: title, message: message)
                .zIndex(1)
        }
    }
}
