import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";
import { Chip, Logo, Wordmark } from "./parts";
import { C, F } from "./theme";

// 1280x640 banner over in-game footage (rainbow gun chams under the Der Eisendrache sky).
// Text stays still so the GIF loops cleanly with the clip.
export const BannerClip: React.FC = () => (
	<AbsoluteFill style={{ background: C.bg, overflow: "hidden" }}>
		{/* footage, pushed right and slightly zoomed so the gun sits on the right half */}
		<AbsoluteFill style={{ left: 300 }}>
			<OffthreadVideo src={staticFile("gunchams.mp4")} muted style={{ width: 1080, height: 640, objectFit: "cover", objectPosition: "60% 40%" }} />
		</AbsoluteFill>
		{/* fade the footage into the charcoal on the left, plus a soft vignette */}
		<AbsoluteFill
			style={{
				background: `linear-gradient(90deg, ${C.bg} 0%, ${C.bg} 30%, rgba(29,29,31,0.85) 45%, rgba(29,29,31,0.25) 65%, rgba(29,29,31,0) 80%)`,
			}}
		/>
		<AbsoluteFill style={{ background: "radial-gradient(ellipse at 70% 50%, transparent 55%, rgba(0,0,0,0.45))" }} />
		<AbsoluteFill style={{ background: `linear-gradient(0deg, rgba(29,29,31,0.9) 0%, rgba(29,29,31,0) 22%)` }} />

		<div style={{ position: "absolute", left: 72, top: 128, width: 600 }}>
			<Logo size={88} eyeGlow={1.1} />
			<div style={{ marginTop: 18 }}>
				<Wordmark size={104} />
			</div>
			<div style={{ marginTop: 16, fontFamily: F.body, fontSize: 25, fontWeight: 500, color: C.text }}>
				Mod menu for <span style={{ color: C.white, fontWeight: 600 }}>Call of Duty: Black Ops III</span>
			</div>
			<div style={{ marginTop: 26, display: "flex", gap: 8 }}>
				<Chip accent>Offline · Private</Chip>
				<Chip>Zombies</Chip>
				<Chip>MP custom games</Chip>
			</div>
		</div>

		{/* what the footage shows */}
		<div
			style={{
				position: "absolute",
				right: 40,
				bottom: 36,
				fontFamily: F.body,
				fontSize: 15,
				color: C.white,
				padding: "6px 12px",
				background: "rgba(29,29,31,0.7)",
				border: `1px solid ${C.line}`,
				borderRadius: 4,
				display: "flex",
				gap: 8,
				alignItems: "center",
			}}
		>
			<div style={{ width: 7, height: 7, borderRadius: 4, background: C.glow, boxShadow: `0 0 8px ${C.glow}` }} />
			Gun Chams · Rainbow
		</div>
		<div style={{ position: "absolute", left: 72, bottom: 40, fontFamily: F.body, fontSize: 16, color: C.muted }}>github.com/NNOOCCDD/synthex-bo3</div>
	</AbsoluteFill>
);
