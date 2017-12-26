//
//  ViewController.swift
//  Que hay de nuevo
//
//  Created by David Garcia on 12/26/17.
//  Copyright © 2017 David Garcia. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import CoreLocation
import GameplayKit

class ViewController: UIViewController, ARSKViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation() //Me da una posicion
    
    var sitesJson : JSON!
    
    var userHeading = 0.0
    var headingStep = 0
    
    var sites = [UUID: String]() //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
//        let configuration = ARSessionConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        return nil
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //MARK: CLLocationManager
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        userLocation = location
        
        //Correr en segundo plano para enfriar la aplicación
        DispatchQueue.global().async {
            self.updateSites()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.headingStep += 1
            
            if self.headingStep < 2 { return }
            
            self.userHeading = newHeading.magneticHeading
            self.locationManager.stopUpdatingHeading()
            self.createSites()
        }
    }
    
    func updateSites() {
        let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=\(userLocation.coordinate.latitude)%7C\(userLocation.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        guard let url = URL(string: urlString) else {
            return
        }
        
        if let data = try? Data(contentsOf: url) {
            sitesJson = JSON(data)
            locationManager.startUpdatingHeading() //Apuntador a la cabeza del usuario.
            
        }
    }
    
    func createSites() {
        //Hacer un bucle de todos los lugares que ocupa el JSON de la wikipedia.
        for pages in sitesJson["query"]["pages"].dictionaryValue.values {
            //Ubicar latitud y longitud de esos lugares
            let lat = pages["coordinates"][0]["lat"].doubleValue
            let lon = pages["coordinates"][0]["lon"].doubleValue
            let location = CLLocation(latitude: lat, longitude: lon)
            
            //Calcular la distancia y la direccion (azimut, cuando miramos las estrellas) desde el usuario hasta ese lugar.
            let distance = Float(userLocation.distance(from: location))
            let azimut = direction(from: userLocation, to: location)
            
            //Sacar ángulo entre azimut y la dirección del usuario
            let angle = azimut - userHeading
            let angleRad = deg2Rad(angle)
        }
        
        
        
        //Crear las matrices de rotacion para posicionar horizontalmente el ancla
        
        //Crear la matriz para la rotacion vertical basada en la distancia
        
        //Multiplicar las matrices de rotacion anteriores y multiplicarlas por la camara de ARKit
        
        //Crear una matriz de identidad y moverla una cierta cantidad dependiendo de donde posicionar el objeto en profundidad.
        
        //Posicionaremos el ancla y le daremos un identificador para localizarlo en escena
    }
    
    //MARK: Mathematical Library
    func deg2Rad(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }
    
    func rad2Deg(_ radians: Double) -> Double {
        return radians * 180 / Double.pi
    }
    
    //atag2 ( sen(dif long)  *  cos(long2), cos(lat1) * sen(lat2) - cos(lat2) * sen(lat1) * cos(dif long))
    func direction(from p1: CLLocation, to p2: CLLocation) -> Double {
        let dif_long = p2.coordinate.longitude - p1.coordinate.longitude
        let y = sin(dif_long) * cos(p2.coordinate.longitude)
        let x = cos(p1.coordinate.latitude) * sin(p2.coordinate.latitude) - cos(p2.coordinate.latitude) * sin(p1.coordinate.latitude) * cos(dif_long)
        
        let atan_rad = atan2(y, x)
        
        return rad2Deg(atan_rad)
}
