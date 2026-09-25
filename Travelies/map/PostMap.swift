//
//  PostsMap.swift
//  mockup
//
//  Created by Studente on 28/07/24.
//

import SwiftUI
import MapKit

//post annotation properties
class PostAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var post: Post
    var clusteringIdentifier: String? = "cluster"
    
    init(post: Post) {
        self.coordinate = CLLocationCoordinate2D(latitude: post.lat!, longitude: post.lon!)
        self.title = post.dataPath
        self.post = post
    }
}

//setting travel annotation appearance------
class PostAnnotationView: GenericAnnotationView<PostAnnotation, PostAnnotationContentView, PostClusterAnnotationContentView> {
    
    init(annotation: NSObject, reuseIdentifier: String) {
        if !(annotation is PostAnnotation) && !(annotation is MKClusterAnnotation) {
            fatalError("Wrong type of annotation passed to PostAnnotationView")
        }
        
        super.init(annotation: annotation as? MKAnnotation, reuseIdentifier: reuseIdentifier)
        self.pinSize = 30.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//cluster post annotation look
struct PostClusterAnnotationContentView: ClusterAnnotationContentView {
    typealias T = PostAnnotation
    
    var cluster: MKClusterAnnotation
    var pinSize: Double
    var TCluster: [PostAnnotation] //convert cluster in a set of PostAnnotation
    
    //we only need this to conform to the protocol, it will be ignored
    init(cluster: MKClusterAnnotation, pinSize: Double) {
        self.pinSize = pinSize
        self.cluster = cluster
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
                    .overlay(Circle().stroke(Color("CameraYellow"), lineWidth: 2))
                
                VStack {
                    if TCluster.first!.post.dataType == TVideo.rawType {
                        VideoThumbnailView(post: TCluster.first!.post)
                    } else if TCluster.first!.post.dataType == TImage.rawType {
                        AsyncImageView(post: TCluster.first!.post)
                    }
                }.overlay(
                    Color(UIColor.systemBackground).opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    )
                    .frame(width: pinSize, height: pinSize)
                    .scaledToFit()
                    .clipShape(Circle())
                
                Text(cluster.memberAnnotations.count > 99 ? "99+" : "\(cluster.memberAnnotations.count)")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            
                
        }
        .offset(y: -pinSize/2.0)
    }
}

// non cluster post annotation look-----------
struct PostAnnotationContentView: SingleAnnotationContentView  {
    typealias T = PostAnnotation
    
    let annotation: T
    var pinSize : Double
    
    init(annotation: PostAnnotation, pinSize: Double) {
        self.annotation = annotation
        self.pinSize = pinSize
    }
    
    var body: some View {
        VStack {
            if annotation.post.dataType == TVideo.rawType {
                VideoThumbnailView(post: annotation.post, playSize: 15)
            } else if annotation.post.dataType == TImage.rawType {
                AsyncImageView(post: annotation.post)
            }
        }.frame(width: pinSize*7.0/6, height: pinSize*7.0/6)
            .scaledToFit()
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2).padding(2))
            .overlay(Circle().stroke(Color("CameraYellow"), lineWidth: 2))
        
    }
}


struct PostMap: UIViewRepresentable {
    @Binding var cameraPosition: MKCoordinateRegion
    let clusterRadius = 20.0 //m
    
    var markerNavigationStatePost: MarkerNavigationStatePost
    var posts: [Post]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(cameraPosition, animated: true)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        
        let configuration = MKStandardMapConfiguration()
        configuration.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
        configuration.showsTraffic = false
        
        mapView.preferredConfiguration = configuration
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(cameraPosition, animated: true)
        uiView.removeAnnotations(uiView.annotations)
                        
        
        let annotations = posts.filter({ $0.lat != nil  && $0.lon != nil }).map { post in
            PostAnnotation(post: post)
        }
        uiView.addAnnotations(annotations)
        
        // Aggiorna le locations nel coordinatore
        context.coordinator.updateLocations(posts)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, posts: posts)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: PostMap
        var posts: [Post]
        
        init(_ parent: PostMap, posts: [Post]) {
            self.parent = parent
            self.posts = posts
        }
        
        func updateLocations(_ posts: [Post]) {
            self.posts = posts
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let postAnnotation = annotation as? PostAnnotation ?? annotation as? MKClusterAnnotation {
                let identifier = "PostAnnotationView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? PostAnnotationView

                if annotationView == nil {
                    annotationView = PostAnnotationView(annotation: postAnnotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = postAnnotation as? any MKAnnotation
                }

                return annotationView
            }
            
            return nil
        }
        
        
        @MainActor func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? PostAnnotation,
               let title = annotation.title,
               let post = posts.first(where: { $0.dataPath == title }) {
                //non cluster annotations --------
                                                  
                   mapView.selectedAnnotations = []
                   
                   self.parent.markerNavigationStatePost.select(item: [post])
                   self.parent.cameraPosition = mapView.region
                
            } else if let cluster = view.annotation as? MKClusterAnnotation {
                //cluster annotations -------
                
                let nearbyLocations = cluster.memberAnnotations.compactMap { annotation -> Post? in
                    guard let title = annotation.title else { return nil }
                    return posts.first(where: { $0.dataPath == title })
                }
                
                //zoom su centro fra i viaggi
                let nearbyFilter = posts.filter{ nearbyLocations.contains($0) }
                let bounds = Post.bounds(for: nearbyFilter)
                
                let postMaxLat = bounds.maxLat
                let postMinLat = bounds.minLat
                let postMaxLon = bounds.maxLon
                let postMinLon = bounds.minLon
                
                let d = calucateDistance(lat1: postMaxLat, lon1: postMaxLon, lat2: postMinLat, lon2: postMinLon)
                
                if d < parent.clusterRadius {
                    //all annotations have same coordinates
                    
                    self.parent.markerNavigationStatePost.select(item: nearbyFilter.sorted(by: <))
                }
                else{
                    //zoom on the center between annotations
                    let center = CLLocationCoordinate2D(latitude: (postMaxLat+postMinLat)/2, longitude: (postMaxLon+postMinLon)/2)
                    
                    let span = MKCoordinateSpan(latitudeDelta: (postMaxLat-postMinLat) * 1.5, longitudeDelta: (postMaxLon-postMinLon)  * 1.5)
                    let region = MKCoordinateRegion(center: center, span: span)
                    mapView.setRegion(region, animated: true)
                }
            }
            
        }
    }
}

