import lua.Table;
import lua.Lua.tonumber;
import defold.Render;
import defold.Sys;
import defold.Vmath;
import defold.types.Vector4;
import defold.types.Matrix4;
import defold.types.Message;

typedef CustomRenderData = {
	var tile_pred:RenderPredicate;
	var gui_pred:RenderPredicate;
	var text_pred:RenderPredicate;
	var particle_pred:RenderPredicate;
	var clear_color:Vector4;
	var view:Matrix4;
	var zoom:Float;
}

class CustomRender extends defold.support.RenderScript<CustomRenderData> {
	override function init(self:CustomRenderData) {
		self.tile_pred = Render.predicate(Table.create(["tile"]));
		self.gui_pred = Render.predicate(Table.create(["gui"]));
		self.text_pred = Render.predicate(Table.create(["text"]));
		self.particle_pred = Render.predicate(Table.create(["particle"]));

		self.clear_color = Vmath.vector4(0, 0, 0, 0);
		self.clear_color.x = tonumber(Sys.get_config("render.clear_color_red", "0"));
		self.clear_color.y = tonumber(Sys.get_config("render.clear_color_green", "0"));
		self.clear_color.z = tonumber(Sys.get_config("render.clear_color_blue", "0"));
		self.clear_color.w = tonumber(Sys.get_config("render.clear_color_alpha", "0"));

		self.view = Vmath.matrix4();
		self.zoom = 1.0;
	}

	override function update(self:CustomRenderData, _) {
		Render.set_depth_mask(true);
		var clearData:RenderClearBuffers = Table.create();
		clearData.set(BUFFER_COLOR_BIT, self.clear_color);
		clearData.set(BUFFER_DEPTH_BIT, 1);
		clearData.set(BUFFER_STENCIL_BIT, 0);
		Render.clear(clearData);

		Render.set_viewport(0, 0, Render.get_window_width(), Render.get_window_height());
		Render.set_view(self.view);

		Render.set_depth_mask(false);
		Render.disable_state(STATE_DEPTH_TEST);
		Render.disable_state(STATE_STENCIL_TEST);
		Render.enable_state(STATE_BLEND);
		Render.set_blend_func(BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA);
		Render.disable_state(STATE_CULL_FACE);

		var w = Render.get_width();
		var h = Render.get_height();
		var zw = w * self.zoom;
		var zh = h * self.zoom;
		var dw = w - zw;
		var dh = h - zh;
		// Render.set_projection(Vmath.matrix4_orthographic(320, 640 + 320, 180, 360 + 180, -1, 1));
		Render.set_projection(Vmath.matrix4_orthographic(dw / 2, w - (dw / 2), dh / 2, h - (dh / 2), -1, 1));
		// Render.set_projection(Vmath.matrix4_orthographic(dw / 2, zw, dh / 2, zh, -1, 1));

		Render.draw(self.tile_pred);
		Render.draw(self.particle_pred);
		Render.draw_debug3d();

		Render.set_view(Vmath.matrix4());
		Render.set_projection(Vmath.matrix4_orthographic(0, Render.get_window_width(), 0, Render.get_window_height(), -1, 1));

		Render.enable_state(STATE_STENCIL_TEST);
		Render.draw(self.gui_pred);
		Render.draw(self.text_pred);
		Render.disable_state(STATE_STENCIL_TEST);

		Render.set_depth_mask(false);
		Render.draw_debug2d();
	}

	override function on_message<T>(self:CustomRenderData, message_id:Message<T>, message:T, _) {
		switch (message_id) {
			case RenderMessages.clear_color:
				self.clear_color = message.color;
			case RenderMessages.set_view_projection:
				self.view = message.view;
			case Messages.set_zoom:
				self.zoom = message.zoom;
		}
	}
}
