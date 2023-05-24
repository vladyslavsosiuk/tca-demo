//
//  ContentView.swift
//  TCADemo
//
//  Created by Vladyslav Sosiuk on 24.05.2023.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        ShoppingCartView(
            store: Store(
                initialState: ShoppingCart.State(
                    items: [
                        .phone,
                        .phone
                    ]
                ),
                reducer: ShoppingCart()
            )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func add(_ x: Int, _ y: Int) -> Int {
    return x + y
}

struct Item: Identifiable, Equatable {
    var id = UUID()
    var name: String
    
    static var phone: Item {
        Item(name: "iPhone")
    }
}

struct DeliveryAddressView: View {
    let store: StoreOf<ShoppingCart>
    
    struct ViewState: Equatable {
        let deliveryAddress: String
        
        init(_ state: ShoppingCart.State) {
            self.deliveryAddress = state.deliveryAddress
        }
    }
    
    var body: some View {
        WithViewStore(
            store,
            observe: ViewState.init
        ) { viewStore in
            Text(viewStore.deliveryAddress)
        }
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
    }
}

struct ShoppingCart: ReducerProtocol {

    struct State: Equatable {
        var items: [Item]
        var deliveryAddress: String = ""
        var checkout: Checkout.State?
    }

    enum Action: Equatable {
        case addItem(Item)
        case removeItem(Item)
        case onPresentCheckoutModalButtonTapped
        case onCheckoutModalDismissed
        case checkout(Checkout.Action)
    }
    
    var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .addItem(let newItem):
                state.items.append(newItem)
                return .none
                
            case .removeItem(let itemToRemove):
                if let indexOfItemToRemove = state.items.firstIndex(where: { $0.name == itemToRemove.name }) {
                    state.items.remove(at: indexOfItemToRemove)
                }
                return .none
                
            case .onPresentCheckoutModalButtonTapped:
                state.checkout = Checkout.State()
                return .none
                
            case .onCheckoutModalDismissed:
                state.checkout = nil
                return .none
                
            case .checkout:
                return .none
            }
        }
        .ifLet(
            \.checkout,
             action: /Action.checkout
        ) {
            Checkout()
        }
    }
}

struct ShoppingCartView: View {
    
    let store: StoreOf<ShoppingCart>
    
    struct ViewState: Equatable {
        let items: [Item]
        let isCheckoutPresented: Bool
        
        init(_ state: ShoppingCart.State) {
            self.items = state.items
            self.isCheckoutPresented = state.checkout != nil
        }
    }
    
    var body: some View {
        WithViewStore(
            store,
            observe: { state in ViewState(state) }
        ) { viewStore in
            VStack {
                HStack {
                    Button("Add item") {
                        viewStore.send(.addItem(.phone))
                    }
                    Button("Remove item") {
                        viewStore.send(.removeItem(.phone))
                    }
                }
                Button("Present checkout modal sheet") {
                    viewStore.send(.onPresentCheckoutModalButtonTapped)
                }
                DeliveryAddressView(store: store)
                List(viewStore.state.items) { item in
                    Text(item.name)
                }
            }
            .sheet(
                isPresented: viewStore.binding(
                    get: \.isCheckoutPresented,
                    send: ShoppingCart.Action.onCheckoutModalDismissed
                )
            ) {
                IfLetStore(
                    store.scope(
                        state: \.checkout,
                        action: { childAction in .checkout(childAction) }
                    )
                ) {
                    CheckoutView(
                        store: $0
                    )
                }
            }
        }
    }
}

struct Checkout: ReducerProtocol {
    struct State: Equatable {
        var isRequestInFlight: Bool = false
        var result: String = ""
    }
    
    enum Action: Equatable {
        case onCheckoutButtonTapped
        case checkoutResult(Bool)
    }
    
    @Dependency(\.checkoutService) private var checkoutService
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onCheckoutButtonTapped:
            state.isRequestInFlight = true
            return .run { send in
                let checkoutResult = await checkoutService.checkout()
                await send(.checkoutResult(checkoutResult))
            }
            
        case .checkoutResult(let success):
            state.isRequestInFlight = false
            state.result = success ? "success" : "failure"
            return .none
        }
    }
}

extension DependencyValues {
    var checkoutService: CheckoutService {
        get {
            self[CheckoutService.self]
        }
        set {
            self[CheckoutService.self] = newValue
        }
    }
}

extension CheckoutService: TestDependencyKey {
    static let testValue: CheckoutService = CheckoutService(
        checkout: unimplemented("\(Self.self).checkout", placeholder: false)
    )
}

extension CheckoutService: DependencyKey {
    static let liveValue: CheckoutService = CheckoutService(
        checkout: {
            do {
                let _ = try await URLSession.shared.data(from: URL(string: "non-ready-api.com")!)
                return true
            } catch {
                return false
            }
        }
    )
}

struct CheckoutService {
    var checkout: () async -> Bool
}

struct CheckoutView: View {
    let store: StoreOf<Checkout>
    
    var body: some View {
        WithViewStore(
            store,
            observe: { $0 }
        ) { viewStore in
            VStack {
                Button("Checkout") {
                    viewStore.send(.onCheckoutButtonTapped)
                }
                if viewStore.isRequestInFlight {
                    ProgressView()
                }
                Text(viewStore.result)
            }
        }
    }
}
