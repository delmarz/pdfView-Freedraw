//
//  ViewController.swift
//  pdfView Freedraw
//
//  Created by Ron Regev on 02/10/2020.
//

import UIKit
import PDFKit

class ViewController: UIViewController, UIGestureRecognizerDelegate, PDFFreedrawGestureRecognizerUndoDelegate {
    
    @IBOutlet weak var undoOutlet: UIButton!
    @IBOutlet weak var redoOutlet: UIButton!
    
	
	private var _selectedStickerView:StickerView?
	var selectedStickerView:StickerView? {
			get {
					return _selectedStickerView
			}
			set {
					// if other sticker choosed then resign the handler
					if _selectedStickerView != newValue {
							if let selectedStickerView = _selectedStickerView {
									selectedStickerView.showEditingHandlers = false
							}
							_selectedStickerView = newValue
					}
					// assign handler to new sticker added
					if let selectedStickerView = _selectedStickerView {
							selectedStickerView.showEditingHandlers = true
							selectedStickerView.superview?.bringSubviewToFront(selectedStickerView)
					}
			}
	}
	
	
	var pdfFreedraw : PDFFreedrawGestureRecognizer!
	let pdfView = PDFView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare the example PDF document and PDF view
        let pdfDocument = PDFDocument(url: Bundle.main.url(forResource: "withDatesPlanner", withExtension: "pdf")!)
      
        DispatchQueue.main.async { // Layout should be done on the main thread
        
					self.pdfView.frame = self.view.frame
					self.view.addSubview(self.pdfView)
					self.view.sendSubviewToBack(self.pdfView)
            
            // autoScales must be set to true, otherwise the swipe motion will drag the canvas instead of drawing
					self.pdfView.autoScales = true
					self.pdfView.displayDirection = .horizontal
					self.pdfView.usePageViewController(true, withViewOptions: nil)
            // Deal with the page shadows that appear by default
            if #available(iOS 12.0, *) {
							self.pdfView.pageShadowsEnabled = false
            } else {
							self.pdfView.layer.borderWidth = 15 // iOS 11: hide the d*** shadow
							self.pdfView.layer.borderColor = UIColor.white.cgColor
            }
            
            // For iOS 11-12, the document should be loaded only after the view is in the stack. If this is called outside the DispatchQueue block, it may be executed too early
					self.pdfView.document = pdfDocument
            
        }
        
        // Define the gesture recognizer. You can use a default initializer for a narrow red pen
        pdfFreedraw = PDFFreedrawGestureRecognizer(color: UIColor.blue, width: 3, type: .pen)
        pdfFreedraw.delegate = self
        pdfFreedraw.undoDelegate = self
        
        // Set the allowed number of undo actions
        pdfFreedraw.maxUndoNumber = 5
        
        // Set the pdfView's isUserInteractionEnabled property to false, otherwise you'll end up swiping pages instead of drawing. This is also one of the conditions used by the PDFFreeDrawGestureRecognizer to execute, so you can use it to turn free drawing on and off.
        pdfView.isUserInteractionEnabled = false
			
        // Add the gesture recognizer to the superview of the PDF view
        view.addGestureRecognizer(pdfFreedraw)
        
        /* IMPORTANT!
        You must make sure all other gesture recognizers have their cancelsTouchesInView option set to false, otherwise different stages of this gesture recognizer's touches may not be called, and the CAShapeLayer that holds the temporary annotation will not be removed.
         */
        
        // Set the initial state of the undo and redo buttons
        freedrawUndoStateChanged()
    }
	
	@IBAction func toogleViewBtnPressed(_ sender: UIButton) {
		pdfView.isUserInteractionEnabled.toggle()
	}
	
    
    // This function will make sure you can control gestures aimed at UIButtons
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle button taps
        return !(touch.view is UIButton)
    }
    
    // This function will allow for multiple gesture recognizers to coexist
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
            if gestureRecognizer is PDFFreedrawGestureRecognizer {
            return true
        }
        return false
    }
    
    func freedrawUndoStateChanged() {
        if pdfFreedraw.canUndo {
            undoOutlet.isEnabled = true
        } else {
            undoOutlet.isEnabled = false
        }
        if pdfFreedraw.canRedo {
            redoOutlet.isEnabled = true
        } else {
            redoOutlet.isEnabled = false
        }
    }

    @IBAction func blueLineAction(_ sender: UIButton) {
        PDFFreedrawGestureRecognizer.color = UIColor.blue
        PDFFreedrawGestureRecognizer.width = 3
        PDFFreedrawGestureRecognizer.type = .pen
    }
    
    @IBAction func redHighlightAction(_ sender: UIButton) {
        PDFFreedrawGestureRecognizer.color = UIColor.red
        PDFFreedrawGestureRecognizer.width = 20
        PDFFreedrawGestureRecognizer.type = .highlighter
    }
    
    @IBAction func eraserAction(_ sender: UIButton) {
        PDFFreedrawGestureRecognizer.type = .eraser
    }
    
    @IBAction func undoAction(_ sender: UIButton) {
        pdfFreedraw.undoAnnotation()
    }
    @IBAction func redoAction(_ sender: UIButton) {
        pdfFreedraw.redoAnnotation()
    }
	
	@IBAction func insertPNGImage(_ sender: UIButton) {
		let testImage = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
		testImage.image = UIImage(named: "S12")
		testImage.contentMode = .scaleAspectFit
						let stickerView3 = StickerView.init(contentView: testImage)
						stickerView3.center = CGPoint.init(x: 150, y: 150)
		stickerView3.setImage(UIImage.init(named: "close")!, forHandler: StickerViewHandler.close)
		stickerView3.setImage(UIImage.init(named: "rotate")!, forHandler: StickerViewHandler.rotate)
		stickerView3.setImage(UIImage.init(named: "flip")!, forHandler: StickerViewHandler.flip)
		stickerView3.setImage(UIImage.init(named: "resize")!, forHandler: StickerViewHandler.resize)
		stickerView3.showEditingHandlers = false
		stickerView3.tag = 1
		stickerView3.delegate = self
		self.view.addSubview(stickerView3)
		self.selectedStickerView = stickerView3
	}
	
    
}


extension ViewController : StickerViewDelegate {
	func stickerViewDidBeginResizing(_ stickerView: StickerView) {
		
	}
	
	func stickerViewDidChangeResizing(_ stickerView: StickerView) {
		
	}
	
	func stickerViewDidEndResizing(_ stickerView: StickerView) {
		self.selectedStickerView = stickerView
	}
	
		func stickerViewDidTap(_ stickerView: StickerView) {
				self.selectedStickerView = stickerView
		}
		
		func stickerViewDidBeginMoving(_ stickerView: StickerView) {
				self.selectedStickerView = stickerView
		
		}
		
		func stickerViewDidChangeMoving(_ stickerView: StickerView) {
		}
		
		func stickerViewDidEndMoving(_ stickerView: StickerView) {
			self.selectedStickerView = stickerView
		}
		
		func stickerViewDidBeginRotating(_ stickerView: StickerView) {
		}
		func stickerViewDidChangeRotating(_ stickerView: StickerView) {
				
		}
		
		func stickerViewDidEndRotating(_ stickerView: StickerView) {
			self.selectedStickerView = stickerView
		}
		
		func stickerViewDidClose(_ stickerView: StickerView) {
				
		}
}
