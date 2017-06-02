import defold.Msg;
import defold.Go;
import defold.Sprite;
import defold.Vmath;
import defold.types.Hash;

typedef DebrisData = {
	@property("debrisStone_1") var image:Hash;
}

class Debris extends defold.support.Script<DebrisData> {
	override function init(self:DebrisData) {
		Msg.post("#sprite", SpriteMessages.play_animation, { id: self.image });

		var to = Go.get_world_position() - Vmath.vector3(lua.Math.random(-10, 10), 150, 0);
		Go.animate(".", "position", PLAYBACK_ONCE_FORWARD, to, EASING_INCUBIC, 0.5, 0, function(_,_,_) Go.delete());
		Go.animate(".", "euler.z", PLAYBACK_ONCE_FORWARD, lua.Math.random(360), EASING_INCUBIC, 0.5);
	}
}
