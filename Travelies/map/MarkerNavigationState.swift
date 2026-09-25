//
//  MarkerNavigationState.swift
//  mockup
//
//  Created by Studente on 13/08/24.
//

import Foundation

@MainActor
protocol MarkerNavigationStateProtocol: AnyObject, ObservableObject {
    associatedtype T
    associatedtype U
    
    var selectedItem: T? { get set }
    
    func select(item: U)
    func reset()
    func isSelected() -> Bool
}

extension MarkerNavigationStateProtocol where Self: AnyObject  {
    func reset() {
        selectedItem = nil
    }
    
    func isSelected() -> Bool {
        return selectedItem != nil
    }
}

@MainActor
class MarkerNavigationStateTravel: MarkerNavigationStateProtocol {
    typealias T = Int
    typealias U = [Travel]
    
    @Published var selectedItem: T?
    var travelList : [Travel] = []
    var onSelection: (() -> Void)?
    var mapTapped: (() -> Void)?
    
    func select(item: U) {
        if item.isEmpty {
            mapTapped?()
            return
        }
        
        if item.count == 1 {
            selectedItem = item[0].id
        } else{
            travelList = item
            onSelection?()
        }
    }
}

@MainActor
class MarkerNavigationStatePost: MarkerNavigationStateProtocol {
    typealias T = [Post]
    
    @Published var selectedItem: T?
    //var postList : [Post] = []
    
    func select(item: [Post]) {
        selectedItem = item
    }

}
