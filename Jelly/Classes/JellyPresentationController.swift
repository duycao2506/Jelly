//
//  JellyPresentationController.swift
//  Created by Sebastian Boldt on 17.11.16.

import UIKit

class JellyPresentationController : UIPresentationController {
    
    private var presentation: JellyPresentation
    fileprivate var dimmingView: UIView! // The PresentationController manages the dimmingView
    fileprivate var blurView: UIVisualEffectView!
    
    init(presentedViewController: UIViewController, presentingViewController: UIViewController?, presentation: JellyPresentation) {
        
        presentedViewController.view.layer.masksToBounds = true
        presentedViewController.view.layer.cornerRadius = CGFloat(presentation.cornerRadius)
        
        self.presentation = presentation
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
        self.setupDimmingView()
        self.setupBlurView()
        
    }
    
    /// Presentation and Dismissal stuff
    override func presentationTransitionWillBegin() {
        switch presentation.backgroundStyle {
        case .blur(let effectStyle):
            animateBlurView(effectStyle: effectStyle)
        case .dimmed:
            animateDimmingView()
        case .none:
            ()
        }
    }
    
    private func animateBlurView(effectStyle: UIBlurEffectStyle) {
        containerView?.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[blurView]|",
                                           options: [], metrics: nil, views: ["blurView": blurView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[blurView]|",
                                           options: [], metrics: nil, views: ["blurView": blurView]))
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            blurView.effect = nil
            return
        }
        
        UIView.animate(withDuration: presentation.duration.rawValue, animations: {
            let effect = UIBlurEffect(style: effectStyle)
            self.blurView.effect = effect

        })
    }
    
    private func animateDimmingView() {
        containerView?.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
        
        UIView.animate(withDuration: presentation.duration.rawValue, animations: {
            self.blurView.effect = nil
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        
        var width : CGFloat = 0.0
        switch self.presentation.widthForViewController {
        case .fullscreen:
            width = parentSize.width
        case .halfscreen:
            width = parentSize.width / 2
        case .custom(let value):
            width = value
        }
        
        var height : CGFloat = 0.0
        switch self.presentation.heightForViewController {
        case .fullscreen:
            height = parentSize.height
        case .halfscreen:
            height = parentSize.height / 2
        case .custom(let value):
            height = value
        }
        
        return CGSize(width: width, height: height)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView!.bounds.size)
        limit(frame: &frame, withSize: frame.size)
        align(frame: &frame, withPresentation: self.presentation)
        applymarginGuards(toFrame: &frame, marginGuards: presentation.marginGuards, container: containerView!.bounds.size)
        return frame
    }
    
    private func applymarginGuards(toFrame frame: inout CGRect, marginGuards: UIEdgeInsets, container: CGSize){
        // Apply horizontal marginGuards
        print("Incoming Frame \(frame)")
        /// If size is bigger or equal container we need to apply marginGuards
        if (frame.origin.x <= 0) {
            frame.origin.x = marginGuards.left
        }
        
        if((frame.origin.x + frame.width) >= container.width) {
            frame.size = CGSize(width: frame.width - marginGuards.right, height: frame.height)
            frame.size = CGSize(width: frame.width - marginGuards.left  , height: frame.height)
        }
        
        // Apply vertical marginGuards
        
        if (frame.origin.y <= 0) {
            frame.origin.y = marginGuards.top

        }
        
        if((frame.origin.y + frame.height) >= container.height) {
            frame.size = CGSize(width: frame.width , height: frame.height - marginGuards.bottom)
            frame.size = CGSize(width: frame.width, height: frame.height - marginGuards.top)
        }
        
        print("Outgoing Frame \(frame)")
    }
    
    private func limit(frame: inout CGRect, withSize size: CGSize) {
        if (frame.size.height > size.height) {
            frame.size.height = size.height
        }
        
        if (frame.size.width > size.width) {
            frame.size.width = size.width
        }
    }
    
    private func align(frame: inout CGRect, withPresentation presentation: JellyPresentation) {
        
        if let alignablePresentation = presentation as? AlignablePresentation {
            
            // Prepare Horizontal Alignment
            switch alignablePresentation.horizontalAlignment {
            case .center:
                frame.origin.x = (containerView!.frame.size.width/2)-(frame.size.width/2)
            case .left:
                frame.origin.x = 0
            case .right:
                frame.origin.x = (containerView?.frame.size.width)! - frame.size.width
            }
            
            // Prepare Vertical Alignment
            switch alignablePresentation.verticalAlignemt {
            case .center:
                frame.origin.y = (containerView!.frame.size.height/2)-(frame.size.height/2)
            case .top:
                frame.origin.y = 0
            case .bottom:
                frame.origin.y = (containerView?.frame.size.height)! - frame.size.height
            }
        } else {
            frame.origin.x = (containerView!.frame.size.width/2)-(frame.size.width/2)
            frame.origin.y = (containerView!.frame.size.height/2)-(frame.size.height/2)
        }
    }
}


fileprivate extension JellyPresentationController {
    func setupBlurView () {
        blurView = UIVisualEffectView()
        blurView.translatesAutoresizingMaskIntoConstraints = false
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        blurView.addGestureRecognizer(recognizer)
    }
    
    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.alpha = 0.0
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)
    }
    
    dynamic func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}
