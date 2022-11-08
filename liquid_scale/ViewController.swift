//
//  ViewController.swift
//  liquid_scale
//
//  Created by Baiaman Apsamatov on 6/7/22.
//

import UIKit

enum NavBar {
 case top
 case bottom
}

enum NavBarButton {
    case menu
    case settings
    case more
    case stats
}

enum PointLabel {
    case topPoint
    case topNeedPoint
    case bottomPoint
    case bottomHavePoint
}

class ViewController: UIViewController {
    lazy var topNavbar: UIView = self.makeNavBar()
    lazy var bottomNavBar: UIView = self.makeNavBar(typeNavBar: .bottom)
    
    lazy var menuButton: UIButton = self.makeNavBarButton()
    lazy var settings: UIButton = self.makeNavBarButton(type: .settings)
    lazy var more: UIButton = self.makeNavBarButton(type: .more)
    lazy var stats: UIButton = self.makeNavBarButton(type: .stats)
    
    lazy var topPointLabel: UILabel = self.makeLabel(typeLabel: .topPoint)
    lazy var tophavePointsLabel: UILabel = self.makeLabel(typeLabel: .topNeedPoint)
    lazy var bottomPointLabel: UILabel = self.makeLabel(typeLabel: .bottomPoint)
    lazy var bottomHavePointLabel: UILabel = self.makeLabel(typeLabel: .bottomHavePoint)
    
    lazy var beginOfScale: UIView = self.makeCanvasView()
    lazy var endOfScale: UIView = self.makeCanvasView()
    lazy var scaleViews: [UIView] = self.makeScaleViews()
    
    lazy var canvasView: UIView = self.makeCanvasView()
    lazy var shapeLayer: CAShapeLayer = self.makeShapeLayer()
    
    lazy var leftEdgeView: UIView = self.makeCurvePointView()
    lazy var centerView: UIView = self.makeCurvePointView()
    lazy var rightEdgeView: UIView = self.makeCurvePointView()
    
    private var displayRefresh: CADisplayLink = CADisplayLink()
    private var percent: CGFloat = .zero
    private var flag: Bool = true
    lazy var checkCurveView: UIView = self.makeCurvePointView()
    private var topPercent: Int = 50
    private var bottomPercent: Int = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.configureConstraints()
        self.settingsOfScale()
        
        self.checkCurveView.backgroundColor = UIColor.clear
        self.checkCurveView.frame.size = .init(width: 1.0, height: 1.0)
        
        let panGesure = UIPanGestureRecognizer(target: self, action: #selector(self.canvasGesture(sender:)))
        self.canvasView.addGestureRecognizer(panGesure)
        self.refreshSettings()
        self.setupFontSizeOfPoints()
    }
    
    func refreshSettings() {
        self.displayRefresh = CADisplayLink(target: self, selector: #selector(self.refreshDraw))
        self.displayRefresh.add(to: .main, forMode: .default)
        self.displayRefresh.isPaused = true
    }
    
    func setupFontSizeOfPoints() {
        self.topPointLabel.font = .systemFont(ofSize: 50.0)
        self.tophavePointsLabel.font = .boldSystemFont(ofSize: 25.0)
        self.bottomPointLabel.font = .systemFont(ofSize: 50.0)
        self.bottomHavePointLabel.font = .boldSystemFont(ofSize: 25.0)
        
        self.bottomPointLabel.textColor = .white
        self.bottomHavePointLabel.textColor = .white
    }
    
    func changePositionOfLabels(translation: CGPoint) {
        let percentOfWay: Int = Int((self.checkCurveView.center.y / self.canvasView.bounds.height) * 100)
        if (translation.y > 0.0) {
            self.topPercent = percentOfWay == 100  ? 100 : abs(percentOfWay)
            self.bottomPercent = percentOfWay == 100 ? 100 : abs(100-percentOfWay)
        } else if (translation.y < 0.0) {
            self.topPercent = abs(percentOfWay)
            self.bottomPercent = percentOfWay == 100 ? 100 : abs(100-percentOfWay)
        }
        
        self.topPointLabel.center.y = self.checkCurveView.frame.origin.y - 55.0
        self.tophavePointsLabel.center.y = self.topPointLabel.center.y
        self.bottomPointLabel.frame.origin.y = self.checkCurveView.getAbsolutePosition().y + 45.0
        self.bottomHavePointLabel.center.y = self.bottomPointLabel.center.y
        
        let increaseFontSizeTopPointLabel: CGFloat = (CGFloat(self.topPercent) / 100.0) * 50.0
        let increaseFontSizeBottomPointLabel: CGFloat = (CGFloat(self.bottomPercent) / 100.0) * 50.0
        let increaseFontSizeTopHavePointTitleLabel: CGFloat = (CGFloat(self.topPercent) / 100.0) * 25.0
        let increaseFontSizeBottomHavePointTitleLabel: CGFloat = (CGFloat(self.bottomPercent) / 100.0) * 25.0
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.topPointLabel.font = .systemFont(ofSize: increaseFontSizeTopPointLabel)
            self.tophavePointsLabel.font = .systemFont(ofSize: increaseFontSizeTopHavePointTitleLabel)
            self.bottomPointLabel.font = .systemFont(ofSize: increaseFontSizeBottomPointLabel)
            self.bottomHavePointLabel.font = .systemFont(ofSize: increaseFontSizeBottomHavePointTitleLabel)
            self.topPointLabel.text = String(self.topPercent) + " %"
            self.bottomPointLabel.text = String(self.bottomPercent) + " %"
        }
    }
    
   @objc func refreshDraw() {
       replacementPath()
    }
    
    @objc func canvasGesture(sender: UIPanGestureRecognizer) {
        let translation: CGPoint = sender.translation(in: self.canvasView)
        let locationPoint: CGPoint = sender.location(in: self.canvasView)
        if (translation.y > 0.0) {
            let percentOfWay = self.checkCurveView.center.y / self.canvasView.bounds.height
            if (Int(percentOfWay * 100.0) != 100) {
                self.centerView.frame.origin.y += abs(translation.y)
            } else {
                self.checkCurveView.center.y = self.canvasView.bounds.maxY
            }
        } else {
            let percentOfWay = self.checkCurveView.center.y / self.canvasView.bounds.height
            if (Int(percentOfWay * 100.0) != 0) {
                self.centerView.frame.origin.y -= abs(translation.y)
            } else {
                self.checkCurveView.center.y = self.canvasView.bounds.minY
            }
        }
        self.centerView.center.x = locationPoint.x
        self.checkCurveView.center = self.caculateMidPoint()
        changePositionOfLabels(translation: translation)
        self.redrawBezier()
        sender.setTranslation(.zero, in: self.canvasView)
        
        if (sender.state == .ended) {
            self.canvasView.isUserInteractionEnabled = false
            self.displayRefresh.isPaused = false
            
            UIView.animate(withDuration: 0.08) {
                self.topPointLabel.center.y = self.checkCurveView.frame.origin.y - 15.0
                self.tophavePointsLabel.center.y = self.topPointLabel.center.y
                self.bottomPointLabel.frame.origin.y = self.checkCurveView.getAbsolutePosition().y + 5.0
                self.bottomHavePointLabel.center.y = self.bottomPointLabel.center.y
            }

            UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.27, initialSpringVelocity: 0) { [weak self] in
                guard let self = self else { return }
                self.topPointLabel.center.y = self.checkCurveView.frame.origin.y - 55.0
                self.tophavePointsLabel.center.y = self.topPointLabel.center.y
                self.bottomPointLabel.frame.origin.y = self.checkCurveView.getAbsolutePosition().y + 45.0
                self.bottomHavePointLabel.center.y = self.bottomPointLabel.center.y
                self.leftEdgeView.center.y = self.checkCurveView.center.y
                self.rightEdgeView.center.y = self.checkCurveView.center.y
                self.centerView.center = self.checkCurveView.center
            } completion: {[weak self] _ in
                guard let self = self else { return }
                self.centerView.center.x = self.canvasView.center.x
                self.checkCurveView.center = self.centerView.center
                self.canvasView.isUserInteractionEnabled = true
                self.displayRefresh.isPaused = true
            }
        }
    }
    
    func redrawBezier() {
        let sizeOfParentView = self.canvasView.bounds
        let bezier = UIBezierPath()
        bezier.move(to: self.leftEdgeView.getAbsolutePosition())
        bezier.addQuadCurve(to: self.rightEdgeView.getAbsolutePosition(), controlPoint: self.centerView.getAbsolutePosition())
        bezier.addLine(to: CGPoint(x: sizeOfParentView.maxX, y: sizeOfParentView.maxY))
        bezier.addLine(to: CGPoint(x: sizeOfParentView.minX, y: sizeOfParentView.maxY))
        bezier.close()
        self.shapeLayer.path = bezier.cgPath
    }
    
    func replacementPath() {
        let sizeOfParentView = self.canvasView.bounds
        let bezier = UIBezierPath()
        bezier.move(to: self.leftEdgeView.getAbsolutePosition())
        bezier.addQuadCurve(to: self.rightEdgeView.getAbsolutePosition(), controlPoint: self.checkCurveView.getAbsolutePosition())
        bezier.addLine(to: CGPoint(x: sizeOfParentView.maxX, y: sizeOfParentView.maxY))
        bezier.addLine(to: CGPoint(x: sizeOfParentView.minX, y: sizeOfParentView.maxY))
        bezier.close()
        self.shapeLayer.path = bezier.cgPath
    }
     
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (self.flag) {
            self.flag = false
            self.shapeLayer.frame = self.canvasView.bounds
            self.canvasView.backgroundColor = .white
            self.setupControlPoint()
        }
    }
    
    func settingsOfScale() {
        let color = UIColor.cyan.withAlphaComponent(0.5)
        let radius: CGFloat = 2.0
        (self.beginOfScale.backgroundColor, self.endOfScale.backgroundColor) = (color, color)
        (self.beginOfScale.layer.cornerRadius, self.endOfScale.layer.cornerRadius) = (radius, radius)
    }
    
    func setupControlPoint() {
        let sizeOfParentView = self.canvasView.bounds
        
        self.leftEdgeView.center = .init(x: -10.0, y: sizeOfParentView.midY)
        self.centerView.center = .init(x: 0.0, y: sizeOfParentView.midY)
        self.rightEdgeView.center = .init(x: sizeOfParentView.maxX + 10.0, y: sizeOfParentView.midY)
        
        let bezier = UIBezierPath()
        bezier.move(to: self.leftEdgeView.center)
        bezier.addQuadCurve(to: self.rightEdgeView.center, controlPoint: self.centerView.center)
        bezier.addLine(to: CGPoint(x: sizeOfParentView.maxX, y: sizeOfParentView.maxY))
        bezier.addLine(to: CGPoint(x: sizeOfParentView.minX, y: sizeOfParentView.maxY))
        bezier.close()
        self.shapeLayer.path = bezier.cgPath
        self.placementScales()
        
        self.checkCurveView.center = self.centerView.center
    }
    
    func placementScales() {
        let rateStep: CGFloat = (self.canvasView.bounds.height - 6) / 13.0
        var delta: CGFloat = rateStep
        for item in self.scaleViews {
            
            item.frame.origin.y = delta
            item.frame.origin.x = self.canvasView.bounds.width - item.frame.size.width - 20.0
            self.canvasView.addSubview(item)
            delta += rateStep
        }
    }
}

extension ViewController {
    
    func setupViews() {
        self.view.addSubview(self.topNavbar)
        self.topNavbar.addSubview(self.menuButton)
        self.topNavbar.addSubview(self.settings)
        
        self.view.addSubview(self.bottomNavBar)
        self.bottomNavBar.addSubview(self.more)
        self.bottomNavBar.addSubview(self.stats)
        
        self.view.addSubview(self.canvasView)
        self.canvasView.layer.addSublayer(self.shapeLayer)
        
        self.canvasView.addSubview(self.leftEdgeView)
        self.canvasView.addSubview(self.centerView)
        self.canvasView.addSubview(self.rightEdgeView)
        
        self.canvasView.addSubview(self.beginOfScale)
        self.canvasView.addSubview(self.endOfScale)
        
        self.canvasView.addSubview(self.checkCurveView)
        
        self.canvasView.addSubview(self.topPointLabel)
        self.canvasView.addSubview(self.tophavePointsLabel)
        
        self.canvasView.addSubview(self.bottomPointLabel)
        self.canvasView.addSubview(self.bottomHavePointLabel)
        self.topPointLabel.text = "50 %"
        self.bottomPointLabel.text = "50 %"
    }
    
    func configureConstraints() {
        NSLayoutConstraint.activate([
            self.topNavbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.topNavbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.topNavbar.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.topNavbar.heightAnchor.constraint(equalToConstant: 80.0),
            
            self.menuButton.leadingAnchor.constraint(equalTo: self.topNavbar.leadingAnchor, constant: 20.0),
            self.menuButton.bottomAnchor.constraint(equalTo: self.topNavbar.bottomAnchor, constant: -5.0),
            self.menuButton.heightAnchor.constraint(equalToConstant: 30.0),
            
            self.settings.trailingAnchor.constraint(equalTo: self.topNavbar.trailingAnchor, constant: -20.0),
            self.settings.bottomAnchor.constraint(equalTo: self.topNavbar.bottomAnchor, constant: -5.0),
            self.settings.heightAnchor.constraint(equalToConstant: 30.0),
            
            self.bottomNavBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.bottomNavBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.bottomNavBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.bottomNavBar.heightAnchor.constraint(equalToConstant: 80.0),
            
            self.more.leadingAnchor.constraint(equalTo: self.bottomNavBar.leadingAnchor, constant: 20.0),
            self.more.heightAnchor.constraint(equalToConstant: 30.0),
            self.more.centerYAnchor.constraint(equalTo: self.bottomNavBar.centerYAnchor),
            
            self.stats.trailingAnchor.constraint(equalTo: self.bottomNavBar.trailingAnchor, constant: -20.0),
            self.stats.centerYAnchor.constraint(equalTo: self.bottomNavBar.centerYAnchor),
            self.stats.heightAnchor.constraint(equalToConstant: 30.0),
            
            self.canvasView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.canvasView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.canvasView.topAnchor.constraint(equalTo: self.topNavbar.bottomAnchor),
            self.canvasView.bottomAnchor.constraint(equalTo: self.bottomNavBar.topAnchor),
            
            self.beginOfScale.topAnchor.constraint(equalTo: self.canvasView.topAnchor),
            self.beginOfScale.trailingAnchor.constraint(equalTo: self.canvasView.trailingAnchor, constant: -20.0),
            self.beginOfScale.widthAnchor.constraint(equalTo: self.canvasView.widthAnchor, multiplier: 1/4.2),
            self.beginOfScale.heightAnchor.constraint(equalToConstant: 3.0),
            
            self.endOfScale.trailingAnchor.constraint(equalTo: self.canvasView.trailingAnchor, constant: -20.0),
            self.endOfScale.widthAnchor.constraint(equalTo: self.beginOfScale.widthAnchor),
            self.endOfScale.heightAnchor.constraint(equalToConstant: 3.0),
            self.endOfScale.bottomAnchor.constraint(equalTo: self.canvasView.bottomAnchor),
            
            self.centerView.centerXAnchor.constraint(equalTo: self.canvasView.centerXAnchor),
            self.centerView.centerYAnchor.constraint(equalTo: self.canvasView.centerYAnchor),
            self.centerView.widthAnchor.constraint(equalToConstant: 10.0),
            self.centerView.heightAnchor.constraint(equalToConstant: 10.0),
            
            self.topPointLabel.bottomAnchor.constraint(equalTo: self.centerView.topAnchor, constant: -40.0),
            self.topPointLabel.centerXAnchor.constraint(equalTo: self.centerView.centerXAnchor, constant: -50.0),
            self.topPointLabel.widthAnchor.constraint(equalToConstant: 80.0),
            self.topPointLabel.heightAnchor.constraint(equalToConstant: 70.0),
            self.tophavePointsLabel.leadingAnchor.constraint(equalTo: self.topPointLabel.trailingAnchor),
            self.tophavePointsLabel.centerYAnchor.constraint(equalTo: self.topPointLabel.centerYAnchor),
            self.tophavePointsLabel.heightAnchor.constraint(equalToConstant: 50.0),
            self.tophavePointsLabel.widthAnchor.constraint(equalToConstant: 70.0),

            self.bottomPointLabel.topAnchor.constraint(equalTo: self.centerView.bottomAnchor, constant: 40.0),
            self.bottomPointLabel.widthAnchor.constraint(equalToConstant: 80.0),
            self.bottomPointLabel.heightAnchor.constraint(equalToConstant: 70.0),
            self.bottomPointLabel.centerXAnchor.constraint(equalTo: self.topPointLabel.centerXAnchor),
            self.bottomHavePointLabel.leadingAnchor.constraint(equalTo: self.bottomPointLabel.trailingAnchor, constant: 0),
            self.bottomHavePointLabel.centerYAnchor.constraint(equalTo: self.bottomPointLabel.centerYAnchor),
            self.bottomHavePointLabel.heightAnchor.constraint(equalToConstant: 50.0),
            self.bottomHavePointLabel.widthAnchor.constraint(equalToConstant: 70.0)
        ])
    }
    
    func caculateMidPoint() -> CGPoint {
        let summPointX = pow(1-0.5, 2.0) * self.leftEdgeView.center.x + 2 * (1-0.5) * 0.5 * self.centerView.center.x + pow(0.5, 2) * self.rightEdgeView.center.x
        let summPointY = pow(1-0.5, 2.0) * self.leftEdgeView.center.y + 2 * (1-0.5) * 0.5 * self.centerView.center.y + pow(0.5, 2) * self.rightEdgeView.center.y
        return .init(x: summPointX, y: summPointY)
    }
}

extension ViewController {
    func makeNavBar(typeNavBar: NavBar = .top) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        switch typeNavBar {
        case .top:
            view.backgroundColor = UIColor.white
        case .bottom:
            view.backgroundColor = UIColor(red: 57/255, green: 74/255, blue: 124/255, alpha: 1.0)
        }
        return view
    }
    
    func makeNavBarButton(type: NavBarButton = .menu) -> UIButton {
        let temp = UIButton()
        var titleButton = ""
        temp.backgroundColor = UIColor.clear
        temp.translatesAutoresizingMaskIntoConstraints = false
        switch type {
        case .stats:
            titleButton = "STATS"
        case .settings:
            titleButton = "SETTINGS"
            temp.setTitleColor(UIColor.blue.withAlphaComponent(0.7), for: .normal)
        case .more:
            titleButton = "MORE"
        case .menu:
            titleButton = ""
        }
        temp.setTitle(titleButton, for: .normal)
        return temp
    }
    
    func makeCanvasView() -> UIView {
        let temp = UIView()
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.backgroundColor = UIColor.clear
        temp.clipsToBounds = true
        temp.layer.masksToBounds = true
        return temp
    }
    
    func makeLabel(typeLabel: PointLabel) -> UILabel {
        let temp = UILabel()
        var tempColor = UIColor.white
        var tempTitle = " POINTS\nYOU NEED"
        temp.textAlignment = .center
        temp.translatesAutoresizingMaskIntoConstraints = false
        
        switch typeLabel {
        case .topNeedPoint, .topPoint:
            tempColor = .blue.withAlphaComponent(0.7)
        case .bottomPoint, .bottomHavePoint:
            tempTitle = " POINTS\nYOU HAVE"
        }
        temp.text = tempTitle
        temp.textColor = .black
        temp.numberOfLines = 0
        temp.adjustsFontForContentSizeCategory = true
        temp.adjustsFontSizeToFitWidth = true
        temp.sizeToFit()
        return temp
    }
    
    func makeShapeLayer() -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.backgroundColor = UIColor.clear.cgColor
        shape.lineWidth = 2.0
        shape.fillColor = UIColor(red: 57/255, green: 74/255, blue: 124/255, alpha: 1.0).cgColor
        shape.strokeColor = UIColor.clear.cgColor
        shape.lineCap = .round
        shape.lineJoin = .round
        shape.actions = ["path":NSNull(),"position":NSNull(), "bounds":NSNull()]
        return shape
    }
    
    func makeScaleViews() -> [UIView] {
        var item: Int = 0
        var tempViews: [UIView] = []
        while 12 != item {
            let temp = UIView()
            temp.frame.size = CGSize(width: 50.0, height: 3.0)
            temp.translatesAutoresizingMaskIntoConstraints = false
            temp.backgroundColor = UIColor.cyan
            temp.layer.cornerRadius = 2.0
            tempViews.append(temp)
            item += 1
        }
        return tempViews
    }
    
    func makeCurvePointView() -> UIView {
        let temp = UIView()
        temp.backgroundColor = .clear
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.frame.size = .init(width: 10.0, height: 10.0)
        temp.layer.actions = ["path":NSNull(),"position":NSNull(), "bounds":NSNull()]
        return temp
    }
}

extension UIView {
    func getAbsolutePosition() -> CGPoint {
        if let presentation = layer.presentation() {
            return presentation.position
        } else {
            return center
        }
    }
}
