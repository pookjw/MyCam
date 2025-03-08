//
//  ObjCDataScannerViewController.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#if canImport(VisionKit)

import UIKit
import VisionKit
import Vision

@objc(CPDataScannerViewController)
@MainActor
public final class ObjCDataScannerViewController: UIViewController {
    @objc public static var isSupported: Bool {
        get {
            DataScannerViewController.isSupported
        }
    }
    
    @objc public static var isAvailable: Bool {
        get {
            DataScannerViewController.isAvailable
        }
    }
    
    @objc public static var supportedTextRecognitionLanguages: [String] {
        DataScannerViewController.supportedTextRecognitionLanguages
    }
    
    @objc public var qualityLevel: QualityLevel {
        QualityLevel(frameworkValue: dataScannerViewController.qualityLevel)
    }
    
    @objc public var recognizesMultipleItems: Bool {
        dataScannerViewController.recognizesMultipleItems
    }
    
    @objc public var isHighFrameRateTrackingEnabled: Bool {
        @objc(highFrameRateTrackingEnabled) get {
            dataScannerViewController.isHighFrameRateTrackingEnabled
        }
    }
    
    @objc public var isPinchToZoomEnabled: Bool {
        @objc(pinchToZoomEnabled) get {
            dataScannerViewController.isPinchToZoomEnabled
        }
    }
    
    @objc public var isGuidanceEnabled: Bool {
        @objc(guidanceEnabled) get {
            dataScannerViewController.isGuidanceEnabled
        }
    }
    
    @objc public var isHighlightingEnabled: Bool {
        @objc(highlightingEnabled) get {
            dataScannerViewController.isHighlightingEnabled
        }
    }
    
    @objc public var zoomFactor: Double {
        get {
            dataScannerViewController.zoomFactor
        }
        set {
            dataScannerViewController.zoomFactor = newValue
        }
    }
    
    @objc public var minZoomFactor: Double {
        dataScannerViewController.minZoomFactor
    }
    
    @objc public var maxZoomFactor: Double {
        dataScannerViewController.maxZoomFactor
    }
    
    @objc public var isScanning: Bool {
        @objc(scanning) get {
            dataScannerViewController.isScanning
        }
    }
    
    @objc public var overlayContainerView: UIView {
        dataScannerViewController.overlayContainerView
    }
    
    @objc public var regionOfInterest: CGRect {
        get {
            dataScannerViewController.regionOfInterest ?? .null
        }
        set {
            dataScannerViewController.regionOfInterest = newValue
        }
    }
    
    @objc public var delegate: Delegate?
    
    @objc public private(set) dynamic var recognizedItems: [RecognizedItem] = []
    
    private let dataScannerViewController: DataScannerViewController
    private var didChangeRecognizedItemsTask: Task<Void, Never>?
    
    @objc public init(
        recognizedDataTypes: Set<RecognizedDataType>,
        qualityLevel: QualityLevel,
        recognizesMultipleItems: Bool,
        isHighFrameRateTrackingEnabled: Bool,
        isPinchToZoomEnabled: Bool,
        isGuidanceEnabled: Bool,
        isHighlightingEnabled: Bool
    ) {
        let recognizedDataTypeFrameworkValues = Set(recognizedDataTypes.map { $0.frameworkValue })
        
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypeFrameworkValues,
            qualityLevel: qualityLevel.frameworkValue,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: isHighFrameRateTrackingEnabled,
            isPinchToZoomEnabled: isPinchToZoomEnabled,
            isGuidanceEnabled: isGuidanceEnabled,
            isHighlightingEnabled: isHighlightingEnabled
        )
        
        self.dataScannerViewController = dataScannerViewController
        
        super.init(nibName: nil, bundle: nil)
        
        dataScannerViewController.delegate = self
        
        didChangeRecognizedItemsTask = Task { [dataScannerViewController, weak self] in
            for await recognizedItems in dataScannerViewController.recognizedItems {
                self?.recognizedItems = recognizedItems.map { .recognizedItem(frameworkValue: $0) }
            }
        }
    }
    
    @available(*, unavailable)
    private init() {
        fatalError()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        didChangeRecognizedItemsTask?.cancel()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataScannerViewController = dataScannerViewController
        addChild(dataScannerViewController)
        let dataScannerView = dataScannerViewController.view!
        let view = view!
        dataScannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dataScannerView)
        NSLayoutConstraint.activate([
            dataScannerView.topAnchor.constraint(equalTo: view.topAnchor),
            dataScannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataScannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dataScannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dataScannerViewController.didMove(toParent: self)
    }
    
    @objc public func startScanning() throws {
        try dataScannerViewController.startScanning()
    }
    
    @objc public func stopScanning() {
        dataScannerViewController.stopScanning()
    }
    
    @objc public func capturePhoto() async throws -> UIImage {
        try await dataScannerViewController.capturePhoto()
    }
}

extension ObjCDataScannerViewController {
    @objc(CPDataScannerQualityLevel) public enum QualityLevel: Int {
        case balanced
        case fast
        case accurate
        
        fileprivate init(frameworkValue: DataScannerViewController.QualityLevel) {
            switch frameworkValue {
            case .balanced:
                self = .balanced
            case .fast:
                self = .fast
            case .accurate:
                self = .accurate
            @unknown default:
                fatalError()
            }
        }
        
        fileprivate var frameworkValue: DataScannerViewController.QualityLevel {
            switch self {
            case .balanced:
                return .balanced
            case .fast:
                return .fast
            case .accurate:
                return .accurate
            }
        }
    }
}

extension ObjCDataScannerViewController {
    @objc(CPDataScannerRecognizedDataType) public final class RecognizedDataType: NSObject {
        fileprivate let frameworkValue: DataScannerViewController.RecognizedDataType
        
        @objc(textDataTypeWithLanguages:textContentType:) public static func text(languages: [String], textContentType: TextContentType) -> RecognizedDataType {
            RecognizedDataType(
                frameworkValue: .text(
                    languages: languages,
                    textContentType: textContentType.frameworkValue
                )
            )
        }
        
        @objc(barcodeDataTypeWithSymbologies:) public static func barcode(symbologies: [VNBarcodeSymbology]) -> RecognizedDataType {
            RecognizedDataType(frameworkValue: .barcode(symbologies: symbologies))
        }
        
        private init(frameworkValue: DataScannerViewController.RecognizedDataType) {
            self.frameworkValue = frameworkValue
            super.init()
        }
        
        private override init() {
            fatalError()
        }
        
        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? RecognizedDataType else {
                return false
            }
            
            return frameworkValue == other.frameworkValue
        }
        
        public override var hash: Int {
            frameworkValue.hashValue
        }
    }
}

extension ObjCDataScannerViewController.RecognizedDataType {
    @objc(CPDataScannerTextContentType) public enum TextContentType: Int {
        case none
        case URL
        case dateTimeDuration
        case emailAddress
        case flightNumber
        case fullStreetAddress
        case shipmentTrackingNumber
        case telephoneNumber
        case currency
        
        fileprivate init(frameworkValue: DataScannerViewController.TextContentType) {
            switch frameworkValue {
            case .URL:
                self = .URL
            case .dateTimeDuration:
                self = .dateTimeDuration
            case .emailAddress:
                self = .emailAddress
            case .flightNumber:
                self = .flightNumber
            case .fullStreetAddress:
                self = .fullStreetAddress
            case .shipmentTrackingNumber:
                self = .shipmentTrackingNumber
            case .telephoneNumber:
                self = .telephoneNumber
            case .currency:
                self = .currency
            @unknown default:
                fatalError()
            }
        }
        
        fileprivate var frameworkValue: DataScannerViewController.TextContentType? {
            switch self {
            case .none:
                return nil
            case .URL:
                return .URL
            case .dateTimeDuration:
                return .dateTimeDuration
            case .emailAddress:
                return .emailAddress
            case .flightNumber:
                return .flightNumber
            case .fullStreetAddress:
                return .fullStreetAddress
            case .shipmentTrackingNumber:
                return .shipmentTrackingNumber
            case .telephoneNumber:
                return .telephoneNumber
            case .currency:
                return .currency
            }
        }
    }
}

extension ObjCDataScannerViewController {
    @objc(DataScannerUnavailableReason) public enum ScanningUnavailable: Int {
        case unsupported
        case cameraRestricted
        
        fileprivate init(frameworkValue: DataScannerViewController.ScanningUnavailable) {
            switch frameworkValue {
            case .unsupported:
                self = .unsupported
            case .cameraRestricted:
                self = .cameraRestricted
            @unknown default:
                fatalError()
            }
        }
        
        fileprivate var frameworkValue: DataScannerViewController.ScanningUnavailable {
            switch self {
            case .unsupported:
                return .unsupported
            case .cameraRestricted:
                return .cameraRestricted
            }
        }
    }
}

@_cdecl("localizedDescriptionFromDataScannerUnavailableReason") public func localizedDescriptionFromDataScannerUnavailableReason(reason: Int) -> NSString {
    ObjCDataScannerViewController.ScanningUnavailable(rawValue: reason)!.frameworkValue.localizedDescription as NSString
}

extension ObjCDataScannerViewController: DataScannerViewControllerDelegate {
    public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {
        delegate?.dataScannerDidZoom?(self)
    }
    
    public func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: VisionKit.RecognizedItem) {
        delegate?
            .dataScanner?(
                self,
                didTapOn: ObjCDataScannerViewController
                    .RecognizedItem
                    .recognizedItem(frameworkValue: item)
            )
    }
    
    public func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [VisionKit.RecognizedItem], allItems: [VisionKit.RecognizedItem]) {
        delegate?
            .dataScanner?(
                self,
                didAdd: addedItems.map { .recognizedItem(frameworkValue: $0) },
                allItems: allItems.map { .recognizedItem(frameworkValue: $0) }
            )
    }
    
    public func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [VisionKit.RecognizedItem], allItems: [VisionKit.RecognizedItem]) {
        delegate?
            .dataScanner?(
                self,
                didUpdate: updatedItems.map { .recognizedItem(frameworkValue: $0) },
                allItems: allItems.map { .recognizedItem(frameworkValue: $0) }
            )
    }
    
    public func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [VisionKit.RecognizedItem], allItems: [VisionKit.RecognizedItem]) {
        delegate?
            .dataScanner?(
                self,
                didRemove: removedItems.map { .recognizedItem(frameworkValue: $0) },
                allItems: allItems.map { .recognizedItem(frameworkValue: $0) }
            )
    }
    
    public func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
        delegate?
            .dataScanner?(
                self,
                becameUnavailableWithError: ScanningUnavailable(frameworkValue: error)
            )
    }
}

extension ObjCDataScannerViewController {
    @objc(CPDataScannerViewControllerDelegate) public protocol Delegate: AnyObject {
        @objc @MainActor optional func dataScannerDidZoom(_ dataScanner: ObjCDataScannerViewController)
        @objc @MainActor optional func dataScanner(_ dataScanner: ObjCDataScannerViewController, didTapOn item: ObjCDataScannerViewController.RecognizedItem)
        @objc @MainActor optional func dataScanner(_ dataScanner: ObjCDataScannerViewController, didAdd addedItems: [ObjCDataScannerViewController.RecognizedItem], allItems: [ObjCDataScannerViewController.RecognizedItem])
        @objc @MainActor optional func dataScanner(_ dataScanner: ObjCDataScannerViewController, didUpdate updatedItems: [ObjCDataScannerViewController.RecognizedItem], allItems: [ObjCDataScannerViewController.RecognizedItem])
        @objc @MainActor optional func dataScanner(_ dataScanner: ObjCDataScannerViewController, didRemove removedItems: [ObjCDataScannerViewController.RecognizedItem], allItems: [ObjCDataScannerViewController.RecognizedItem])
        @objc @MainActor optional func dataScanner(_ dataScanner: ObjCDataScannerViewController, becameUnavailableWithError error: ObjCDataScannerViewController.ScanningUnavailable)
    }
}

extension ObjCDataScannerViewController {
    @objc(CPDataScannerRecognizedItem) public class RecognizedItem: NSObject {
        fileprivate static func recognizedItem(frameworkValue: VisionKit.RecognizedItem) -> RecognizedItem {
            switch frameworkValue {
            case .text(let text):
                return RecognizedTextItem(frameworkValue: text)
            case .barcode(let barcode):
                return RecognizedBarcodeItem(frameworkValue: barcode)
            @unknown default:
                fatalError()
            }
        }
        
        fileprivate override init() {
            super.init()
        }
    }
    
    @objc(CPDataScannerRecognizedBarcodeItem) public class RecognizedBarcodeItem: RecognizedItem {
        @objc public var payloadStringValue: String? {
            frameworkValue.payloadStringValue
        }
        
        @objc public var bounds: Bounds {
            Bounds(frameworkValue: frameworkValue.bounds)
        }
        
        @objc public var observation: VNBarcodeObservation {
            frameworkValue.observation
        }
        
        @objc(uuid) public var id: UUID {
            frameworkValue.id
        }
        
        private let frameworkValue: VisionKit.RecognizedItem.Barcode
        
        fileprivate init(frameworkValue: VisionKit.RecognizedItem.Barcode) {
            self.frameworkValue = frameworkValue
            super.init()
        }
        
        fileprivate override init() {
            fatalError()
        }
        
        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? RecognizedBarcodeItem else {
                return false
            }
            
            return frameworkValue.id == other.frameworkValue.id
        }
        
        public override var hash: Int {
            frameworkValue.id.hashValue
        }
        
        public override var description: String {
            String(format: "<%@: %p> payloadStringValue: %@", arguments: [NSStringFromClass(type(of: self)), self, payloadStringValue ?? "nil"])
        }
    }
    
    @objc(CPDataScannerRecognizedTextItem) public class RecognizedTextItem: RecognizedItem {
        @objc public var transcript: String {
            frameworkValue.transcript
        }
        
        @objc public var bounds: Bounds {
            Bounds(frameworkValue: frameworkValue.bounds)
        }
        
        @objc(uuid) public var id: UUID {
            frameworkValue.id
        }
        
        @objc public var observation: VNRecognizedTextObservation {
            frameworkValue.observation
        }
        
        private let frameworkValue: VisionKit.RecognizedItem.Text
        
        fileprivate init(frameworkValue: VisionKit.RecognizedItem.Text) {
            self.frameworkValue = frameworkValue
            super.init()
        }
        
        fileprivate override init() {
            fatalError()
        }
        
        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? RecognizedTextItem else {
                return false
            }
            
            return frameworkValue.id == other.frameworkValue.id
        }
        
        public override var hash: Int {
            frameworkValue.id.hashValue
        }
        
        public override var description: String {
            String(format: "<%@: %p> transcript: %@", arguments: [NSStringFromClass(type(of: self)), self, transcript])
        }
    }
    
    @objc(CPDataScannerRecognizedItemBounds) public final class Bounds: NSObject {
        @objc public var topLeft: CGPoint {
            frameworkValue.topLeft
        }
        
        @objc public var topRight: CGPoint {
            frameworkValue.topRight
        }
        
        @objc public var bottomRight: CGPoint {
            frameworkValue.bottomRight
        }
        
        @objc public var bottomLeft: CGPoint {
            frameworkValue.bottomLeft
        }
        
        private let frameworkValue: VisionKit.RecognizedItem.Bounds
        
        fileprivate init(frameworkValue: VisionKit.RecognizedItem.Bounds) {
            self.frameworkValue = frameworkValue
            super.init()
        }
        
        private override init() {
            fatalError()
        }
        
        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Bounds else {
                return false
            }
            
            return (frameworkValue.topLeft == other.frameworkValue.topLeft) &&
            (frameworkValue.topRight == other.frameworkValue.topRight) &&
            (frameworkValue.bottomRight == other.frameworkValue.bottomRight) &&
            (frameworkValue.bottomLeft == other.frameworkValue.bottomLeft)
        }
    }
}

#endif
