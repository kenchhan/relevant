//
//  Canvas.swift
//  BreakfastFinder
//
//  Created by Ken Chhan on 12/4/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import Vision
import SocketIO

class Canvas {
    private var pieces = [Lego]()
    private var grid = Array(repeating: Array(repeating: ".", count: Constants.defaultColumnCount), count: Constants.defaultRowCount)
    
    static let connectionURL = "http://localhost:8090"
    let manager = SocketManager(socketURL: URL(string: Canvas.connectionURL)!)
    var socket: SocketIOClient!
    var bufferSize: CGSize
    private var componentValues: [String: String] = [:]
    
    // generate template every 10-15 calls. compile ongoing list of seen objects and then make template
    
    init(_ bufferSize: CGSize) {
        socket = manager.defaultSocket
        
        
        self.bufferSize = bufferSize
        
        setSocketEvents()
        //socket.connect()
        componentValues = ["1x2_blue": "b",
                           "1x2_grey": "g",
                           
        ]
    }
    
    public func handle(_ observedLegos: [VNRecognizedObjectObservation]) {
        if let baseplate = observedLegos.first(where: { $0.labels[0].identifier == "6x12_green" }) {
            createGridTemplate(observedLegos)
            
//            self.socket.emit("templateUpdate", grid)
            // form template
            
            // if new template, emit socket event
        }

    }
    
    private func createGridTemplate(_ observations: [VNRecognizedObjectObservation]) {
        if let baseplate = observations.first(where: { $0.labels[0].identifier == "6x12_green" }) {

            
            let baseplateBounds = VNImageRectForNormalizedRect(baseplate.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            addPiecesToTemplate(using: baseplateBounds, adding: observations)
            
            
            // socket event
        }
        
        
    }
    
    private func addPiecesToTemplate(using baseplate: CGRect, adding pieces: [VNRecognizedObjectObservation]) {
        for piece in pieces {
            if (piece.labels[0].identifier != "6x12_green") {
                let observationBounds = VNImageRectForNormalizedRect(piece.boundingBox, Int(bufferSize.width), Int(bufferSize.height))

                let relativeObservationOrigin = CGPoint(
                    x: observationBounds.origin.x - baseplate.origin.x,
                    y: observationBounds.origin.y - baseplate.origin.y)
                

                let xGridOrigin = Int(Double(relativeObservationOrigin.x)) / Int(Double(baseplate.width / 12))
                
                let yGridOrigin = Int(Double(relativeObservationOrigin.y)) / Int(Double(baseplate.height / 6))

                guard (xGridOrigin < Constants.defaultColumnCount - 1) && (yGridOrigin < Constants.defaultRowCount - 1) else {
                    return
                }
                
                
                let pieceName = piece.labels[0].identifier
                
                guard xGridOrigin+extractWidth(pieceName) < Constants.defaultColumnCount && yGridOrigin+extractHeight(pieceName) < Constants.defaultRowCount else { return }
                
                if let gridValue = componentValues[pieceName] {
                    for x in xGridOrigin...xGridOrigin+extractWidth(pieceName) {
                        for y in yGridOrigin...yGridOrigin+extractHeight(pieceName) {
                            grid[x][y] = gridValue
                        }
                    }
                }
            }
        }
        print(grid)
    }
    
    private func extractWidth(_ size: String) -> Int {
        let dimensions = size.components(separatedBy: "_")[0]
        return Int(dimensions.components(separatedBy: "x")[1])!
    }
    
    private func extractHeight(_ size: String) -> Int {
        let dimensions = size.components(separatedBy: "_")[0]
        return Int(dimensions.components(separatedBy: "x")[0])!
    }
    
    private func setSocketEvents() {
        self.socket.on(clientEvent: .connect, callback: {data, ack in
            print("socket connected!")
            //            self.socket.emit("pingz");
        })
        
        self.socket.on("pingResult", callback: {data, ack in
            print("in pingResult")
            //            self.ping()
            // call api at '/ping' then reload result
        })
    }
    
    private func getLegoDimensions(from pieceName: String) -> String {
        return pieceName.components(separatedBy: "_")[0]
    }
    
    
    
    private struct Constants {
        static let defaultColumnCount = 12
        static let defaultRowCount = 6
    }
}
