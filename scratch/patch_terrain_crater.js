const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../main/entities/terrain/terrain.script');
let content = fs.readFileSync(filePath, 'utf8');
const isCrlf = content.includes('\r\n');
let normalized = content.replace(/\r\n/g, '\n');

const target = `	elseif message_id == hash("carve_crater") then
		local cx = message.x or 0
		local cy = message.y or 0
		local r = message.radius or 30
		constants.log(">>> TERRAIN ON_MESSAGE CARVE_CRATER at:", cx, cy, "r:", r)

		local min_gx, min_gy, max_gx, max_gy, cleared = terrain_grid.carve_circle(cx, cy, r)
		if cleared > 0 and self.is_initialized then
			local grid = terrain_grid.grid
			local biome = self.current_biome or "grass"

			local sub_w = max_gx - min_gx + 1
			local sub_h = max_gy - min_gy + 1

			local sub_buf = buffer.create(sub_w * sub_h, {
				{ name = hash("rgba"), type = buffer.VALUE_TYPE_UINT8, count = 4 }
			})
			local sub_stream = buffer.get_stream(sub_buf, hash("rgba"))

			local s_idx = 1
			for gy = min_gy, max_gy do
				for gx = min_gx, max_gx do
					write_terrain_pixel(sub_stream, s_idx, gx, gy, self.w, self.h, grid, biome)
					s_idx = s_idx + 4
				end
			end

			pcall(function()
				resource.set_texture(TEXTURE_PATH, {
					x = min_gx,
					y = min_gy,
					width = sub_w,
					height = sub_h,
					type = graphics.TEXTURE_TYPE_2D,
					format = graphics.TEXTURE_FORMAT_RGBA
				}, sub_buf)
			end)
		end
	end`;

const replacement = `	elseif message_id == hash("carve_crater") then
		local cx = message.x or 0
		local cy = message.y or 0
		local r = message.radius or 30
		constants.log(">>> TERRAIN ON_MESSAGE CARVE_CRATER at:", cx, cy, "r:", r)

		local min_gx, min_gy, max_gx, max_gy, cleared = terrain_grid.carve_circle(cx, cy, r)
		if cleared > 0 and self.is_initialized and self.stream then
			local gcx = math.floor(cx / terrain_grid.scale)
			local gcy = math.floor(cy / terrain_grid.scale)
			local gr = math.ceil(r / terrain_grid.scale)
			local gr2 = gr * gr

			local scorch_pad = 4
			local scorch_r = gr + scorch_pad
			local scorch_r2 = scorch_r * scorch_r

			local upd_min_gx = math.max(0, gcx - scorch_r)
			local upd_max_gx = math.min(self.w - 1, gcx + scorch_r)
			local upd_min_gy = math.max(0, gcy - scorch_r)
			local upd_max_gy = math.min(self.h - 1, gcy + scorch_r)

			local sub_w = upd_max_gx - upd_min_gx + 1
			local sub_h = upd_max_gy - upd_min_gy + 1

			for gy = upd_min_gy, upd_max_gy do
				local dy = gy - gcy
				local dy2 = dy * dy
				local row_offset = (gy * self.w) * 4
				for gx = upd_min_gx, upd_max_gx do
					local dx = gx - gcx
					local dist2 = dx * dx + dy2
					local p_idx = row_offset + gx * 4 + 1

					if dist2 <= gr2 then
						-- Vaporized by blast -> Transparent air (0, 0, 0, 0)
						self.stream[p_idx + 0] = 0
						self.stream[p_idx + 1] = 0
						self.stream[p_idx + 2] = 0
						self.stream[p_idx + 3] = 0
					elseif dist2 <= scorch_r2 then
						-- Scorched / charred blast rim on remaining solid terrain
						if self.stream[p_idx + 3] > 0 then
							local edge_dist = math.sqrt(dist2) - gr
							local scorch = 0.20 + (edge_dist / scorch_pad) * 0.80
							if scorch > 1.0 then scorch = 1.0 end
							self.stream[p_idx + 0] = math.floor(self.stream[p_idx + 0] * scorch)
							self.stream[p_idx + 1] = math.floor(self.stream[p_idx + 1] * scorch)
							self.stream[p_idx + 2] = math.floor(self.stream[p_idx + 2] * scorch)
						end
					end
				end
			end

			local sub_buf = buffer.create(sub_w * sub_h, {
				{ name = hash("rgba"), type = buffer.VALUE_TYPE_UINT8, count = 4 }
			})
			local sub_stream = buffer.get_stream(sub_buf, hash("rgba"))

			local s_idx = 1
			for gy = upd_min_gy, upd_max_gy do
				local row_offset = (gy * self.w) * 4
				for gx = upd_min_gx, upd_max_gx do
					local p_idx = row_offset + gx * 4 + 1
					sub_stream[s_idx + 0] = self.stream[p_idx + 0]
					sub_stream[s_idx + 1] = self.stream[p_idx + 1]
					sub_stream[s_idx + 2] = self.stream[p_idx + 2]
					sub_stream[s_idx + 3] = self.stream[p_idx + 3]
					s_idx = s_idx + 4
				end
			end

			pcall(function()
				resource.set_texture(TEXTURE_PATH, {
					x = upd_min_gx,
					y = upd_min_gy,
					width = sub_w,
					height = sub_h,
					type = graphics.TEXTURE_TYPE_2D,
					format = graphics.TEXTURE_FORMAT_RGBA
				}, sub_buf)
			end)
		end
	end`;

if (!normalized.includes(target)) {
    console.error("Target block not found in terrain.script!");
    process.exit(1);
}

normalized = normalized.replace(target, replacement);

if (isCrlf) {
    normalized = normalized.replace(/\n/g, '\r\n');
}

fs.writeFileSync(filePath, normalized, 'utf8');
console.log("Successfully patched crater carving in terrain.script!");
