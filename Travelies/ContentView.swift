import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(\.presentationMode) var presentation
    @State private var cameraPosition = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
    @State private var lastCameraPostion: MKCoordinateRegion? //saves last camera position before leaving this page
    
    @State private var isListShown = false
    @StateObject private var markerNavigationState = MarkerNavigationStateTravel()
    @State private var travels: [Travel] = []
    
    let currentUser = UserDataModel.shared.getCurrentUser()
    
    let user: User
    let friendPage: Bool
    
    @EnvironmentObject var forceRefresh: ForceRefresh //tells if the camera sheet has been closed
    @State private var isVisible = false //tells if this page is currently on screen
    
    init(user: User, friendPage: Bool = false){
        self.user = user
        self.friendPage = friendPage
    }
    
    var body: some View {
        VStack {
            ZStack {
                HStack (spacing: 4){
                    if !friendPage {
                        Text("I tuoi viaggi")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(UIColor.label))
                    } else {
                        Text("I viaggi di")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text("\(user.username)")
                            .font(.custom("DIN Alternate", size: 18))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
                
                HStack(spacing: 12) {
                    if friendPage{
                        Button(action: {
                            self.presentation.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(Color(UIColor.label))
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                    
                    Spacer()
                    Button(action: {
                        markerNavigationState.travelList = [] // otherwise it shows just travelList and not entire list
                        
                        updateCameraPositionToLastPos()
                        
                        withAnimation {
                            isListShown.toggle()
                        }
                    }) {
                        Image(systemName: "list.bullet.below.rectangle")
                            .foregroundColor(
                                isListShown
                                ? Color(UIColor.systemBackground)
                                : Color(UIColor.label)
                            )
                            .padding(6)
                            .background(
                                isListShown
                                ? Color(UIColor.label)
                                : Color(UIColor.systemBackground)
                            )
                            .font(.system(size: 24, weight: .semibold))
                            .cornerRadius(6)
                    }
                    
                    if !friendPage{
                        NavigationLink(destination: TripCreate()) {
                            Image(systemName: "plus")
                                .foregroundColor(Color(UIColor.label))
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            
            VStack(spacing: 18) {
                MapViewRepresentable(cameraPosition: $cameraPosition, markerNavigationState: markerNavigationState, locations: travels, onRegionChange: { newRegion in  lastCameraPostion = newRegion })
                .cornerRadius(24)
                .frame(maxHeight: .infinity)
                
                if isListShown {
                    TravelTiles( markerNavigationState.travelList )
                }
                
            }
            .onAppear(){
                
                // if user tap on the map (not a pin) make travel list disappear
                markerNavigationState.mapTapped = {
                    updateCameraPositionToLastPos()
                    withAnimation{
                        isListShown = false
                    }
                }
                
                // if the list of travel is already shown, change it (no animation)
                // else makes it appear
                markerNavigationState.onSelection = {
                    updateCameraPositionToLastPos()
                    if isListShown {
                        isListShown = false //this force TravelTiles() to update the list
                        isListShown = true
                    } else {
                        withAnimation {
                            isListShown = true
                        }
                    }
                    
                }
            }
            .padding([.trailing, .leading], 24)
            .edgesIgnoringSafeArea(.bottom)
            .frame(maxWidth: .infinity)
            .task {
                // Code inside here is already running in an async context
                await updateTravels()
            }
            .onChange(of: forceRefresh.refresh) { _,newValue in
                if newValue && isVisible { //update user travels only if this page is on screen
                                          //(don't update user datas if they close camera when on their friend's page)
                    Task {
                        print("Camera has been closed")
                        await updateTravels()
                    }
                }
            }
            .onChange(of: travels) { _, newTravels in
                for travel in newTravels {
                    TravelDataModel.shared.update(travel, withKey: travel.id)
                }
            }
            .refreshable {
                // Code inside here is already running in an async context
                await updateTravels()
            }
        }
        //when user select an annotation on the map, open the corresponding travel page
        .navigationDestination(isPresented: .constant(markerNavigationState.isSelected())) {
            TripProfile(travelId: markerNavigationState.selectedItem)
                .environmentObject(forceRefresh)
        }
        .onAppear(){
            isVisible = true
        }
        .onDisappear(){
            updateCameraPositionToLastPos()
            isVisible = false
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    //this prevents a bug when using NavigateTo(), moving the camera, opening a Trip with a TripProfile and coming back
    //the camera would go to the last value specified by NavigateTo() instead of where you left
    func updateCameraPositionToLastPos(){
        if lastCameraPostion != nil {
            withAnimation {
                cameraPosition = lastCameraPostion!
            }
        }
    }

    func updateTravels() async {
        do {
            travels = try await TravelDataModel.shared.fetchAll(userId: user.id).filter {
                if friendPage {
                    return ($0.creator == user) && ($0.privacy == 1 || $0.isMember(user: currentUser))
                } else {
                    return true
                }
            }
            
            if let update = try? await TravelRepository.getTravelsByUser(userId: user.id), Set(update) != Set(travels) {
                travels = update.filter {
                    if friendPage {
                        return ($0.creator == user) && ($0.privacy == 1 || $0.isMember(user: currentUser))
                    } else {
                        return true
                    }
                }
            }
            
            markerNavigationState.reset()
        } catch {
            print(error)
        }
    }
        
    func TravelTiles(_ travelList: [Travel] = []) -> some View {
        let source = travelList.isEmpty ? travels : travelList
        
        return List(source.sorted(by: <)) { travel in
            TravelTile(data: travel, member: travel.creator != user, action: {
                if let center = travel.getCenter() {
                    navigateTo(location: center, span: (0.05, 0.05))
                } else {
                    print("Travel with no coordinates")
                }
            })
            .environmentObject(forceRefresh)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listRowSpacing(18)
        .contentMargins(.vertical, 0)
        .listStyle(GroupedListStyle())
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
        
    func navigateTo(location: (Double, Double)?, span: (Double, Double)?) {
        if location != nil {
            let coord = CLLocationCoordinate2D(
                latitude:  location!.0 + Double.random(in: 0.00001...0.001),
                longitude: location!.1 + Double.random(in: 0.00001...0.001)
            )
            
            withAnimation {
                cameraPosition = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: span!.0, longitudeDelta: span!.1)
                )
            }
        }
    }
}
