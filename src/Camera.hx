import defold.Go;
import defold.Camera;
import defold.Msg;
import defold.types.Vector3;

typedef CameraData = {
	var initial_position:Vector3;
}

class Camera extends defold.support.Script<CameraData> {
	override function init(self:CameraData) {
		Msg.post("#camera", CameraMessages.acquire_camera_focus);
		self.initial_position = Go.get_position();
	}

	override function final_(_)
		Msg.post("#camera", CameraMessages.release_camera_focus);

	override function update(self:CameraData, _) {
		//
		// limit the vertical position so that we don't scroll below the original position
		// there's no point looking at a lot of ground
		//
		var pos = Go.get_position();
		pos.y = Math.max(pos.y, self.initial_position.y);
		Go.set_position(pos);
	}
}
