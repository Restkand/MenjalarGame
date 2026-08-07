extends Node

var GROWTH_SPEED   = 9.0
var VINE_SPEED     = 3.2
var MAX_TURN       = 1.1
var NOISE_AMOUNT   = 0.35
var ENERGY_RATE    = 7.0
var COST_PER_PIXEL = 0.30
var COST_TIP_EXP   = 0.62
var GAZE_RANGE     = 84.0
var GAZE_HALF      = 0.52
var HEAT_RATE      = 0.30
var HEAT_DECAY     = 0.10
var NIGHT_HEAT     = 0.55
var DAY_LEN        = 22.0
var NIGHT_LEN      = 24.0

const DEAD_ZONE = 7.0
const SHED_COST = 40
const C_WARN = Color("D8A34A")
const W = 240
const H = 160
const SCALE = 4
const GROUND_Y = 112
const MAX_STRANDS = 24
const SEED_X = 120
const LEAF_SPACING = 7.0
const COST_BRANCH = 15.0
const ENERGY_MAX = 200.0
const ENERGY_START = 120.0
const SUSPICION_MAX = 100.0
const COVERAGE_GOAL = 0.55

const FACADE_X0 = 44
const FACADE_X1 = 196
const FACADE_Y0 = 12
const FACADE_Y1 = 112

const PHASE_DAY = 0
const PHASE_NIGHT = 1

const SUN_RAY = Vector2(-0.34, -0.94)

const T_SKY      = 0
const T_SOIL_DRY = 1
const T_SOIL_WET = 2
const T_CONCRETE = 3
const T_WALL     = 4
const T_WINDOW   = 5
const T_LEDGE    = 6
const T_PIPE     = 7
const T_NEIGHBOR = 8
const T_DOOR     = 9

const C_SKY       = Color("8B96A3")
const C_WALL      = Color("6E7784")
const C_WALL_DARK = Color("5F6874")
const C_NEIGHBOR  = Color("545C68")
const C_WINDOW    = Color("9AA4B0")
const C_LEDGE     = Color("7D7D75")
const C_DOOR      = Color("4A4E57")
const C_SOIL      = Color("4A3728")
const C_SOIL_WET  = Color("5C4433")
const C_CONCRETE  = Color("7D7D75")
const C_PIPE      = Color("4A6B7C")
const C_ROOT      = Color("A87B4E")
const C_BRANCH    = Color("7A5C3A")
const C_LEAF      = Color("5EC24A")
const C_TIP       = Color("B8E986")
const C_WARDEN    = Color("3A3F49")
const C_ALERT     = Color("C25A4A")
