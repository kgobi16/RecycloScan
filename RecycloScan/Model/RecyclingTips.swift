//
//  RecyclingTips.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import Foundation

struct RecyclingTip: Codable, Identifiable {
    let id: UUID
    let category: String
    let tip: String
    let icon: String
    
    init(category: String, tip: String, icon: String = "lightbulb.fill") {
        self.id = UUID()
        self.category = category
        self.tip = tip
        self.icon = icon
    }
}

//Recycling Tips Database
struct RecyclingTipsDatabase {
    
    static let allTips: [RecyclingTip] = [
        // Plastic Tips
        RecyclingTip(
            category: "Plastic",
            tip: "Rinse plastic containers before recycling to prevent contamination and improve recycling quality.",
            icon: "drop.fill"
        ),
        RecyclingTip(
            category: "Plastic",
            tip: "Remove caps and lids from plastic bottles before recycling - they're often made of different plastics.",
            icon: "bottle.fill"
        ),
        RecyclingTip(
            category: "Plastic",
            tip: "Check the recycling symbol on plastics - numbers 1, 2, and 5 are most commonly accepted.",
            icon: "arrow.3.trianglepath"
        ),
        RecyclingTip(
            category: "Plastic",
            tip: "Plastic bags aren't accepted in curbside recycling - return them to grocery stores instead.",
            icon: "bag.fill"
        ),
        
        // Paper Tips
        RecyclingTip(
            category: "Paper",
            tip: "Flatten cardboard boxes to save space in your blue bin and make collection easier.",
            icon: "square.fill"
        ),
        RecyclingTip(
            category: "Paper",
            tip: "Remove staples, plastic windows, and tape from envelopes before recycling.",
            icon: "envelope.fill"
        ),
        RecyclingTip(
            category: "Paper",
            tip: "Pizza boxes with grease stains should go in general waste, not paper recycling.",
            icon: "xmark.circle.fill"
        ),
        RecyclingTip(
            category: "Paper",
            tip: "Shredded paper should be placed in a paper bag before recycling to prevent jamming equipment.",
            icon: "doc.fill"
        ),
        
        // Glass Tips
        RecyclingTip(
            category: "Glass",
            tip: "Rinse glass bottles and jars before recycling. Labels can stay on!",
            icon: "wineglass.fill"
        ),
        RecyclingTip(
            category: "Glass",
            tip: "Broken glass should be wrapped in newspaper and placed in general waste, not recycling.",
            icon: "exclamationmark.triangle.fill"
        ),
        RecyclingTip(
            category: "Glass",
            tip: "Window glass, mirrors, and ceramic items can't be recycled with bottles and jars.",
            icon: "house.fill"
        ),
        
        // Metal Tips
        RecyclingTip(
            category: "Metal",
            tip: "Aluminum cans are infinitely recyclable - they can be recycled and back on shelves in 60 days!",
            icon: "cylinder.fill"
        ),
        RecyclingTip(
            category: "Metal",
            tip: "Clean aluminum foil can be recycled - scrunch it into a ball to make it easier to process.",
            icon: "circle.fill"
        ),
        RecyclingTip(
            category: "Metal",
            tip: "Empty aerosol cans completely before recycling. Remove plastic caps if possible.",
            icon: "spray.fill"
        ),
        
        // General Waste Tips
        RecyclingTip(
            category: "General",
            tip: "When in doubt, throw it out! Contaminated recycling can ruin entire batches.",
            icon: "questionmark.circle.fill"
        ),
        RecyclingTip(
            category: "General",
            tip: "Keep recyclables dry - wet cardboard and paper can't be processed and contaminate other materials.",
            icon: "cloud.rain.fill"
        ),
        RecyclingTip(
            category: "General",
            tip: "Don't bag your recyclables - place items loose in your bin so they can be sorted properly.",
            icon: "tray.fill"
        ),
        
        // Organic/Garden Waste Tips
        RecyclingTip(
            category: "Garden",
            tip: "Mix green waste (grass clippings) with brown waste (leaves) for better composting.",
            icon: "leaf.fill"
        ),
        RecyclingTip(
            category: "Garden",
            tip: "Chop larger branches into smaller pieces to help them break down faster.",
            icon: "scissors"
        ),
        RecyclingTip(
            category: "Garden",
            tip: "Keep garden waste dry until collection day to prevent odors and make bins easier to empty.",
            icon: "sun.max.fill"
        ),
        
        // E-Waste Tips
        RecyclingTip(
            category: "Electronics",
            tip: "Never throw batteries in regular bins - they can catch fire. Take them to special collection points.",
            icon: "battery.100"
        ),
        RecyclingTip(
            category: "Electronics",
            tip: "Old phones contain valuable metals. Recycle them at electronics stores or community collection events.",
            icon: "iphone"
        ),
        RecyclingTip(
            category: "Electronics",
            tip: "Wipe personal data from electronics before recycling to protect your privacy.",
            icon: "lock.fill"
        ),
        
        // Sustainability Tips
        RecyclingTip(
            category: "Sustainability",
            tip: "Reduce first, reuse second, recycle third - recycling uses energy, so avoiding waste is best!",
            icon: "arrow.triangle.2.circlepath"
        ),
        RecyclingTip(
            category: "Sustainability",
            tip: "Buy products with minimal packaging to reduce waste before it starts.",
            icon: "cart.fill"
        ),
        RecyclingTip(
            category: "Sustainability",
            tip: "One person recycling makes a difference - if everyone in your street recycles, that's tons of waste diverted!",
            icon: "person.3.fill"
        ),
        RecyclingTip(
            category: "Sustainability",
            tip: "Composting food scraps can reduce your household waste by up to 30%.",
            icon: "apple.logo"
        )
    ]
    
    // Get random tip
    static func randomTip() -> RecyclingTip {
        return allTips.randomElement() ?? allTips[0]
    }
    
    // Get tip by category
    static func tips(for category: String) -> [RecyclingTip] {
        return allTips.filter { $0.category == category }
    }
    
    // Get all categories
    static var categories: [String] {
        let categorySet = Set(allTips.map { $0.category })
        return Array(categorySet).sorted()
    }
    
    // Get tip that hasn't been shown recently
    static func randomTip(excluding recentTipIDs: [UUID]) -> RecyclingTip {
        let availableTips = allTips.filter { !recentTipIDs.contains($0.id) }
        
        if availableTips.isEmpty {
            return randomTip()
        }
        
        return availableTips.randomElement() ?? allTips[0]
    }
}
