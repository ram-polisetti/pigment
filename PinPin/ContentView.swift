import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BoardView()
                .tabItem {
                    Label("Board", systemImage: "square.grid.2x2")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
        }
        .tint(.black)
    }
}
