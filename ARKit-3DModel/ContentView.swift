
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            IntegratedViewController()
                .edgesIgnoringSafeArea(.all)
        }.statusBar(hidden: true)
    }
}

struct IntegratedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<IntegratedViewController>) -> ARViewController {
        let arViewController = ARViewController()
        return arViewController
    }
    func updateUIViewController(_ uiViewController: ARViewController, context: UIViewControllerRepresentableContext<IntegratedViewController>) {
    }
}
