import SwiftUI
import UIKit

struct FontDebugView: View {
    @State private var availableFontFamilies: [String] = []
    @State private var spaceGroteskFontNames: [String] = []
    @State private var selectedFontFamily: String = "All"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                spaceGroteskTestSection
                sideByComparisonSection
                spaceGroteskFoundSection
                fontPathCheckSection
                allFontFamiliesSection
            }
            .navigationTitle("Font Debugger")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                loadFonts()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - View Components
    
    private var spaceGroteskTestSection: some View {
        Section(header: Text("SpaceGrotesk Test")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SpaceGrotesk-Bold (Custom)")
                    .font(.custom("SpaceGrotesk-Bold", size: 18))
                
                Text("System Font Bold (Fallback)")
                    .font(.system(size: 18, weight: .bold))
                
                Text("SpaceGrotesk-Regular (Custom)")
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                
                Text("System Font Regular (Fallback)")
                    .font(.system(size: 16, weight: .regular))
            }
            .padding(.vertical, 8)
        }
    }
    
    private var sideByComparisonSection: some View {
        Section(header: Text("SpaceGrotesk Side-by-Side Comparison")) {
            HStack(spacing: 0) {
                customFontSide
                Divider().background(Color.gray)
                systemFontSide
            }
            .listRowInsets(EdgeInsets())
        }
    }
    
    private var customFontSide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Font")
                .font(.caption)
                .foregroundColor(.secondary)
            
            customLogoText
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
    }
    
    private var customLogoText: some View {
        HStack(spacing: -0.5) {
            Text("ketchup")
                .font(.custom("SpaceGrotesk-Bold", size: 24))
                .foregroundColor(.white)
            
            Text("soon")
                .font(.custom("SpaceGrotesk-Bold", size: 24))
                .foregroundColor(.pink)
        }
        .kerning(-0.5)
    }
    
    private var systemFontSide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Font")
                .font(.caption)
                .foregroundColor(.secondary)
            
            systemLogoText
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
    }
    
    private var systemLogoText: some View {
        HStack(spacing: -0.5) {
            Text("ketchup")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("soon")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.pink)
        }
        .kerning(-0.5)
    }
    
    private var spaceGroteskFoundSection: some View {
        Section(header: Text("SpaceGrotesk Fonts Found")) {
            if spaceGroteskFontNames.isEmpty {
                Text("No SpaceGrotesk fonts found!")
                    .foregroundColor(.red)
            } else {
                ForEach(spaceGroteskFontNames, id: \.self) { fontName in
                    Text(fontName)
                        .font(.custom(fontName, size: 16, relativeTo: .body))
                }
            }
        }
    }
    
    private var fontPathCheckSection: some View {
        Section(header: Text("Font Path Check")) {
            Text("Checking Bundle Path...")
                .onAppear {
                    checkFontPaths()
                }
        }
    }
    
    private var allFontFamiliesSection: some View {
        Section(header: Text("All Font Families")) {
            fontFamilyPicker
            filteredFontList
        }
    }
    
    private var fontFamilyPicker: some View {
        Picker("Filter Font Families", selection: $selectedFontFamily) {
            Text("All").tag("All")
            ForEach(availableFontFamilies, id: \.self) { family in
                Text(family).tag(family)
            }
        }
    }
    
    private var filteredFontList: some View {
        if selectedFontFamily == "All" {
            return ForEach(availableFontFamilies.sorted(), id: \.self) { family in
                Text(family)
                    .font(.headline)
            }
        } else {
            let fontNames = UIFont.fontNames(forFamilyName: selectedFontFamily).sorted()
            return ForEach(fontNames, id: \.self) { name in
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Sample Text")
                        .font(.custom(name, size: 16, relativeTo: .body))
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadFonts() {
        // Get all available font families
        availableFontFamilies = UIFont.familyNames.sorted()
        
        // Look for SpaceGrotesk fonts specifically
        spaceGroteskFontNames = []
        
        // First check for the family name
        if let spaceGroteskIndex = availableFontFamilies.firstIndex(where: { $0.contains("Space Grotesk") || $0.contains("SpaceGrotesk") }) {
            let familyName = availableFontFamilies[spaceGroteskIndex]
            spaceGroteskFontNames = UIFont.fontNames(forFamilyName: familyName)
        }
        
        // If not found by family, search all fonts for SpaceGrotesk in the name
        if spaceGroteskFontNames.isEmpty {
            for family in availableFontFamilies {
                let familyFonts = UIFont.fontNames(forFamilyName: family)
                for font in familyFonts {
                    if font.contains("SpaceGrotesk") || font.contains("Space Grotesk") {
                        spaceGroteskFontNames.append(font)
                    }
                }
            }
        }
        
        // Debug logging
        debugLog("Available font families: \(availableFontFamilies)")
        debugLog("SpaceGrotesk fonts found: \(spaceGroteskFontNames)")
    }
    
    private func checkFontPaths() {
        // Check font file paths
        if let bundlePath = Bundle.main.resourcePath {
            let fontFilePath = bundlePath + "/Fonts/Space_Grotesk/static/SpaceGrotesk-Bold.ttf"
            let fileManager = FileManager.default
            let exists = fileManager.fileExists(atPath: fontFilePath)
            debugLog("Font path check - \(fontFilePath): \(exists ? "EXISTS" : "MISSING")")
            
            // List contents of the Fonts directory to verify structure
            if let fontsPath = Bundle.main.path(forResource: "Fonts", ofType: nil) {
                do {
                    let fontDirContents = try fileManager.contentsOfDirectory(atPath: fontsPath)
                    debugLog("Fonts directory contents: \(fontDirContents)")
                    
                    // Check Space_Grotesk directory
                    if let spaceGroteskPath = Bundle.main.path(forResource: "Space_Grotesk", ofType: nil, inDirectory: "Fonts") {
                        let spaceGroteskContents = try fileManager.contentsOfDirectory(atPath: spaceGroteskPath)
                        debugLog("Space_Grotesk directory contents: \(spaceGroteskContents)")
                        
                        // Check static directory
                        if let staticPath = Bundle.main.path(forResource: "static", ofType: nil, inDirectory: "Fonts/Space_Grotesk") {
                            let staticContents = try fileManager.contentsOfDirectory(atPath: staticPath)
                            debugLog("Space_Grotesk/static directory contents: \(staticContents)")
                        }
                    }
                } catch {
                    debugLog("Error listing font directories: \(error)")
                }
            }
        }
    }
}

extension View {
    func debugLog(_ message: String) {
        #if DEBUG
        print("FontDebugView: \(message)")
        #endif
    }
}

#Preview {
    FontDebugView()
        .preferredColorScheme(.dark)
} 