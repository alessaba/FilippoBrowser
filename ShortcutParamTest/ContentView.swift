//
//  ContentView.swift
//  ShortcutParamTest
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import Foundation

let fm = FileManager.default

struct ContentView : View {
    let dirs [String] = try? fm.contentsOfDirectory(atPath: "/") ?? [""]
    var body: some View {
        List(dirs) { dir in
            Text(dir)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
