import	UIKit
import	AddressBook

func
HexChar( p: Int ) -> Character {
	return [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ][ p & 0x0f ];
}

func
HexString( p: NSData ) -> String {
	let	wBytes = UnsafePointer<Int8>( p.bytes )
	var	v: String = ""
	for i in 0 ..< p.length {
		v.append( HexChar( Int( wBytes[ i ] ) >> 4 ) )
		v.append( HexChar( Int( wBytes[ i ] ) ) )
	}
	return v
}

func
RandomData( p: Int ) -> NSData {
	let wFD = open( "/dev/random", O_RDONLY )
	assert( wFD > 2 )
	var w = [ UInt8 ]( count: p, repeatedValue: 0 )
	read( wFD, &w, UInt( p ) )
	close( wFD )
	return NSData( bytes: w, length: p )
}

func
UTF8Data( p: String ) -> NSData {
	let	v = p.dataUsingEncoding( NSUTF8StringEncoding )
	assert( v != nil )
	return v!
}

func
UTF8String( p: NSData ) -> String {
	let	v = NSString( data:p, encoding: NSUTF8StringEncoding )
	assert( v != nil )
	return v!
}

func
UTF8String( p: UnsafePointer<UInt8>, length: Int ) -> String {
	let	v = NSString( bytes: p, length: length, encoding: NSUTF8StringEncoding )
	assert( v != nil )
	return v!
}

func
Base64String( p: NSData, options: NSDataBase64EncodingOptions = nil ) -> String {
	return p.base64EncodedStringWithOptions( options )
}

func
Base64Data( p: String, options: NSDataBase64DecodingOptions = .IgnoreUnknownCharacters ) -> NSData {
	let	v = NSData( base64EncodedString: p, options: options )
	assert( v != nil )
	return v!
}

func
InputBox(
	title		:	String!
,	message		:	String! = nil
,	config		:	((UITextField!) -> Void)! = nil
,	ok			:	((UITextField!) -> Void)
) -> UIAlertController {
	var v = UIAlertController(
		title			:	title
	,	message			:	message
	,	preferredStyle	:	.Alert
	)
	var wTF : UITextField!
	v.addTextFieldWithConfigurationHandler() { p in
		if config != nil { config( p ) }
		wTF = p
	}
	v.addAction( UIAlertAction( title: "Cancel", style: .Cancel, handler:nil ) )
	v.addAction( UIAlertAction( title: "OK", style: .Default ) { _ in ok( wTF ) } )
	return v
}
	
func
Animation(
	animations	:	() -> ()
,	duration	:	NSTimeInterval			= 0.25
,	completion	:	( Bool -> Void )!		= nil
,	delay		:	NSTimeInterval			= 0
,	options		:	UIViewAnimationOptions	= .CurveEaseInOut
) {
	UIView.animateWithDuration	(	duration
	,	delay					:	delay
	,	options					:	options
	,	animations				:	animations
	,	completion				:	completion
	)
}

func
SpringAnimation(
	animations	:	() -> ()
,	duration	:	NSTimeInterval			= 0.25
,	completion	:	( Bool -> Void )!		= nil
,	delay		:	NSTimeInterval			= 0
,	options		:	UIViewAnimationOptions	= .CurveEaseInOut
,	damping		:	CGFloat					= 0.5
,	velocity	:	CGFloat					= 0.1
) {
	UIView.animateWithDuration	(	duration
	,	delay					:	delay
	,	usingSpringWithDamping	:	damping
	,	initialSpringVelocity	:	velocity
	,	options					:	options
	,	animations				:	animations
	,	completion				:	completion
	)
}

func
BlockAlert(
  _	title	:	String! = nil
, _	message	:	String! = nil
) {
	UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(
		UIAlertController(
			title			:	title
		,	message			:	message
		,	preferredStyle	:	.Alert
		)
	,	animated:true
	,	completion:nil
	)
}
/*
class
JMPSAddressBook : NSObject {
	var	u	:	Unmanaged<ABAddressBookRef>! = nil

//	deinit {
//		if u { CFRelease( u.takeUnretainedValue() ) }
//	}


	func
	grant(
		granted	:	( ( JMPSAddressBook ) -> Void )!
	,	denied	:	( () -> Void )!
	,	error	:	( ( NSError! ) -> Void )!
	) {
		switch ( ABAddressBookGetAuthorizationStatus() )
		{
		case	.Restricted,	.Denied:
			denied();
		case	.Authorized:
			var e :  UnsafePointer<Unmanaged<CFError>?> = nil
			u = ABAddressBookCreateWithOptions( nil, e )
			if e { error( e.owner as NSError ) }
			if u { granted( self ) }
		case	.NotDetermined:
			var e :  CMutablePointer<Unmanaged<CFError>?> = nil
			u = ABAddressBookCreateWithOptions( nil, e )
			if e { error( e.owner as NSError ) }
			if u {
				ABAddressBookRequestAccessWithCompletion(
					nil
				,	{	( qGranted: Bool , qError: CFError!  ) in
						dispatch_async(
							dispatch_get_main_queue()
						,	{	if qGranted { granted( self ) }
								else {
									if qError	{ error( e.owner as NSError ) }
									else		{ denied() }
								}
							}
						)
					}
				);
			}
		}
	}

	func
	granted(
		granted		: ( ( JMPSAddressBook ) -> Void )!
	) {
		grant(
			granted
		,	{	BlockAlert(
					"設定であなたの連絡帳にアクセスする権限を与えてください。"
				,	"Permission was not granted for Contacts."
				)
			}
		,	{	( p: NSError! ) in
				BlockAlert(
					p.description
				,	"Unknown Error"
				)
			}
		)
	}
}
*/