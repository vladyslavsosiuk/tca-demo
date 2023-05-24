//
//  CheckoutTests.swift
//  TCADemoTests
//
//  Created by Vladyslav Sosiuk on 24.05.2023.
//

import XCTest
import ComposableArchitecture
@testable import TCADemo

@MainActor
final class CheckoutTests: XCTestCase {

    func testOnCheckoutButtonTapped_HappyPath() async {
        let store = TestStore(
            initialState: Checkout.State(),
            reducer: Checkout()
        )
        store.dependencies.checkoutService.checkout = {
            return true
        }
        
        await store.send(.onCheckoutButtonTapped) {
            $0.isRequestInFlight = true
        }
        await store.receive(.checkoutResult(true)) {
            $0.isRequestInFlight = false
            $0.result = "success"
        }
    }
    
    func testOnCheckoutButtonTapped_Failure() async {
        let store = TestStore(
            initialState: Checkout.State(),
            reducer: Checkout()
        )
        store.dependencies.checkoutService.checkout = {
            return false
        }
        
        await store.send(.onCheckoutButtonTapped) {
            $0.isRequestInFlight = true
        }
        await store.receive(.checkoutResult(false)) {
            $0.isRequestInFlight = false
            $0.result = "failure"
        }
    }
}
