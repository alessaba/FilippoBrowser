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
			FileBrowser(path: "/System/Library/")
				.navigationBarTitle(Text("File Browser"))
		}
		
	}
}

struct FileBrowser : View {
	var path : String
	var subDirs : [String] {
		do{
			if path == "/System"{
				return ["Library"]
			} else if path == "usr" {
				return ["lib"]
			} else {
				return (try fm.contentsOfDirectory(atPath: path))
			}
		} catch {
			return []
		}
	}
	var body: some View {
		List(0 ..< subDirs.count) { subDir in
			NavigationButton(destination: FileBrowser(path: "self.path\(self.subDirs[subDir])/")) {
				HStack {
					Image(systemName: "doc")
					Text(self.subDirs[subDir])
						.fontWeight(.semibold)
						.color(.blue)
						.padding(.leading)
					Text("0 elements")
						 .color(.secondary)
						 .padding(.leading)

			   }
			}
		}.listStyle(.grouped)
	}
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif


