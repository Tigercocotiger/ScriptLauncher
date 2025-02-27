//
//  Favorites.swift
//  ScriptLauncher
//
//  Created by MacBook-16/M1P-001 on 25/02/2025.
//


import SwiftUI

// Modèle pour les favoris
struct Favorites: Codable {
    var scriptPaths: Set<String>
}

// Modèle pour un fichier script
struct ScriptFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var isFavorite: Bool
    var lastExecuted: Date?
}

// Modèle pour une section d'aide
struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}