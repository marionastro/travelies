//
//  TestComponent.swift
//  mockup
//
//  Created by Studente on 25/06/24.
//

import SwiftUI

enum TabbedItems : Int, CaseIterable {
    case MAP     = 0
    case PROFILE = 1

    var iconName: String {
        switch self {
            case .MAP:
                return "map"
            case .PROFILE:
                return "person.2"
        }
    }
}

struct Navigator: View {
    @State var currentTab = TabbedItems.MAP.rawValue
    @State private var isCameraShown = false
    @EnvironmentObject var forceRefresh: ForceRefresh

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentTab) {
                //each tab has its own navigation stack
                NavigationStack{
                    ContentView(user: UserDataModel.shared.getCurrentUser())
                        .environmentObject(forceRefresh)
                }
                .padding([.bottom], 50)
                .tag(0)
                
                NavigationStack{
                    UserProfile()
                        .environmentObject(forceRefresh)
                }
                .padding([.bottom], 50)
                .tag(1)
            }
            HStack {
                ZStack {
                    Button(action: { isCameraShown = true }) {
                        ZStack {
                            Circle()
                                .frame(width: 75, height: 75)
                                .foregroundColor(Color(UIColor.label))
                            Circle()
                                .frame(width: 65, height: 65)
                                .foregroundColor(Color(UIColor.systemBackground))
                            Circle()
                                .frame(width: 55, height: 55)
                                .foregroundColor(Color("CameraYellow"))
                            Image("camera.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                    }
                    .buttonStyle(CameraButton())
                    .sheet(isPresented: $isCameraShown) {
                            Camera()
                                .presentationDragIndicator(.visible)
                                .onAppear(){
                                    forceRefresh.refresh = false
                                }
                                .onDisappear(){
                                    forceRefresh.refresh = true
                                }
                    }
                    HStack {
                        Button(action: { currentTab = TabbedItems.MAP.rawValue }) {
                            TabItem(icon: TabbedItems.MAP.iconName, isActive: currentTab == TabbedItems.MAP.rawValue)
                        }
                        .buttonStyle(NoAnimationButton())
                        Spacer()
                        Button(action: { currentTab = TabbedItems.PROFILE.rawValue }) {
                            TabItem(icon: TabbedItems.PROFILE.iconName, isActive: currentTab == TabbedItems.PROFILE.rawValue)
                        }
                        .buttonStyle(NoAnimationButton())
                    }
                    .padding([.leading, .trailing], 64)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 32)
            .background(Color(UIColor.systemBackground))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

extension Navigator {
    func TabItem(icon: String, isActive: Bool) -> some View {
        Image(systemName: isActive ? "\(icon).fill" : icon)
            .foregroundColor(Color(UIColor.label))
            .font(.system(size: 24, weight: .semibold))
    }
}

struct NoAnimationButton: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
    }
}

struct CameraButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        let scaleValue = configuration.isPressed ? 0.9 : 1
        
        configuration.label
            .scaleEffect(scaleValue)
            .animation(.linear(duration: 0.1), value: scaleValue)
    }
}

// Gesture per tornare indietro
extension UINavigationController: UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
}
