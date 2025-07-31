//
//  FlutterPurchaseManager.swift
//  coreapp
//
//  Created by Assistant on 2025/01/31.
//

import Foundation
import StoreKit

/// 购买商品类型
enum PurchaseCategory {
    case consumable     // 消耗型商品（金币）
    case nonConsumable  // 非消耗型商品（VIP）
}

/// 购买交易状态
enum TransactionStatus: String {
    case idle               = "空闲状态"
    case purchasing         = "购买中"
    case completed          = "购买完成"
    case failed             = "购买失败"
    case cancelled          = "购买取消"
    case restored           = "购买恢复"
    case deferred           = "购买延期"
}

/// 购买事件代理
@objc protocol PurchaseManagerDelegate: AnyObject {
    func onProductsReceived(_ products: [[String: Any]])
    func onPurchaseUpdated(_ data: [String: Any])
    func onPurchaseCompleted(_ data: [String: Any])
    func onPurchaseFailed(_ data: [String: Any])
    func onPurchaseRestored(_ data: [String: Any])
    func onPurchaseDeferred(_ data: [String: Any])
}

/// 内购回调
typealias PurchaseCompletionHandler = (TransactionStatus, String, [String: Any]?) -> Void

@objc class FlutterPurchaseManager: NSObject {
    
    // MARK: - 单例
    @objc static let shared = FlutterPurchaseManager()
    
    // MARK: - 属性
    @objc weak var delegate: PurchaseManagerDelegate?
    private var purchaseCallback: PurchaseCompletionHandler?
    private var productInfoRequest: SKProductsRequest?
    private var currentProductCategory: PurchaseCategory = .consumable
    
    // 当前处理的商品信息
    private var processingProductId: String?
    private var availableProducts: [SKProduct] = []
    
    // MARK: - 初始化
    private override init() {
        super.init()
        setupPaymentObserver()
        setupNotifications()
    }
    
    deinit {
        cleanupResources()
    }
    
    // MARK: - 支付队列观察者设置
    private func setupPaymentObserver() {
        SKPaymentQueue.default().add(self)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSNotification.Name("UIApplicationWillTerminateNotification"),
            object: nil
        )
    }
    
    @objc private func applicationWillTerminate() {
        cleanupResources()
    }
    
    private func cleanupResources() {
        SKPaymentQueue.default().remove(self)
        productInfoRequest?.cancel()
        productInfoRequest = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 公共接口
extension FlutterPurchaseManager {
    
    /// 检查设备是否支持内购
    @objc func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// 查询商品信息
    /// - Parameters:
    ///   - productId: 商品ID
    ///   - completion: 完成回调
    @objc func requestProductInformation(productId: String, completion: @escaping (Bool, String?) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(false, "设备不支持内购")
            return
        }
        
        // 取消当前请求
        productInfoRequest?.cancel()
        
        let productIds: Set<String> = [productId]
        productInfoRequest = SKProductsRequest(productIdentifiers: productIds)
        productInfoRequest?.delegate = self
        
        // 保存回调
        purchaseCallback = { status, message, data in
            switch status {
            case .completed:
                completion(true, nil)
            case .failed:
                completion(false, message)
            default:
                break
            }
        }
        
        productInfoRequest?.start()
        NSLog("🔍 开始查询商品信息: \(productId)")
    }
    
    /// 开始购买流程
    /// - Parameters:
    ///   - productId: 商品ID
    ///   - category: 商品类型
    ///   - completion: 完成回调
    @objc func startPurchaseFlow(productId: String, isConsumable: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(false, "设备不支持内购")
            return
        }
        
        let category: PurchaseCategory = isConsumable ? .consumable : .nonConsumable
        
        // 查找已缓存的商品
        guard let product = availableProducts.first(where: { $0.productIdentifier == productId }) else {
            // 如果没有缓存，先请求商品信息
            requestProductInformation(productId: productId) { [weak self] success, error in
                if success {
                    self?.startPurchaseFlow(productId: productId, isConsumable: isConsumable, completion: completion)
                } else {
                    completion(false, error ?? "商品信息获取失败")
                }
            }
            return
        }
        
        // 设置当前处理状态
        processingProductId = productId
        currentProductCategory = category
        
        // 保存回调
        purchaseCallback = { status, message, data in
            switch status {
            case .completed:
                completion(true, nil)
            case .failed, .cancelled:
                completion(false, message)
            default:
                break
            }
        }
        
        // 创建支付请求
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        NSLog("🛒 开始购买流程: \(productId), 类型: \(category)")
    }
    
    /// 恢复购买
    @objc func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
        NSLog("🔄 开始恢复购买")
    }
    
    /// 完成交易
    /// - Parameter transactionId: 交易ID
    @objc func finishTransactionWithId(_ transactionId: String) {
        let queue = SKPaymentQueue.default()
        for transaction in queue.transactions {
            if transaction.transactionIdentifier == transactionId {
                queue.finishTransaction(transaction)
                NSLog("✅ 完成交易: \(transactionId)")
                break
            }
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension FlutterPurchaseManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        NSLog("📦 收到商品信息响应，商品数量: \(response.products.count)")
        
        if response.products.isEmpty {
            purchaseCallback?(.failed, "未找到商品信息", nil)
            return
        }
        
        // 缓存商品信息
        availableProducts.append(contentsOf: response.products)
        
        // 打印商品信息
        for product in response.products {
            NSLog("📱 商品: \(product.productIdentifier), 价格: \(product.price), 标题: \(product.localizedTitle)")
        }
        
        // 通知代理
        let productData = response.products.map { product in
            return [
                "productId": product.productIdentifier,
                "price": product.price.stringValue,
                "title": product.localizedTitle,
                "description": product.localizedDescription
            ]
        }
        
        delegate?.onProductsReceived(productData)
        purchaseCallback?(.completed, "商品信息获取成功", ["products": productData])
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("❌ 商品信息请求失败: \(error.localizedDescription)")
        purchaseCallback?(.failed, "商品信息请求失败: \(error.localizedDescription)", nil)
    }
}

// MARK: - SKPaymentTransactionObserver
extension FlutterPurchaseManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            handleTransactionUpdate(transaction)
        }
    }
    
    private func handleTransactionUpdate(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        NSLog("🔄 交易状态更新: \(productId), 状态: \(transaction.transactionState.rawValue)")
        
        switch transaction.transactionState {
        case .purchasing:
            handlePurchasingState(transaction)
            
        case .purchased:
            handlePurchasedState(transaction)
            
        case .failed:
            handleFailedState(transaction)
            
        case .restored:
            handleRestoredState(transaction)
            
        case .deferred:
            handleDeferredState(transaction)
            
        @unknown default:
            NSLog("⚠️ 未知交易状态: \(transaction.transactionState)")
            finishTransactionIfNeeded(transaction)
        }
    }
    
    private func handlePurchasingState(_ transaction: SKPaymentTransaction) {
        let data = [
            "productId": transaction.payment.productIdentifier,
            "transactionId": transaction.transactionIdentifier ?? "",
            "status": "purchasing"
        ]
        
        delegate?.onPurchaseUpdated(data)
        purchaseCallback?(.purchasing, "购买进行中", data)
    }
    
    private func handlePurchasedState(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        
        let data: [String: Any] = [
            "productId": productId,
            "transactionId": transaction.transactionIdentifier ?? "",
            "transactionDate": transaction.transactionDate?.timeIntervalSince1970 ?? 0,
            "status": "purchased",
            "receiptData": getReceiptData() ?? ""
        ]
        
        NSLog("✅ 购买成功: \(productId)")
        
        // 通知代理
        delegate?.onPurchaseCompleted(data)
        purchaseCallback?(.completed, "购买成功", data)
        
        // 注意：这里不立即finishTransaction，等Flutter处理完成后再调用
    }
    
    private func handleFailedState(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        let error = transaction.error as NSError?
        let errorMessage = error?.localizedDescription ?? "购买失败"
        
        let data = [
            "productId": productId,
            "transactionId": transaction.transactionIdentifier ?? "",
            "status": "failed",
            "errorCode": error?.code ?? -1,
            "errorMessage": errorMessage
        ] as [String : Any]
        
        NSLog("❌ 购买失败: \(productId), 错误: \(errorMessage)")
        
        // 通知代理
        delegate?.onPurchaseFailed(data)
        purchaseCallback?(.failed, errorMessage, data)
        
        // 失败的交易需要立即完成
        finishTransactionIfNeeded(transaction)
    }
    
    private func handleRestoredState(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        
        let data: [String: Any] = [
            "productId": productId,
            "transactionId": transaction.transactionIdentifier ?? "",
            "originalTransactionId": transaction.original?.transactionIdentifier ?? "",
            "transactionDate": transaction.transactionDate?.timeIntervalSince1970 ?? 0,
            "status": "restored",
            "receiptData": getReceiptData() ?? ""
        ]
        
        NSLog("🔄 购买恢复: \(productId)")
        
        // 通知代理
        delegate?.onPurchaseRestored(data)
        purchaseCallback?(.restored, "购买已恢复", data)
        
        // 注意：这里不立即finishTransaction，等Flutter处理完成后再调用
    }
    
    private func handleDeferredState(_ transaction: SKPaymentTransaction) {
        let data = [
            "productId": transaction.payment.productIdentifier,
            "transactionId": transaction.transactionIdentifier ?? "",
            "status": "deferred"
        ]
        
        NSLog("⏳ 购买延期: \(transaction.payment.productIdentifier)")
        
        // 通知代理
        delegate?.onPurchaseDeferred(data)
        purchaseCallback?(.deferred, "购买延期", data)
    }
    
    private func finishTransactionIfNeeded(_ transaction: SKPaymentTransaction) {
        if transaction.transactionState != .purchasing {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
    
    private func getReceiptData() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return nil
        }
        return receiptData.base64EncodedString()
    }
} 