//
//  EditView.swift
//  BucketList
//
//  Created by Ruben Granet on 05/01/2023.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) var dismiss
    var location: Location
    var onSave: (Location) -> Void
    
    @State private var name: String
    @State private var description: String
    
    @State private var loadingState = LoadingState.loading
    @State private var pages = [Page]()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Place Name", text: $name)
                    TextField("Decription", text: $description)
                }
                
                Section {
                    switch loadingState {
                    case .loading:
                        Text("Loading...")
                    case .loaded:
                        ForEach(pages, id: \.self) { page in
                            /*@START_MENU_TOKEN@*/Text(page.title)/*@END_MENU_TOKEN@*/
                                .font(.headline)
                            + Text(":") +
                            Text(page.description)
                                .italic()
                        }
                    case .failed:
                        Text("Please try again later.")
                    }
                }
                
            }
            .navigationTitle("Place details")
            .toolbar {
                Button("Save") {
                    var newLocation = location
                    newLocation.id = UUID()
                    newLocation.name = name
                    newLocation.description = description
                    dismiss()
                }
            }
            .task {
                await fetchNearByPlaces()
            }
        }
    }
    
    
    init(location: Location, onSave: @escaping (Location) -> Void) {
        self.location = location
        self.onSave = onSave
        
        _name = State(initialValue: location.name)
        _description = State(initialValue: location.description)
    }
    
    enum LoadingState {
        case loading, loaded, failed
    }
    
    func fetchNearByPlaces() async {
        let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=\(location.coordinate.latitude)%7C\(location.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // we got some data back
            let items = try JSONDecoder().decode(Result.self, from: data)
            
            // success - convert the array values to our pages array
            pages = items.query.pages.values.sorted()
            loadingState = .loaded
        } catch {
            // if we're still here it means the request failed
            loadingState = .failed
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(location: Location.example) {newLocation in}
    }
}


