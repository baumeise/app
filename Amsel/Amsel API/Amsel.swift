//
//  Amsel.swift
//  Amsel
//
//  Created by Anja on 17.11.19.
//  Copyright © 2019 Anja. All rights reserved.
//

import UIKit
import Network
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class Amsel {
    
    static let shared = Amsel()
    
    private let amselIp = "192.168.4.1"
    private var hostUDP: Network.NWEndpoint.Host = "192.168.4.1"
    private var portUDP: Network.NWEndpoint.Port = 8080
    private let network_configuration = NEHotspotConfiguration(ssid: "Amsel", passphrase: "passwort", isWEP: false)
    private(set) var status = Status.NOT_CONNECTED
    
    enum Status {
        case NOT_CONNECTED // Default status
        case WIFI_CONNECTED // Wifi connected
        case WIFI_ERROR // Wifi not connected
        case AMSEL_TCP_ONLY // Amsel IP accessable
        case AMSEL_UDP_ONLY // Amsel IP accessable
        case AMSEL_TCP_UDP
        case AMSEL_ERROR // Amsel IP not accessable
    }
    
    private var connectionTcp: ConnectionTcp
    private var connectionUdp: ConnectionUdp
    
    //Initializer access level change now
    private init() {
        self.connectionTcp = ConnectionTcp(with: self.amselIp)
        self.connectionUdp = ConnectionUdp();
    }
    
    func connect(_ viewController: UIViewController) {
        // Show loading alert
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        viewController.present(alert, animated: true, completion: nil)
        
        // Connect to WIFI
        doWifiConnection(completion: { (status) in
            self.status = status
            
            if self.status == .WIFI_CONNECTED {
                // Check TCP
                self.connectionTcp.checkConnection(completion: { (tcpValid) in
                    if tcpValid && (self.status == .AMSEL_UDP_ONLY || self.status == .AMSEL_TCP_UDP) {
                        self.status = .AMSEL_TCP_UDP
                        DispatchQueue.main.async {
                              alert.dismiss(animated: false, completion: nil)
                        }
                    } else if tcpValid {
                        self.status = .AMSEL_TCP_ONLY
                        // Check/Connect UDP
                        self.connectionUdp.connect(self.hostUDP, self.portUDP, completion: { (udpValid) in
                            if udpValid && (self.status == .AMSEL_TCP_ONLY || self.status == .AMSEL_TCP_UDP) {
                                self.status = .AMSEL_TCP_UDP
                                DispatchQueue.main.async {
                                      alert.dismiss(animated: false, completion: nil)
                                }
                            } else if udpValid {
                                self.status = .AMSEL_UDP_ONLY
                                DispatchQueue.main.async {
                                      alert.dismiss(animated: false, completion: nil)
                                }
                            }
                        })
                    }
                })
            } else {
                // Error handling -> Wifi "Amsel" not available
                DispatchQueue.main.async {
                      alert.dismiss(animated: false, completion: nil)
                }
            }
        })
    }
    
    func checkConnection() {
        tcpCheck: if status == .AMSEL_TCP_UDP || status == .AMSEL_TCP_ONLY {
            if connectionTcp.isBusy() { break tcpCheck }
            self.connectionTcp.checkConnection(completion: { (tcpValid) in
                if tcpValid && (self.status == .AMSEL_UDP_ONLY || self.status == .AMSEL_TCP_UDP) {
                    self.status = .AMSEL_TCP_UDP
                } else if tcpValid {
                    self.status = .AMSEL_TCP_ONLY
                } else {
                    self.status = .AMSEL_ERROR
                }
            })
        }
        udpCheck: if status == .AMSEL_TCP_UDP || status == .AMSEL_UDP_ONLY {
            self.connectionUdp.checkConnection(completion: { (udpValid) in
                if udpValid && (self.status == .AMSEL_TCP_ONLY || self.status == .AMSEL_TCP_UDP) {
                    self.status = .AMSEL_TCP_UDP
                } else if udpValid {
                    self.status = .AMSEL_UDP_ONLY
                } else {
                    self.status = .AMSEL_ERROR
                }
            })
        }
    }
    
    func udpValid() -> Bool {
        return self.status == .AMSEL_UDP_ONLY || self.status == .AMSEL_TCP_UDP
    }
    
    func tcpValid() -> Bool {
        return self.status == .AMSEL_TCP_ONLY || self.status == .AMSEL_TCP_UDP
    }
    
    private func doWifiConnection(completion: @escaping (Status) -> Void) {
        // Source: https://medium.com/@Chandrachudh/connecting-to-preferred-wifi-without-leaving-the-app-in-ios-11-11f04d4f5bd0
        #if targetEnvironment(simulator)
            completion(.WIFI_CONNECTED)
        #else
            network_configuration.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(network_configuration) { (error) in
                if let error = error, error.localizedDescription != "already associated." {
                    print("Error: " + error.localizedDescription)
                    completion(.WIFI_ERROR)
                }
                else {
                    if currentSSIDs().first == self.network_configuration.ssid {
                        print("WiFi connected")
                        completion(.WIFI_CONNECTED)
                    } else {
                        print("Error: Connection to Amsel not possible")
                        completion(.WIFI_ERROR)
                    }
                }
            }
        #endif
        
        func currentSSIDs() -> [String] {
            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
                return []
            }
            return interfaceNames.compactMap { name in
                guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                    return nil
                }
                guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                    return nil
                }
                return ssid
            }
        }
    }
    
    // TCP functions
    func hello_tcp(_ responseLabel: UILabel) {
        if connectionTcp.isBusy() { return }
        connectionTcp.request("")
    }
    
    func print_tcp(_ text: String = "") {
        if connectionTcp.isBusy() { return }
        let args = ["string": text]
        connectionTcp.request("print", withString: args)
    }
    
    func safe_reset_tcp() {
        connectionTcp.safeReset()
    }
    
    func distance_tcp(completion: @escaping (String) -> Void) {
        if connectionTcp.isBusy() { return }
        connectionTcp.request("distance", completion: { (response) in
            if response.lowercased().contains("error") {
                completion("-")
            } else {
                completion(response)
            }
        })
    }
    
    func forward_tcp(speed: Float = 100) {
        if connectionTcp.isBusy() { return }
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        let args = ["speed": Int(speed)]
        connectionTcp.request("forward", withInt: args)
    }
    
    func reverse_tcp(speed: Float = 100) {
        if connectionTcp.isBusy() { return }
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        let args = ["speed": Int(speed)]
        connectionTcp.request("backward", withInt: args)
    }
    
    func left_tcp(speed: Float = 100) {
        if connectionTcp.isBusy() { return }
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        let args = ["speed": Int(speed)]
        connectionTcp.request("left", withInt: args)
    }
    
    func right_tcp(speed: Float = 100) {
        if connectionTcp.isBusy() { return }
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        let args = ["speed": Int(speed)]
        connectionTcp.request("right", withInt: args)
    }
    
    func stopDriving_tcp() {
        if connectionTcp.isBusy() { return }
        let args = ["speed": Int(0)]
        connectionTcp.request("forward", withInt: args)
        connectionTcp.request("reverse", withInt: args)
    }
    
    func stopSteering_tcp() {
        if connectionTcp.isBusy() { return }
        let args = ["speed": Int(0)]
        connectionTcp.request("right", withInt: args)
        connectionTcp.request("left", withInt: args)
    }
    
    func stop_tcp() {
        if connectionTcp.isBusy() { return }
        connectionTcp.request("stop")
    }
    
    // UDP functions
    func forward(speed: Float = 100) {
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        connectionUdp.sendUDP("forward:\(Int(speed))")
    }
    
    func reverse(speed: Float = 100) {
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        connectionUdp.sendUDP("reverse:\(Int(speed))")
    }
    
    func left(speed: Float = 100) {
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        connectionUdp.sendUDP("left:\(Int(speed))")
    }
    
    func right(speed: Float = 100) {
        let speed = clamp(speed, minValue: 0, maxValue: 100)
        connectionUdp.sendUDP("right:\(Int(speed))")
    }
    
    func stopDriving() {
        connectionUdp.sendUDP("forward:\(Int(0))")
        connectionUdp.sendUDP("reverse:\(Int(0))")
    }
    
    func stopSteering() {
        connectionUdp.sendUDP("right:\(Int(0))")
        connectionUdp.sendUDP("left:\(Int(0))")
    }
    
    func stop() {
        connectionUdp.sendUDP("stop")
    }
}

class ConnectionUdp {
    var connection: NWConnection?
    
    func connect(_ hostUDP: Network.NWEndpoint.Host, _ portUDP: Network.NWEndpoint.Port, completion: @escaping (Bool) -> Void) {
        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)

        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                    completion(true)
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                    completion(false)
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
                    completion(false)
            }
        }

        self.connection?.start(queue: .global())
    }
    
    func checkConnection(completion: @escaping (Bool) -> Void) {
        let contentToSendUDP = "".data(using: String.Encoding.utf8)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
                completion(true)
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
                completion(false)
            }
        })))
    }

    func sendUDP(_ content: Data) {
        self.connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func sendUDP(_ content: String) {
        let contentToSendUDP = content.data(using: String.Encoding.utf8)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func receiveUDP() {
        self.connection?.receiveMessage { (data, context, isComplete, error) in
            if (isComplete) {
                print("Receive is complete")
                if (data != nil) {
                    let backToString = String(decoding: data!, as: UTF8.self)
                    print("Received message: \(backToString)")
                } else {
                    print("Data == nil")
                }
            }
        }
    }
    
}

class ConnectionTcp {
    
    private let amselUrl: String
    private var busy = false
    private var urlSession: URLSessionDataTask?
    
    init(with amselIp: String) {
        amselUrl =  "http://\(amselIp):80"
    }
    
    func isBusy() -> Bool {
        return busy
    }
    
    func checkConnection(completion: @escaping (Bool) -> Void) {
        
        if let url = URL(string: amselUrl) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 5.0
            
            urlSession?.cancel()
            busy = true
            urlSession = URLSession(configuration: sessionConfig)
                .dataTask(with: request) { (_, response, error) in
                    if let error = error {
                        print("Error: ", error)
                        self.busy = false
                        completion(false)
                    } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                        print("Amsel down")
                        self.busy = false
                        completion(false)
                    } else {
                        print("Amsel up")
                        self.busy = false
                        completion(true)
                    }
            }
            urlSession!.resume()
        }
    }
    
    func safeReset() {
        if let url = URL(string: amselUrl + "/stop") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 5.0
            
            urlSession?.cancel()
            busy = true
            urlSession = URLSession(configuration: sessionConfig)
                .dataTask(with: request) { (_, response, error) in
                    self.busy = false
                    let args = ["string": ""]
                    self.request("print", withString: args)
            }
            urlSession!.resume()
        }
    }
    
    func request(_ request: String,  withInt argsInt: [String:Int]? = nil, withString argsString: [String:String]? = nil, completion: ((String) -> Void)? = nil) {
        guard Amsel.shared.tcpValid() else {
            if let completion = completion {
                completion("Error: No TCP connection to Amsel available")
            }
            return
        }
        
        // Create URL
        let urlString = "\(amselUrl)/\(request)"
        guard var url = URL(string: urlString) else {
            if let completion = completion {
                completion("Error: \(urlString) doesn't seem to be a valid URL")
            }
            return
        }
        
        // Append parameters to URL, if available
        if let args = argsInt {
            for (arg, value) in args {
                url = url.appending(arg, value: String(value))
            }
        }
        if let args = argsString {
            for (arg, value) in args {
                url = url.appending(arg, value: value)
            }
        }
        
        // Create and queuable URL operation
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5.0
        
        urlSession?.cancel()
        self.busy = true
        urlSession = URLSession(configuration: sessionConfig)
        .dataTask(with: url) { (data, response, error) in
            if let completion = completion, let error = error {
                self.busy = false
                completion("Error: \(error)")
                return
            }
            if let completion = completion, let data = data, let string = String(data: data, encoding: .ascii) {
                self.busy = false
                completion(string)
            }
            self.busy = false
            
        }
        urlSession!.resume()
    }
}

extension URL {
    func appending(_ queryItem: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)
        // Append the new query item in the existing query items array
        queryItems.append(queryItem)
        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems
        // Returns the url from new url components
        return urlComponents.url!
    }
}

public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
    return min(max(value, minValue), maxValue)
}
