import Foundation
import Yosemite
import protocol WooFoundation.Analytics

protocol CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String? { get }

    func preflightResultReceived(_ result: CardReaderPreflightResult?)

    func trackProcessingCompletion(intent: PaymentIntent)

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData, eventData: [String: String])

    func trackPaymentFailure(with error: Error)

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource)

    func trackEmailTapped()

    func trackReceiptPrintTapped()

    func trackReceiptPrintSuccess()

    func trackReceiptPrintCanceled()

    func trackReceiptPrintFailed(error: Error)
}

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {

    }

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) {

    }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData, eventData: [String: String]) {
        // We need to map from captured eventData to POS key/values, if any
        // Then assure that eventData is coming through from POS
        let parsedValue = eventData["milliseconds_since_customer_interaction_started"] ?? "key_not_found"
        // Just for testing: We should see a value for milliseconds_since_customer_interaction_started, and empty values for the rest.
        // if we see key_not_found, then properties are not being passed from POS.
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.PointOfSale.cardPresentCollectPaymentSuccess(
            milliseconds_since_customer_interaction_started: parsedValue,
            milliseconds_since_order_creation_success: "",
            milliseconds_since_reader_ready_to_collect_payment: "",
            milliseconds_since_card_tapped: "",
            checkout_tap_count: ""))
    }

    func trackPaymentFailure(with error: any Error) {

    }

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {

    }

    func trackEmailTapped() {

    }

    func trackReceiptPrintTapped() {

    }

    func trackReceiptPrintSuccess() {

    }

    func trackReceiptPrintCanceled() {

    }

    func trackReceiptPrintFailed(error: any Error) {

    }
}

final class CollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {

    private let siteID: Int64
    private let analytics: Analytics
    private let configuration: CardPresentPaymentsConfiguration
    private let orderDurationRecorder: OrderDurationRecorderProtocol
    private var connectedReader: CardReader?
    private var paymentGatewayAccount: PaymentGatewayAccount?

    var connectedReaderModel: String? {
        connectedReader?.readerType.model
    }

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         configuration: CardPresentPaymentsConfiguration,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         connectedReader: CardReader? = nil,
         paymentGatewayAccount: PaymentGatewayAccount? = nil) {
        self.siteID = siteID
        self.analytics = analytics
        self.configuration = configuration
        self.orderDurationRecorder = orderDurationRecorder
        self.connectedReader = connectedReader
        self.paymentGatewayAccount = paymentGatewayAccount
    }

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {
        switch result {
        case .completed(let connectedReader, let paymentGatewayAccount):
            self.connectedReader = connectedReader
            self.paymentGatewayAccount = paymentGatewayAccount
        case .canceled(_, let paymentGatewayAccount):
            self.connectedReader = nil
            self.paymentGatewayAccount = paymentGatewayAccount
        case .none:
            break
        }
    }

    func trackProcessingCompletion(intent: PaymentIntent) {
        guard let paymentMethod = intent.paymentMethod() else {
            return
        }
        switch paymentMethod {
        case .interacPresent:
            analytics.track(event: .InPersonPayments
                .collectInteracPaymentSuccess(gatewayID: paymentGatewayAccount?.gatewayID,
                                              countryCode: configuration.countryCode,
                                              cardReaderModel: connectedReaderModel,
                                              siteID: siteID))
        default:
            return
        }
    }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData, eventData: [String: String]) {
        // On the IPP side, there's no additional eventData we want to capture, so would remain as it is
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .collectPaymentSuccess(forGatewayID: paymentGatewayAccount?.gatewayID,
                                   countryCode: configuration.countryCode,
                                   paymentMethod: capturedPaymentData.paymentMethod,
                                   cardReaderModel: connectedReaderModel,
                                   millisecondsSinceOrderAddNew: try? orderDurationRecorder.millisecondsSinceOrderAddNew(),
                                   millisecondsSinceCardPaymentStarted: try? orderDurationRecorder.millisecondsSinceCardPaymentStarted(),
                                   siteID: siteID))
        orderDurationRecorder.reset()
    }

    func trackPaymentFailure(with error: Error) {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentFailed(forGatewayID: paymentGatewayAccount?.gatewayID,
                                                                                       error: error,
                                                                                       countryCode: configuration.countryCode,
                                                                                       cardReaderModel: connectedReader?.readerType.model,
                                                                                       siteID: siteID))
    }

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentCanceled(forGatewayID: paymentGatewayAccount?.gatewayID,
                                                                                         countryCode: configuration.countryCode,
                                                                                         cardReaderModel: connectedReaderModel,
                                                                                         cancellationSource: cancelationSource,
                                                                                         siteID: siteID))
    }

    func trackEmailTapped() {
        analytics.track(event: .InPersonPayments
            .receiptEmailTapped(countryCode: configuration.countryCode,
                                cardReaderModel: connectedReader?.readerType.model ?? "",
                                source: .local))
    }

    func trackReceiptPrintTapped() {
        analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: configuration.countryCode,
                                                                    cardReaderModel: connectedReaderModel,
                                                                    source: .local))
    }

    func trackReceiptPrintSuccess() {
        analytics.track(event: .InPersonPayments.receiptPrintSuccess(countryCode: configuration.countryCode,
                                                                     cardReaderModel: connectedReaderModel,
                                                                     source: .local))
    }

    func trackReceiptPrintCanceled() {
        analytics.track(event: .InPersonPayments.receiptPrintCanceled(countryCode: configuration.countryCode,
                                                                      cardReaderModel: connectedReaderModel,
                                                                      source: .local))
    }

    func trackReceiptPrintFailed(error: Error) {
        analytics.track(event: .InPersonPayments.receiptPrintFailed(error: error,
                                                                    countryCode: configuration.countryCode,
                                                                    cardReaderModel: connectedReaderModel,
                                                                    source: .local))
    }
}
