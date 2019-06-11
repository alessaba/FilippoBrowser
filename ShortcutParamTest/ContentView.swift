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
	var path : String
	var body: some View {
		NavigationView {
			FileBrowser(path: path)
				.navigationBarTitle(Text("File Browser"))
		}
		
	}
}

struct FileBrowser : View {
	var path : String
	var subDirs : [String] {
		do{
			if path == "/System/"{
				return ["Library"]
			} else if path == "/usr/" {
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
			NavigationButton(destination: FileBrowser(path: "\(self.path)\(self.subDirs[subDir])/")) {
				HStack {
					
					if isFolder("\(self.path)\(self.subDirs[subDir])/") {
						Image(systemName: "folder")
					} else if getExtension(self.subDirs[subDir]) == "png" || getExtension(self.subDirs[subDir]) == "jpg" {
						Image(systemName: "photo")
					} else if getExtension(self.subDirs[subDir]) == "plist" || getExtension(self.subDirs[subDir]) == "json"{
						Image(systemName: "list.bullet.indent")
					} else if getExtension(self.subDirs[subDir]) == "txt" {
						Image(systemName: "doc.text.fill")
					} else {
						Image(systemName: "doc")
					}
					
					Text(self.subDirs[subDir])
						.fontWeight(.semibold)
						.color(.blue)
						.padding(.leading)
					if isFolder("\(self.path)\(self.subDirs[subDir])"){
						Text("\(subfoldersCount("\(self.path)\(self.subDirs[subDir])/")) elements")
							.color(.secondary)
							.padding(.leading)
					}
					

			   }
			}
		}.listStyle(.grouped)
		
	}
}

func isFolder(_ path: String) -> Bool {
	var isFoldr : ObjCBool = false
	fm.fileExists(atPath: path, isDirectory: &isFoldr)
	return isFoldr.boolValue
}

func getExtension(_ path: String) -> String{
	let strComponents = path.split(separator: ".")
	var ext : String
	if strComponents.count > 1 {
		ext = String(strComponents[1])
	} else {
		ext = ""
	}
	return ext
}

func subfoldersCount(_ path: String) -> Int {
	do{
		let n = (try fm.contentsOfDirectory(atPath: path)).count
		return n
	} catch {
		if path == "/System" || path == "/usr"{
			return 1
		} else {
			return 0
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


