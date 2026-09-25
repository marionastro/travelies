//
//  FriendContentView.swift
//  mockup
//
//  Created by Studente on 13/08/24.
//

import Foundation
import SwiftUI
import MapKit

struct FriendContentView: View {
    @Environment(\.presentationMode) var presentation
    @State private var cameraPosition = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
    @State private var isListShown = false
    
    @StateObject private var markerNavigationState = MarkerNavigationStateTravel()
    @State private var travels: [Travel] = []
    
    let user: User
    
    var body: some View {
        VStack {
            ZStack {
                HStack(spacing: 4) {
                    Text("I viaggi di")
                        .font(.custom("DIN Alternate", size: 18))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(user.username)")
                        .font(.custom("DIN Alternate", size: 18))
                        .foregroundColor(Color(UIColor.label))
                }
                HStack(spacing: 12) {
                    Button(action: {
                        self.presentation.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(Color(UIColor.label))
                            .font(.system(size: 24, weight: .semibold))
                    }
                    Spacer()
                    Button(action: {
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
                    NavigationLink(destination: TripCreate()) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(UIColor.label))
                            .font(.system(size: 24, weight: .semibold))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
            
            VStack(spacing: 18) {
                MapViewRepresentable(cameraPosition: $cameraPosition, markerNavigationState: markerNavigationState, locations: travels)
                    .cornerRadius(24)
                    .frame(maxHeight: .infinity)

                if isListShown {
                    TravelTiles()
                }
            }
            .navigationDestination(isPresented: .constant(markerNavigationState.isSelected())) {
                TripProfile(travelId: markerNavigationState.selectedItem)
            }
        }
        .padding([.trailing, .leading], 24)
        .edgesIgnoringSafeArea(.bottom)
        .frame(maxWidth: .infinity)
        .task {
            // Code inside here is already running in an async context
            do {
                markerNavigationState.reset()
                
                travels = try await TravelDataModel.shared.fetchAll(userId: user.id)
            } catch {
                print(error)
            }
        }
        .refreshable {
            // Code inside here is already running in an async context
            do {
                markerNavigationState.reset()
                
                TravelDataModel.shared.resetByUserId(userId: user.id)
                travels = try await TravelDataModel.shared.fetchAll(userId: user.id)
            } catch {
                print(error)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    func TravelTiles() -> some View {
        List(travels.sorted(by: >)) { travel in
            TravelTile(data: travel, member: travel.creator != user, action: {
                navigateTo(location: travel.getCenter(), span: (0.05, 0.05))
            })
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
