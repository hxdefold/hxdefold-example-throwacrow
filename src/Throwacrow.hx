import Defold.hash;
import defold.Camera;
import defold.Render;
import defold.Physics;
import defold.Sys;
import defold.types.Quaternion;
import defold.support.ScriptOnInputAction;

typedef ThrowacrowData = {
	var initial_position:Vector3;
	var initial_rotation:Quaternion;
	var camera_offset:Vector3;
	var camera_target:Vector3;
	var camera_zoom:Float;
	var flinging:Bool;
	var aiming:Bool;
	var panning:Bool;
	var idle_frames:Int;
	var pressed_position:Vector3;
	var pressed_camera_position:Vector3;
}

class Throwacrow extends Script<ThrowacrowData> {
	static var BG_COLOR = Vmath.vector4(213/255, 237/255, 246/255, 1);

	override function init(self:ThrowacrowData) {
		Msg.post(".", GoMessages.acquire_input_focus);
		Msg.post("camera", CameraMessages.acquire_camera_focus);
		Msg.post("#collisionobject", GoMessages.disable);

		// store initial position and rotation so that we can reset after flinging
		self.initial_position = Go.get_position();
		self.initial_rotation = Go.get_rotation();

		// keep track of the camera offset since we need to keep the offset when we let the camera follow the flung bird
		self.camera_offset = Go.get_world_position() - Go.get_world_position("camera");

		// the target position of the camera that we will tween towards every frame
		self.camera_target = Go.get_position("camera");

		// the current camera zoom from which we will tween to the target zoom value
		self.camera_zoom = 1;

		self.flinging = false;		// true if we are currently flinging
		self.aiming = false;		// true if we are currently aiming
		self.panning = false;		// true if we are currently panning around the level
		self.idle_frames = 0;		// the number of frames where the flung bird has been idle
	}

	override function final_(_) {
		Msg.post(".", GoMessages.release_input_focus);
		Msg.post("camera", CameraMessages.release_camera_focus);
	}

	override function update(self:ThrowacrowData, _) {
		Msg.post("@render:", RenderMessages.clear_color, { color: BG_COLOR });
		Msg.post("@render:", RenderMessages.draw_text, { text: "Click and drag to fling", position: Vmath.vector3(20, 40, 0) } );

		//
		// let the camera follow the bird while it is flung
		//
		if (self.flinging)
			self.camera_target = Go.get_position() - self.camera_offset;

		//
		// move the camera towards the target position
		//
		var target_zoom = Math.max(1, Math.min(1.5, Math.sqrt(Go.get_position().x / self.initial_position.x)));
		self.camera_zoom = self.camera_zoom + (target_zoom - self.camera_zoom) * 0.05;
		Go.set_position(Vmath.lerp(0.1, Go.get_position("camera"), self.camera_target), "camera");
		Msg.post("@render:", Messages.set_zoom, { zoom: self.camera_zoom });

		//
		// do we have a bird in the air?
		// in this case we check if the bird is idle or still moving
		//
		if (self.flinging) {
			// get angular and linear velocity and start counting the number of frames when
			// we're more or less still/idle
			// if we're idle for a number of frames we assume that the system is at rest and
			// let the player fling again
			var linear_velocity:Vector3 = Go.get("#collisionobject", "linear_velocity");
			var angular_velocity:Vector3 = Go.get("#collisionobject", "angular_velocity");
			if (Vmath.length(linear_velocity) < 5 && Vmath.length(angular_velocity) < 5) {
				self.idle_frames++;
				if (self.idle_frames > 60) {
					Msg.post("#collisionobject", GoMessages.disable);
					Msg.post(".", GoMessages.acquire_input_focus);
					Go.set_position(self.initial_position);
					Go.set_rotation(self.initial_rotation);
					self.flinging = false;
					self.camera_target = self.initial_position - self.camera_offset;
				}
			} else {
				self.idle_frames = 0;
			}
		}
	}

	override function on_input(self:ThrowacrowData, action_id:Hash, action:ScriptOnInputAction):Bool {
		var action_position = Vmath.vector3(action.x, action.y, 0);
		//
		// check for touch/click
		// we decide here if we should start aiming or if we should fling the bird
		//
		if (action_id == hash("touch")) {
			if (action.pressed) {
				//
				// did we click on the bird?
				// if yes, start aiming
				// if no, start panning
				//
				if (Vmath.length(action_position + Go.get_world_position("camera") - Go.get_world_position()) < 50) {
					self.aiming = true;
					self.pressed_position = action_position;
				} else {
					self.panning = true;
					self.pressed_position = action_position;
					self.pressed_camera_position = Go.get_position("camera");
				}
			} else if (action.released) {
				//
				// did we release while aiming?
				// if yes, fling the bird!
				// if no, stop panning
				//
				if (self.aiming) {
					var direction = self.initial_position - Go.get_position();
					Msg.post("#collisionobject", GoMessages.enable);
					Msg.post("#collisionobject", PhysicsMessages.apply_force, { force: direction * 950 * Go.get("#collisionobject", "mass"), position: Go.get_world_position() });
					Msg.post(".", GoMessages.release_input_focus);
					self.flinging = true;
					self.aiming = false;
					self.idle_frames = 0;
					self.pressed_position = null;
				} else {
					self.panning = false;
				}
			}
		} else if (action_id == hash("toggle_physics_debug") && action.released) {
			Msg.post("@system:", SysMessages.toggle_physics_debug);
		} else if (action_id == hash("toggle_profiler") && action.released) {
			Msg.post("@system:", SysMessages.toggle_profile);
		}
		//
		// mouse/finger moved while aiming?
		//
		else if (self.aiming) {
			//
			// calculate the distance we've moved from the position where we started
			// dragging the bird
			// limit this distance to below a threshold value
			//
			var dx = self.pressed_position.x - action_position.x;
			var dy = self.pressed_position.y - action_position.y;
			var radians = Math.atan2(dy, dx);
			var cos = Math.cos(radians);
			var sin = Math.sin(radians);
			var distance = Math.sqrt(dx * dx + dy * dy);
			var max_distance = 120;
			if (distance > max_distance) {
				dx = cos * max_distance;
				dy = sin * max_distance;
				distance = max_distance;
			}
			Go.set_position(Vmath.vector3(self.initial_position.x - dx, self.initial_position.y - dy, self.initial_position.z));
		}
		//
		// mouse/finger moved while panning?
		// update camera target position and clamp it horizontally
		//
		else if (self.panning) {
			var delta = self.pressed_position - action_position;
			var pos = self.pressed_camera_position + delta;
			pos.x = Math.min(4000, Math.max(-4000, pos.x));
			self.camera_target = pos;
		}
		return false;
	}
}
