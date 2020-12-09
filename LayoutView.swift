//
//  LayoutView.swift
//  coursework
//
//  Created by Pavlentiy on 02.12.2020.
//
//TODO: subview can set size to parents
//TODO: change setOrigin(delete superview)

import UIKit


class LayoutView: Decodable {
    
    var identifier: String
    var colorHex: String
    var sizeRule: SizeRule
    var verticalRules: [VerticalRule]
    var horizontalRules: [HorizontalRule]
    var subviews: [LayoutView]
    
    var uiView: UIView
    var superview: LayoutView!
    
    // этот энамчик для парсинга json
    enum CodingKeys: String, CodingKey {
        case identifier
        case colorHex
        case sizeRule
        case verticalRules
        case horizontalRules
        case subviews
        case testFrame
    }
    required init(from decoder: Decoder) throws {
        // здесь мы инициализируем из json поэтому так сложно расписано
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.colorHex = try container.decode(String.self, forKey: .colorHex)
        self.sizeRule = try container.decode(SizeRule.self, forKey: .sizeRule)
        self.subviews = try container.decode([LayoutView].self, forKey: .subviews)
        
        // тут код для парсинга json, не обращайте внимание
        var horizontalArrayContainer = try container.nestedUnkeyedContainer(forKey: .horizontalRules)
        var horizontalRules = [HorizontalRule]()
        for _ in 0..<horizontalArrayContainer.count! {
            let itemContainer = try horizontalArrayContainer.nestedContainer(keyedBy: HorizontalRule.CodingKeys.self)
            horizontalRules.append(try HorizontalRule(from: itemContainer, availabelViews: self.subviews))
        }
        self.horizontalRules = horizontalRules
        
        // тут код для парсинга json, не обращайте внимание
        var verticalArrayContainer = try container.nestedUnkeyedContainer(forKey: .verticalRules)
        var verticalRules = [VerticalRule]()
        for _ in 0..<verticalArrayContainer.count! {
            let itemContainer = try verticalArrayContainer.nestedContainer(keyedBy: VerticalRule.CodingKeys.self)
            verticalRules.append(try VerticalRule(from: itemContainer, availabelViews: self.subviews))
        }
        self.verticalRules = verticalRules
        
        
        // тут мы создаем реальную вьюшку и выставляем ей всякие параметры
        
        self.uiView = UIView()
        self.uiView.backgroundColor = UIColor(hex: self.colorHex)
        self.uiView.frame = try container.decode(CGRect.self, forKey: .testFrame)
        
        self.subviews.forEach {
            // выставляем родительскую вьюшку у каждой дочерней
            $0.superview = self
            // добавляем дочерние вьюшки в иерархию реальной
            self.uiView.addSubview($0.uiView)
        }
    }
    
    var viewWidth: Float?               //ширина отдельной view
    var viewHeight: Float?              //высота отдельной view
    var minimumWidth: Float?            //минимальное значение ширины отдельной view
    var minimumHeight: Float?           //минимальное значение высоты отдельной view
    
    var xOrigin: Float?                 //координаты view по x
    var yOrigin: Float?                 //координаты view по y
    
    

    //показывает, сколько из четырех значений (x, y, width, height) найдено для одной view
    var progress: Int {
        var result = 0
        if self.xOrigin    != nil { result += 1 }
        if self.yOrigin    != nil { result += 1 }
        if self.viewWidth  != nil { result += 1 }
        if self.viewHeight != nil { result += 1 }
        return result
    }
    
    enum AlignGroup {
        case minEdge // левая или верхняя сторона
        case center
        case maxEdge // правая или нижняя сторона
        case fill // обе стороны
    }
    
    /// должна задать ширину отдельной view, исходя из полученных данных
    func setWidth(size: SizeRuleSide, from: String = ""){
        if self.viewWidth == nil || from == "equal"{
            switch size.type {
            case .constant:
                self.viewWidth = size.number
            case .minimum:
                self.minimumWidth = size.number
            case .relativeOtherSide:
                if self.viewHeight != nil{
                    self.viewWidth = size.number * self.viewHeight!
                }
            case .relativeParant:
                if self.superview.viewWidth != nil{
                    self.viewWidth = size.number * self.superview.viewWidth!
                }
            }
        }
    }
    
    
    /// должна задать высоту отдельной view, исходя из полученных данных
    func setHeight(size: SizeRuleSide, from: String = ""){
        if self.viewHeight == nil || from == "equal"{
            switch size.type {
            case .constant:
                self.viewHeight = size.number
            case .minimum:
                self.minimumHeight = size.number
            case .relativeOtherSide:
                if self.viewWidth != nil{
                    self.viewHeight = size.number * self.viewWidth!
                }
            case .relativeParant:
                if self.superview.viewHeight != nil{
                    self.viewHeight = size.number * self.superview.viewHeight!
                }
            }
        }
    }
    
    
    ///считает отступы сверху и снизу, опираясь на заданные значения
    private func arrangeVerticaly(items: [LayoutView], top: EdgeOffset, bottom: EdgeOffset, spacing: Float, height: ItemSize){
        var align: AlignGroup
        if top.type == .minimum && bottom.type == .minimum {
            align = .center
        } else if top.type == .minimum {
            align = .maxEdge
        } else if bottom.type == .minimum {
            align = .minEdge
        } else {
            align = .fill
        }
        
        if align != .minEdge && viewHeight == nil {
            // мы не можем посчитать верхний отступ и размеры если нет высоты текущей вьюшки
            return
        }
        
        let spacingSum = Float(items.count - 1) * spacing
        switch height.type {
        case .constant:
            let itemsHeightSum = Float(items.count) * height.number
            let totalHeight = itemsHeightSum + spacingSum + top.number + bottom.number
            if align != .fill && viewHeight != nil && viewHeight! < totalHeight {
                // сумарная высота больше текущей вьюшки, поэтому мы расположим группу как .fill
                arrangeVerticaly(items: items, top: EdgeOffset(number: top.number, type: .constant), bottom: EdgeOffset(number: bottom.number, type: .constant), spacing: spacing, height: ItemSize(number: 0, type: .equal))
                return
            }
            for item in items {
                item.viewHeight = height.number
            }
            setupYOrigin(items: items, itemsHeightSum: itemsHeightSum, align: align, spacing: spacing, topOffset: top.number, bottomOffset: bottom.number)
            
        case .minimum:
            var itemsHeightSum: Float = 0
            for item in items {
                if item.viewHeight == nil {
                    // у всех вьюшек должна быть задана высота
                    return
                }
                if item.viewHeight! < height.number {
                    // если высота не удовлетворяет условию
                    item.viewHeight! = height.number
                }
                itemsHeightSum += item.viewHeight!
            }
            setupYOrigin(items: items, itemsHeightSum: itemsHeightSum, align: align, spacing: spacing, topOffset: top.number, bottomOffset: bottom.number)

        case .equal:
            let itemsHeightSum = viewHeight! - top.number - bottom.number - spacingSum
            let itemHeight = itemsHeightSum / Float(items.count)
            for item in items {
                item.viewHeight = itemHeight
            }
            setupYOrigin(items: items, itemsHeightSum: itemsHeightSum, align: align, spacing: spacing, topOffset: top.number, bottomOffset: bottom.number)
        }
    }
    private func setupYOrigin(items: [LayoutView], itemsHeightSum: Float, align: AlignGroup, spacing: Float, topOffset: Float, bottomOffset: Float) {
        let spacingSum = Float(items.count - 1) * spacing
        let totalHeight = itemsHeightSum + spacingSum + topOffset + bottomOffset
        
        let start: Float
        switch align {
        case .minEdge:
            start = topOffset
        case .fill:
            fallthrough // также как и .center
        case .center:
            start = topOffset + (viewHeight! - totalHeight) / 2
        case .maxEdge:
            start = viewHeight! - itemsHeightSum - spacingSum - bottomOffset
        }
        var nextOffset: Float = start
        for item in items {
            item.yOrigin = nextOffset
            nextOffset += item.viewHeight! + spacing
        }
    }

    
    ///считает отступы слева и справа, опираясь на заданные значения
    func arrangeHorizontaly(items: [LayoutView], left: EdgeOffset, right: EdgeOffset, spacing: Float, width: ItemSize){
        var align: AlignGroup
        if left.type == .minimum && right.type == .minimum {
            align = .center
        } else if left.type == .minimum {
            align = .maxEdge
        } else if right.type == .minimum {
            align = .minEdge
        } else {
            align = .fill
        }
        
        if align != .minEdge && viewWidth == nil {
            // мы не можем посчитать левый отступ и размеры если нет ширина текущей вьюшки
            return
        }
        
        let spacingSum = Float(items.count - 1) * spacing
        switch width.type {
        case .constant:
            let itemsWidthSum = Float(items.count) * width.number
            let totalWidth = itemsWidthSum + spacingSum + left.number + right.number
            if align != .fill && viewWidth != nil && viewWidth! < totalWidth {
                // сумарная ширина больше текущей вьюшки, поэтому мы расположим группу как .fill
                arrangeHorizontaly(items: items, left: EdgeOffset(number: left.number, type: .constant), right: EdgeOffset(number: right.number, type: .constant), spacing: spacing, width: ItemSize(number: 0, type: .equal))
                return
            }
            for item in items {
                item.viewWidth = width.number
            }
            setupXOrigin(items: items, itemsWidthSum: itemsWidthSum, align: align, spacing: spacing, leftOffset: left.number, rightOffset: right.number)
            
        case .minimum:
            var itemsWidthSum: Float = 0
            for item in items {
                if item.viewWidth == nil {
                    // у всех вьюшек должна быть задана ширина
                    return
                }
                if item.viewWidth! < width.number {
                    // если ширина не удовлетворяет условию
                    item.viewWidth! = width.number
                }
                itemsWidthSum += item.viewWidth!
            }
            setupXOrigin(items: items, itemsWidthSum: itemsWidthSum, align: align, spacing: spacing, leftOffset: left.number, rightOffset: right.number)

        case .equal:
            let itemsWidthSum = viewWidth! - left.number - right.number - spacingSum
            let itemWidth = itemsWidthSum / Float(items.count)
            for item in items {
                item.viewWidth = itemWidth
            }
            setupXOrigin(items: items, itemsWidthSum: itemsWidthSum, align: align, spacing: spacing, leftOffset: left.number, rightOffset: right.number)
        }
    }
    private func setupXOrigin(items: [LayoutView], itemsWidthSum: Float, align: AlignGroup, spacing: Float, leftOffset: Float, rightOffset: Float) {
        let spacingSum = Float(items.count - 1) * spacing
        let totalWidth = itemsWidthSum + spacingSum + leftOffset + rightOffset
        
        let start: Float
        switch align {
        case .minEdge:
            start = leftOffset
        case .fill:
            fallthrough // также как и .center
        case .center:
            start = leftOffset + (viewWidth! - totalWidth) / 2
        case .maxEdge:
            start = viewWidth! - itemsWidthSum - spacingSum - rightOffset
        }
        var nextOffset: Float = start
        for item in items {
            item.xOrigin = nextOffset
            nextOffset += item.viewWidth! + spacing
        }
    }

    
    func calculateLayout(isRootView: Bool = true) -> CalculationResult{

        let oldProgress = self.progress
        
        self.setHeight(size: self.sizeRule.height)
        self.setWidth(size: self.sizeRule.width)
        
        
        for rule in self.horizontalRules{
            self.arrangeHorizontaly(items: rule.items, left: rule.left, right: rule.right, spacing: rule.spacing, width: rule.width)
        }

        
        for rule in self.verticalRules{
            self.arrangeVerticaly(items: rule.items, top: rule.top, bottom: rule.bottom, spacing: rule.spacing, height: rule.height)
        }

                                        
        if isRootView {
            if self.viewWidth == nil || self.viewHeight == nil{
                fatalError("root view size not set")
            }
            xOrigin = 0
            yOrigin = 0
        }
        
        var resultStatus = CalculationResult(fulfulled: true, changed: false)
        
        // корректируем статус в зависимости от статуса чилдов
        for child in subviews {
            child.superview = self
            let childStatus = child.calculateLayout(isRootView: false)
            resultStatus = combineResults(main: resultStatus, added: childStatus)
        }
        
        let newProgress = self.progress
        let currentViewStatus = CalculationResult(
            fulfulled: newProgress == 4,
            changed: newProgress != oldProgress
        )
        resultStatus = combineResults(main: resultStatus, added: currentViewStatus)
        
        while resultStatus.changed {
            resultStatus = calculateLayout(isRootView: isRootView)
        }
        if !resultStatus.fulfulled && isRootView{
            fatalError("not enough values")
        }
        
        return resultStatus
    }
    

    struct CalculationResult {
        var fulfulled: Bool // true если все параметры вью и дочерних вью найдены
        var changed: Bool // true если какой-то из параметров вью или дочерних вью поменялся
    }

    func combineResults(main: CalculationResult, added: CalculationResult) -> CalculationResult {
        return CalculationResult(
            fulfulled: main.fulfulled && added.fulfulled,
            changed: main.changed || added.changed
        )
    }
    
    func setFrame(){
        self.uiView.frame = CGRect(x: Double(self.xOrigin!), y: Double(self.yOrigin!), width: Double(self.viewWidth!), height: Double(self.viewHeight!))
        for view in self.subviews{
            view.setFrame()
        }
    }
}

