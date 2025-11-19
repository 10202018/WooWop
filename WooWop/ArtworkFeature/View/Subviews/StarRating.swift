//
//  StarRating.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/16/24.
//

import SwiftUI

struct StarRating: View {
  @Binding var rating: Int
  var maxRating = 5
  @Binding var bounceValue: Int
  
  var body: some View {
    HStack {
      ForEach(1 ..< (maxRating + 1), id: \.self) { value in
        HStack(alignment: .top) {
          Image(systemName: "star")
            .font(.system(size: 36))
            .symbolVariant(value <= rating ? .fill : .none)
            .foregroundStyle(.yellow)
            .frame(width: 60)
            .scaleEffect(3)
            .aspectRatio(contentMode: .fill)
            .symbolEffect(.bounce, value: bounceValue)
            .onTapGesture {
              if value != rating {
                rating = value
                bounceValue += 1
              } else {
                rating = 0
              }
            }
        }
      }
    }
  }
}

struct StarRating_Previews: PreviewProvider {
  static var previews: some View {
    StarRating(rating: .constant(3), bounceValue: .constant(1))
  }
}
