import WidgetKit
import SwiftUI

@main
struct SonanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        SonanceLiveActivityWidget()
        NowPlayingWidget()
    }
}
