import UIKit
import MapKit

class MapViewController: UIViewController {
    var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MKMapView(frame: self.view.bounds)
        self.view.addSubview(mapView)

        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        // Abilita il clustering
        mapView.annotationManager.clustering = true

        // Configura le altre proprietà della mappa, se necessario
    }
}
