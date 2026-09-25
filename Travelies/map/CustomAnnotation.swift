//
//  CustomAnnotation.swift
//  mockup
//
//  Created by Studente on 30/08/24.
//

import MapKit
import SwiftUI

class GenericAnnotationView<T: MKAnnotation, AnnotationContentView: SingleAnnotationContentView,
                                ClusterContentView: ClusterAnnotationContentView> : MKAnnotationView
        where AnnotationContentView.T == T, ClusterContentView.T==T {
    
    open var hostingController: UIHostingController<AnyView>?
    var pinSize : Double = 30.0 //default value
    
    override var annotation: MKAnnotation? {
        didSet {
            clusteringIdentifier = "shop" //allow clustering
            configure()
        }
    }
    
    //extend interactable are of pin
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let touchableArea = self.bounds.insetBy(dx: -pinSize * 13.0/6, dy: -pinSize * 13.0/6)
           return touchableArea.contains(point)
    }

    func configure() {
        subviews.forEach { $0.removeFromSuperview() }
        self.frame = CGRect(x: 0, y: 0, width: pinSize*7.0/6, height: pinSize*13.0/6)
        //guard let annotation = annotation as? T else { return }

        if let cluster = annotation as? MKClusterAnnotation {
            configureClusterView(for: cluster)
        } else {
            configureSingleAnnotation()
        }
    }

    open func configureSingleAnnotation (){
        // Override in subclasses
        //print("configureSingleAnnotation() was not overwritten in \(String(describing: type(of: self)))")
        //fatalError("Must Override")
        
        
        guard annotation is T else {
                return //without this the app crushes cause it tries to unwrapped an annotation that's not T
            }
        
            let travelContentView = AnnotationContentView(annotation: annotation as! T, pinSize: pinSize)
            hostingController = UIHostingController(rootView: AnyView(travelContentView))

            if let hostView = hostingController?.view {
                hostView.frame = CGRect(x: 0, y: 0, width: pinSize*7.0/6, height: pinSize*7.0/6)
                hostView.backgroundColor = .clear
                addSubview(hostView)
            }
    }

    open func configureClusterView(for cluster: MKClusterAnnotation) {
        // Override in subclasses
        //print("configureClusterView() was not overwritten in \(String(describing: type(of: self)))")
        //fatalError("Must Override")
        
        let clusterContentView = ClusterContentView.createDefault(cluster: cluster, pinSize: pinSize)
        hostingController = UIHostingController(rootView: AnyView(clusterContentView))

        if let hostView = hostingController?.view {
            hostView.frame = CGRect(x: 0, y: 0, width: pinSize*7.0/6, height: pinSize*7.0/6)
            hostView.backgroundColor = .clear
            addSubview(hostView)
        }
    }
}

protocol SingleAnnotationContentView: View{
    associatedtype T: MKAnnotation
    
    var annotation: T { get }
    var pinSize : Double { get }
    
    init(annotation: Self.T, pinSize: Double)
}


protocol ClusterAnnotationContentView: View{
    associatedtype T: MKAnnotation
    
    var cluster: MKClusterAnnotation { get }
    var pinSize : Double { get }
    //convert cluster in a set of T-Annotation
    var TCluster: [T] {
            //cluster.memberAnnotations.compactMap { $0 as? T }
            get set
        }
    
    init(cluster: MKClusterAnnotation, pinSize: Double)
}

//allow to have the same init() body in all specializations
extension ClusterAnnotationContentView {
    static func createDefault(cluster: MKClusterAnnotation, pinSize: Double) -> Self {
        var instance = Self.init(cluster: cluster, pinSize: pinSize)
        instance.TCluster = cluster.memberAnnotations.compactMap { $0 as? T }
        return instance
    }
}
