import SwiftUI

@main
struct TraveliesApp: App {
    static let shared = TraveliesApp()
    
    @StateObject var auth = AuthenticationService()
    @State private var isActive = false
    @State private var deepLinkQuery: String?
    @StateObject private var forceRefresh = ForceRefresh()
    
    @StateObject var alertDataHandler = AlertDataHandler.shared

    var body: some Scene {
        WindowGroup {
            if isActive {
                ApplicationSwitcher(deepLinkQuery: $deepLinkQuery).environmentObject(forceRefresh)
                    .environmentObject(auth)
                    .onOpenURL { url in
                        handleDeepLink(url: url)
                    }
                    .customInfoAlert(
                        isPresented: $alertDataHandler.infoAlertPresented,
                        title: $alertDataHandler.alertTitle,
                        message: $alertDataHandler.alertMessage,
                        onOK: alertDataHandler.alertOkCallback
                    )
                    .customInputAlert(
                        isPresented: $alertDataHandler.inputAlertPresented,
                        input: $alertDataHandler.alertInput,
                        title: $alertDataHandler.alertTitle
                    )
                    .customConfirmationAlert(
                        isPresented: $alertDataHandler.confirmationAlertPresented,
                        title: $alertDataHandler.alertTitle,
                        message: $alertDataHandler.alertMessage,
                        onCancel: alertDataHandler.alertCancelCallback,
                        onOK: alertDataHandler.alertOkCallback
                    )
            } else {
                SplashScreen(isActive: $isActive)
                    .environmentObject(auth)
                    .onOpenURL { url in
                        handleDeepLink(url: url)
                    }
            }
        }
    }

    private func handleDeepLink(url: URL) {
        print("Received URL: \(url.absoluteString)")
        
        guard url.scheme == "travelies" else {
            print("URL scheme not recognized")
            return
        }

        let urlString = url.absoluteString

        if urlString.hasPrefix("travelies://f?invite=") {
            handleInvitationLink(url: urlString, prefix: "f?invite=")
        } else if urlString.hasPrefix("travelies://j?invite=") {
            handleParticipationLink(url: urlString, prefix: "j?invite=")
        } else {
            print("No recognized query found in the URL")
        }
    }

    private func handleInvitationLink(url: String, prefix: String) {
        if let queryRange = url.range(of: prefix) {
            let invitationCode = String(url[queryRange.upperBound...])
            print("Invitation code: \(invitationCode)")
                    
            Task {
                do {
                    try await UserRepository.handleInvitation(invitationCode: invitationCode)
                    alertDataHandler.showInfoAlert(
                        title: "Evvai!",
                        message: "Ora siete amici.",
                        onOk: {}
                    )
                    forceRefresh.refresh = true
                } catch {
                    alertDataHandler.showInfoAlert(
                        title: "Errore",
                        message: error.localizedDescription,
                        onOk: {}
                    )
                }
            }
        } else {
            print("No query found in the URL")
        }
        
        forceRefresh.refresh = false
    }

    private func handleParticipationLink(url: String, prefix: String) {
        if let queryRange = url.range(of: prefix) {
            let invitationCode = String(url[queryRange.upperBound...])
            print("Participation code: \(invitationCode)")
            
            Task {
                do {
                    try await TravelRepository.handleParticipation(invitationCode: invitationCode)
                    alertDataHandler.showInfoAlert(
                        title: "Evvai!",
                        message: "Ora fai parte del viaggio.",
                        onOk: {}
                    )
                    forceRefresh.refresh = true
                } catch {
                    alertDataHandler.showInfoAlert(
                        title: "Errore",
                        message: error.localizedDescription,
                        onOk: {}
                    )
                }                
            }
        } else {
            print("No query found in the URL")
        }
        
        forceRefresh.refresh = false
    }
}

class ForceRefresh: ObservableObject {
    @Published var refresh: Bool = false
}

struct ApplicationSwitcher: View {
    @EnvironmentObject var auth: AuthenticationService
    @Binding var deepLinkQuery: String?
    @EnvironmentObject var forceRefresh: ForceRefresh

    var body: some View {
        if auth.isLogged {
            Navigator().environmentObject(forceRefresh)
        } else {
            LoginView()
        }
    }
}

struct SplashScreen: View {
    @EnvironmentObject var auth: AuthenticationService
    @Binding var isActive: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Image("Logo")
            }
            .task {
                auth.isLogged = await verifySession()
                
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}

func verifySession() async -> Bool {
    do {
        let id = UserDefaults.standard.integer(forKey: "user_id")
        
        guard id > 0 else {
            return false
        }
        
        guard let sessionKey = UserDefaults.standard.string(forKey: "session_key") else {
            return false
        }
        
        let parameters: [String: Any] = [
            "id": id,
            "session_key": sessionKey
        ]
        
        let (_, response) = try await Rest.postFormEncoded(endPoint: "session", data: parameters)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            return false
        } else {
            let _ = try await UserDataModel.shared.fetch(key: id)
            let _ = try await TravelDataModel.shared.fetchAll(userId: id)
        }
    } catch {
        print(error)
        return false
    }
    
    return true
}
