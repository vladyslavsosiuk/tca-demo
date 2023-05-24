//
//  ShoppingCartTests.swift
//  TCADemoTests
//
//  Created by Vladyslav Sosiuk on 24.05.2023.
//

import XCTest
import ComposableArchitecture
@testable import TCADemo

@MainActor
final class ShoppingCartTests: XCTestCase {

    func testAddItem() async {
        let store = TestStore(
            initialState: ShoppingCart.State(
                items: []
            ),
            reducer: ShoppingCart()
        )
        let id = UUID()
        
        await store.send(.addItem(Item(id: id, name: "my name"))) { state in
            state.items = [Item(id: id, name: "my name")]
        }
    }
    
    func testRemoveItem() async {
        let store = TestStore(
            initialState: ShoppingCart.State(
                items: [
                    .phone
                ]
            ),
            reducer: ShoppingCart()
        )
        
        await store.send(.removeItem(.phone)) { state in
            state.items = []
        }
    }
}
