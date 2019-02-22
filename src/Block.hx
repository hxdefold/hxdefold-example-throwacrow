import defold.Physics;
import defold.Sprite;
import defold.Factory;

typedef BlockData = {
	/** the amount of damage the block can take before destroyed **/
	@property(200) var durability:Float;
	/** the sprite to show when block has only little damage **/
	@property("elementStone011") var undamaged:Hash;
	/** the sprite to show when block has medium amount of damage **/
	@property("elementStone014") var damaged:Hash;
	/** the sprite to show when block is almost destroyed **/
	@property("elementStone046") var almost_destroyed:Hash;
	/** if debris should be created when the block is destroyed **/
	@property(true) var debris:Bool;

	var mass:Float;
	var initial_durability:Float;
	var damage_levels:Array<Hash>;
}

class Block extends Script<BlockData> {
	override function init(self:BlockData) {
		self.mass = Go.get("#collisionobject", "mass");
		self.initial_durability = self.durability;
		//
		// create ordered list of the damage levels
		// this will be used to lookup which sprite to use
		//
		self.damage_levels = [self.almost_destroyed, self.damaged, self.undamaged];
	}

	static var GROUND = Defold.hash("ground");

	override function on_message<T>(self:BlockData, message_id:Message<T>, message:T, _) {
		switch (message_id) {
			case PhysicsMessages.collision_response:
				var other_url = Msg.url(null, message.other_id, "collisionobject");
				var other_velocity = Vmath.length(Go.get(other_url, "linear_velocity"));
				var other_mass:Float = Go.get(other_url, "mass");
				//
				// damage is based on the mass ratio between what we're colliding with and own mass
				// combined with the velocity of the object we're colliding with
				// if we are colliding with the ground we use own velocity and a fixed mass
				//
				var velocity = other_velocity;
				if (message.other_group == GROUND) {
					velocity = Vmath.length(Go.get("#collisionobject", "linear_velocity"));
					other_mass = 1000;
				}
				//
				// only apply damage if the velocity is high enough
				//
				if (velocity > 20) {
					var damage = velocity * 0.01 * self.mass / other_mass;
					self.durability = self.durability - damage;
					//
					// remove the block if it is destroyed and potentially also spawn some debris
					//
					if (self.durability <= 0) {
						Go.delete();
						if (self.debris) {
							for (_ in 0...5) {
								var pos = Go.get_world_position() + Vmath.vector3(lua.Math.random(-30, 30), lua.Math.random(-30, 30), 0);
								var rot = Vmath.quat_rotation_z(lua.Math.rad(lua.Math.random(360)));
								var scale = lua.Math.random(5, 8) / 10;
								Factory.create("#factory", pos, rot, lua.Table.create(), scale);
							}
							self.debris = false;
						}
					}
					//
					// the block is not destroyed
					// update the sprite to reflect current state
					//
					else {
						var damage_level = Math.floor(3 * self.durability / self.initial_durability);
						Msg.post("#sprite", SpriteMessages.play_animation, { id: self.damage_levels[damage_level] });
					}
				}
			}
	}
}
