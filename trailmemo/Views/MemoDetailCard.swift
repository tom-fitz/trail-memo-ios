//
//  MemoDetailCard.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import SwiftUI

struct MemoDetailCard: View {
    let memo: Memo
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Circle()
                    .fill(getUserColor(userId: memo.userId))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(memo.userName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let parkName = memo.parkName {
                        HStack(spacing: 4) {
                            Text("📍")
                                .font(.caption)
                            Text(parkName)
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Memo text
            Text(memo.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(5)
            
            // Timestamp
            Text(memo.createdAt.timeAgo())
                .font(.caption)
                .foregroundColor(.secondary)
            
            // View details button
            Button(action: {
                // TODO: Navigate to full detail view
                print("View full details for memo: \(memo.id)")
            }) {
                HStack {
                    Spacer()
                    Text("View Full Details")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
