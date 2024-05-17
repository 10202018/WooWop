//
//  AnimatedButton.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/14/24.
//
import SwiftUI

struct AnimatedButton: View {
//  @State private var isPressed: Bool = false
//  
//  /// The timer used against `startTime`.
//  let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
//  
//  @State private var currentTime = Date.now
//  @State private var startTime = Date.now
  
//  var time: Int {
//    let difference = currentTime.timeIntervalSince(startTime)
//    return Int(difference)
//  }

  @State private var animationState: CGFloat = 0.0

  let effect: Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)

  @State private var isRightRotation = true // Controls rotation direction
  
  var body: some View {
    Button(action: { }) {
      Text("Continuously Animated")
        .foregroundColor(.white)
        .font(.system(size: 20, weight: .bold))
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(.blue) // Optional rotation
        )
    }
    .scaleEffect(1.0 + animationState)
    .rotationEffect(Angle.degrees(animationState * 180))
    .onAppear {
      withAnimation(effect) {
        animationState = 0.2 // Adjust for desired animation range
        
      }
    }
//    .onReceive(timer) { newTime in
//      currentTime = newTime
//      if time == 2 {
//        Text("WooWop!")
//          .foregroundColor(.white)
//          .font(.system(size: 20, weight: .bold))
//          .padding()
//          .background(
//            RoundedRectangle(cornerRadius: 10)
//              .fill(isPressed ? .orange : .blue)
//              .scaleEffect(isPressed ? 0.9 : 1.1)
//              .animation(.easeInOut, value: 0.5)
//          )
//        animateSignUpCardForSecondsOf(1.0)
//        resetTimer()
//      }
//    }
  }
  
  // MARK: Helper Methods
//  func animateSignUpCardForSecondsOf(_ duration: Double) {
//    withAnimation(.easeInOut(duration: duration)) {
//      self.rotationAngle = 360
//    }
//  }
//  func resetTimer() {
//    startTime = currentTime
//  }
}

#Preview {
  AnimatedButton()
}
