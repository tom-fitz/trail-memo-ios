//
//  Config.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//


import Foundation

enum Config {
    static let apiBaseURL = "https://trail-memo-api-production.up.railway.app"
    
    static let mapboxAccessToken = "pk.eyJ1IjoidG9tLWZpdHpnZXJhbGQiLCJhIjoiY21pemF1azdzMG9wdzNkcHl3MWE2cDBmaCJ9.uLSqpelxA3R9HgezEtmzGQ"
        
    // Default map center (Bozeman, MT area)
    static let defaultMapLatitude: Double = 45.6789
    static let defaultMapLongitude: Double = -111.0517
    static let defaultMapZoom: Double = 12.0
}
