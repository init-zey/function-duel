extends Object
class_name Complex

var real : float = 0
var imag : float = 0

var radius : float:
	get:
		return sqrt(pow(real, 2) + pow(imag, 2))

var arg : float:
	get:
		if real == 0:
			if imag > 0:
				return PI/2
			else:
				return -PI/2
		return atan(imag/real)

func _init(real, imag=0):
	self.real = real
	self.imag = imag

static func reverse(v) -> Complex:
	var ls = pow(v.real, 2) + pow(v.imag, 2)
	return Complex.new(v.real/ls, -v.imag/ls)

static func exp(v) -> Complex:
	return Complex.new(exp(v.real) * cos(v.imag), exp(v.real) * sin(v.imag))

static func ln(v) -> Complex:
	return Complex.new(log(v.radius), v.arg)

static func sqr(v) -> Complex:
	return Complex.new(pow(v.real, 2) - pow(v.imag, 2), 2 * v.real * v.imag)

static func sqrt(v) -> Complex:
	var sqrt_abs = sqrt(v.radius)
	return Complex.new(sqrt_abs * cos(v.arg/2), sqrt_abs * sin(v.arg/2))

static func abs(v) -> Complex:
	return Complex.new(v.radius, 0)

static func floor(v) -> Complex:
	return Complex.new(floor(v.real), floor(v.imag))

static func sign(v) -> Complex:
	return Complex.new(sign(v.real), sign(v.imag))

static func sin(v) -> Complex:
	return Complex.new(sin(v.real) * cosh(v.imag), cos(v.real) * sinh(v.imag))

static func cos(v) -> Complex:
	return Complex.new(cos(v.real) * cosh(v.imag), -sin(v.real) * sinh(v.imag))

static func tan(v) -> Complex:
	return Complex.multiply(sin(v), Complex.reverse(Complex.cos(v)))

static func plus(v1, v2) -> Complex:
	return Complex.new(v1.real + v2.real, v1.imag + v2.imag)

static func multiply(v1, v2) -> Complex:
	return Complex.new(v1.real * v2.real - v1.imag * v2.imag, v1.real * v2.imag + v1.imag * v2.real)

static func equal(v1, v2) -> bool:
	return v1.real == v2.real and v1.imag == v2.imag
	
static func from_string(str) -> Complex:
	var splited = str.split("+")
	var real = float(splited[0])
	var imag = 0
	if len(splited)>1:
		imag = float(splited[1])
	return Complex.new(real, imag)

func _to_string() -> String:
	var r = str(real).substr(0, 4)
	var p = "+"
	var i = str(imag).substr(0, 4) + "i"
	if imag == 1:
		i = "i"
	elif imag == -1:
		i = "-i"
	if real == 0:
		p = ""
		if not imag == 0:
			r = ""
	if imag == 0:
		p = ""
		i = ""
	elif imag < 0:
		p = ""
	return r+p+i

func op_to_string() -> String:
	if real < 0:
		return self.to_string()
	else:
		return "+" + self.to_string()

func mul_to_string() -> String:
	var r = self.to_string()
	if r == "-1":
		return "-"
	if r == "1":
		return ""
	return r
