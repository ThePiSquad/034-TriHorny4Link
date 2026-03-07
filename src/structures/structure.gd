@abstract
extends Damageable

class_name Structure

var color:Enums.ColorType

# Neighbors, can be null indicating there is no structure connecting to it
var north:Structure
var south:Structure
var east:Structure
var west:Structure
