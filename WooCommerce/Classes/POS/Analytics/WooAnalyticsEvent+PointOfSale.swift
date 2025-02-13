import enum Yosemite.CardPresentPaymentOnboardingState

extension WooAnalyticsEvent {
    enum PointOfSale {
        enum CartItemType {
            case simpleProduct
            case variation
        }

        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
            static let itemType = "product_type"
            static let itemsInCart = "items_in_cart"
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }

        static func addItemToCart(type: CartItemType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleAddItemToCart, properties: [Key.itemType: type.analyticsValue])
        }

        static func checkoutTapped(_ itemsInCart: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleCheckoutTapped,
                              properties: [Key.itemsInCart: itemsInCart])
        }

        static func cardPresentCollectPaymentSuccess(milliseconds_since_customer_interaction_started: String,
                                                     milliseconds_since_order_creation_success: String,
                                                     milliseconds_since_reader_ready_to_collect_payment: String,
                                                     milliseconds_since_card_tapped: String,
                                                     checkout_tap_count: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
                "milliseconds_since_customer_interaction_started": "\(milliseconds_since_customer_interaction_started)",
                "milliseconds_since_order_creation_success": "\(milliseconds_since_order_creation_success)",
                "milliseconds_since_reader_ready_to_collect_payment": "\(milliseconds_since_reader_ready_to_collect_payment)",
                "milliseconds_since_card_tapped": "\(milliseconds_since_card_tapped)",
                "checkout_tap_count": "\(checkout_tap_count)",
            ])
        }
    }
}

private extension WooAnalyticsEvent.PointOfSale.CartItemType {
    var analyticsValue: String {
        switch self {
        case .simpleProduct:
            return "simple"
        case .variation:
            return "variation"
        }
    }
}
