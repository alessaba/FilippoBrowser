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
	var body: some View {
		NavigationView {
			NavigationButton(destination: FileBrowser(path: "/")) {
				FileBrowser(path: "/")
			}
		}
	}
}

struct FileBrowser : View {
	var path : String = "/"
	var dirs : [String] {
		do{
			let d = try fm.contentsOfDirectory(atPath: path)
			return d
		} catch {
			return [""]
		}
		
	}
	var body: some View {
		List(0 ..< dirs.count) { item in
			HStack {
				Text(self.dirs[item])
					.fontWeight(.semibold)
					.color(.blue)
					.padding(.leading)
				Spacer()
				Text("Ciao")
			}
		}
	}
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif


