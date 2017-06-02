import defold.Physics;

typedef WindData = {
	@property(900000, 0, 0) var strength:Vector3;
}

class Wind extends Script<WindData> {
	override function on_message<T>(self:WindData, message_id:Message<T>, message:T, _) {
		//
		// push anything that enters the wind away from it
		//
		switch (message_id) {
			case PhysicsMessages.collision_response:
				Msg.post(Msg.url(null, message.other_id, "collisionobject"), PhysicsMessages.apply_force, { force: self.strength, position: message.other_position });
		}
	}
}
