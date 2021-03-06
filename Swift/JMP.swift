//	Written by Satoru Ogura, Tokyo.
//
import	Foundation
import	CoreGraphics

func
HexChar( p: Int ) -> Character {
	return [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ][ p & 0x0f ]
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
	read( wFD, &w, Int( p ) )
	close( wFD )
	return NSData( bytes: w, length: p )
}

func
RandomIndices( p: Int ) -> [ Int ] {
	var	v = [ Int ]()
	for i in 0 ..< p { v.append( i ) }
	for i in 0 ..< p {
		let j = Int( arc4random_uniform( UInt32( p - i ) ) ) + i
		( v[ i ], v[ j ] ) = ( v[ j ], v[ i ] )
	}
	return v
}

func
ToArray<T>( start: UnsafePointer<T>, count: Int ) -> [ T ] {
	return Array( UnsafeBufferPointer( start: UnsafePointer<T>( start ), count: count ) )
}
//	USAGE:	let wArray : [ Int16 ] = ToArray( data.bytes, data.length / sizeof( Int16 ) )

func
URL( p: String ) -> NSURL? {
	return NSURL( string: p )
}

func
Data( p: NSURL ) -> NSData? {
	return NSData( contentsOfURL: p )
}

func
UTF8Length( p: String ) -> Int {
	return p.lengthOfBytesUsingEncoding( NSUTF8StringEncoding )
}

func
UTF8Data( p: String ) -> NSData? {
	return p.dataUsingEncoding( NSUTF8StringEncoding )
}

func
UTF8String( p: NSData ) -> String? {
	return String( data:p, encoding: NSUTF8StringEncoding )
}

func
UTF8String( p: UnsafePointer<UInt8>, length: Int ) -> String? {
	return String( bytes: p, length: length, encoding: NSUTF8StringEncoding )
}

func
Base64String( p: NSData, _ options: NSDataBase64EncodingOptions = [] ) -> String {
	return p.base64EncodedStringWithOptions( options )
}

func
Base64Data( p: String, _ options: NSDataBase64DecodingOptions = [] ) -> NSData? {
	return NSData( base64EncodedString: p, options: options )
}

func
EncodeJSON( p: AnyObject, _ options: NSJSONWritingOptions = [] ) throws -> NSData {
	return try NSJSONSerialization.dataWithJSONObject( p, options: options )
}

func
DecodeJSON( p: NSData, _ options: NSJSONReadingOptions = [] ) throws -> AnyObject {
	return try NSJSONSerialization.JSONObjectWithData( p, options: options )
}

func
IsNull( p: AnyObject? ) -> Bool {
	if p == nil { return true }
	return p is NSNull
}

func
AsInt( p: AnyObject? ) -> Int? {
	if let w = p where w is NSNumber || w is String {
		return w.integerValue
	}
	return nil
}

//	Assuming the Data is BD
//	Search: A Result:	[]
//	Search: B Result:	[ 0 ]
//	Search: C Result:	[ 0, 1 ]
//	Search: D Result:	[ 1 ]
//	Search: E Result:	[]

func
BinarySearch< T: Comparable >( a: T, _ b: [ T ] ) -> [ Int ] {
	switch b.count {
	case 0:	return []
	case 1:	return a == b[ 0 ] ? [ 0 ] : []
	default:
		if a < b.first || a > b.last { return [] }
		var ( l, h ) = ( 0, b.count - 1 )
		while h - l > 1 {
			let m = ( l + h ) / 2
			if a == b[ m ] { return [ m ] }
			if a < b[ m ] { h = m } else { l = m }
		}
		return [ l, h ]
	}
}

enum
ReaderError		:	ErrorType {
case				EOD
}
class
Reader< T > {
	var
	_unread : T?
	func
	_Read() throws -> T { throw ReaderError.EOD }
	func
	Read() throws -> T {
		if let v = _unread { _unread = nil; return v }
		return try _Read()
	}
	func
	Unread( p: T ) { _unread = p; }
}

class
StdinUnicodeReader: Reader< UnicodeScalar > {
	var
	m	= String.UnicodeScalarView()
	override func
	_Read() throws -> UnicodeScalar {
		while m.count == 0 {
			if let w = readLine( stripNewline: false ) { m = w.unicodeScalars } else { throw ReaderError.EOD }
		}
		let v = m.first
		m = m.dropFirst()
		return v!
	}
}

class
StdinCharacterReader: Reader< Character > {
	var
	m	= String.CharacterView()
	override func
	_Read() throws -> Character {
		while m.count == 0 {
			if let w = readLine( stripNewline: false ) { m = w.characters } else { throw ReaderError.EOD }
		}
		let v = m.first
		m = m.dropFirst()
		return v!
	}
}

class
StringUnicodeReader	: Reader< UnicodeScalar > {
	var
	m	: String.UnicodeScalarView
	init( _ a: String ) { m = a.unicodeScalars }
	override func
	_Read() throws -> UnicodeScalar {
		if m.count == 0 { throw ReaderError.EOD }
		let v = m.first
		m = m.dropFirst()
		return v!
	}
}


class
StringCharacterReader: Reader< Character > {
	var
	m	: String.CharacterView
	init( _ a: String ) { m = a.characters }
	override func
	_Read() throws -> Character {
		if m.count == 0 { throw ReaderError.EOD }
		let v = m.first
		m = m.dropFirst()
		return v!
	}
}

func
SkipWhite( r: Reader< UnicodeScalar > ) throws {
	while true {
		let u = try r.Read()
		if !NSCharacterSet.whitespaceAndNewlineCharacterSet().longCharacterIsMember( u.value ) {
			r.Unread( u )
			break
		}
	}
}

class
Cell<T>	{
	var
	m			:	T
	let
	next		:	Cell?
	init(	_ a	:	T, _ pNext: Cell? = nil ) { m = a; next = pNext }
}


func
Notify( name: String, ed: NSNotification! -> () ) -> NSObjectProtocol {
	return NSNotificationCenter.defaultCenter().addObserverForName(
		name
	,	object				:	nil
	,	queue				:	nil
	,	usingBlock			:	ed
	)
}

func
Main( ed: () -> () ) {
	dispatch_async( dispatch_get_main_queue(), ed )
}

func
Sub( ed: () -> () ) {
	dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ed )
}

//func
//Delay( p: NSTimeInterval, ed: () -> () ) -> NSTimer {
//	return NSTimer.scheduledTimerWithTimeInterval(
//		NSTimeInterval( p )
//	,	target		:	NSBlockOperation( block: { ed() } )
//	,	selector	:	#selector( NSOperation.main )
//	,	userInfo	:	nil
//	,	repeats		:	false
//	)
//}

func
Periodical( p: NSTimeInterval, ed: () -> () ) -> NSTimer {
	let v = NSTimer.scheduledTimerWithTimeInterval(
		NSTimeInterval( p )
	,	target		:	NSBlockOperation( block: { Main{ ed() } } )
	,	selector	:	#selector( NSOperation.main )
	,	userInfo	:	nil
	,	repeats		:	true
	)
	return v
}

func
Delay( p: NSTimeInterval, _ queue: dispatch_queue_t = dispatch_get_main_queue(), ed: () -> () ) {
	dispatch_after(
		dispatch_time( DISPATCH_TIME_NOW, Int64( p * NSTimeInterval( NSEC_PER_SEC ) ) )
	,	queue
	,	ed
	)
}

func
ResourcePath( resource: String, _ type: String = "" ) -> String? {
	return NSBundle.mainBundle().pathForResource( resource, ofType: type )
}

func
ResourceURL( resource: String, _ type: String = "" ) -> NSURL? {
	return NSBundle.mainBundle().URLForResource( resource, withExtension: type )
}

func
DocumentDirectoryURLs() -> [ NSURL ] {
	return NSFileManager.defaultManager().URLsForDirectory( .DocumentDirectory, inDomains: .UserDomainMask ) as [ NSURL ]
}

func
DocumentDirectoryPathes() -> [ String ] {
	return NSSearchPathForDirectoriesInDomains(
		.DocumentDirectory
	,	.UserDomainMask
	,	true
	) as [ String ]
}

func
Dist2( left: CGPoint, _ right: CGPoint ) -> Double {
	let w = Double( right.x - left.x )
	let h = Double( right.y - left.y )
	return w * w + h * h
}

func
Center( p: CGRect ) -> CGPoint {
	return CGPointMake( CGRectGetMidX( p ), CGRectGetMidY( p ) )
}

typealias	JSONDict = [ String: AnyObject ]

func
JSON( a: String ) -> AnyObject? {
	if	let	wURL = URL( a )
	,	let	wData = Data( wURL ) {
		return try? DecodeJSON( wData )
	} else {
		return nil
	}
}

func
ArrayJSON( a: String ) -> [ AnyObject ]? {
	return JSON( a ) as? [ AnyObject ]
}

func
DictJSON( a: String ) -> JSONDict? {
	return JSON( a ) as? JSONDict
}

func
BalancedPosition( p: NSData ) -> Int? {
	let	wBytes = UnsafePointer<UInt8>( p.bytes )
	var	wBalance = 0
	var	wInString = false
	var	wInBackSlash = false

	for i in 0 ..< p.length {
		if wInString {
			if wInBackSlash {
				wInBackSlash = false
			} else {
				switch wBytes[ i ] {
				case 0x5c:	//	\
					wInBackSlash = true
				case 0x22:
					wInString = false
				default:
					break
				}
			}
		} else {
			switch wBytes[ i ] {
			case 0x5b, 0x7b:	//	[	{
				wBalance = wBalance + 1
			case 0x5d, 0x7d:	//	]	}
				if wBalance == 0 { return nil }
				wBalance = wBalance - 1
				if wBalance == 0 { return i + 1 }
			case 0x22:
				wInString = true
				wInBackSlash = false
			default:
				break
			}
		}
	}
	return nil
}

func
JSONForAll( data: NSMutableData, _ p: AnyObject -> () ) {
	while let wBP = BalancedPosition( data ) {
		let	wRange = NSMakeRange( 0, wBP )
		do {
			p( try DecodeJSON( data.subdataWithRange( wRange ) ) )
		} catch {
		}
		data.replaceBytesInRange( wRange, withBytes: nil, length: 0 )
	}
}

func
OnHTML(
	uri		: String
, _	method	: String
, _	body	: NSData? = nil
, _	er		: ( NSError ) -> () = { e in }
, _	ex		: ( NSHTTPURLResponse, NSData ) -> () = { r, d in }
, _	ed		: NSData -> () = { p in }
) {
	let	wR = NSMutableURLRequest( URL: URL( uri )! )
	wR.HTTPMethod = method
	if body != nil { wR.HTTPBody = body! }
	NSURLSession.sharedSession().dataTaskWithRequest( wR ) { d, r, e in
		if let wE = e { er( wE ) }
		else {
			if let
				wR = r as? NSHTTPURLResponse
			,	wD = d {
				switch wR.statusCode {
				case 200:
					ed( wD )
				default:
					ex( wR, wD )
				}
			} else {
				assert( false )
			}
		}
	}
}

func
OnJSON(
	uri		: String
, _	method	: String = "GET"
, _	json	: AnyObject? = nil
, _	er		: ( NSError ) -> () = { e in }
, _	ex		: ( NSHTTPURLResponse, NSData ) -> () = { r, d in }
, _	ed		: AnyObject -> () = { p in }
) {
	do {
		var	wBody	:	NSData?
		if let wJSON = json { wBody = try EncodeJSON( wJSON ) }
		OnHTML( uri, method, wBody, er, ex ) { p in
			do {
				ed( try DecodeJSON( p ) )
			} catch let e as NSError {
				er( e )
			} catch {
				assert( false )
			}
		}
	} catch let e as NSError {
		er( e )
	} catch {
		assert( false )
	}
}


func
ShowSharedCookies() {
	if let wCs = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
		for w in wCs { print( w ) }
	}
}

func
DeleteSharedCookies() {
	let	wCS = NSHTTPCookieStorage.sharedHTTPCookieStorage()
	if let wCs = wCS.cookies {
		for w in wCs { wCS.deleteCookie( w ) }
	}
}

func
Request( p: String ) -> NSURLRequest? {
	if let w = URL( p ) {
		return NSURLRequest( URL: w )
	} else {
		return nil
	}
}
