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

struct Directory : Identifiable{
	var id = UUID()
	var path : String
	var subDirs : [String] {
		do{
			let d = try fm.contentsOfDirectory(atPath: path)
			return d
		} catch {
			return [""]
		}
	}
}

struct ContentView : View {
	var body: some View {
		NavigationView {
			FileBrowser(directory: Directory(path: "/"))
		}.navigationBarTitle(Text("Landmarks"))
		
	}
}

struct FileBrowser : View {
	var directory : Directory
	
	var body: some View {
		List(directory) { item in
			NavigationButton(destination: FileBrowser(directory: Directory(path: "/"))) {
				HStack {
					Image(systemName: "doc")
					Text(item)
						.fontWeight(.semibold)
						.color(.blue)
						.padding(.leading)
					Text("0 elements")
						 .color(.secondary)
						 .padding(.leading)

			   }
			}
		}
	}
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(path: "/")
    }
}
#endif


