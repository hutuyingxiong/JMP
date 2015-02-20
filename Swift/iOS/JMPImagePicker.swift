import	UIKit
import	CoreMotion

class
JMPImagePicker: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var	toBack	:	( UIViewController -> () ) = { p in }
	var	taken	:	( UIViewController -> () ) = { p in }

	var	uMM		: CMMotionManager!

//vv	OUTLETS FOR IPC's OVERLAY VIEW
	@IBOutlet	weak	var	oPreviewIV		: UIImageView!
	@IBOutlet	weak	var	oFlipB			: UIView!
	@IBOutlet	weak	var	oFlashOnB		: UIButton!
	@IBOutlet	weak	var	oFlashOffB		: UIButton!
	@IBOutlet	weak	var	oFlashAutoB		: UIButton!
	@IBOutlet	weak	var	oCameraB		: UIButton!
	@IBOutlet	weak	var	oBackB			: UIButton!
//^^

	override func
	viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self
		self.sourceType = .Camera
		self.cameraCaptureMode = .Photo
		self.showsCameraControls = false
		self.allowsEditing = true
		
		self.cameraOverlayView = NSBundle.mainBundle().loadNibNamed( "JMPImagePickerOverlay", owner:self, options:nil ).first as? UIView

		let	wH = self.view.bounds.size.height
		if wH <= 480 {	//	4S
			self.cameraOverlayView!.frame = self.view.bounds
			oPreviewIV.frame = self.view.bounds;
			oPreviewIV.contentMode = .ScaleAspectFill
		} else if wH <= 568 {	//	5, 5S
			self.cameraOverlayView!.frame = self.view.bounds
			self.cameraViewTransform = CGAffineTransformMakeTranslation( 0, 64 )
		} else if wH <= 667 {	//	6
			self.cameraOverlayView!.frame = CGRectMake( 0, 0, 375, 375 * 4 / 3 + 64 + 78 )
			self.cameraViewTransform = CGAffineTransformMakeTranslation( 0, 64 )
		}
//
	    uMM = CMMotionManager()
	    uMM.accelerometerUpdateInterval = 0.5	//	more than animation duration
	}

	func
	CameraDevice( p: UIImagePickerControllerCameraDevice ) {
		super.cameraDevice = p
		let w = !UIImagePickerController.isFlashAvailableForCameraDevice( p )
		oFlashOnB.hidden = w
		oFlashOffB.hidden = w
		oFlashAutoB.hidden = w
	}

	func
	CameraFlashMode( p: UIImagePickerControllerCameraFlashMode ) {
		super.cameraFlashMode = p
		oFlashOnB.hidden = true
		oFlashOffB.hidden = true
		oFlashAutoB.hidden = true
		switch p {
		case .On:	oFlashOnB.hidden = false
		case .Off:	oFlashOffB.hidden = false
		case .Auto:	oFlashAutoB.hidden = false
		}
	}
	
	func
	imagePickerController(	//	Through Editing
		picker								: UIImagePickerController
	,	didFinishPickingMediaWithInfo info	: [ NSObject : AnyObject ]
	) {
		if let w = info[ UIImagePickerControllerOriginalImage ] as? UIImage {
		
			var	wImage: UIImage!
			
			switch picker.cameraDevice {
			case .Rear:
				oPreviewIV.image = UIImage( CGImage: w.CGImage, scale: 1, orientation: .Right )
				wImage = w
			case .Front:
				oPreviewIV.image = UIImage( CGImage: w.CGImage, scale: 1, orientation: .LeftMirrored )
				switch w.imageOrientation {
				case .Right:	wImage = UIImage( CGImage: w.CGImage, scale: 1, orientation: .LeftMirrored )	//	Portrait
				case .Left:		wImage = UIImage( CGImage: w.CGImage, scale: 1, orientation: .RightMirrored )	//	UpsideDown
				case .Up:		wImage = UIImage( CGImage: w.CGImage, scale: 1, orientation: .UpMirrored )		//	Right
				case .Down:		wImage = UIImage( CGImage: w.CGImage, scale: 1, orientation: .DownMirrored )	//	Left
				default:		break;
				}
			}

			dispatch_after(
				dispatch_time( DISPATCH_TIME_NOW, Int64( NSEC_PER_SEC ) )
			,	dispatch_get_main_queue()
			,	{ self.oPreviewIV.image = nil }
			)
		}
	}

	@IBAction func
	DoCamera( p: AnyObject ) {
		takePicture()
	}
	
	@IBAction func
	DoFlip( p: AnyObject ) {
		CameraDevice( self.cameraDevice == .Rear ? .Front : .Rear )
	}
	
	@IBAction func
	DoFlash( p: AnyObject ) {
		switch self.cameraFlashMode {
		case .Off:	CameraFlashMode( .On )
		case .On:	CameraFlashMode( .Auto )
		case .Auto:	CameraFlashMode( .Off )
		}
	}
	
	@IBAction func
	DoBack( p: AnyObject ) {
		toBack( self )
	}
	
	func
	navigationController( navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool ) {
		self.cameraOverlayView!.hidden = !( viewController == self.viewControllers[ 0 ] as? NSObject )
	}

	func
	navigationController( navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool ) {
	}

	override func
	viewWillAppear( p: Bool ) {
		super.viewWillAppear( p )
		//	Using main queue is not recommended. So create new operation queue and pass it to startAccelerometerUpdatesToQueue.
		//	Dispatch U/I code to main thread using dispach_async in the handler.
		uMM.startAccelerometerUpdatesToQueue( NSOperationQueue() ) { p, _ in
			if p != nil {
				let w = abs( p.acceleration.y ) < abs( p.acceleration.x )
				?	p.acceleration.x > 0 ? M_PI * 3 / 2	:	M_PI / 2
				:	p.acceleration.y > 0 ? M_PI			:	0
				let	wAT = CGAffineTransformMakeRotation( CGFloat( w ) )
				dispatch_async(
					dispatch_get_main_queue()
				,	{	Animate() {
							self.oFlipB.transform = wAT
							self.oFlashOnB.transform = wAT
							self.oFlashOffB.transform = wAT
							self.oFlashAutoB.transform = wAT
							self.oCameraB.transform = wAT
							self.oBackB.transform = wAT
						}
					}
				)
			}
		}
	}

	override func
	viewDidDisappear( p: Bool ) {
		super.viewDidDisappear( p )
		uMM.stopAccelerometerUpdates()
	}
}



















