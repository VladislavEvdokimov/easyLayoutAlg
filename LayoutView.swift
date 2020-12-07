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
    
    var generalWidth: Float?            //ширина всего ряда view
    var generalHeight: Float?           //высота всего ряда view
    var minimumGeneralWidth: Float?     //минимальная ширина всего ряда view
    var minimumGeneralHeight: Float?    //минимальная высота всего ряда view
    
    var viewWidth: Float?               //ширина отдельной view
    var viewHeight: Float?              //высота отдельной view
    var minimumWidth: Float?            //минимальное значение ширины отдельной view
    var minimumHeight: Float?           //минимальное значение высоты отдельной view
    
    var leftIndent: Float?              //отступ слева для всего ряда view
    var rightIndent: Float?             //отступ справа для всего ряда view
    var topIndent: Float?               //отступ сверху для всего ряда view
    var bottomIndent: Float?            //отступ снизу для всего ряда view
    var minimumLeftIndent: Float?       //минимальное значение отступа слева для всего ряда view
    var minimumRightIndent: Float?      //минимальное значение отступа справа для всего ряда view
    var minimumTopIndent: Float?        //минимальное значение отступа сверху для всего ряда view
    var minimumBottomIndent: Float?     //минимальное значение отступа снизу для всего ряда view
    
    var horizontalSpacing: Float?
    var verticalSpacing: Float?
    
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
    func arrangeVerticaly(items: [LayoutView], top: EdgeOffset, bottom: EdgeOffset, spacing: Float, height: ItemSize){
        switch top.type {
        case .constant:
            topIndent = top.number
        case .minimum:
            minimumTopIndent = top.number
        }
        
        switch bottom.type {
        case .constant:
            bottomIndent = bottom.number
        case .minimum:
            minimumBottomIndent = bottom.number
        }
        
        switch height.type {
        case .constant:
            generalHeight = height.number
            calculateGeneralHeightBasedViewsHeight(items: items, spacing: spacing, from: "constant")
            calculateVerticalIndent()
        case .minimum:
            minimumGeneralHeight = height.number
            calculateGeneralHeightBasedViewsHeight(items: items, spacing: spacing)
            calculateVerticalIndent()
        case .equal:
            calculateIfEqualHeight(items: items, spacing: spacing)
            calculateVerticalIndent()
        }
        verticalSpacing = spacing
    }

    
    ///считает отступы слева и справа, опираясь на заданные значения
    func arrangeHorizontaly(items: [LayoutView], left: EdgeOffset, right: EdgeOffset, spacing: Float, width: ItemSize){
        switch left.type {
        case .constant:
            leftIndent = left.number
        case .minimum:
            minimumLeftIndent = left.number
        }
        
        switch right.type {
        case .constant:
            rightIndent = right.number
        case .minimum:
            minimumRightIndent = right.number
        }
        
        switch width.type {
        case .constant:
            generalWidth = width.number
            calculateGeneralWidthBasedViewsWidth(items: items, spacing: spacing, from: "constant")
            calculateHorizontalIndent()
        case .minimum:
            minimumGeneralWidth = width.number
            calculateGeneralWidthBasedViewsWidth(items: items, spacing: spacing)
            calculateHorizontalIndent()
        case .equal:
            calculateIfEqualWidth(items: items, spacing: spacing)
            calculateHorizontalIndent()
        }
        
        horizontalSpacing = spacing
    }
    
    ///(aux) считает generalHeight, а также задает каждой view одинаковое значение высоты
    func calculateIfEqualHeight(items: [LayoutView], spacing: Float){
        if self.viewHeight != nil{
            if topIndent != nil{
                if bottomIndent != nil{
                    generalHeight = self.viewHeight! - topIndent! - bottomIndent!
                }else{
                    generalHeight = self.viewHeight! - topIndent! - minimumBottomIndent!
                    bottomIndent = minimumBottomIndent
                }
            }else{
                if bottomIndent != nil{
                    generalHeight = self.viewHeight! - bottomIndent! - minimumTopIndent!
                    topIndent = minimumTopIndent
                }else{
                    generalHeight = self.viewHeight! - minimumBottomIndent! - minimumTopIndent!
                    bottomIndent = minimumBottomIndent
                    topIndent = minimumTopIndent
                }
            }
            let numberOfItems = Float(items.count)
            let numbersOfSpacing = numberOfItems - 1
            let generalHeightWithoutSpacing = generalHeight! - numbersOfSpacing * spacing
            let heightOfSingleView = generalHeightWithoutSpacing / numberOfItems
            if generalHeightWithoutSpacing > 0{
                for item in items{
                    item.setHeight(size: SizeRuleSide(number: heightOfSingleView,type: .constant), from: "equal")
                }
            }
        }
    }

    
    ///(aux) считает generalWidth, а также задает каждой view одинаковое значение ширины
    func calculateIfEqualWidth(items: [LayoutView], spacing: Float){
        if self.viewWidth != nil{
            if leftIndent != nil{
                if rightIndent != nil{
                    generalWidth = self.viewWidth! - leftIndent! - rightIndent!
                }else{
                    generalWidth = self.viewWidth! - leftIndent! - minimumRightIndent!     //один из путей выхода из проблемы распределения размеров
                    rightIndent = minimumRightIndent
                }
            }else{
                if rightIndent != nil{
                    generalWidth = self.viewWidth! - rightIndent! - minimumLeftIndent!
                    leftIndent = minimumLeftIndent
                }else{
                    generalWidth = self.viewWidth! - minimumRightIndent! - minimumLeftIndent!
                    rightIndent = minimumRightIndent
                    leftIndent = minimumLeftIndent
                }
            }
            let numberOfItems = Float(items.count)
            let numbersOfSpacing = numberOfItems - 1
            let generalWidthWithoutSpacing = generalWidth! - numbersOfSpacing * spacing
            let widthOfSingleView = generalWidthWithoutSpacing / numberOfItems
            if generalWidthWithoutSpacing > 0{
                for item in items{
                    item.setWidth(size: SizeRuleSide(number: widthOfSingleView,type: .constant), from: "equal")
                }
            }
        }
    }
    
    ///(aux) считает generalHeight, исходя из высоты каждой отдельной view и  в случае, когда generalHeight указана константой и не сходится с посчитанным значением,  generalHeight обнуляется
    func calculateGeneralHeightBasedViewsHeight(items: [LayoutView], spacing: Float, from: String = ""){
        var heightOfAllView: Float = 0
        var counter: Int = 0
        for item in items{
            if item.viewHeight != nil{
                heightOfAllView += item.viewHeight!
                counter += 1
            }
        }
        if counter == items.count{
            let supposedGeneralHeight = heightOfAllView + (Float(items.count) - 1) * spacing
            if from == "constant"{
                if supposedGeneralHeight != generalHeight{
                    generalHeight = nil
                }
            }else{
                if supposedGeneralHeight >= minimumGeneralHeight!{
                    generalHeight = supposedGeneralHeight
                }
            }
        }
    }
    

    ///(aux) считает generalWidth, исходя из ширины каждой отдельной view и  в случае, когда generalWidth указана константой и не сходится с посчитанным значением,  generalWidth обнуляется
    func calculateGeneralWidthBasedViewsWidth(items: [LayoutView], spacing: Float, from: String = ""){
        var widthOfAllView: Float = 0
        var counter: Int = 0
        for item in items{
            if item.viewWidth != nil{
                widthOfAllView += item.viewWidth!
                counter += 1
            }
        }
        if counter == items.count{
            let supposedGeneralWidth = widthOfAllView + (Float(items.count) - 1) * spacing
            if from == "constant"{
                if supposedGeneralWidth != generalWidth{
                    generalWidth = nil
                }
            }else{
                if supposedGeneralWidth >= minimumGeneralWidth!{
                    generalWidth = supposedGeneralWidth
                }
            }
        }
    }
    
    ///(aux)считает отсупы сверху и сниза, исходя из generalHeight
    func calculateVerticalIndent(){
        if generalHeight != nil{
            if self.viewHeight != nil{
                let heightOfIndent = self.viewHeight! - generalHeight!        //Ширина отступов (слева и справа вместе)
                // зададим значения отступам, зная ширину всего ряда view
                if topIndent != nil{
                    if bottomIndent != nil{
                        if bottomIndent! + topIndent! + generalHeight! != self.viewHeight{
                            bottomIndent  = nil
                            topIndent   = nil
                            generalHeight = nil
                        }
                    }else{
                        let supposedBottomIndent = self.viewHeight! - topIndent! - generalHeight!
                        if supposedBottomIndent >= 0 && minimumBottomIndent! <= supposedBottomIndent{
                            bottomIndent = supposedBottomIndent
                        }else{
                            topIndent = nil
                            generalHeight = nil
                        }
                    }
                }else{
                    if bottomIndent == nil{
                        if heightOfIndent >= minimumTopIndent! + minimumBottomIndent!{
                            let auxIndent = heightOfIndent - minimumTopIndent! - minimumBottomIndent! / 2
                            topIndent = auxIndent + minimumTopIndent!
                            bottomIndent = auxIndent + minimumBottomIndent!
                        }else{
                            generalHeight = nil
                        }
                    }else{
                        let supposedTopIndent = self.viewHeight! - bottomIndent! - generalHeight!
                        if supposedTopIndent >= 0 && minimumTopIndent! <= supposedTopIndent{
                            topIndent = supposedTopIndent
                        }else{
                            bottomIndent = nil
                            generalHeight = nil
                        }
                    }
                }
            }
        }
    }


    ///(aux)считает отсупы слева и справа, исходя из generalWidth
    func calculateHorizontalIndent(){
        if generalWidth != nil{
            if self.viewWidth != nil{
                let widthOfIndent = self.viewWidth! - generalWidth!        //Ширина отступов (слева и справа вместе)
                // зададим значения отступам, зная ширину всего ряда view
                if leftIndent != nil{
                    if rightIndent != nil{
                        if rightIndent! + leftIndent! + generalWidth! != self.viewWidth{
                            rightIndent  = nil
                            leftIndent   = nil
                            generalWidth = nil
                        }
                    }else{
                        let supposedRightIndent = self.viewWidth! - leftIndent! - generalWidth!
                        if supposedRightIndent >= 0 && minimumRightIndent! <= supposedRightIndent{
                            rightIndent = supposedRightIndent
                        }else{
                            leftIndent = nil
                            generalWidth = nil
                        }
                    }
                }else{
                    if rightIndent == nil{
                        if widthOfIndent >= minimumLeftIndent! + minimumRightIndent!{
                            let auxIndent = widthOfIndent - minimumLeftIndent! - minimumRightIndent! / 2
                            leftIndent = auxIndent + minimumLeftIndent!
                            rightIndent = auxIndent + minimumRightIndent!
                        }else{
                            generalWidth = nil
                        }
                    }else{
                        let supposedLeftIndent = self.viewWidth! - rightIndent! - generalWidth!
                        if supposedLeftIndent >= 0 && minimumLeftIndent! <= supposedLeftIndent{
                            leftIndent = supposedLeftIndent
                        }else{
                            rightIndent = nil
                            generalWidth = nil
                        }
                    }
                }
            }
        }
    }
    
    ///(aux) задает значения координат x и  y для subview на основе отступов от краев и размеров
    func setOrigin(){
        var number: Float = 0
        var previousViewWidth: Float? = 0
        var previousViewHeight: Float? = 0
        for view in self.superview.subviews{
            if previousViewWidth != nil && view.leftIndent != nil{
                view.xOrigin = view.leftIndent! + (view.horizontalSpacing! + previousViewWidth!) * number
            }
            if previousViewHeight != nil && topIndent != nil{
                view.yOrigin = view.topIndent! + (view.verticalSpacing! + previousViewHeight!) * number
            }
            previousViewWidth = view.viewWidth
            previousViewHeight = view.viewHeight
            number += 1
        }
    }
   
    
    
    func calculateLayout(isRootView: Bool = true) -> CalculationResult{

        let oldProgress = self.progress
        
        self.setHeight(size: self.sizeRule.height)
        self.setWidth(size: self.sizeRule.height)
        
        
        for rule in self.horizontalRules{
            self.arrangeHorizontaly(items: rule.items, left: rule.left, right: rule.right, spacing: rule.spacing, width: rule.width)
        }

        
        for rule in self.verticalRules{
            self.arrangeVerticaly(items: rule.items, top: rule.top, bottom: rule.bottom, spacing: rule.spacing, height: rule.height)
        }

                                        
        if isRootView{
            if self.viewWidth == nil || self.viewHeight == nil{
                fatalError("root view size not set")
            }
            self.xOrigin = 0
            self.yOrigin = 0
        }else{
            self.setOrigin()
        }
        
        var resultStatus = CalculationResult.fulfilled
        
        // корректируем статус в зависимости от статуса чилдов
        for child in subviews {
            child.superview = self
            let childStatus = child.calculateLayout(isRootView: false)
            resultStatus = combineResults(main: resultStatus, added: childStatus)
        }
                            
        let currentViewStatus: CalculationResult
        let newProgress = self.progress
        if newProgress == 4 {
            // все параметры найдены
            currentViewStatus = .fulfilled
        } else if newProgress == oldProgress {
            // ничего не поменялось
            currentViewStatus = .unchanged
        } else {
            // что-то поменялось
            currentViewStatus = .found
        }
        resultStatus = combineResults(main: resultStatus, added: currentViewStatus)
        
        while resultStatus == .found{
            resultStatus = calculateLayout(isRootView: isRootView)
        }
        if resultStatus == .unchanged && isRootView{
            fatalError("not enough values")
        }
        
        return resultStatus
    }
    

    enum CalculationResult {
        case fulfilled // frame посчитан полностью для view и всех ее дочерних view
        case unchanged // еще остались непосчитанные значения и за время прохода ничего не изменилось
        case found // для view или для одного из его потомков найдено хотябы одно значение для frame, но не все
    }

    func combineResults(main: CalculationResult, added: CalculationResult) -> CalculationResult {
        switch added {
        case .fulfilled:
            break
        case .unchanged:
            if main != .found {
                return .unchanged
            }
        case .found:
            return .found
        }
        return main
    }
    
    func setFrame(){
        self.uiView.frame = CGRect(x: Double(self.xOrigin!), y: Double(self.yOrigin!), width: Double(self.viewWidth!), height: Double(self.viewHeight!))
        for view in self.subviews{
            view.setFrame()
        }
    }
}

