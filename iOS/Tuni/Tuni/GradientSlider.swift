//
//  GradientSlider.swift
//  Lampi
//

import SwiftUI

struct GradientSlider: View {
    @Binding var value: Double
    var handleColor: Color = .white
    var handleImage: Image?
    var trackColors: [Color] = [.white]

    var onEditingChanged: (Double) -> Void = { _ in }

    private let sliderHeight = defaultSliderHeight

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Track(colors: trackColors)
                Handle(color: handleColor, size: sliderHeight, image: handleImage)
                    .position(x: CGFloat(value) * geometry.size.width,
                              y: sliderHeight / 2.0)
                    .gesture(DragGesture()
                                .onChanged() { gesture in
                                    let newValue = Double(gesture.location.x / geometry.size.width)
                                    value = min(max(0.0, newValue), 1.0)

                                    onEditingChanged(value)
                                }
                    )
            }
        }
        .padding(.horizontal, (sliderHeight / 2.0))
        .frame(height: sliderHeight)
    }
}

private extension GradientSlider {
    private static let defaultSliderHeight = CGFloat(40.0)

    struct Track: View {
        var colors: [Color] = [.white]

        var body: some View {
            RoundedRectangle(cornerRadius: 5.0)
                .fill(LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 5.0)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .frame(height: 10.0)
        }
    }

    struct Handle: View {
        var color: Color = .white
        var size: CGFloat = 40.0
        var image: Image?

        var body: some View {
            Circle()
                .fill(color)
                .shadow(radius: 2.0)
                .frame(height: size)
                .overlay(image)
        }
    }
}

#Preview("Slider with Handle Image") {
    GradientSlider(value: .constant(0.5), handleImage: Image(systemName: "sun.max"))
        .foregroundColor(.red) // changes color of handle image
        .previewLayout(.sizeThatFits)
}

#Preview("Base Slider with Colored Handle and Track") {
    GradientSlider(value: .constant(0.5), handleColor: .orange, trackColors: [.blue, .yellow])
        .previewLayout(.sizeThatFits)
}

#Preview("Slider with onEditingChanged") {
    GradientSlider(value: .constant(0.5)) { value in
        print("Gradient Slider changed: \(value)")
    }
    .previewLayout(.sizeThatFits)
}
#Preview("Slider Track") {
    GradientSlider.Track(colors: [.black, .white])
        .previewLayout(.sizeThatFits)
}

#Preview("Rainbow Track") {
    GradientSlider.Track(colors: Color.rainbow())
        .previewLayout(.sizeThatFits)
}

#Preview("Slider Handle") {
    GradientSlider.Handle()
        .previewLayout(.sizeThatFits)
}


extension Color {
    static func rainbow(numColors: Int = 20) -> [Color] {
        let stepDistance = 1.0 / Double(numColors)
        let colors: [Color] = (0...numColors).map {
            let hue = Double($0) * stepDistance
            return Color(hue: hue, saturation: 1.0, brightness: 1.0)
        }

        return colors
    }
}
