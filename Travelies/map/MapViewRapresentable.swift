import SwiftUI
import MapKit


//travel annotation properties
class TravelAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var travel: Travel
    var clusteringIdentifier: String? = "cluster"
    
    init(travel: Travel) {
        let center = travel.getCenter()! //only travel with coordinates get pins
        self.coordinate = CLLocationCoordinate2D(latitude: center.0, longitude: center.1)
        self.title = travel.name
        self.travel = travel
    }
}

//setting travel annotation appearance------
class TravelAnnotationView: GenericAnnotationView<TravelAnnotation, TravelAnnotationContentView, TravelClusterAnnotationContentView> {
    
    init(annotation: NSObject, reuseIdentifier: String) {
        if !(annotation is TravelAnnotation) && !(annotation is MKClusterAnnotation) {
            fatalError("Wrong type of annotation passed to TravelAnnotationView")
        }
        
        super.init(annotation: annotation as? MKAnnotation, reuseIdentifier: reuseIdentifier)
        self.pinSize = 30.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//cluster Travel annotation look
struct TravelClusterAnnotationContentView: ClusterAnnotationContentView{
    typealias T = TravelAnnotation
    
    var cluster: MKClusterAnnotation
    var pinSize: Double
    var TCluster: [TravelAnnotation] //convert cluster in a set of TravelAnnotation
    
    //we only need this to conform to the protocol, it will be ignored
    init(cluster: MKClusterAnnotation, pinSize: Double) {
        self.cluster = cluster
        self.pinSize = pinSize
        self.TCluster = [] //actual value is set by ClusterAnnotationContentView.createDefault()
    }
    
    
    var body: some View {
        ZStack{
            
            // Triangolo capovolto per emulare il pin
            Image(systemName: "triangle.fill")
                .resizable()
                .frame(width: pinSize/2.0, height: pinSize*2.0/5)
                .foregroundColor(Color("CameraYellow"))
                .rotationEffect(.degrees(180))
                .offset(y: pinSize*2.0/3)
            
            // Cerchio con il numero
            ZStack{
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: pinSize*7.0/6, height: pinSize*7.0/6)
                    .overlay(
                    Color(UIColor.systemBackground).opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    )
                    .scaledToFit()
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color("CameraYellow"), lineWidth: 4))
                
                Text(cluster.memberAnnotations.count > 9 ? "9+" : "\(cluster.memberAnnotations.count)")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            
                
        }
        .offset(y: -pinSize/2.0)
    }
}

// non cluster travel look-----------
struct TravelAnnotationContentView: SingleAnnotationContentView {
    typealias T = TravelAnnotation
    
    let annotation: T
    var pinSize : Double
    
    init(annotation: TravelAnnotation, pinSize: Double) {
        self.annotation = annotation
        self.pinSize = pinSize
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemBackground))
                .frame(width: pinSize*7.0/6, height: pinSize*7.0/6)
            
            Text("\(annotation.title?.first?.uppercased() ?? "·")")
                .bold()
            
        }.frame(width: pinSize*7.0/6, height: pinSize*7.0/6)
            .scaledToFit()
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2).padding(2))
            .overlay(Circle().stroke(Color("CameraYellow"), lineWidth: 4))
        
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var cameraPosition: MKCoordinateRegion
    let clusterRadius = 10_000.0  //m
    
    var markerNavigationState: MarkerNavigationStateTravel
    var locations: [Travel]
    
    var onRegionChange: ((MKCoordinateRegion) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(cameraPosition, animated: true)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        
        let configuration = MKStandardMapConfiguration()
        configuration.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
        configuration.showsTraffic = false
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        mapView.preferredConfiguration = configuration
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(cameraPosition, animated: true)
        uiView.removeAnnotations(uiView.annotations)
                        
        //navigationState.selectedTravel = nil
        
        let annotations = locations.filter({ $0.getCenter() != nil }).map { location in
            TravelAnnotation(travel: location)
        }
        uiView.addAnnotations(annotations)
        
        // Aggiorna le locations nel coordinatore
        context.coordinator.updateLocations(locations)
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, locations: locations)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var locations: [Travel]
        
        init(_ parent: MapViewRepresentable, locations: [Travel]) {
            self.parent = parent
            self.locations = locations
        }
        
        func updateLocations(_ locations: [Travel]) {
            self.locations = locations
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onRegionChange?(mapView.region)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            if let travelAnnotation = annotation as? TravelAnnotation ?? annotation as? MKClusterAnnotation {
                let identifier = "TravelAnnotationView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TravelAnnotationView

                if annotationView == nil {
                    annotationView = TravelAnnotationView(annotation: travelAnnotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = travelAnnotation as? any MKAnnotation
                }

                return annotationView
            }
            
            return nil
        }
        
        //handle tapping on map, not on an annotation
        @MainActor @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            let mapView = gestureRecognizer.view as! MKMapView
            _ = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Check if the tap is on an annotation or cluster
            let tappedAnnotations = mapView.annotations.filter {
                let annotationView = mapView.view(for: $0)
                if let annotationView = annotationView {
                    return annotationView.frame.contains(location)
                }
                return false
            }
            
            // no annotation tapped
            if tappedAnnotations.isEmpty {
                parent.onRegionChange?(mapView.region)
                parent.markerNavigationState.select(item: [])
            }
        }
        
        //handle annotation selection
        @MainActor func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? TravelAnnotation,
               let title = annotation.title,
               let location = locations.first(where: { $0.name == title }) {
                //non cluster annotatations -----
                                                  
                    mapView.selectedAnnotations = []
                   
                    self.parent.markerNavigationState.select(item: [location])
                    self.parent.cameraPosition = mapView.region
                
            } else if let cluster = view.annotation as? MKClusterAnnotation {
                //cluster annotatations -----
                
                let nearbyLocations = cluster.memberAnnotations.compactMap { annotation -> Travel? in
                    guard let title = annotation.title else { return nil }
                    return locations.first(where: { $0.name == title })
                }
                
                let latMax = nearbyLocations.map{$0.getCenter()!.0}.max() ?? 0.0
                let latMin = nearbyLocations.map{$0.getCenter()!.0}.min() ?? 0.0
                let lonMax = nearbyLocations.map{$0.getCenter()!.1}.max() ?? 0.0
                let lonMin = nearbyLocations.map{$0.getCenter()!.1}.min() ?? 0.0
                
                let d = calucateDistance(lat1: latMax, lon1: lonMax, lat2: latMin, lon2: lonMin)
                
                if d < parent.clusterRadius {
                    //all annotations have same coordinates
                    self.parent.markerNavigationState.select(item: nearbyLocations)
                }
                else{
                    //zoom on the center between annotations
                    let center = CLLocationCoordinate2D(latitude: (latMax+latMin)/2, longitude: (lonMax+lonMin)/2)
                    
                    
                    let span = MKCoordinateSpan(latitudeDelta: (latMax-latMin) * 2.0, longitudeDelta: (lonMax-lonMin)  * 2.0)
                    let region = MKCoordinateRegion(center: center, span: span)
                    mapView.setRegion(region, animated: true)
                }
            }
        }
    }
}
