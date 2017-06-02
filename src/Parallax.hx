import defold.Go;
import defold.types.Vector3;

typedef ParallaxData = {
	var initial_camera_position:Vector3;
	var initial_position:Vector3;
	var offset_factor:Float;
}

/**
	add a parallax effect to the game object this script is attached to
**/
class Parallax extends defold.support.Script<ParallaxData> {
	override function init(self:ParallaxData) {
		self.initial_camera_position = Go.get_position("camera");
		self.initial_position = Go.get_position();
		self.offset_factor = self.initial_position.z;
	}

	override function update(self:ParallaxData, _) {
		//
		// offset the game object based on how far the camera has
		// scrolled from it's initial position and the z-value of this
		// game object
		//
		var camera_position = Go.get_position("camera");
		var diff = self.initial_camera_position - camera_position;
		diff.y = diff.y * 0.25;
		diff.z = 0;
		Go.set_position(self.initial_position + diff * self.offset_factor);
	}
}
